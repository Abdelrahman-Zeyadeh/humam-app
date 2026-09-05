import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/quran/quran_database.dart';
import '../../../core/data/quran/quran_providers.dart';
import 'ayah_end_circle.dart';
import 'ayah_share_format.dart';
import 'ayah_share_theme.dart';

/// معاينة بطاقة النص (مطابقة تماماً للصورة 1) — تُستخدم في تبويب "نص" من
/// نافذة المشاركة، وتُلتقط كصورة عند تنفيذ المشاركة/الحفظ لنفس التبويب.
class AyahTextCardPreview extends StatelessWidget {
  final bool isDark;
  final List<Ayah> ayahs;
  final String cleanSurahName;
  final int fromAyah;
  final int toAyah;
  final String selectedTafsirKey;
  final WidgetRef ref;

  const AyahTextCardPreview({
    super.key,
    required this.isDark,
    required this.ayahs,
    required this.cleanSurahName,
    required this.fromAyah,
    required this.toAyah,
    required this.selectedTafsirKey,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final rangeStr = fromAyah == toAyah ? '$fromAyah' : '$fromAyah - $toAyah';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AyahShareColors.borderTan),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // أيقونة النسخ السريعة في زاوية البطاقة
          Align(
            alignment: Alignment.topLeft,
            child: InkWell(
              onTap: () async {
                final buffer = StringBuffer();
                for (final a in ayahs) {
                  buffer.write('${a.textUthmani} ﴿${toArabicDigits(a.ayah)}﴾ ');
                }
                await Clipboard.setData(ClipboardData(text: '{ ${buffer.toString().trim()} }\n[ سورة $cleanSurahName : $rangeStr ]'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص الآية بنجاح 📋')));
                }
              },
              child: const Icon(Icons.copy_rounded, color: AyahShareColors.primaryGreen, size: 20),
            ),
          ),
          const SizedBox(height: 6),

          // نص الآيات
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '{ '),
                for (final a in ayahs) ...[
                  TextSpan(text: '${a.textUthmani} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: AyahEndCircle(
                      ayahId: a.id,
                      ayahNumber: a.ayah,
                      pageNumber: a.page,
                      size: 24,
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
                const TextSpan(text: '}'),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 18,
              height: 2.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // توثيق السورة والآية
          Text(
            '[ سورة $cleanSurahName : $rangeStr ]',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
          ),

          // التفسير المختار إن وُجد
          if (selectedTafsirKey != 'none' && ayahs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            FutureBuilder<Tafsir?>(
              future: ref.read(quranRepositoryProvider).tafsirForAyah(ayahs.first.id, edition: selectedTafsirKey),
              builder: (ctx, snap) {
                final content = snap.data?.content ?? '';
                if (content.isEmpty) return const SizedBox.shrink();
                return Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF5D4037)),
                );
              },
            ),
          ],

          const SizedBox(height: 10),
          const Text(
            'بواسطة تطبيق هُمَام',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// معاينة بطاقة المصحف الشريف الأصيلة (مطابقة تماماً للصورة 3 بدائرة نهاية
/// الآيات المصحفية) — تُستخدم في تبويبي "صورة" و"صوت" من نافذة المشاركة.
class AyahMushafImagePreview extends StatelessWidget {
  final bool isDark;
  final List<Ayah> ayahs;
  final String cleanSurahName;
  final int surahId;
  final int fromAyah;
  final String selectedTafsirKey;
  final double fontSize;
  final WidgetRef ref;

  const AyahMushafImagePreview({
    super.key,
    required this.isDark,
    required this.ayahs,
    required this.cleanSurahName,
    required this.surahId,
    required this.fromAyah,
    required this.selectedTafsirKey,
    required this.fontSize,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AyahShareColors.goldMushaf, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // لافتة اسم السورة المزخرفة بالألوان العثمانية (مطابقة لصور وحي)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECE3D0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8D7344), width: 1.2),
            ),
            child: Text(
              'سُورَةُ $cleanSurahName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2416),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // البسملة إن كانت البداية
          if (fromAyah == 1 && surahId != 9 && surahId != 1) ...[
            const Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 16.5, color: Color(0xFF2C2416)),
            ),
            const SizedBox(height: 8),
          ],

          // نص الآيات القرآنية مع رقم الآية الدائري المصحفي الأصيل
          Text.rich(
            TextSpan(
              children: [
                for (final a in ayahs) ...[
                  TextSpan(text: '${a.textUthmani} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: AyahEndCircle(
                      ayahId: a.id,
                      ayahNumber: a.ayah,
                      pageNumber: a.page,
                      size: 26,
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: fontSize,
              height: 2.3,
              leadingDistribution: TextLeadingDistribution.even,
              color: const Color(0xFF1E1912),
            ),
          ),

          // التفسير المختار إن وُجد
          if (selectedTafsirKey != 'none' && ayahs.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: AyahShareColors.goldMushaf, height: 1),
            const SizedBox(height: 6),
            FutureBuilder<Tafsir?>(
              future: ref.read(quranRepositoryProvider).tafsirForAyah(ayahs.first.id, edition: selectedTafsirKey),
              builder: (ctx, snap) {
                final content = snap.data?.content ?? '';
                if (content.isEmpty) return const SizedBox.shrink();
                return Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF5D4037)),
                );
              },
            ),
          ],

          const SizedBox(height: 8),
          const Text(
            'بواسطة تطبيق هُمَام',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF8D7344), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
