import 'package:flutter/material.dart';

import 'profile_shared_widgets.dart';

/// قسم "تحليل التقدم": صفوف تقدّم نحو أهداف الأذكار، التسبيح، القرآن،
/// الصلوات، والحفظ والمراجعة.
class ProgressGoalsSection extends StatelessWidget {
  const ProgressGoalsSection({
    super.key,
    required this.morningStreak,
    required this.eveningStreak,
    required this.streakDays,
    required this.fajrStreak,
    required this.hifzStreak,
  });

  final int morningStreak;
  final int eveningStreak;
  final int streakDays;
  final int fajrStreak;
  final int hifzStreak;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'تحليل التقدم'),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ProgressGoalRow(
                  label: 'الأذكار',
                  current:
                      (morningStreak > 0 ? 50 : 0) +
                      (eveningStreak > 0 ? 50 : 0),
                  total: 100,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: 12),
                const ProgressGoalRow(
                  label: 'التسبيح',
                  current: 33,
                  total: 100,
                  icon: Icons.fingerprint,
                ),
                const SizedBox(height: 12),
                ProgressGoalRow(
                  label: 'القرآن (ساعة)',
                  current: streakDays,
                  total: 10,
                  icon: Icons.headphones,
                ),
                const SizedBox(height: 12),
                ProgressGoalRow(
                  label: 'الصلوات',
                  current: fajrStreak > 0 ? 5 : 0,
                  total: 5,
                  icon: Icons.mosque,
                ),
                const SizedBox(height: 12),
                ProgressGoalRow(
                  label: 'الحفظ والمراجعة',
                  current: hifzStreak,
                  total: 7,
                  icon: Icons.school,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
