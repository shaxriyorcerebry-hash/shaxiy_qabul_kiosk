import 'package:flutter/material.dart';

import '../data.dart';
import '../l10n.dart';
import '../theme.dart';

/// The weekly in-person reception schedule of the governor and deputies —
/// an intro banner, the governor's card across the full width, and a card
/// grid of the deputies: name, position, weekly slot and phone.
///
/// The hall kiosks stand in portrait (1080 px wide, or 720–864 logical at
/// 125–150 % scaling), so the grid drops to two columns — one below 760 px —
/// and the governor's card lays out side by side down to 720 px.
///
/// This is the single content screen of the kiosk, lifted verbatim in look
/// from the "Shaxsiy murojaat qabuli" section of the info kiosk.
///
/// Purely a drawing: what to draw — server schedule, cache or built-in list —
/// is [KioskState]'s decision, so this widget stands up in a test without a
/// server behind it.
class ShaxsiyScreen extends StatelessWidget {
  const ShaxsiyScreen({
    super.key,
    required this.lang,
    required this.officials,
    required this.intro,
    required this.note,
  });

  final Lang lang;
  final List<QabulOfficial> officials;
  final String intro;
  final String note;

  @override
  Widget build(BuildContext context) {
    // The governor has a single, dated reception — it gets its own row.
    final hokim = officials.indexWhere(isHokimOfficial);
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth > 1240 ? 3 : (box.maxWidth >= 760 ? 2 : 1);
        final gridWidth = (box.maxWidth - 64).clamp(280.0, 1500.0);
        final cardWidth = (gridWidth - 20 * (cols - 1)) / cols;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 6, 32, 12),
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
                          horizontal: 26, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1FA),
                        border: Border.all(color: const Color(0xFFC4D6EC)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        intro,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (hokim >= 0) ...[
                    _EnterIn(
                      delayMs: 40,
                      child: _HokimCard(
                        index: hokim + 1,
                        official: officials[hokim],
                        lang: lang,
                        width: gridWidth,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      for (var i = 0; i < officials.length; i++)
                        if (i != hokim)
                          _EnterIn(
                            delayMs: (i * 45).clamp(0, 400),
                            child: _OfficialCard(
                              index: i + 1,
                              official: officials[i],
                              lang: lang,
                              width: cardWidth,
                              // Evens out a row; a lone card needs no floor.
                              minHeight: cols > 1 ? 240 : 0,
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _EnterIn(
                    delayMs: 420,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
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
                              note,
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

/// The governor: one reception, on one date, so the card is the page's
/// feature — full width, brand gradient, the date set large on a white slot.
///
/// Side by side from 720 px (a portrait 1080 px kiosk, and 864 px at 125 %
/// scaling); stacked below that.
class _HokimCard extends StatelessWidget {
  const _HokimCard({
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
    final wide = width >= 720;
    final info = _HokimInfo(index: index, official: official, lang: lang);
    final slot = _HokimSlot(official: official, lang: lang);
    return Container(
      width: width,
      padding: EdgeInsets.all(wide ? 24 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, AppColors.primaryDark, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: wide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 11, child: info),
                  const SizedBox(width: 26),
                  Expanded(flex: 10, child: slot),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, const SizedBox(height: 20), slot],
            ),
    );
  }
}

/// Left side of the governor's card: who, and how to call — white on blue.
class _HokimInfo extends StatelessWidget {
  const _HokimInfo({
    required this.index,
    required this.official,
    required this.lang,
  });

  final int index;
  final QabulOfficial official;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 1.4),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    official.name[lang]!,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              official.position[lang]!,
              style: TextStyle(
                fontSize: 21,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(Icons.call_outlined,
                size: 24, color: Colors.white.withValues(alpha: 0.86)),
            const SizedBox(width: 10),
            Text(
              official.phone,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Right side of the governor's card: when. Three states — a set date, no
/// date ("not set"), or the weekly wording while the date is unknown.
class _HokimSlot extends StatelessWidget {
  const _HokimSlot({required this.official, required this.lang});

  final QabulOfficial official;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final t = Tr(lang);
    final scheduled = official.scheduled;
    final unset = scheduled == null && official.time.isEmpty;

    final List<Widget> body;
    if (scheduled != null) {
      body = [
        _label(Icons.event_available_outlined, t.nextReception,
            AppColors.primary),
        const SizedBox(height: 10),
        Text(
          AppData.receptionDay(scheduled.at, lang,
              withYear: scheduled.withYear),
          style: const TextStyle(
            fontSize: 42,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _capitalised(AppData.weekdayName(scheduled.at, lang)),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.body,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _timePill(official.time),
          ],
        ),
      ];
    } else if (unset) {
      body = [
        _label(Icons.event_busy_outlined, t.nextReception, AppColors.muted),
        const SizedBox(height: 12),
        Text(
          official.day[lang]!,
          style: const TextStyle(
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
          ),
        ),
      ];
    } else {
      body = [
        _label(Icons.schedule_outlined, t.receptionDayLabel,
            AppColors.primary),
        const SizedBox(height: 10),
        Text(
          official.day[lang]!,
          style: const TextStyle(
            fontSize: 27,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: _timePill(official.time),
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...body,
          if (official.location.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined,
                    size: 23, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    official.location,
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.body,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _label(IconData icon, String text, Color color) => Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: color,
              ),
            ),
          ),
        ],
      );

  static Widget _timePill(String time) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      );

  static String _capitalised(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// One official: numbered, strictly typographic — no gradients, thin rules.
class _OfficialCard extends StatelessWidget {
  const _OfficialCard({
    required this.index,
    required this.official,
    required this.lang,
    required this.width,
    required this.minHeight,
  });

  final int index;
  final QabulOfficial official;
  final Lang lang;
  final double width;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 18),
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
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
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
