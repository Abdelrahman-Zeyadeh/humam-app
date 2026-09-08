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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
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
                    'تحدي اليوم',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: homeTextSoft(context),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  await userPrefs.markDailyChallengeCompletedToday();
                  ref.read(categoryStreakVersionProvider.notifier).bump();
                },
                child: const Text('تمّ ✓', style: TextStyle(fontSize: 11.5)),
              ),
          ],
        ),
      ),
    );
  }
}
