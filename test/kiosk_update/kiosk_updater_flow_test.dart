// Updater oqimi — lokal HTTP server bilan uchidan-uchigacha (ADR-037).
// ⚠️ `_kiosk_update_kit` dan nusxalanadi — 5 kiosk repoda bir xil.
//
// Haqiqiy Setup.exe ishga tushirilmaydi (KioskUpdaterDebug.runInstaller),
// qolgan hammasi — version.json, yuklash, SHA-256, bo'shlik, ogohlantirish,
// installer argumentlari, launcher bayrog'i, serverga hisobot — haqiqiy.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shaxiy_qabul_kiosk/core/update/kiosk_update_ui.dart';
import 'package:shaxiy_qabul_kiosk/core/update/kiosk_updater.dart';

class _Server {
  late HttpServer http;
  final reports = <Map<String, dynamic>>[];
  Map<String, dynamic>? versionJson;
  List<int> setupBytes = const [];
  int setupStatus = 200;

  String get origin => 'http://127.0.0.1:${http.port}';

  Future<void> start() async {
    http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen((r) async {
      final p = r.uri.path;
      if (r.method == 'POST' && p == '/api/kiosk/app-update/report') {
        reports.add(jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>);
        r.response.statusCode = 204;
      } else if (p == '/downloads/kiosk/test_app/version.json') {
        if (versionJson == null) {
          r.response.statusCode = 404;
        } else {
          r.response.headers.contentType = ContentType.json;
          r.response.add(utf8.encode(jsonEncode(versionJson)));
        }
      } else if (p.startsWith('/dl/')) {
        r.response.statusCode = setupStatus;
        if (setupStatus == 200) r.response.add(setupBytes);
      } else {
        r.response.statusCode = 404;
      }
      await r.response.close();
    });
  }

  void publish(String version, {String? sha, String? app, String? url, String min = '0.0.0'}) {
    versionJson = {
      'app': ?app,
      'version': version,
      'min_version': min,
      'setup_url': url ?? '$origin/dl/Test_Setup_v$version.exe',
      'sha256': sha ?? sha256.convert(setupBytes).toString(),
      'changelog': '• Yangi imkoniyat\n• Тест',
    };
  }
}

void main() {
  late _Server server;
  late Directory data;
  late Directory exeDir;
  late List<List<String>> installs;
  KioskUpdater? created;

  KioskUpdater make({bool Function()? canInstall}) => created = KioskUpdater.init(
        KioskUpdateConfig(
          appKey: 'test_app',
          appTitle: 'Test',
          installName: 'TestApp',
          origin: server.origin,
          deviceId: 'e2e-1',
        ),
        canInstall: canInstall,
      );

  Future<void> waitFor(bool Function() cond, {int ms = 8000}) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (!cond()) {
      if (DateTime.now().isAfter(end)) fail('kutilgan holat bo\'lmadi');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  setUp(() async {
    // flutter_test hamma HTTP so'rovga 400 qaytaradi — bu testda haqiqiy lokal server kerak
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    server = _Server();
    await server.start();
    final rnd = Random(7);
    server.setupBytes = [0x4D, 0x5A, ...List.generate(300 * 1024, (_) => rnd.nextInt(256))];
    data = await Directory.systemTemp.createTemp('kiosk_upd_data');
    exeDir = await Directory.systemTemp.createTemp('kiosk_upd_exe');
    installs = [];
    KioskUpdaterDebug.forceSupported = true;
    KioskUpdaterDebug.allowHttpLocalhost = true;
    KioskUpdaterDebug.noTimers = true;
    KioskUpdaterDebug.currentVersion = '1.0.0';
    KioskUpdaterDebug.dataDir = data.path;
    KioskUpdaterDebug.exeDir = exeDir.path;
    KioskUpdaterDebug.idle = Duration.zero;
    KioskUpdaterDebug.warningSeconds = 1;
    KioskUpdaterDebug.installDelay = Duration.zero;
    KioskUpdaterDebug.underLauncher = false;
    KioskUpdaterDebug.runInstaller = (exe, args) async => installs.add([exe, ...args]);
  });

  tearDown(() async {
    created?.dispose();
    created = null;
    KioskUpdaterDebug.reset();
    await server.http.close(force: true);
    for (final d in [data, exeDir]) {
      try {
        await d.delete(recursive: true);
      } catch (_) {}
    }
  });

  test('to\'liq oqim: tekshiruv → yuklash → SHA-256 → bo\'shlik → ogohlantirish → jim o\'rnatish', () async {
    server.publish('1.1.0', app: 'test_app');
    final u = make();
    await u.debugBooted;
    await u.checkNow();
    expect(u.phase, UpdatePhase.ready);
    expect(u.remote!.version, '1.1.0');
    expect(u.remote!.changelog, contains('Тест'));
    final file = File('${data.path}\\updates\\Test_Setup_v1.1.0.exe');
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), server.setupBytes.length);

    u.debugTick();
    expect(u.phase, UpdatePhase.warning);
    await waitFor(() => installs.isNotEmpty);
    final args = installs.single;
    expect(args.first, file.path);
    expect(args, containsAll(['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CLOSEAPPLICATIONS']));
    expect(args.any((a) => a.startsWith('/LOG=')), isTrue);
    expect(args, isNot(contains('/NORELAUNCH')));
    expect(File('${exeDir.path}\\updating.flag').existsSync(), isFalse);
    final last = jsonDecode(File('${data.path}\\last_install.json').readAsStringSync());
    expect(last['from'], '1.0.0');
    expect(last['to'], '1.1.0');

    await waitFor(() => server.reports.length >= 2);
    expect(server.reports.map((r) => r['status']), containsAll(['update_available', 'downloading']));
    final r0 = server.reports.first;
    expect(r0['app'], 'test_app');
    expect(r0['device_id'], 'e2e-1');
    expect(r0['version'], '1.0.0');
    expect(r0['available_version'], '1.1.0');
    expect(File(u.logPath).readAsStringSync(), contains('yangi versiya 1.1.0'));
  });

  test('KioskLauncher ostida: /NORELAUNCH va updating.flag', () async {
    KioskUpdaterDebug.underLauncher = true;
    server.publish('1.1.0');
    final u = make();
    await u.debugBooted;
    await u.checkNow();
    u.debugTick();
    await waitFor(() => installs.isNotEmpty);
    expect(installs.single, contains('/NORELAUNCH'));
    expect(File('${exeDir.path}\\updating.flag').readAsStringSync(), 'Test_Setup_v1.1.0');
  });

  test('ilova band (canInstall=false) yoki yaqinda teginilgan — o\'rnatmaydi', () async {
    var busy = true;
    server.publish('1.1.0');
    final u = make(canInstall: () => !busy);
    await u.debugBooted;
    await u.checkNow();
    u.debugTick();
    expect(u.phase, UpdatePhase.ready);

    busy = false;
    KioskUpdaterDebug.idle = const Duration(minutes: 2);
    u.markActivity();
    u.debugTick();
    expect(u.phase, UpdatePhase.ready, reason: '2 daqiqa o\'tmagan');
  });

  test('avtomatik ogohlantirish paytida teginish — keyinga qoldiriladi', () async {
    server.publish('1.1.0');
    final u = make();
    await u.debugBooted;
    await u.checkNow();
    u.debugTick();
    expect(u.phase, UpdatePhase.warning);
    u.markActivity();
    expect(u.phase, UpdatePhase.ready);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(installs, isEmpty);
  });

  test('qo\'lda o\'rnatish: teginish bekor qilmaydi, «Bekor qilish» qiladi', () async {
    server.publish('1.1.0');
    KioskUpdaterDebug.warningSeconds = 3;
    final u = make(canInstall: () => false);
    await u.debugBooted;
    await u.installNow(); // tekshiradi + yuklaydi + ogohlantirish
    expect(u.phase, UpdatePhase.warning);
    expect(u.warningManual, isTrue);
    u.markActivity();
    expect(u.phase, UpdatePhase.warning);
    u.cancelWarning();
    expect(u.phase, UpdatePhase.ready);

    KioskUpdaterDebug.warningSeconds = 1;
    await u.installNow();
    await waitFor(() => installs.isNotEmpty);
  });

  test('SHA-256 mos kelmasa — o\'rnatilmaydi, fayl o\'chiriladi, «failed» hisobot', () async {
    server.publish('1.1.0', sha: 'a' * 64);
    final u = make();
    await u.debugBooted;
    await u.checkNow();
    expect(u.phase, UpdatePhase.failed);
    expect(u.lastError, contains('SHA-256'));
    expect(Directory('${data.path}\\updates').listSync(), isEmpty);
    u.debugTick();
    expect(installs, isEmpty);
    await waitFor(() => server.reports.any((r) => r['status'] == 'failed'));

    // keyingi siklda to'g'ri fayl — tiklanadi
    server.publish('1.1.0');
    await u.checkNow();
    expect(u.phase, UpdatePhase.ready);
  });

  test('installer 404 — xato, HTML .exe bo\'lib saqlanmaydi', () async {
    server.publish('1.1.0');
    server.setupStatus = 404;
    final u = make();
    await u.debugBooted;
    await u.checkNow();
    expect(u.phase, UpdatePhase.failed);
    expect(u.lastError, contains('HTTP 404'));
  });

  test('reliz yo\'q (404) yoki versiya eski/teng — yangilanish yo\'q', () async {
    final u = make();
    await u.debugBooted;
    await u.checkNow();
    expect(u.phase, UpdatePhase.upToDate);
    server.publish('1.0.0');
    await u.checkNow();
    expect(u.phase, UpdatePhase.upToDate);
    server.publish('0.9.9');
    await u.checkNow();
    expect(u.phase, UpdatePhase.upToDate);
    await waitFor(() => server.reports.where((r) => r['status'] == 'up_to_date').length >= 3);
  });

  test('boshqa ilovaning version.json i va https bo\'lmagan tashqi manzil — rad etiladi', () async {
    server.publish('1.1.0', app: 'boshqa_app');
    final u = make();
    await u.debugBooted;
    await u.checkNow();
    expect(u.phase, UpdatePhase.failed);
    expect(u.lastError, contains('boshqa ilovaniki'));

    server.publish('1.1.0', url: 'http://example.com/Test_Setup_v1.1.0.exe');
    await u.checkNow();
    expect(u.phase, UpdatePhase.failed);
    expect(u.lastError, contains('ruxsat etilmagan'));
  });

  test('majburiy: min_version joriydan katta', () async {
    server.publish('1.2.0', min: '1.1.0');
    final u = make();
    await u.debugBooted;
    await u.checkNow();
    expect(u.mandatory, isTrue);
  });

  test('qayta ochilganda: last_install.json → «installed» hisobot', () async {
    File('${data.path}\\last_install.json')
        .writeAsStringSync(jsonEncode({'from': '0.9.0', 'to': '1.0.0'}));
    final u = make();
    await u.debugBooted;
    await waitFor(() => server.reports.any((r) => r['status'] == 'installed'));
    expect(File('${data.path}\\last_install.json').existsSync(), isFalse);
    expect(u.lastError, isNull);
  });

  test('qayta ochilganda: eski bayroqlar tozalanadi', () async {
    File('${exeDir.path}\\updating.flag').writeAsStringSync('x');
    File('${exeDir.path}\\exit.flag').writeAsStringSync('x');
    final u = make();
    await u.debugBooted;
    expect(File('${exeDir.path}\\updating.flag').existsSync(), isFalse);
    expect(File('${exeDir.path}\\exit.flag').existsSync(), isFalse);
  });

  test('notifyExitRequested — faqat launcher ostida exit.flag yozadi', () async {
    KioskUpdater.notifyExitRequested();
    expect(File('${exeDir.path}\\exit.flag').existsSync(), isFalse);
    KioskUpdaterDebug.underLauncher = true;
    KioskUpdater.notifyExitRequested();
    expect(File('${exeDir.path}\\exit.flag').existsSync(), isTrue);
  });

  test('isNewer — semver', () {
    expect(KioskUpdater.isNewer('1.2.10', '1.2.9'), isTrue);
    expect(KioskUpdater.isNewer('1.2.9', '1.2.10'), isFalse);
    expect(KioskUpdater.isNewer('1.3.0', '1.3.0+25'), isFalse);
    expect(KioskUpdater.isNewer('1.4.0', 'v1.3.7'), isTrue);
    expect(KioskUpdater.isNewer('2.0.0', '1.99.99'), isTrue);
  });

  testWidgets('panel va ogohlantirish ekrani', (tester) async {
    server.publish('1.1.0');
    final u = make();
    await tester.runAsync(() async {
      await u.debugBooted;
      await u.checkNow();
    });
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => KioskUpdateOverlay(child: child!),
      home: const Scaffold(body: SingleChildScrollView(child: KioskUpdatePanel())),
    ));
    expect(find.text('Yangilanish'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('1.1.0'), findsOneWidget);
    expect(find.text('Hozir o\'rnatish'), findsOneWidget);

    KioskUpdaterDebug.warningSeconds = 30;
    u.debugTick();
    await tester.pump();
    expect(find.textContaining('Ilova yangilanadi'), findsOneWidget);
    expect(find.textContaining('5 daqiqadan keyin'), findsOneWidget);
    // ekranga teginish — keyinga qoldiriladi va ogohlantirish yo'qoladi
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(u.phase, UpdatePhase.ready);
    expect(find.textContaining('Ilova yangilanadi'), findsNothing);
  });
}
