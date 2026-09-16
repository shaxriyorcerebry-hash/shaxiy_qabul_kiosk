import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config.dart';
import '../data.dart';
import '../l10n.dart';
import 'tls.dart';

/// The weekly reception schedule as the backend holds it: the intro banner,
/// the closing note and the officials themselves.
///
/// Parsed into the very same [QabulOfficial] the screen already draws, so
/// moving the schedule from the app to the server is a change of source, not
/// a rewrite of the screen.
class ReceptionSchedule {
  const ReceptionSchedule({
    required this.intro,
    required this.note,
    required this.officials,
  });

  final Map<Lang, String> intro;
  final Map<Lang, String> note;
  final List<QabulOfficial> officials;

  /// Nobody has been entered on the server yet — the caller keeps showing the
  /// built-in list rather than an empty screen.
  bool get isEmpty => officials.isEmpty;

  /// Reads a section payload.
  ///
  /// Deliberately forgiving: the schedule is edited by hand in an admin panel,
  /// so a missing translation or a renamed field is a question of when, not
  /// if, and none of them may take a kiosk in a public hall down. The contract
  /// ([[02 - API/18b]]) names `officials` / `full_name` / `reception_day`; the
  /// earlier draft ([[02 - API/18]]) named them `items` / `name` / `day`. Both
  /// are accepted. An entry with no name at all is skipped; a payload that is
  /// not an object at all throws and the caller keeps its cache.
  static ReceptionSchedule parse(Map<String, dynamic> d) {
    final raw = d['officials'] ?? d['items'];
    return ReceptionSchedule(
      intro: triText(d['intro']),
      note: triText(d['note']),
      officials: [
        for (final o in _sorted(_objects(raw)))
          if (o['is_active'] != false)
            if (_hasText(triText(o['full_name'] ?? o['name'])))
              QabulOfficial(
                triText(o['full_name'] ?? o['name']),
                triText(o['position']),
                triText(o['reception_day'] ?? o['day']),
                o['time']?.toString().trim() ?? '',
                o['phone']?.toString().trim() ?? '',
              ),
      ],
    );
  }
}

/// `{"uz": "...", "ru": "...", "en": "..."}` → a language map.
///
/// Uzbek is the source language of the schedule, so an empty `ru`/`en` falls
/// back to it: the screen indexes these maps with `!`, and a visitor reading
/// in Russian should see the Uzbek line rather than nothing.
Map<Lang, String> triText(dynamic raw) {
  if (raw is String) {
    final v = raw.trim();
    return {Lang.uz: v, Lang.ru: v, Lang.en: v};
  }
  if (raw is! Map) return const {Lang.uz: '', Lang.ru: '', Lang.en: ''};
  String pick(String key) => raw[key]?.toString().trim() ?? '';
  final uz = pick('uz');
  final ru = pick('ru');
  final en = pick('en');
  return {
    Lang.uz: uz,
    Lang.ru: ru.isEmpty ? uz : ru,
    Lang.en: en.isEmpty ? uz : en,
  };
}

bool _hasText(Map<Lang, String> m) => (m[Lang.uz] ?? '').isNotEmpty;

List<Map<String, dynamic>> _objects(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map) e.cast<String, dynamic>(),
  ];
}

/// Orders the list by `sort_order`, leaving entries without one where they
/// were — the card numbers on screen follow this order.
List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> items) {
  final copy = [...items];
  copy.sort((a, b) {
    final x = a['sort_order'];
    final y = b['sort_order'];
    if (x is! num || y is! num) return 0;
    return x.compareTo(y);
  });
  return copy;
}

/// One answer from the backend.
///
/// [schedule] is null when the server has the section but nobody has filled it
/// in yet (`data: null`) — distinct from [notModified], which means the caller
/// already has the current copy.
class ReceptionResult {
  const ReceptionResult({this.schedule, this.raw, this.etag, this.version = 0})
    : notModified = false;

  const ReceptionResult.notModified()
    : schedule = null,
      raw = null,
      etag = null,
      version = 0,
      notModified = true;

  final ReceptionSchedule? schedule;

  /// The payload exactly as it arrived, for the cache to store verbatim.
  final Map<String, dynamic>? raw;

  final String? etag;
  final int version;
  final bool notModified;
}

/// Reads the reception schedule from the qabulhona backend.
///
/// Contract: `GET /api/kiosk/info/reception-schedule?lang=all` — public, no
/// auth. `lang=all` brings all three languages in one response, so the
/// language buttons never need the network. The response is wrapped
/// (`{"section":…,"version":…,"data":{…}}`); the earlier draft of the contract
/// put the fields at the top level, so both shapes are accepted.
///
/// The same endpoint serves the info kiosk's "Shaxsiy qabul" section — one
/// endpoint, one seed, two kiosks.
///
/// Uses `dart:io` directly so the kiosk keeps its two-package dependency list.
class ReceptionApi {
  ReceptionApi({String? apiBase, this.timeout = const Duration(seconds: 20)})
    : apiBase = apiBase ?? KioskConfig.apiBase;

  final String apiBase;
  final Duration timeout;

  bool get enabled => apiBase.trim().isNotEmpty;

  /// Fetches the schedule. Pass [etag] to be told `304` instead of being sent
  /// bytes that have not changed. Throws on any network or shape failure; the
  /// caller falls back to its cache and then to the built-in list.
  Future<ReceptionResult> fetch({String? etag}) async {
    if (!enabled) throw const SocketException('backend not configured');
    final uri = Uri.parse('$apiBase${KioskConfig.receptionPath}?lang=all');

    final client = kioskHttpClient(timeout);
    try {
      final req = await client.getUrl(uri).timeout(timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (etag != null && etag.isNotEmpty) {
        req.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
      }
      final res = await req.close().timeout(timeout);

      if (res.statusCode == HttpStatus.notModified) {
        await res.drain<void>();
        return const ReceptionResult.notModified();
      }
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('GET ${uri.path} -> ${res.statusCode}');
      }
      if (body.isEmpty) return const ReceptionResult();

      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('reception-schedule: not an object');
      }
      final map = decoded.cast<String, dynamic>();
      final payload = payloadOf(map);
      return ReceptionResult(
        schedule: payload == null ? null : ReceptionSchedule.parse(payload),
        raw: payload,
        etag: res.headers.value(HttpHeaders.etagHeader),
        version: map['version'] is int ? map['version'] as int : 0,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// The section payload inside a response. An explicit `data: null` means
  /// "not filled in yet" and comes back as null.
  static Map<String, dynamic>? payloadOf(Map<String, dynamic> body) {
    if (body.containsKey('data')) {
      final d = body['data'];
      return d is Map ? d.cast<String, dynamic>() : null;
    }
    final rest = Map<String, dynamic>.from(body)
      ..remove('section')
      ..remove('version')
      ..remove('updated_at');
    return rest.isEmpty ? null : rest;
  }
}

/// The last good answer, kept on disk.
///
/// A kiosk that boots before the network does — or after the office loses its
/// connection for a day — still shows the schedule it last received, not the
/// list that was compiled into it months ago. The `ETag` is stored alongside,
/// so a restart still costs one `304` rather than a full download.
class ReceptionCache {
  ReceptionCache({Directory? dir}) : _override = dir;

  final Directory? _override;
  Directory? _resolved;

  /// `%LOCALAPPDATA%\shaxiy_qabul_kiosk`, or the system temp directory on a
  /// machine without that variable (tests, other platforms).
  Directory get dir {
    if (_override != null) return _override;
    final local = Platform.environment['LOCALAPPDATA'];
    return _resolved ??= Directory(
      local == null || local.isEmpty
          ? '${Directory.systemTemp.path}/shaxiy_qabul_kiosk'
          : '$local\\shaxiy_qabul_kiosk',
    );
  }

  File get _file => File('${dir.path}/reception_schedule.json');

  File get _pointsFile => File('${dir.path}/reception_points.json');

  /// Whatever the last successful refresh left behind, or null. Never throws.
  Future<({ReceptionSchedule? schedule, String? etag})> read() async {
    try {
      final file = _file;
      if (!file.existsSync()) return (schedule: null, etag: null);
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return (schedule: null, etag: null);
      final etag = decoded['etag'];
      final data = decoded['data'];
      return (
        schedule: data is Map
            ? ReceptionSchedule.parse(data.cast<String, dynamic>())
            : null,
        etag: etag is String && etag.isNotEmpty ? etag : null,
      );
    } catch (_) {
      // An unreadable cache is no worse than no cache: fall through to the
      // network, and to the built-in list behind it.
      return (schedule: null, etag: null);
    }
  }

  /// Stores the raw payload as it arrived, so a later app version parses the
  /// bytes the server actually sent rather than this version's reading of it.
  /// Never throws — a read-only profile costs the kiosk its offline copy and
  /// nothing else.
  Future<void> write(Map<String, dynamic>? data, String? etag) async {
    try {
      final file = _file;
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({'etag': etag, 'data': data}),
        flush: true,
      );
    } catch (_) {
      // Ignored on purpose — see above.
    }
  }

  /// The last `GET /kiosk/reception-points` list, as it arrived, or null.
  /// Never throws.
  Future<List<dynamic>?> readPoints() async {
    try {
      final file = _pointsFile;
      if (!file.existsSync()) return null;
      final decoded = jsonDecode(await file.readAsString());
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Stores the reception point list verbatim. Never throws, as [write].
  Future<void> writePoints(List<dynamic> points) async {
    try {
      final file = _pointsFile;
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(points), flush: true);
    } catch (_) {
      // Ignored on purpose — see [write].
    }
  }
}
