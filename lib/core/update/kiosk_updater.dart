// Kiosk ilovalarining online yangilanishi (ADR-037).
//
// ⚠️ Bu fayl `_kiosk_update_kit` dan nusxalanadi — 5 kiosk repoda bir xil.
// O'zgartirsangiz: kit'dagi asl nusxani tuzating va `sync.ps1` ni ishga tushiring.
//
// Oqim: ochilgandan 60 s keyin va har 3 soatda `version.json` → yangi bo'lsa
// fonda yuklab, SHA-256 tekshiradi → ilova bo'sh turganda (≥ 2 daqiqa teginish
// yo'q + ilova `canInstall` ruxsat bersa) 15 s ogohlantirish → Setup.exe jim
// rejimda → ilova yopiladi → Inno Setup fayllarni almashtirib, ilovani qayta
// ochadi (yoki KioskLauncher qayta ochadi).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

// --- Kompilyatsiya vaqtidagi sozlamalar (faqat sinov build'lari uchun) ---
const _kUpdateUrl = String.fromEnvironment('UPDATE_URL');
const _kReportUrl = String.fromEnvironment('UPDATE_REPORT_URL');
const _kTest = bool.fromEnvironment('UPDATE_TEST');
const _kInDebug = bool.fromEnvironment('UPDATE_IN_DEBUG');
const _kFirstDelaySec =
    int.fromEnvironment('UPDATE_FIRST_DELAY_SEC', defaultValue: 60);
const _kIntervalMin =
    int.fromEnvironment('UPDATE_INTERVAL_MIN', defaultValue: 180);
const _kIdleSec = int.fromEnvironment('UPDATE_IDLE_SEC', defaultValue: 120);
const _kWarningSec = int.fromEnvironment('UPDATE_WARNING_SEC', defaultValue: 15);

/// Ilovaga xos sozlamalar.
class KioskUpdateConfig {
  const KioskUpdateConfig({
    required this.appKey,
    required this.appTitle,
    required this.installName,
    this.origin = 'https://qabulxona.gennis.uz',
    this.deviceId,
    this.kioskKey,
    this.httpClient,
  });

  /// Serverdagi kalit: `eshik_kiosk`, `info_kiosk`, `navbat_olish`,
  /// `navbat_holati`, `shaxiy_qabul_kiosk`.
  final String appKey;

  /// Ekranda ko'rinadigan nom («Navbat olish»).
  final String appTitle;

  /// Inno `MyAppName` — `C:\Kiosk\<installName>` va
  /// `%LOCALAPPDATA%\<installName>` (log, yuklangan installer).
  final String installName;

  /// Backend manzili (`/api` siz).
  final String origin;

  /// Qurilma identifikatori (bo'lmasa — kompyuter nomi).
  final String? deviceId;

  /// `X-Kiosk-Key` (bo'lsa).
  final String? kioskKey;

  /// Ilovaning o'z TLS sozlamasi bilan HttpClient (masalan ildiz sertifikat).
  final HttpClient Function()? httpClient;

  Uri get versionUri => _kUpdateUrl.isNotEmpty
      ? Uri.parse(_kUpdateUrl)
      : Uri.parse('$origin/downloads/kiosk/$appKey/version.json');

  Uri? get reportUri {
    if (_kReportUrl.isNotEmpty) return Uri.parse(_kReportUrl);
    if (_kTest) return null; // sinov build'i prod jadvalini ifloslamasin
    return Uri.parse('$origin/api/kiosk/app-update/report');
  }
}

/// Serverdagi `version.json`.
class RemoteRelease {
  const RemoteRelease({
    required this.version,
    required this.minVersion,
    required this.setupUrl,
    required this.sha256,
    required this.changelog,
  });

  final String version;
  final String minVersion;
  final Uri setupUrl;
  final String sha256;
  final String changelog;

  String get fileName {
    final last = setupUrl.pathSegments.isEmpty ? '' : setupUrl.pathSegments.last;
    final safe = last.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return safe.toLowerCase().endsWith('.exe') ? safe : 'setup_v$version.exe';
  }
}

enum UpdatePhase {
  /// Hali tekshirilmagan.
  idle,
  checking,
  upToDate,

  /// Yangi versiya bor, hali yuklanmagan.
  available,
  downloading,

  /// Yuklangan va tekshirilgan — o'rnatishni kutmoqda.
  ready,

  /// Ekranda ogohlantirish (teskari sanoq).
  warning,
  installing,
  failed,
  unsupported,
}

class KioskUpdater extends ChangeNotifier {
  KioskUpdater._(this.config, this._canInstall);

  static KioskUpdater? _instance;

  /// `init` chaqirilmagan bo'lsa — null (UI bo'limlari o'zi yashirinadi).
  static KioskUpdater? get instance => _instance;

  /// Windows release build (yoki `UPDATE_IN_DEBUG` / `UPDATE_TEST`).
  static bool get supported =>
      KioskUpdaterDebug.forceSupported ||
      (!kIsWeb && Platform.isWindows && (kReleaseMode || _kInDebug || _kTest));

  /// Ilova KioskLauncher orqali ishga tushganmi (Shell Launcher rejimi).
  static bool get underLauncher =>
      KioskUpdaterDebug.underLauncher ??
      (!kIsWeb && Platform.environment['KIOSK_LAUNCHER'] == '1');

  /// `main()` da, `runApp` dan oldin bir marta.
  /// [canInstall] — ilovaga xos bo'shlik sharti (chop etish yo'q, e'lon
  /// o'ynamayapti va h.k.). Teginishlar bu yerda o'zi hisobga olinadi.
  static KioskUpdater init(
    KioskUpdateConfig config, {
    bool Function()? canInstall,
  }) {
    final u = KioskUpdater._(config, canInstall ?? () => true);
    _instance = u;
    u._booting = u._boot();
    return u;
  }

  /// Ilova «Chiqish» (PIN) orqali yopilayotganini KioskLauncher'ga bildiradi —
  /// aks holda launcher ilovani darhol qayta ochadi. Chiqish oqimida
  /// `exit()` dan oldin chaqiring.
  static void notifyExitRequested() {
    if (!underLauncher) return;
    try {
      File('${_exeDir()}\\exit.flag')
          .writeAsStringSync(DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<void> _booting = Future<void>.value();

  /// Testlar uchun: ishga tushish (versiya o'qish, bayroqlar) tugashi.
  @visibleForTesting
  Future<void> get debugBooted => _booting;

  final KioskUpdateConfig config;
  final bool Function() _canInstall;

  UpdatePhase phase = UpdatePhase.idle;
  String currentVersion = '';
  RemoteRelease? remote;
  DateTime? lastCheck;
  String? lastError;
  double progress = 0;

  /// Ogohlantirish qo'lda boshlanganmi (panel tugmasi) — teginish bekor qilmaydi.
  bool warningManual = false;
  int warningSecondsLeft = 0;

  bool get mandatory =>
      remote != null && isNewer(remote!.minVersion, currentVersion);
  bool get hasUpdate =>
      remote != null && isNewer(remote!.version, currentVersion);
  bool get busy =>
      phase == UpdatePhase.checking ||
      phase == UpdatePhase.downloading ||
      phase == UpdatePhase.warning ||
      phase == UpdatePhase.installing;

  DateTime _lastActivity = DateTime.now();
  Timer? _checkTimer;
  Timer? _installTimer;
  Timer? _warningTimer;
  File? _setupFile;
  final _rnd = Random();

  Duration get idleFor => DateTime.now().difference(_lastActivity);

  String get logPath => '${_dataDir()}\\update.log';

  /// Har qanday foydalanuvchi faoliyati (teginish, skan, chaqiruv).
  /// Avtomatik ogohlantirish paytida — o'rnatishni keyinga qoldiradi.
  void markActivity() {
    _lastActivity = DateTime.now();
    if (phase == UpdatePhase.warning && !warningManual) {
      _cancelWarning('foydalanuvchi faoliyati — keyinga qoldirildi');
    }
  }

  // ----------------------------------------------------------------- boot

  Future<void> _boot() async {
    try {
      currentVersion = KioskUpdaterDebug.currentVersion ??
          (await PackageInfo.fromPlatform()).version;
    } catch (e) {
      currentVersion = '0.0.0';
      _log('versiya o\'qilmadi: $e');
    }
    if (!supported) {
      phase = UpdatePhase.unsupported;
      notifyListeners();
      return;
    }
    _log('ishga tushdi: v$currentVersion, launcher=$underLauncher, '
        'url=${config.versionUri}');
    _cleanupFlags();
    await _reportJustInstalled();
    notifyListeners();
    if (KioskUpdaterDebug.noTimers) return;

    final first = Duration(seconds: _kFirstDelaySec);
    Timer(first, () => unawaited(checkNow()));
    _scheduleNextCheck(first);
    _installTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _maybeAutoInstall());
  }

  void _scheduleNextCheck(Duration after) {
    _checkTimer?.cancel();
    // 5 kiosk serverga bir soniyada urilmasin: 0–10 daqiqa tasodifiy
    final jitter = _kIntervalMin >= 30 ? _rnd.nextInt(600) : 0;
    _checkTimer = Timer(
      after + Duration(minutes: _kIntervalMin, seconds: jitter),
      () {
        unawaited(checkNow());
        _scheduleNextCheck(Duration.zero);
      },
    );
  }

  // ---------------------------------------------------------------- check

  /// `version.json` ni o'qiydi; yangi bo'lsa darhol fonda yuklaydi.
  Future<void> checkNow({bool manual = false}) async {
    if (!supported || busy) return;
    phase = UpdatePhase.checking;
    lastError = null;
    notifyListeners();
    try {
      final rel = await _fetchRelease();
      remote = rel;
      lastCheck = DateTime.now();
      if (rel == null || !isNewer(rel.version, currentVersion)) {
        phase = UpdatePhase.upToDate;
        _log('tekshiruv: yangilanish yo\'q (server: ${rel?.version ?? '-'})'
            '${manual ? ' [qo\'lda]' : ''}');
        notifyListeners();
        unawaited(_report('up_to_date'));
        return;
      }
      _log('tekshiruv: yangi versiya ${rel.version}'
          '${mandatory ? ' (majburiy)' : ''}${manual ? ' [qo\'lda]' : ''}');
      phase = UpdatePhase.available;
      notifyListeners();
      unawaited(_report('update_available'));
      await _download(rel);
    } catch (e) {
      lastCheck = DateTime.now();
      _fail('tekshiruv xatosi: $e');
    }
  }

  Future<RemoteRelease?> _fetchRelease() async {
    final client = _client();
    try {
      final req = await client.getUrl(config.versionUri);
      req.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final res = await req.close().timeout(const Duration(seconds: 20));
      // Reliz hali yuklanmagan — xato emas
      if (res.statusCode == 404) {
        await res.drain<void>();
        return null;
      }
      if (res.statusCode != 200) {
        await res.drain<void>();
        throw HttpException('version.json: HTTP ${res.statusCode}');
      }
      // utf8 — changelog'dagi o'zbekcha/ruscha harflar buzilmasin
      final body = await res
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      final j = jsonDecode(body) as Map<String, dynamic>;
      final app = j['app'];
      if (app is String && app.isNotEmpty && app != config.appKey) {
        throw FormatException('version.json boshqa ilovaniki: $app');
      }
      final version = (j['version'] as String?)?.trim() ?? '';
      if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
        throw FormatException('noto\'g\'ri versiya: $version');
      }
      final setupUrl = Uri.parse((j['setup_url'] as String?) ?? '');
      if (!_allowedUrl(setupUrl)) {
        throw FormatException('setup_url ruxsat etilmagan: $setupUrl');
      }
      final sha = ((j['sha256'] as String?) ?? '').trim().toLowerCase();
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
        throw const FormatException('sha256 noto\'g\'ri');
      }
      return RemoteRelease(
        version: version,
        minVersion: (j['min_version'] as String?)?.trim() ?? '0.0.0',
        setupUrl: setupUrl,
        sha256: sha,
        changelog: (j['changelog'] as String?) ?? '',
      );
    } finally {
      client.close(force: true);
    }
  }

  bool _allowedUrl(Uri u) {
    if (u.scheme == 'https' && u.host.isNotEmpty) return true;
    // http — faqat sinov build'ida va faqat shu kompyuterning o'zida
    return (_kTest || KioskUpdaterDebug.allowHttpLocalhost) &&
        u.scheme == 'http' &&
        (u.host == '127.0.0.1' || u.host == 'localhost');
  }

  // ------------------------------------------------------------- download

  Future<void> _download(RemoteRelease rel) async {
    final dir = Directory('${_dataDir()}\\updates');
    await dir.create(recursive: true);
    final target = File('${dir.path}\\${rel.fileName}');

    // Avval yuklangan va butun bo'lsa — qayta yuklamaymiz
    if (await target.exists() && await _sha256(target) == rel.sha256) {
      _setupFile = target;
      phase = UpdatePhase.ready;
      progress = 1;
      _log('installer avvaldan bor: ${target.path}');
      notifyListeners();
      return;
    }

    phase = UpdatePhase.downloading;
    progress = 0;
    notifyListeners();
    unawaited(_report('downloading'));

    final part = File('${target.path}.part');
    final client = _client();
    try {
      final req = await client.getUrl(rel.setupUrl);
      final res = await req.close().timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        await res.drain<void>();
        // tekshirilmasa — 404 sahifasi .exe bo'lib ishga tushadi
        throw HttpException('yuklab bo\'lmadi: HTTP ${res.statusCode}');
      }
      final total = res.contentLength;
      var received = 0;
      var lastNotify = DateTime.now();
      final sink = part.openWrite();
      try {
        // faylga oqim bilan: 100+ MB installer xotiraga yig'ilmaydi
        await for (final chunk
            in res.timeout(const Duration(seconds: 60))) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0 &&
              DateTime.now().difference(lastNotify).inMilliseconds > 250) {
            progress = received / total;
            lastNotify = DateTime.now();
            notifyListeners();
          }
        }
      } finally {
        await sink.close();
      }
      final digest = await _sha256(part);
      if (digest != rel.sha256) {
        await part.delete();
        throw const FileSystemException(
            'fayl buzilgan yoki almashtirilgan (SHA-256 mos kelmadi)');
      }
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      // eski installerlar joy egallamasin
      await for (final f in dir.list()) {
        if (f is File && f.path != target.path) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
      _setupFile = target;
      progress = 1;
      phase = UpdatePhase.ready;
      _log('yuklandi: ${target.path} (${(received / 1048576).toStringAsFixed(1)} MB)');
      notifyListeners();
    } catch (e) {
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
      _fail('yuklash xatosi: $e');
    } finally {
      client.close(force: true);
    }
  }

  // -------------------------------------------------------------- install

  /// Testlar uchun: 15 s lik o'rnatish taymerining bir qadami.
  @visibleForTesting
  void debugTick() => _maybeAutoInstall();

  void _maybeAutoInstall() {
    if (phase != UpdatePhase.ready || _setupFile == null) return;
    if (idleFor < (KioskUpdaterDebug.idle ?? const Duration(seconds: _kIdleSec))) {
      return;
    }
    bool ok;
    try {
      ok = _canInstall();
    } catch (_) {
      ok = false;
    }
    if (!ok) return;
    _startWarning(manual: false);
  }

  /// Panel tugmasi: kerak bo'lsa tekshirib/yuklab, ogohlantirish bilan o'rnatadi
  /// (bo'shlikni kutmaydi).
  Future<void> installNow() async {
    if (!supported || busy) return;
    if (phase != UpdatePhase.ready) {
      await checkNow(manual: true);
    }
    if (phase == UpdatePhase.ready && _setupFile != null) {
      _startWarning(manual: true);
    }
  }

  /// Qo'lda boshlangan ogohlantirishni bekor qilish.
  void cancelWarning() => _cancelWarning('bekor qilindi [qo\'lda]');

  void _startWarning({required bool manual}) {
    warningManual = manual;
    warningSecondsLeft = KioskUpdaterDebug.warningSeconds ?? _kWarningSec;
    phase = UpdatePhase.warning;
    _log('ogohlantirish boshlandi (${manual ? 'qo\'lda' : 'avto'})');
    notifyListeners();
    _warningTimer?.cancel();
    _warningTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      warningSecondsLeft--;
      if (warningSecondsLeft <= 0) {
        t.cancel();
        unawaited(_install());
      } else {
        notifyListeners();
      }
    });
  }

  void _cancelWarning(String why) {
    if (phase != UpdatePhase.warning) return;
    _warningTimer?.cancel();
    phase = UpdatePhase.ready;
    warningManual = false;
    _log('ogohlantirish: $why');
    notifyListeners();
  }

  Future<void> _install() async {
    final setup = _setupFile;
    final rel = remote;
    if (setup == null || rel == null) return;
    phase = UpdatePhase.installing;
    notifyListeners();
    // «Yangilanmoqda…» ekrani chizilib ulgursin
    await Future<void>.delayed(
        KioskUpdaterDebug.installDelay ?? const Duration(milliseconds: 1200));
    try {
      if (!await setup.exists() || await _sha256(setup) != rel.sha256) {
        throw const FileSystemException('installer o\'zgargan yoki yo\'q');
      }
      File('${_dataDir()}\\last_install.json').writeAsStringSync(jsonEncode({
        'from': currentVersion,
        'to': rel.version,
        'at': DateTime.now().toIso8601String(),
      }));
      final args = <String>[
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/CLOSEAPPLICATIONS',
        '/LOG=${_dataDir()}\\setup.log',
      ];
      if (underLauncher) {
        // ilovani launcher qayta ochadi; Inno ham ochsa — ikki nusxa bo'ladi
        args.add('/NORELAUNCH');
        final name = setup.uri.pathSegments.last.replaceAll(
            RegExp(r'\.exe$', caseSensitive: false), '');
        File('${_exeDir()}\\updating.flag').writeAsStringSync(name);
      }
      _log('o\'rnatish: ${setup.path} ${args.join(' ')}');
      final runner = KioskUpdaterDebug.runInstaller;
      if (runner != null) {
        await runner(setup.path, args);
        return;
      }
      await Process.start(setup.path, args,
          mode: ProcessStartMode.detached);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      exit(0); // fayllar band bo'lmasin — Inno Setup ularni almashtiradi
    } catch (e) {
      _fail('o\'rnatish xatosi: $e');
    }
  }

  // --------------------------------------------------------------- report

  Future<void> _reportJustInstalled() async {
    final f = File('${_dataDir()}\\last_install.json');
    if (!f.existsSync()) return;
    try {
      final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      if (j['to'] == currentVersion) {
        _log('yangilandi: ${j['from']} → $currentVersion');
        await _report('installed');
      } else {
        _log('o\'rnatish natijasi kutilganidek emas: ${j['from']} → '
            '${j['to']}, hozir $currentVersion (setup.log ni qarang)');
        lastError = 'oxirgi o\'rnatish muvaffaqiyatsiz (setup.log)';
        await _report('failed');
      }
    } catch (_) {
    } finally {
      try {
        f.deleteSync();
      } catch (_) {}
    }
  }

  Future<void> _report(String status) async {
    final uri = config.reportUri;
    if (uri == null) return;
    final host = Platform.environment['COMPUTERNAME'] ?? Platform.localHostname;
    final body = jsonEncode({
      'app': config.appKey,
      'device_id': (config.deviceId?.isNotEmpty ?? false)
          ? config.deviceId
          : host.toLowerCase(),
      'device_name': host,
      'version': currentVersion,
      'status': status,
      'available_version': remote?.version,
      'error': lastError?.substring(0, min(lastError!.length, 300)),
      'checked_at': DateTime.now().toUtc().toIso8601String(),
    });
    final client = _client();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      final key = config.kioskKey;
      if (key != null && key.isNotEmpty) req.headers.set('X-Kiosk-Key', key);
      req.add(utf8.encode(body));
      final res = await req.close().timeout(const Duration(seconds: 15));
      await res.drain<void>();
      if (res.statusCode >= 300) _log('report $status: HTTP ${res.statusCode}');
    } catch (e) {
      _log('report $status: $e');
    } finally {
      client.close(force: true);
    }
  }

  // ---------------------------------------------------------------- utils

  void _fail(String msg) {
    phase = UpdatePhase.failed;
    lastError = msg;
    progress = 0;
    _log(msg);
    notifyListeners();
    unawaited(_report('failed'));
  }

  HttpClient _client() {
    final c = config.httpClient?.call() ?? HttpClient();
    c.connectionTimeout = const Duration(seconds: 15);
    c.idleTimeout = const Duration(seconds: 30);
    return c;
  }

  void _cleanupFlags() {
    // Ilova ochildi — demak o'rnatish tugagan (yoki launcher'siz ishlayapmiz)
    for (final n in ['updating.flag', 'exit.flag']) {
      try {
        final f = File('${_exeDir()}\\$n');
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }

  String _dataDir() {
    final dbg = KioskUpdaterDebug.dataDir;
    if (dbg != null) return dbg;
    final base = Platform.environment['LOCALAPPDATA'] ??
        Directory.systemTemp.path;
    final d = Directory('$base\\${config.installName}');
    if (!d.existsSync()) {
      try {
        d.createSync(recursive: true);
      } catch (_) {}
    }
    return d.path;
  }

  static String _exeDir() =>
      KioskUpdaterDebug.exeDir ?? File(Platform.resolvedExecutable).parent.path;

  void _log(String msg) {
    debugPrint('[update] $msg');
    try {
      final f = File(logPath);
      if (f.existsSync() && f.lengthSync() > 512 * 1024) {
        final lines = f.readAsLinesSync();
        f.writeAsStringSync('${lines.skip(lines.length ~/ 2).join('\n')}\n');
      }
      f.writeAsStringSync('${DateTime.now().toIso8601String()}  $msg\n',
          mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  /// Oxirgi [n] qator (panel uchun).
  List<String> readLog([int n = 120]) {
    try {
      final lines = File(logPath).readAsLinesSync();
      return lines.length <= n ? lines : lines.sublist(lines.length - n);
    } catch (_) {
      return const [];
    }
  }

  static Future<String> _sha256(File f) async =>
      (await sha256.bind(f.openRead()).first).toString();

  /// Semver: "1.2.10" > "1.2.9". `!=` emas — aks holda eski versiya ham
  /// «yangi» deb o'rnatiladi (downgrade).
  static bool isNewer(String latest, String current) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .replaceFirst(RegExp(r'^v'), '')
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final a = parse(latest);
    final b = parse(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _installTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }
}

/// Faqat testlar uchun: tarmoq/jarayon/vaqtni boshqarish nuqtalari.
/// Ilova kodida ishlatilmaydi.
@visibleForTesting
class KioskUpdaterDebug {
  static bool forceSupported = false;
  static bool allowHttpLocalhost = false;
  static bool? underLauncher;
  static String? currentVersion;
  static String? dataDir;
  static String? exeDir;
  static Duration? idle;
  static int? warningSeconds;
  static Duration? installDelay;

  /// Berilsa — `Process.start` + `exit(0)` o'rniga chaqiriladi.
  static Future<void> Function(String exe, List<String> args)? runInstaller;

  /// true — `init` taymerlarni ishga tushirmaydi (testda qo'lda chaqiriladi).
  static bool noTimers = false;

  static void reset() {
    forceSupported = false;
    allowHttpLocalhost = false;
    underLauncher = null;
    currentVersion = null;
    dataDir = null;
    exeDir = null;
    idle = null;
    warningSeconds = null;
    installDelay = null;
    runInstaller = null;
    noTimers = false;
  }
}
