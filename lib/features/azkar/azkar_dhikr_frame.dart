import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// إطار نص الذكر — بطاقة داخلية أنيقة (خلفية مصبوغة بلون التمييز خفيفاً +
/// حدّ رفيع + زخرفة نجمية صغيرة أعلى النص) بمحاذاة وسط، بطلب صاحب المشروع
/// صراحة "النص مكانه بالنص وبطاقات الأذكار تكون باطار جميل وأنيق". مشتركة
/// بين `azkar_screen.dart` (أذكار الصباح/المساء) وأقسام مكتبة حصن المسلم
/// كلها (`azkar_library_category_screen.dart`) — توحيد شكل كل شاشات الأذكار.
class DhikrTextFrame extends StatelessWidget {
  const DhikrTextFrame({super.key, required this.text, required this.done});
  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final color = done ? AppColors.teal : themeAccent(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 13,
            color: color.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: done ? onSurface.withValues(alpha: 0.55) : onSurface,
              fontSize: 15,
              height: 1.9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
