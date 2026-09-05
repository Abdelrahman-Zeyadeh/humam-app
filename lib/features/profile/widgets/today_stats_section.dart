import 'package:flutter/material.dart';

import 'profile_shared_widgets.dart';

/// قسم "إحصائيات اليوم": أوراد الأذكار، التسبيحات، ودقائق القرآن/التطبيق.
class TodayStatsSection extends StatelessWidget {
  const TodayStatsSection({
    super.key,
    required this.morningStreak,
    required this.eveningStreak,
    required this.streakDays,
  });

  final int morningStreak;
  final int eveningStreak;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'إحصائيات اليوم'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'أوراد الأذكار',
                value:
                    '${(morningStreak > 0 ? 1 : 0) + (eveningStreak > 0 ? 1 : 0)}',
                icon: Icons.auto_awesome,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: 'تسبيحات',
                value: '33',
                icon: Icons.fingerprint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'دقائق قرآن',
                value: '${streakDays * 5}',
                icon: Icons.headphones_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: 'دقائق في التطبيق',
                value: '${streakDays * 12}',
                icon: Icons.timer_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
