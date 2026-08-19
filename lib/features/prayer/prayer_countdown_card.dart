import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hijri/hijri_date.dart';
import '../../core/theme/app_colors.dart';
import 'prayer_times_service.dart';

/// نبضة كل ثانية لعدّاد الصلاة القادمة — مشتركة بين شاشة الصلاة والداشبورد
/// بدل تكرارها بكل شاشة على حدة.
final prayerTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// بطاقة الصلاة القادمة — **التاريخ الهجري ضمن البطاقة نفسها** الآن (كان
/// نصاً منفصلاً فوقها بشاشة الصلاة فقط، وغير موجود إطلاقاً بالداشبورد قبل
/// هذه البطاقة). مشتركة بين `prayer_screen.dart` والداشبورد
/// (`home_screen.dart`) — حساب محلي بالكامل عبر `computeDayTimes`.
class PrayerCountdownCard extends ConsumerWidget {
  const PrayerCountdownCard({super.key, required this.lat, required this.lon, required this.methodKey, this.onTap, this.footer});
  final double lat;
  final double lon;
  final String methodKey;
  final VoidCallback? onTap;

  /// محتوى إضافي اختياري يُرسَم أسفل العدّاد داخل نفس البطاقة (فاصل خفيف
  /// بينهما) — تستخدمه الرئيسية لعرض آية/ذكر الفترة ضمن نفس "الودجت"
  /// بدل بطاقة منفصلة. `null` بشاشة الصلاة (بلا تغيير).
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(prayerTickProvider).value ?? DateTime.now();
    final dayTimes = computeDayTimes(lat: lat, lon: lon, date: now, methodKey: methodKey);
    var next = nextPrayer(dayTimes, now);
    // كل صلوات اليوم فاتت — نعرض فجر الغد كبديل بدل ترك العدّاد فارغاً.
    if (next == null) {
      final tomorrow = computeDayTimes(lat: lat, lon: lon, date: now.add(const Duration(days: 1)), methodKey: methodKey);
      next = tomorrow.firstWhere((t) => t.moment.isPrayer);
    }

    // بطاقة مصغَّرة قليلاً عن السابق (كانت "كبيرة كثير" بالداشبورد بتقييم
    // مباشر على جهاز فعلي) — padding وأحجام خط أقل، بلا فقد أي معلومة.
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        children: [
          Text(
            todayHijriArabic(),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('الصلاة القادمة', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          const SizedBox(height: 4),
          Text(next.moment.nameAr, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          _CountdownText(target: next.time),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
            const SizedBox(height: 10),
            footer!,
          ],
        ],
      ),
    );

    return Card(
      color: AppColors.navy,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Ink(
        decoration: const BoxDecoration(
          // كحلي متوسط → كحلي بدل كحلي متوسط → كحلي شبه أسود سابقاً —
          // نفس الهوية بثقل بصري أخف (طلب "ألوان أفتح").
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.blue, AppColors.navy],
          ),
        ),
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _CountdownText extends ConsumerWidget {
  const _CountdownText({required this.target});
  final DateTime target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(prayerTickProvider).value ?? DateTime.now();
    final remaining = target.difference(now);
    final positive = remaining.isNegative ? Duration.zero : remaining;
    final h = positive.inHours.toString().padLeft(2, '0');
    final m = (positive.inMinutes % 60).toString().padLeft(2, '0');
    final s = (positive.inSeconds % 60).toString().padLeft(2, '0');
    return Text('باقي $h:$m:$s', style: const TextStyle(color: AppColors.goldSoft, fontSize: 14, fontWeight: FontWeight.w700));
  }
}
