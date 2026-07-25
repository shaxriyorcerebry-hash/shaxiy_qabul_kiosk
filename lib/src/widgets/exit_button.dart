import 'package:flutter/material.dart';

import '../theme.dart';

/// Small, discreet exit affordance shown inside the footer. It is a door icon
/// on a blue-and-white badge; tapping it asks for confirmation before leaving
/// kiosk mode.
class ExitButton extends StatelessWidget {
  const ExitButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Chiqish',
      child: Material(
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
      ),
    );
  }
}
