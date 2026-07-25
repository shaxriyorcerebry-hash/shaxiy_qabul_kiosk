import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import 'pressable.dart';

/// Asks for the kiosk exit password. Resolves to `true` only when the correct
/// password was entered, and `false` on cancel or dismissal.
///
/// The kiosk is a touch panel that may have no keyboard attached, so the
/// dialog carries its own on-screen keys; a physical keyboard works too.
Future<bool> askExitPassword(BuildContext context) async {
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, _) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: 0.9 + curved.value * 0.1,
          child: const _ExitPasswordDialog(),
        ),
      );
    },
  );
  return ok ?? false;
}

class _ExitPasswordDialog extends StatefulWidget {
  const _ExitPasswordDialog();

  @override
  State<_ExitPasswordDialog> createState() => _ExitPasswordDialogState();
}

class _ExitPasswordDialogState extends State<_ExitPasswordDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _wrong = false;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _shake.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _type(String ch) {
    _ctrl.text += ch;
    if (_wrong) setState(() => _wrong = false);
  }

  void _backspace() {
    final t = _ctrl.text;
    if (t.isNotEmpty) _ctrl.text = t.substring(0, t.length - 1);
    if (_wrong) setState(() => _wrong = false);
  }

  void _submit() {
    if (_ctrl.text == KioskConfig.exitPassword) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _wrong = true);
    _ctrl.clear();
    _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.88;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: maxH),
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              // Damped horizontal shake on a rejected password.
              final v = _shake.value;
              final dx = v == 0
                  ? 0.0
                  : 18 * (1 - v) * math.sin(v * 3 * 2 * math.pi);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66062040),
                    blurRadius: 60,
                    offset: Offset(0, 24),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Header(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
                      child: Column(
                        children: [
                          _Field(
                            ctrl: _ctrl,
                            focus: _focus,
                            wrong: _wrong,
                            onSubmit: _submit,
                          ),
                          SizedBox(height: _wrong ? 10 : 0),
                          if (_wrong)
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 20,
                                  color: Color(0xFFC0392B),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Parol noto'g'ri",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFC0392B),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 18),
                          _Keyboard(
                            onKey: _type,
                            onBackspace: _backspace,
                            onClear: () {
                              _ctrl.clear();
                              if (_wrong) setState(() => _wrong = false);
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: 'Bekor qilish',
                                  filled: false,
                                  onTap: () =>
                                      Navigator.of(context).pop(false),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _ActionButton(
                                  label: 'Chiqish',
                                  filled: true,
                                  onTap: _submit,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Blue header band with the lock icon and title.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kiosk rejimidan chiqish',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Davom etish uchun parolni kiriting',
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

/// The obscured password field. Focused on open so a physical keyboard can
/// type straight into it.
class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.focus,
    required this.wrong,
    required this.onSubmit,
  });

  final TextEditingController ctrl;
  final FocusNode focus;
  final bool wrong;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      focusNode: focus,
      autofocus: true,
      obscureText: true,
      obscuringCharacter: '●',
      textAlign: TextAlign.center,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: wrong ? const Color(0xFFFDF0EE) : AppColors.panelBg,
        hintText: 'Parol',
        hintStyle: const TextStyle(
          fontSize: 20,
          letterSpacing: 0,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: wrong ? const Color(0xFFE0A79F) : AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: wrong ? const Color(0xFFC0392B) : AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Compact on-screen keyboard: digits, lowercase letters, backspace, clear.
class _Keyboard extends StatelessWidget {
  const _Keyboard({
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const List<String> _rows = [
    '1234567890',
    'qwertyuiop',
    'asdfghjkl',
    'zxcvbnm',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Ten keys plus gaps across the widest row sets the key size.
        final keyW = ((box.maxWidth - 9 * 6) / 10).clamp(38.0, 56.0);
        return Column(
          children: [
            for (final row in _rows) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 6,
                children: [
                  for (final ch in row.split(''))
                    _Key(label: ch, width: keyW, onTap: () => onKey(ch)),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                _Key(label: 'Tozalash', width: keyW * 3, onTap: onClear),
                _Key(
                  icon: Icons.backspace_outlined,
                  width: keyW * 3,
                  onTap: onBackspace,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.icon,
    required this.width,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.90,
      child: Container(
        width: width,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.panelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: icon != null
            ? Icon(icon, size: 22, color: AppColors.primaryDark)
            : Text(
                label!,
                style: TextStyle(
                  fontSize: label!.length > 1 ? 15 : 21,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: filled ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
