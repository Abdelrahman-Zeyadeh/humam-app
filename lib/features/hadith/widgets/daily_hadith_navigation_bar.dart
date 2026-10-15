import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// شريط التنقل بين الأحاديث (السابق/التالي)، زر اختيار حديث عشوائي، وعدّاد
/// موضع الحديث الحالي ضمن القائمة الكاملة.
///
/// الودجت عرضية بحتة؛ تفعيل/تعطيل أزرار السابق والتالي يُحسب في الشاشة
/// الأم (حسب حدود القائمة المفلترة حالياً) ويُمرَّر هنا جاهزاً كي يبقى
/// منطق حدود التنقل في مكانه الأصلي.
class DailyHadithNavigationBar extends StatelessWidget {
  const DailyHadithNavigationBar({
    super.key,
    required this.hadithId,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
    required this.onRandom,
  });

  final int hadithId;
  final int totalCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'الحديث السابق',
          onPressed: onPrevious,
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: onRandom,
                icon: const Icon(Icons.shuffle_rounded, size: 15),
                label: const Text('حديث آخر', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeAccent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeAccent(context).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$hadithId / $totalCount',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: themeAccent(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'الحديث التالي',
          onPressed: onNext,
        ),
      ],
    );
  }
}
