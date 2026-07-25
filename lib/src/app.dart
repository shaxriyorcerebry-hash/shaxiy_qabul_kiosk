import 'package:flutter/material.dart';

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
      home: const KioskRoot(),
    );
  }
}
