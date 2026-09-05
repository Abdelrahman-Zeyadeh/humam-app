import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/daily_hadith_data.dart';

/// يفتح لوحة سفلية (bottom sheet) قابلة للسحب تعرض فهرس كل الأحاديث مع
/// حقل بحث، وتتيح القفز مباشرة إلى أي حديث منها.
///
/// نُقلت هذه الدالة بحرفيتها من `_showAllHadithsSheet` في الشاشة الأصلية؛
/// منطق التصفية (حسب الفئة ونص البحث) وتحديث الحديث المختار ما زالا في
/// الشاشة الأم ويصلان هنا عبر [filteredHadiths] و [onSearchChanged] و
/// [onHadithSelected] حفاظاً على نفس السلوك تماماً.
void showDailyHadithIndexSheet(
  BuildContext context, {
  required int selectedIndex,
  required List<DailyHadithItem> Function() filteredHadiths,
  required ValueChanged<String> onSearchChanged,
  required ValueChanged<int> onHadithSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B232E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: StatefulBuilder(
                    builder: (ctx, setSheetState) {
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (v) {
                            setSheetState(() {});
                            onSearchChanged(v);
                          },
                          decoration: const InputDecoration(
                            hintText: 'ابحث في المتن أو الراوي أو المصدر...',
                            hintStyle: TextStyle(fontSize: 12),
                            prefixIcon: Icon(Icons.search, size: 18),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: filteredHadiths().length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, i) {
                      final item = filteredHadiths()[i];
                      final origIndex = kCuratedDailyHadiths.indexOf(item);
                      final isSel = origIndex == selectedIndex;
                      return ListTile(
                        selected: isSel,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: isSel
                              ? themeAccent(context)
                              : (isDark ? Colors.white12 : Colors.black12),
                          child: Text(
                            '${item.id}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : null,
                            ),
                          ),
                        ),
                        title: Text(
                          item.matn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${item.category} · ${item.source}',
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        onTap: () {
                          onHadithSelected(origIndex);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
