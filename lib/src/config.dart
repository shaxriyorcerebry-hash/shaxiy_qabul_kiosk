import 'l10n.dart';

/// Static kiosk configuration — organisation details shown across the app.
class KioskConfig {
  const KioskConfig._();

  /// Window title / process-facing name (not translated).
  static const String orgName = 'Xalq qabulxonasi — Shaxsiy qabul';

  /// Short organisation name shown in the footer, per language.
  static const Map<Lang, String> orgShortName = {
    Lang.uz: 'Xalq qabulxonasi',
    Lang.ru: 'Народная приёмная',
    Lang.en: "People's Reception",
  };

  static const String orgPhone = '(71) 230-24-30';

  /// Seconds of inactivity before the kiosk resets to its default state.
  static const int idleSeconds = 90;

  /// Password required to leave kiosk mode, asked for by the exit button.
  ///
  /// This only stops a visitor walking up and closing the kiosk; it is
  /// compiled into the executable and so is not a secret from anyone with
  /// access to the files on the machine.
  static const String exitPassword = '20median47';

  static const String logoAsset = 'assets/images/xalq_qabulxona_icon.png';

  /// Origin of the qabulhona backend that serves the reception schedule, or
  /// empty to run fully offline (the kiosk then shows its built-in list).
  static const String backendOrigin = 'https://qabulxona.gennis.uz';

  /// API path prefix on that backend.
  static const String apiPrefix = '/api';

  /// Full API base, e.g. `https://qabulxona.gennis.uz/api`. Empty => offline.
  static String get apiBase =>
      backendOrigin.isEmpty ? '' : '$backendOrigin$apiPrefix';

  /// The schedule section, shared with the info kiosk — one endpoint, one
  /// seed, two kiosks. The backend serves it under the general
  /// `/kiosk/info/{section}` envelope; the first draft of the contract said
  /// `/kiosk/reception-schedule`, which is a `404`.
  static const String receptionPath = '/kiosk/info/reception-schedule';

  /// The reception points; the governor's (`ticket_prefix: H`) carries the
  /// date and hour the governor set in the dashboard (`next_reception_at`).
  static const String receptionPointsPath = '/kiosk/reception-points';

  /// How often the kiosk asks the backend for both. An unchanged schedule
  /// costs one `304` and the point list is a few hundred bytes, so this is
  /// short enough for a newly set reception date to reach the hall quickly.
  static const Duration refreshEvery = Duration(minutes: 5);
}
