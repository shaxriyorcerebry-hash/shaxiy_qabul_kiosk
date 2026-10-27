import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Small, discreet exit affordance shown inside the footer. It is a door icon
/// on a blue-and-white badge.
///
/// - oddiy bosish ([onTap]) — parol so'rab kiosk rejimidan chiqish;
/// - [settingsHoldDuration] bosib turish ([onLongPress]) — xodim uchun
///   «Sozlamalar» paneli (yangilanish), parolsiz (ADR-037).
class ExitButton extends StatelessWidget {
  const ExitButton({super.key, required this.onTap, this.onLongPress});

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// «Sozlamalar» ochilishi uchun bosib turish vaqti. Tasodifiy teginish
  /// (tashrif buyuruvchi) ochib yubormasligi uchun standart yarim soniyadan
  /// uzunroq.
  static const Duration settingsHoldDuration = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332563EB),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.meeting_room_outlined,
              color: AppColors.primary, size: 22),
        ),
      ),
    );

    // `InkWell.onLongPress` faqat standart yarim soniyani biladi — shuning
    // uchun logodagi kabi alohida recogniser. Bosish qisqa bo'lsa, tap
    // (parol oynasi) yutadi; [settingsHoldDuration] dan keyin — long-press.
    final hold = onLongPress;
    if (hold != null) {
      button = RawGestureDetector(
        gestures: {
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: settingsHoldDuration),
            (r) => r.onLongPress = hold,
          ),
        },
        child: button,
      );
    }

    // `manual`: Tooltip'ning o'z yarim soniyalik long-press'i arenada
    // yuqoridagi 2 soniyalik bosib turishni yutib qo'ymasin (sichqoncha
    // ustiga kelganda baribir ko'rinadi).
    return Tooltip(
      message: 'Chiqish',
      triggerMode: TooltipTriggerMode.manual,
      child: button,
    );
  }
}
