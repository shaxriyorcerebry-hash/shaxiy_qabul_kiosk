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
}
