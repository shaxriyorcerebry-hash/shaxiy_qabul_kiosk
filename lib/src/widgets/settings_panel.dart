import 'package:flutter/material.dart';

import '../../core/update/kiosk_update_ui.dart';
import '../theme.dart';
import 'pressable.dart';

/// Xodim uchun «Sozlamalar» paneli — «Chiqish» tugmasini bosib turib ochiladi.
///
/// Parol so'ramaydi (ADR-037, lead qarori): ichida faqat «Yangilanish»
/// bo'limi ([KioskUpdatePanel] — tekshirish/o'rnatish) bor. Kiosk rejimidan
/// chiqish esa avvalgidek parol bilan: «Chiqish» tugmasi panelni yopib,
/// parol oynasini ochadi.
///
/// `true` — xodim «Chiqish» ni bosdi (chaqiruvchi parol oynasini ochadi);
/// `false` — yopildi. [onActivity] — panel ichidagi har teginishda (kioskning
/// bo'shlik taymeri panelni o'qib turgan xodimdan yopib qo'ymasin).
Future<bool> showSettingsPanel(
  BuildContext context, {
  VoidCallback? onActivity,
}) async {
  final exit = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, _) {
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: 0.94 + anim.value * 0.06,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => onActivity?.call(),
            child: const _SettingsPanel(),
          ),
        ),
      );
    },
  );
  return exit ?? false;
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.88;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720, maxHeight: maxH),
          child: Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(28),
            elevation: 24,
            shadowColor: const Color(0x66062040),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Header(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(26, 22, 26, 8),
                    child: const KioskUpdatePanel(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 14, 26, 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Yopish',
                          filled: false,
                          onTap: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _ActionButton(
                          label: 'Chiqish',
                          icon: Icons.lock_outline_rounded,
                          filled: true,
                          onTap: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Parol oynasidagi kabi ko'k sarlavha.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E4B8F), Color(0xFF2563EB)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sozlamalar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Xodimlar uchun · ilova yangilanishi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.primaryDark;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : const Color(0x0F2563EB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? AppColors.primary : const Color(0x472563EB),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
