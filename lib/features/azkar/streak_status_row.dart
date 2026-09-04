import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_colors.dart';

/// صف حالة موحَّد لأي خانة عبادية مستقلة (أذكار الصباح/المساء/النوم،
/// قيام الليل): عدد أيام السلسلة المتتالية + هل اكتملت اليوم أم لا.
/// نفس الودجت حرفياً بكل الخانات ("زي الثانيات") بدل تصميم منفصل لكل واحدة.
class StreakStatusRow extends ConsumerWidget {
  const StreakStatusRow({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final days = userPrefs.streakDaysFor(category);
    final doneToday = userPrefs.completedTodayFor(category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            size: 16,
            color: themeAccent(context),
          ),
          const SizedBox(width: 4),
          Text(
            '$days يوم متتالي بهذه الخانة',
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (doneToday ? AppColors.teal : onSurface).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  doneToday ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 13,
                  color: doneToday
                      ? AppColors.tealDeep
                      : onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  doneToday ? 'تمّ اليوم' : 'لسا اليوم',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: doneToday
                        ? AppColors.tealDeep
                        : onSurface.withValues(alpha: 0.55),
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
