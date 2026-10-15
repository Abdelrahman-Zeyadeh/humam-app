import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'tasbih_library_data.dart';
import 'tasbih_library_tile.dart';

/// شيت اختيار الذكر لشاشة المسبحة — يجمع "سبحات جاهزة" (بهدف وسجل آخر
/// إتمام) و"أذكار سريعة" (بلا هدف مسجَّل) بمكان واحد خلف ضغطة، بدل عرضهما
/// دائماً كشريطين أفقيين فوق العداد (راجع توثيق زر الاختيار بـ
/// `tasbih_screen.dart`). استُخرجت من الشاشة أثناء تفكيكها بلا أي تغيير
/// سلوكي؛ الحالة (السبحة النشطة/الذكر المختار) تبقى مُدارة بالشاشة الأمّ
/// وتُمرَّر هون فقط للعرض، مع دالتي رد نداء لتطبيق الاختيار.
Future<void> showTasbihPhrasePicker(
  BuildContext context, {
  required String? activeLibraryKey,
  required Map<String, DateTime?> lastCompletedByKey,
  required String selectedPhrase,
  required void Function(TasbihLibraryItem item) onSelectLibraryItem,
  required void Function(String phrase) onSelectPhrase,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final accent = themeAccent(context);
  final fg = isDark ? AppColors.inkOnDark : const Color(0xFF135B4C);
  final surface = isDark ? AppColors.surfaceDark : Colors.white;
  final border = isDark ? AppColors.lineDark : AppColors.line;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    'سبحات جاهزة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final item in kTasbihLibrary)
                TasbihLibraryItemTile(
                  item: item,
                  isSelected: activeLibraryKey == item.key,
                  lastLabel: lastCompletedLabel(lastCompletedByKey[item.key]),
                  accent: accent,
                  surface: surface,
                  border: border,
                  fg: fg,
                  onTap: () {
                    onSelectLibraryItem(item);
                    Navigator.of(ctx).pop();
                  },
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    'أذكار سريعة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final phrase in kDefaultTasbihPhrases)
                    ChoiceChip(
                      label: Text(phrase),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selectedPhrase == phrase
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selectedPhrase == phrase ? Colors.white : fg,
                      ),
                      selected: selectedPhrase == phrase,
                      selectedColor: accent,
                      backgroundColor: surface,
                      side: BorderSide(
                        color: selectedPhrase == phrase ? accent : border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (_) {
                        onSelectPhrase(phrase);
                        Navigator.of(ctx).pop();
                      },
                    ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
