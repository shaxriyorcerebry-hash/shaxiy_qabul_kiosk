import 'package:flutter/material.dart';

/// Core brand colours, taken directly from the original kiosk design.
class AppColors {
  const AppColors._();

  static const Color brand = Color(0xFF1B33C4); // logo blue
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E4B8F);
  static const Color ink = Color(0xFF0D3B73);
  static const Color body = Color(0xFF26415F);
  static const Color muted = Color(0xFF4A6892);
  static const Color cardBorder = Color(0xFFD7E3F4);
  static const Color panelBg = Color(0xFFF2F7FC);

  // Home gradient base.
  static const List<Color> homeGradient = [
    Color(0xFFEAF2FB),
    Color(0xFFF5F8FC),
    Color(0xFFFFFFFF),
  ];
}

/// A resolved colour palette for the header / footer chrome.
class Palette {
  const Palette({
    required this.headerBg,
    required this.headerBorder,
    required this.headMain,
    required this.headSub,
    required this.langTray,
    required this.langTrayBorder,
    required this.langInactive,
    required this.footerBg,
    required this.footerText,
    required this.footerHint,
    required this.footerDot,
    required this.titleColor,
  });

  final Color headerBg;
  final Color headerBorder;
  final Color headMain;
  final Color headSub;
  final Color langTray;
  final Color langTrayBorder;
  final Color langInactive;
  final Color footerBg;
  final Color footerText;
  final Color footerHint;
  final Color footerDot;
  final Color titleColor;

  static const Palette light = Palette(
    headerBg: Color(0xD6FFFFFF),
    headerBorder: Color(0x1F1E4B8F),
    headMain: Color(0xFF1E4B8F),
    headSub: Color(0xFF5B7699),
    langTray: Color(0x121E4B8F),
    langTrayBorder: Color(0x1A1E4B8F),
    langInactive: Color(0xFF4A6892),
    footerBg: Color(0x8CFFFFFF),
    footerText: Color(0xFF5B7699),
    footerHint: Color(0xFF2563EB),
    footerDot: Color(0xFFB9CCE4),
    titleColor: Color(0xFF1E4B8F),
  );
}
