import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../data.dart';
import '../kiosk_state.dart';
import '../l10n.dart';
import '../theme.dart';
import 'pressable.dart';

/// Top bar: organisation logo + name, live clock, and language switch.
class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.state,
    required this.palette,
    required this.clock,
  });

  final KioskState state;
  final Palette palette;
  final ValueListenable<DateTime> clock;

  @override
  Widget build(BuildContext context) {
    final t = Tr(state.lang);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: palette.headerBg,
            border: Border(bottom: BorderSide(color: palette.headerBorder)),
          ),
          child: Row(
            children: [
              const _Logo(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
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
                ),
              ),
              const SizedBox(width: 20),
              _Clock(clock: clock, lang: state.lang, palette: palette),
              const SizedBox(width: 18),
              _LangSwitch(state: state, palette: palette),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
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
  });

  final ValueListenable<DateTime> clock;
  final Lang lang;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: clock,
      builder: (context, now, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
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
