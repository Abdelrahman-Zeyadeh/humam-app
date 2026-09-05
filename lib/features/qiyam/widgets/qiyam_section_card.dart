import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// بطاقة قسم موحّدة لجسم شاشة قيام الليل (تسجيل/خطة الآيات/التذكير) —
/// خلفية سطح مرفوعة قليلاً بحواف مدوّرة وظل خفيف، بنفس روح باقي بطاقات
/// التطبيق، بدل نص خام مفصول بـ`Divider`.
class QiyamSectionCard extends StatelessWidget {
  const QiyamSectionCard({super.key, required this.child, this.accent});
  final Widget child;

  /// شريط علوي ملوّن مميِّز لهوية هذا القسم تحديداً — بلا هذا اللون، كل
  /// البطاقات الثلاث كانت متطابقة الشكل تماماً (بطلب صاحب المشروع "تصميم
  /// بصري أعمق").
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accent != null) Container(height: 4, color: accent),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}
