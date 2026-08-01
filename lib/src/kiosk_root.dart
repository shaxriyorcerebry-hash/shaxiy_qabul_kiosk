import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'config.dart';
import 'kiosk_state.dart';
import 'l10n.dart';
import 'theme.dart';
import 'screens/shaxsiy_screen.dart';
import 'widgets/exit_password_dialog.dart';
import 'widgets/footer_bar.dart';
import 'widgets/header_bar.dart';
import 'widgets/kiosk_background.dart';

/// The root kiosk shell: owns state, the live clock and the idle-reset timer,
/// and lays out background + header + section title + content + footer + exit.
class KioskRoot extends StatefulWidget {
  const KioskRoot({super.key});

  @override
  State<KioskRoot> createState() => _KioskRootState();
}

class _KioskRootState extends State<KioskRoot> with WindowListener {
  final KioskState _state = KioskState();
  final ValueNotifier<DateTime> _clock = ValueNotifier(DateTime.now());
  Timer? _ticker;
  DateTime _lastActivity = DateTime.now();

  /// True while the exit password prompt is on screen, so the idle timer
  /// knows to dismiss it.
  bool _exitPrompt = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Cache first, then the backend — never blocks the first frame, and never
    // throws: an unreachable server just leaves the built-in schedule up.
    unawaited(_state.start());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _clock.dispose();
    _state.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  void _tick() {
    _clock.value = DateTime.now();
    final idle = DateTime.now().difference(_lastActivity).inSeconds;
    // An abandoned password prompt must not sit open on a public screen, and a
    // non-default language should reset for the next visitor.
    final dirty = _state.isDirty || _exitPrompt;
    if (idle > KioskConfig.idleSeconds && dirty) {
      _lastActivity = DateTime.now();
      // Close any open dialog (e.g. the exit prompt) before resetting.
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      }
      _state.reset();
    }
  }

  void _markActive() => _lastActivity = DateTime.now();

  // Window close (Alt+F4) is blocked while prevent-close is on.
  @override
  void onWindowClose() async {
    if (await windowManager.isPreventClose()) return;
    await windowManager.destroy();
  }

  Future<void> _confirmExit() async {
    // Leaving kiosk mode is staff-only: it takes the exit password.
    _exitPrompt = true;
    final ok = await askExitPassword(context);
    _exitPrompt = false;
    if (ok) {
      await _startExplorer();
      await WakelockPlus.disable();
      await windowManager.setPreventClose(false);
      await windowManager.setFullScreen(false);
      await windowManager.destroy();
    }
  }

  /// Bring the Windows shell back up on the way out.
  ///
  /// On a kiosk machine this app is normally set as the shell in place of
  /// Explorer, so quitting would otherwise leave a bare desktop with no task
  /// bar. Started detached so it outlives this process; a failure here must
  /// never block the exit, so it is swallowed.
  Future<void> _startExplorer() async {
    try {
      await Process.start(
        'explorer.exe',
        const [],
        mode: ProcessStartMode.detached,
      );
    } catch (_) {
      // Explorer is unavailable or already running — leaving is still fine.
    }
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.light;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _markActive(),
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          return Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: KioskBackground()),
                Positioned.fill(
                  child: Column(
                    children: [
                      HeaderBar(state: _state, palette: palette, clock: _clock),
                      _SectionTitle(
                        title: Tr(_state.lang).shaxsiyTitle,
                        palette: palette,
                      ),
                      Expanded(
                        child: ShaxsiyScreen(
                          lang: _state.lang,
                          officials: _state.officials,
                          intro: _state.intro(_state.lang),
                          note: _state.note(_state.lang),
                        ),
                      ),
                      FooterBar(
                        palette: palette,
                        lang: _state.lang,
                        onExit: _confirmExit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The static section header naming what this single-purpose kiosk shows.
/// Mirrors the section-nav bar of the info kiosk, without the (unneeded)
/// back / home navigation buttons.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.palette});

  final String title;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 18, 32, 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.co_present_outlined,
                size: 26, color: Colors.white),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: palette.titleColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
