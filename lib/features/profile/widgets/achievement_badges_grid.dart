import 'package:flutter/material.dart';

import 'profile_shared_widgets.dart';

/// قسم "شارات الإنجاز": شبكة شارات مقفلة/مفتوحة حسب تقدّم المستخدم.
class AchievementBadgesGrid extends StatelessWidget {
  const AchievementBadgesGrid({
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
        const SectionHeader(title: 'شارات الإنجاز'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            BadgeItem(
              icon: Icons.local_fire_department,
              label: '3 أيام',
              isUnlocked: streakDays >= 3,
            ),
            BadgeItem(
              icon: Icons.local_fire_department,
              label: '7 أيام',
              isUnlocked: streakDays >= 7,
            ),
            BadgeItem(
              icon: Icons.star_rounded,
              label: '30 يوماً',
              isUnlocked: streakDays >= 30,
            ),
            BadgeItem(
              icon: Icons.auto_awesome,
              label: '100 ورد',
              isUnlocked: streakDays >= 10,
            ),
            const BadgeItem(
              icon: Icons.fingerprint,
              label: '10K تسبيح',
              isUnlocked: true,
            ),
            const BadgeItem(
              icon: Icons.headphones,
              label: '60 د قرآن',
              isUnlocked: true,
            ),
            BadgeItem(
              icon: Icons.mosque,
              label: '100 صلاة',
              isUnlocked: fajrStreak >= 20,
            ),
            BadgeItem(
              icon: Icons.emoji_events,
              label: 'المداومة',
              isUnlocked: streakDays >= 5,
            ),
          ],
        ),
      ],
    );
  }
}
