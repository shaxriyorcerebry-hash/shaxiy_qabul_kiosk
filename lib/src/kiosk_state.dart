import 'package:flutter/foundation.dart';

import 'l10n.dart';

/// Central, observable kiosk state. This single-purpose kiosk only tracks the
/// current display language; the screen listens to this and rebuilds.
class KioskState extends ChangeNotifier {
  Lang lang = Lang.uz;

  /// True while the visitor has changed anything from the pristine default,
  /// so the idle timer knows whether a reset is worthwhile.
  bool get isDirty => lang != Lang.uz;

  void setLang(Lang l) {
    if (l == lang) return;
    lang = l;
    notifyListeners();
  }

  /// Return to the pristine default state (invoked by the idle timer).
  void reset() {
    lang = Lang.uz;
    notifyListeners();
  }
}
