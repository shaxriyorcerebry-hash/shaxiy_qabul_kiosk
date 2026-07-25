import 'package:flutter/material.dart';

import '../data.dart';
import '../l10n.dart';
import '../theme.dart';

/// The weekly in-person reception schedule of the governor and deputies —
/// an intro banner and a card grid: name, position, weekly slot and phone.
///
/// This is the single content screen of the kiosk, lifted verbatim in look
/// from the "Shaxsiy murojaat qabuli" section of the info kiosk.
class ShaxsiyScreen extends StatelessWidget {
  const ShaxsiyScreen({super.key, required this.lang});

  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final t = Tr(lang);
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth > 1240 ? 3 : 2;
        final gridWidth = (box.maxWidth - 64).clamp(280.0, 1500.0);
        final cardWidth = (gridWidth - 20 * (cols - 1)) / cols;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 6, 32, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: gridWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EnterIn(
                    delayMs: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1FA),
                        border: Border.all(color: const Color(0xFFC4D6EC)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        t.shaxsiyIntro,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      for (var i = 0; i < AppData.shaxsiyQabul.length; i++)
                        _EnterIn(
                          delayMs: (i * 45).clamp(0, 400),
                          child: _OfficialCard(
                            index: i + 1,
                            official: AppData.shaxsiyQabul[i],
                            lang: lang,
                            width: cardWidth,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _EnterIn(
                    delayMs: 420,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1FA),
                        border: Border.all(color: const Color(0xFFC4D6EC)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 26, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.shaxsiyNote,
                              style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.45,
                                  color: AppColors.body),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One official: numbered, strictly typographic — no gradients, thin rules.
class _OfficialCard extends StatelessWidget {
  const _OfficialCard({
    required this.index,
    required this.official,
    required this.lang,
    required this.width,
  });

  final int index;
  final QabulOfficial official;
  final Lang lang;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 264),
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x4D1E4B8F), width: 1.4),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  official.name[lang]!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            official.position[lang]!,
            style: const TextStyle(
              fontSize: 18.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 21, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  official.day[lang]!,
                  style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.body),
                ),
              ),
              Text(
                official.time,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.call_outlined, size: 21, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                official.phone,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Staggered fade + rise entrance.
class _EnterIn extends StatelessWidget {
  const _EnterIn({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 480 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 34 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}
