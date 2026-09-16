import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config.dart';
import '../data.dart';
import '../l10n.dart';
import 'tls.dart';

/// Uzbekistan keeps UTC+5 all year, so which day a reception falls on never
/// depends on the time zone the kiosk machine happens to be set to.
const Duration tashkentOffset = Duration(hours: 5);

/// [t] on the Tashkent wall clock. An instant (`…Z`, `…+05:00`) is shifted;
/// a time written without an offset is taken to be Tashkent time already.
DateTime tashkentWall(DateTime t) => t.isUtc ? t.add(tashkentOffset) : t;

/// The Tashkent wall clock at [now].
DateTime tashkentNow(DateTime now) => now.toUtc().add(tashkentOffset);

/// The governor's next in-person reception, as the governor sets it in the
/// dashboard (`PUT /panel/reception-points/{id}/schedule`, [[API/29]]).
/// Which card is the governor's is [isHokimOfficial]'s call.
///
/// The weekly schedule (`ReceptionSchedule`) is a text an editor keeps; this
/// is a date the governor picks, so where the two disagree this one is shown.
/// Only the governor has one — the deputies have no reception point.
class HokimReception {
  const HokimReception({this.at, this.location = ''});

  /// Start of the reception on the Tashkent wall clock, or null while none is
  /// set. The backend keeps no end time.
  final DateTime? at;

  /// Where it is held, as typed in the dashboard (Uzbek only).
  final String location;

  /// The governor's point in a `GET /kiosk/reception-points` list.
  ///
  /// Null when there is no such list or no governor in it — "unknown", which
  /// leaves the weekly wording up. A governor's point without a time is
  /// "not set", which is something else: [at] is null.
  static HokimReception? fromPoints(dynamic raw) {
    if (raw is! List) return null;
    final points = [
      for (final p in raw)
        if (p is Map && _isHokimPoint(p)) p,
    ]..sort((a, b) => _order(a).compareTo(_order(b)));
    if (points.isEmpty) return null;
    final p = points.first;
    return HokimReception(
      at: _parseTime(p['next_reception_at']),
      location: p['reception_location']?.toString().trim() ?? '',
    );
  }

  /// The ticket prefix is what the queue kiosks key on (`H` — governor,
  /// `P` — the President's reception); the name is the fallback for a list
  /// that does not carry it.
  static bool _isHokimPoint(Map p) {
    final prefix = p['ticket_prefix']?.toString().trim().toUpperCase() ?? '';
    if (prefix.isNotEmpty) return prefix == 'H';
    return (p['name_uz']?.toString().toLowerCase() ?? '').contains('hokim');
  }

  static num _order(Map p) {
    final v = p['sort_order'];
    return v is num ? v : 1 << 30;
  }

  static DateTime? _parseTime(dynamic v) {
    if (v is! String || v.trim().isEmpty) return null;
    final t = DateTime.tryParse(v.trim());
    return t == null ? null : tashkentWall(t);
  }

  /// True until the reception day is over in Tashkent: on the day itself the
  /// date stays up after the start hour, since the end hour is not known.
  bool isUpcoming(DateTime now) {
    final a = at;
    if (a == null) return false;
    final today = tashkentNow(now);
    return !DateTime.utc(a.year, a.month, a.day)
        .isBefore(DateTime.utc(today.year, today.month, today.day));
  }

  /// [official]'s card with the dated reception in place of the weekly one —
  /// or, once no date is set or the last one has passed, saying so.
  QabulOfficial applyTo(QabulOfficial official, DateTime now) {
    final a = at;
    if (a == null || !isUpcoming(now)) {
      return QabulOfficial(
        official.name,
        official.position,
        {for (final l in Lang.values) l: Tr(l).receptionUnset},
        '',
        official.phone,
      );
    }
    final withYear = a.year != tashkentNow(now).year;
    return QabulOfficial(
      official.name,
      official.position,
      {
        for (final l in Lang.values)
          l: AppData.receptionDate(a, l, withYear: withYear),
      },
      '${_two(a.hour)}:${_two(a.minute)}',
      official.phone,
      location: location,
      scheduled: ScheduledReception(a, withYear: withYear),
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

/// Reads the reception points from the qabulhona backend.
///
/// Contract: `GET /api/kiosk/reception-points` — public, no auth, a bare JSON
/// list (`id`, `name_uz`, `ticket_prefix`, `sort_order`, `next_reception_at`,
/// `reception_location`, …). It carries no `ETag`, but it is a few hundred
/// bytes.
class ReceptionPointsApi {
  ReceptionPointsApi({
    String? apiBase,
    this.timeout = const Duration(seconds: 20),
  }) : apiBase = apiBase ?? KioskConfig.apiBase;

  final String apiBase;
  final Duration timeout;

  bool get enabled => apiBase.trim().isNotEmpty;

  /// The list exactly as served, for the cache to keep. Throws on any network
  /// or shape failure; the caller keeps what it has.
  Future<List<dynamic>> fetch() async {
    if (!enabled) throw const SocketException('backend not configured');
    final uri = Uri.parse('$apiBase${KioskConfig.receptionPointsPath}');

    final client = kioskHttpClient(timeout);
    try {
      final req = await client.getUrl(uri).timeout(timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('GET ${uri.path} -> ${res.statusCode}');
      }
      final decoded = jsonDecode(body);
      // Accept a wrapped list too, should the endpoint ever gain an envelope.
      final list = decoded is Map ? decoded['data'] ?? decoded['items'] : decoded;
      if (list is! List) {
        throw const FormatException('reception-points: not a list');
      }
      return list;
    } finally {
      client.close(force: true);
    }
  }
}
