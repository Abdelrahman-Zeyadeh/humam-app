import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../daily_challenge.dart';
import '../home_style_helpers.dart';

/// بطاقة "تحدي اليوم" — مهمة صغيرة عشوائية يومياً (راجع `daily_challenge.
/// dart`)، منفصلة عمداً عن "أهدافي اليوم" (`GoalsGroupCard`، ورد ثابت
/// مرتبط بخطط فعلية) — هاي بلا خطة، مجرّد اقتراح إضافي اختياري يتجدّد كل
/// يوم بلا حاجة لإعداد مسبق من المستخدم.
class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `userPrefsProvider` عادي (`Provider` لا `ChangeNotifierProvider`) —
    // مراقبة `categoryStreakVersionProvider` ضرورية لإعادة البناء بعد
    // `markDailyChallengeCompletedToday`، بنفس نمط بقية بطاقات/صفوف
    // الإعدادات المشابهة (راجع `EveningSummaryReminderRow` مثلاً).
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final done = userPrefs.dailyChallengeCompletedToday;
    final text = dailyChallengeTextFor(DateTime.now());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = done ? AppColors.tealDeep : const Color(0xFFC5A059);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: isDark
                ? [
                    accentColor.withValues(alpha: 0.16),
                    AppColors.surfaceDark,
                  ]
                : done
                    ? const [Color(0xFFEEF8F5), Color(0xFFE3F2EE)]
                    : const [Color(0xFFFFFCF5), Color(0xFFF6ECDA)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.3),
            width: 1.1,
          ),
        ),
        child: Row(
          children: [
            IconBadge(
              icon: done ? Icons.check_circle_rounded : Icons.bolt_rounded,
              color: done ? AppColors.tealDeep : AppColors.goldDeep,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحدي اليوم ✨',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFD4AF67)
                          : const Color(0xFF8C6D3F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: homeTextStrong(context),
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (!done)
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF135B4C).withValues(alpha: isDark ? 0.3 : 0.14),
                  foregroundColor:
                      isDark ? const Color(0xFF64B5A5) : const Color(0xFF135B4C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  await userPrefs.markDailyChallengeCompletedToday();
                  ref.read(categoryStreakVersionProvider.notifier).bump();
                },
                child: const Text(
                  'تمّ ✓',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
