import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/quran/quran_database.dart';
import '../../../core/data/quran/quran_providers.dart';
import 'ayah_share_format.dart';
import 'ayah_share_theme.dart';

/// نافذة اختيار كتاب التفسير المرافق للآية/الآيات المشتركة. يستدعي
/// [onSelected] بمفتاح التفسير المختار (أو 'none') ثم يغلق نفسه.
void showAyahShareTafsirDialog(
  BuildContext context, {
  required String selectedKey,
  required ValueChanged<String> onSelected,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AyahShareColors.primaryGreen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('اختر كتاب التفسير', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(ctx),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in [
            ('none', 'بدون تفسير', ''),
            ('mukhtasar', 'تفسير المختصر', 'المختصر في تفسير القرآن الكريم'),
            ('saadi', 'تفسير السعدي', 'تيسير الكريم الرحمن في تفسير كلام المنان'),
            ('muyassar', 'التفسير الميسر', 'مجمع الملك فهد لطباعة المصحف الشريف'),
            ('jalalayn', 'تفسير الجلالين', 'للإمامين المحلي والسيوطي'),
            ('en_sahih', 'English', 'Sahih International Translation'),
          ])
            ListTile(
              leading: Icon(
                selectedKey == entry.$1 ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: selectedKey == entry.$1 ? AyahShareColors.primaryGreen : Colors.grey,
              ),
              title: Text(entry.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: entry.$3.isNotEmpty ? Text(entry.$3, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
              onTap: () {
                onSelected(entry.$1);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

/// نافذة اختيار السورة (أسفل الشاشة) — تحمّل قائمة السور من [allSurahsProvider]
/// وتستدعي [onSurahSelected] عند اختيار المستخدم لسورة جديدة.
void showAyahShareSurahPicker(
  BuildContext context,
  WidgetRef ref, {
  required int currentSurahId,
  required ValueChanged<int> onSurahSelected,
}) {
  final surahsAsync = ref.read(allSurahsProvider);
  surahsAsync.whenData((surahs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            const Text('اختر السورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: surahs.length,
                itemBuilder: (ctx, i) {
                  final s = surahs[i];
                  final isSel = s.id == currentSurahId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSel ? AyahShareColors.primaryGreen : Colors.grey.withValues(alpha: 0.15),
                      child: Text('${s.id}', style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    title: Text(s.nameAr, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
                    subtitle: Text('${s.ayahCount} آية • ${s.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'}'),
                    selected: isSel,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSurahSelected(s.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  });
}

/// نافذة البحث عن آية (بداية أو نهاية نطاق المشاركة) ضمن آيات السورة الحالية
/// [ayahs]. يستدعي [onRangeChanged] بالمدى الجديد (من/إلى) بعد ضبطه بنفس
/// منطق التصحيح التلقائي الأصلي (تبديل الحد الآخر إن تجاوزه الاختيار الجديد).
void showAyahShareSearchPicker(
  BuildContext context, {
  required bool isFrom,
  required List<Ayah> ayahs,
  required int fromAyah,
  required int toAyah,
  required void Function(int newFromAyah, int newToAyah) onRangeChanged,
}) {
  String searchQuery = '';
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final filtered = ayahs.where((a) {
          if (searchQuery.isEmpty) return true;
          return a.ayah.toString().contains(searchQuery) ||
              toArabicDigits(a.ayah).contains(searchQuery) ||
              a.textUthmani.contains(searchQuery);
        }).toList();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AyahShareColors.primaryGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isFrom ? 'اختر آية البداية' : 'اختر آية النهاية', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 380,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    onChanged: (val) => setDialogState(() => searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'ابحث برقم الآية أو كلماتها...',
                      prefixIcon: const Icon(Icons.search, color: AyahShareColors.primaryGreen, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final a = filtered[i];
                      final isSel = isFrom ? a.ayah == fromAyah : a.ayah == toAyah;
                      return ListTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel ? AyahShareColors.primaryGreen : const Color(0xFFE8F3EB),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            toArabicDigits(a.ayah),
                            style: TextStyle(
                              color: isSel ? Colors.white : AyahShareColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          a.textUthmani,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 15),
                        ),
                        onTap: () {
                          var newFrom = fromAyah;
                          var newTo = toAyah;
                          if (isFrom) {
                            newFrom = a.ayah;
                            if (newTo < newFrom) newTo = newFrom;
                          } else {
                            newTo = a.ayah;
                            if (newFrom > newTo) newFrom = newTo;
                          }
                          onRangeChanged(newFrom, newTo);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
