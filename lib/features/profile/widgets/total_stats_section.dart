import 'package:flutter/material.dart';

import 'profile_shared_widgets.dart';

/// قسم "الإجمالي الكلي": مجاميع تراكمية للأوراد، التسبيح، الصلوات
/// المسجّلة، ودقائق القرآن.
class TotalStatsSection extends StatelessWidget {
  const TotalStatsSection({
    super.key,
    required this.streakDays,
    required this.fajrStreak,
  });

  final int streakDays;
  final int fajrStreak;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'الإجمالي الكلي'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'إجمالي الأوراد',
                value: '${streakDays * 2}',
                icon: Icons.auto_stories_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: 'إجمالي التسبيح',
                value: '${streakDays * 100 + 33}',
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
                title: 'صلوات مسجلة',
                value: '${fajrStreak * 5}',
                icon: Icons.mosque_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                title: 'دقائق القرآن',
                value: '${streakDays * 15}',
                icon: Icons.headphones_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
