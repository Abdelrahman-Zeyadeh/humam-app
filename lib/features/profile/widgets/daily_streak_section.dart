import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'profile_shared_widgets.dart';

/// قسم "الانتظام اليومي": صف أيام الأسبوع بلهيب لمن انتظم، ومقاييس
/// الحالي/الأفضل/النسبة الشهرية.
class DailyStreakSection extends StatelessWidget {
  const DailyStreakSection({super.key, required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        const SectionHeader(title: 'الانتظام اليومي'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2836) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.lineDark : AppColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['سب', 'أح', 'إث', 'ثل', 'أر', 'خم', 'جم'].map((
                  day,
                ) {
                  final isToday = day == 'أر' || streakDays > 0;
                  return Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? const Color(0xFFE67E22)
                              : (isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.04)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.local_fire_department,
                          size: 18,
                          color: isToday
                              ? Colors.white
                              : Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 11,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StreakMetric(label: 'الحالي', value: '$streakDays'),
                  StreakMetric(
                    label: 'الأفضل',
                    value: '${streakDays > 7 ? streakDays : 7}',
                  ),
                  StreakMetric(
                    label: 'شهرياً',
                    value: '${(streakDays / 30 * 100).clamp(0, 100).toInt()}%',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
