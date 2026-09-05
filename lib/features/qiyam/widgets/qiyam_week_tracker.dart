import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_colors.dart';

/// إتمام آخر ٧ أيام لفئة معيّنة — يُعاد جلبه كلّما تغيّرت سلاسل الاستمرار
/// (`categoryStreakVersionProvider`، نفس ما يُنبَّه به عند كل تسجيل جديد).
final _weekCompletionProvider = FutureProvider.family<List<bool>, String>((
  ref,
  category,
) {
  ref.watch(categoryStreakVersionProvider);
  return ref.watch(userPrefsProvider).fixedWeekCompletionFor(category);
});

/// صف "أيام الأسبوع" — أيام الأسبوع السبعة الثابتة (السبت..الجمعة)
class QiyamWeekTracker extends ConsumerWidget {
  const QiyamWeekTracker({super.key, required this.category});
  final String category;

  static const _dayNames = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']; // السبت..الجمعة

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final weekAsync = ref.watch(_weekCompletionProvider(category));
    final now = DateTime.now();
    final todayIndex = (now.weekday % 7 + 1) % 7;

    return weekAsync.when(
      loading: () => const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (done) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (i < done.length && done[i])
                        ? themeAccent(context)
                        : Colors.transparent,
                    border: Border.all(
                      color: (i < done.length && done[i])
                          ? themeAccent(context)
                          : (i > todayIndex
                                ? onSurface.withValues(alpha: 0.1)
                                : onSurface.withValues(alpha: 0.25)),
                    ),
                  ),
                  child: (i < done.length && done[i])
                      ? const Icon(Icons.check, size: 18, color: AppColors.navy)
                      : Text(
                          _dayNames[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == todayIndex
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: i == todayIndex
                                ? themeAccent(context)
                                : onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  i == todayIndex ? 'اليوم' : '',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: themeAccent(context),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
