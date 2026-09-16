import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';
import '../kiosk_state.dart';
import '../l10n.dart';
import '../theme.dart';
import 'pressable.dart';

/// Top bar: organisation logo + name, live clock, and language switch.
///
/// On one row down to 1000 px. Narrower — a portrait kiosk at 125–150 %
/// scaling — the name would be cut to "Prezidentining …", so the clock and
/// the language switch move to a second row under it.
class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.state,
    required this.palette,
    required this.clock,
    this.onLogoHold,
  });

  final KioskState state;
  final Palette palette;
  final ValueListenable<DateTime> clock;

  /// Staff-only: fired after the logo is held for [logoHoldDuration]. Nothing
  /// on screen hints at it, and it is long enough that a visitor's tap or a
  /// resting hand does not set it off.
  final VoidCallback? onLogoHold;

  static const Duration logoHoldDuration = Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    final t = Tr(state.lang);
    final name = Text(
      t.orgFullName,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: palette.headMain,
        letterSpacing: 0.1,
        height: 1.16,
      ),
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: palette.headerBg,
            border: Border(bottom: BorderSide(color: palette.headerBorder)),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth >= 936) {
                return Row(
                  children: [
                    _hold(const _Logo()),
                    const SizedBox(width: 20),
                    Expanded(child: name),
                    const SizedBox(width: 20),
                    _Clock(clock: clock, lang: state.lang, palette: palette),
                    const SizedBox(width: 18),
                    _LangSwitch(state: state, palette: palette),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      _hold(const _Logo(size: 72)),
                      const SizedBox(width: 18),
                      Expanded(child: name),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Clock(
                        clock: clock,
                        lang: state.lang,
                        palette: palette,
                        alignEnd: false,
                      ),
                      const Spacer(),
                      _LangSwitch(state: state, palette: palette),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Wraps the logo in the long-press recogniser. `GestureDetector` only
  /// knows the default half-second press, hence the raw detector.
  Widget _hold(Widget logo) {
    final onHold = onLogoHold;
    if (onHold == null) return logo;
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: logoHoldDuration),
          (r) => r.onLongPress = onHold,
        ),
      },
      child: logo,
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.size = 86});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x262563EB),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(KioskConfig.logoAsset, fit: BoxFit.cover),
      ),
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock({
    required this.clock,
    required this.lang,
    required this.palette,
    this.alignEnd = true,
  });

  final ValueListenable<DateTime> clock;
  final Lang lang;
  final Palette palette;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: clock,
      builder: (context, now, _) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppData.formatTime(now),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: palette.headMain,
              letterSpacing: 1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            AppData.formatDate(now, lang),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: palette.headSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _LangSwitch extends StatelessWidget {
  const _LangSwitch({required this.state, required this.palette});

  final KioskState state;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.langTray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.langTrayBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in Lang.values) ...[
            _LangButton(
              label: l.label,
              active: state.lang == l,
              inactiveColor: palette.langInactive,
              onTap: () => state.setLang(l),
            ),
            if (l != Lang.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.active,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        constraints: const BoxConstraints(minWidth: 76),
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                )
              : null,
          borderRadius: BorderRadius.circular(13),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x592563EB),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 21,
            fontWeight: active ? FontWeight.w800 : FontWeight.w700,
            color: active ? Colors.white : inactiveColor,
          ),
        ),
      ),
    );
  }
}
