import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// شريط الفئات السريعة أعلى شاشة حديث اليوم، يسمح بتصفية الأحاديث حسب
/// موضوعها (الإخلاص، الصلاة، الصبر، ...) دون مغادرة الشاشة الرئيسية.
///
/// الودجت عرضية بحتة: القرار في اختيار الحديث الجديد بعد تغيّر الفئة يبقى
/// في الشاشة الأم عبر [onCategorySelected] حفاظاً على نفس منطق الاختيار
/// الأصلي.
class DailyHadithCategoryChips extends StatelessWidget {
  const DailyHadithCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, idx) {
          final cat = categories[idx];
          final isSelected = cat == selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            selectedColor: themeAccent(context),
            showCheckmark: false,
            onSelected: (val) {
              if (val) {
                onCategorySelected(cat);
              }
            },
          );
        },
      ),
    );
  }
}
