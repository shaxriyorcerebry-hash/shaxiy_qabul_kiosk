import 'package:flutter/material.dart';

import '../core/update/kiosk_update_ui.dart';
import 'kiosk_root.dart';
import 'theme.dart';

/// Application root — a single-page kiosk, no routing needed.
class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xalq qabulxonasi — Shaxsiy qabul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
        scaffoldBackgroundColor: AppColors.homeGradient.first,
        useMaterial3: true,
      ),
      // Yangilanish ogohlantirishi hamma narsaning (dialoglarning ham) ustida.
      builder: (context, child) => KioskUpdateOverlay(child: child!),
      home: const KioskRoot(),
    );
  }
}
