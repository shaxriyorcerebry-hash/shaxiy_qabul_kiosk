import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/config.dart';

/// Kiosk bootstrap: lock the window to fullscreen, block Alt+F4 / close, and
/// keep the screen awake. Set `KIOSK_WINDOWED=1` in the environment to run in a
/// normal resizable window instead (handy for development and screenshots).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final windowed = (Platform.environment['KIOSK_WINDOWED'] ?? '').isNotEmpty;

  final options = WindowOptions(
    title: KioskConfig.orgName,
    fullScreen: !windowed,
    titleBarStyle: windowed ? TitleBarStyle.normal : TitleBarStyle.hidden,
    minimumSize: const Size(1024, 640),
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    if (!windowed) {
      await windowManager.setFullScreen(true);
      await windowManager.setPreventClose(true);
    }
    await windowManager.show();
    await windowManager.focus();
  });

  await WakelockPlus.enable();

  runApp(const KioskApp());
}
