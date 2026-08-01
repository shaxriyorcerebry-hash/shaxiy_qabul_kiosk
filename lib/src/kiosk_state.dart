import 'dart:async';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'data.dart';
import 'l10n.dart';
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
class KioskState extends ChangeNotifier {
  KioskState({
    ReceptionApi? api,
    ReceptionCache? cache,
    this.refreshEvery = KioskConfig.refreshEvery,
  }) : _api = api ?? ReceptionApi(),
       _cache = cache ?? ReceptionCache();

  final ReceptionApi _api;
  final ReceptionCache _cache;
  final Duration refreshEvery;

  Timer? _timer;
  bool _disposed = false;
  String? _etag;

  Lang lang = Lang.uz;

  /// The schedule as last received, or null while the kiosk is still on its
  /// built-in list.
  ReceptionSchedule? _schedule;

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
    return s == null || s.isEmpty ? AppData.shaxsiyQabul : s.officials;
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
    ready = true;
    _notify();
    unawaited(refresh());
    _timer ??= Timer.periodic(refreshEvery, (_) => refresh());
  }

  /// Asks the backend once. Never throws — a kiosk that cannot reach the
  /// server keeps whatever it is already showing.
  Future<void> refresh() async {
    if (!_api.enabled || _disposed) return;
    try {
      final res = await _api.fetch(etag: _etag);
      lastSync = DateTime.now();
      if (res.notModified) return;
      if (res.etag != null && res.etag!.isNotEmpty) _etag = res.etag;
      _schedule = res.schedule;
      await _cache.write(res.raw, res.etag);
      _notify();
    } catch (e) {
      debugPrint('reception schedule: refresh failed, keeping current ($e)');
    }
  }

  /// Feeds a payload in as though it had just arrived, so a test can stand the
  /// screen up without a server behind it.
  @visibleForTesting
  void applySchedule(ReceptionSchedule? schedule) {
    ready = true;
    _schedule = schedule;
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
