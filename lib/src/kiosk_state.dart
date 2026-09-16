import 'dart:async';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'data.dart';
import 'l10n.dart';
import 'services/hokim_reception.dart';
import 'services/reception_api.dart';

/// Central, observable kiosk state: the current display language and the
/// reception schedule the screen draws.
///
/// The schedule is edited in the admin panel and picked up here, so a change
/// of governor or of a reception hour no longer means recompiling the app and
/// reinstalling it on every kiosk. Three sources, in order of preference:
///
/// 1. **The backend** — the truth, re-checked every [KioskConfig.refreshEvery].
/// 2. **The disk cache** — the last good answer, so a kiosk that boots before
///    the network does still shows a current schedule.
/// 3. **The built-in list** ([AppData.shaxsiyQabul]) — the seed the backend was
///    filled from, and the reason a hall screen is never blank: an unreachable
///    server, an unseeded section or a first start all land here.
///
/// On top of whichever list that is, the governor's card follows the date the
/// governor set in the dashboard ([HokimReception]), polled on the same timer.
class KioskState extends ChangeNotifier {
  /// [pointsApi] talks to the same backend as [api] unless given its own, so a
  /// state built offline (`ReceptionApi(apiBase: '')`) stays offline.
  KioskState({
    ReceptionApi? api,
    ReceptionPointsApi? pointsApi,
    ReceptionCache? cache,
    this.refreshEvery = KioskConfig.refreshEvery,
    DateTime Function()? clock,
  }) : _api = api ?? ReceptionApi(),
       _pointsApi = pointsApi ?? ReceptionPointsApi(apiBase: api?.apiBase),
       _cache = cache ?? ReceptionCache(),
       _clock = clock ?? DateTime.now;

  final ReceptionApi _api;
  final ReceptionPointsApi _pointsApi;
  final ReceptionCache _cache;
  final Duration refreshEvery;
  final DateTime Function() _clock;

  Timer? _timer;
  bool _disposed = false;
  String? _etag;

  Lang lang = Lang.uz;

  /// The schedule as last received, or null while the kiosk is still on its
  /// built-in list.
  ReceptionSchedule? _schedule;

  /// The governor's dated reception, or null while it is unknown (never
  /// fetched, nothing cached) — then the weekly wording stays on the card.
  HokimReception? _hokim;

  /// When the backend was last reached successfully, or null if never.
  DateTime? lastSync;

  /// True once the cache has been read and the first fetch attempted.
  bool ready = false;

  /// True while the visitor has changed anything from the pristine default,
  /// so the idle timer knows whether a reset is worthwhile.
  bool get isDirty => lang != Lang.uz;

  /// What the screen draws. An empty schedule is not shown as an empty screen:
  /// the built-in list stands in until someone fills the section.
  List<QabulOfficial> get officials {
    final s = _schedule;
    final list = s == null || s.isEmpty ? AppData.shaxsiyQabul : s.officials;
    final hokim = _hokim;
    if (hokim == null) return list;
    final i = list.indexWhere(isHokimOfficial);
    if (i < 0) return list;
    return [...list]..[i] = hokim.applyTo(list[i], _clock());
  }

  /// True when the officials on screen came from the server.
  bool get fromBackend {
    final s = _schedule;
    return s != null && !s.isEmpty;
  }

  /// Intro banner: the server's wording if it has one, otherwise the built-in.
  String intro(Lang l) => _text(_schedule?.intro, l) ?? Tr(l).shaxsiyIntro;

  /// Closing note, same rule as [intro].
  String note(Lang l) => _text(_schedule?.note, l) ?? Tr(l).shaxsiyNote;

  static String? _text(Map<Lang, String>? m, Lang l) {
    final v = m?[l];
    return v == null || v.isEmpty ? null : v;
  }

  void setLang(Lang l) {
    if (l == lang) return;
    lang = l;
    notifyListeners();
  }

  /// Return to the pristine default state (invoked by the idle timer).
  ///
  /// Only the visitor's own choices are undone — the schedule is not content
  /// the visitor touched, so it survives.
  void reset() {
    lang = Lang.uz;
    notifyListeners();
  }

  // ---- schedule -----------------------------------------------------------

  /// Reads the cache, then refreshes from the backend and keeps refreshing.
  ///
  /// Returns as soon as the cache is on screen: the network is never allowed
  /// to hold up the first frame of a kiosk.
  Future<void> start() async {
    final cached = await _cache.read();
    if (cached.schedule != null) _schedule = cached.schedule;
    _etag = cached.etag;
    _hokim = HokimReception.fromPoints(await _cache.readPoints());
    ready = true;
    _notify();
    unawaited(refresh());
    _timer ??= Timer.periodic(refreshEvery, (_) => refresh());
  }

  /// Asks the backend once for the schedule and the governor's date — on the
  /// timer, and when staff ask for it (a long press on the logo).
  ///
  /// True when both answers arrived. Never throws — a kiosk that cannot reach
  /// the server keeps whatever it is already showing, and one request failing
  /// does not hold up the other. A call while one is under way joins it
  /// rather than sending the requests twice.
  Future<bool> refresh() {
    if (_disposed) return Future.value(false);
    return _inFlight ??= _refreshBoth().whenComplete(() => _inFlight = null);
  }

  Future<bool>? _inFlight;

  Future<bool> _refreshBoth() async {
    final before = _hokimKey();
    final ok = await Future.wait([_refreshSchedule(), _refreshHokim()]);
    // Also catches the reception day ending with nothing new from the server.
    if (_hokimKey() != before) _notify();
    return ok.every((v) => v);
  }

  Future<bool> _refreshSchedule() async {
    if (!_api.enabled) return false;
    try {
      final res = await _api.fetch(etag: _etag);
      lastSync = DateTime.now();
      if (res.notModified) return true;
      if (res.etag != null && res.etag!.isNotEmpty) _etag = res.etag;
      _schedule = res.schedule;
      await _cache.write(res.raw, res.etag);
      _notify();
      return true;
    } catch (e) {
      debugPrint('reception schedule: refresh failed, keeping current ($e)');
      return false;
    }
  }

  Future<bool> _refreshHokim() async {
    if (!_pointsApi.enabled) return false;
    try {
      final raw = await _pointsApi.fetch();
      _hokim = HokimReception.fromPoints(raw);
      await _cache.writePoints(raw);
      return true;
    } catch (e) {
      debugPrint('reception points: refresh failed, keeping current ($e)');
      return false;
    }
  }

  /// What the governor's card shows, to tell whether it needs redrawing.
  String _hokimKey() {
    final h = _hokim;
    if (h == null) return '';
    return '${h.at}|${h.location}|${h.isUpcoming(_clock())}';
  }

  /// Feeds a payload in as though it had just arrived, so a test can stand the
  /// screen up without a server behind it.
  @visibleForTesting
  void applySchedule(ReceptionSchedule? schedule) {
    ready = true;
    _schedule = schedule;
    _notify();
  }

  /// Same as [applySchedule], for a `GET /kiosk/reception-points` list.
  @visibleForTesting
  void applyPoints(List<dynamic>? points) {
    _hokim = HokimReception.fromPoints(points);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
