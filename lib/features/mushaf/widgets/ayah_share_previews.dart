import 'dart:io';

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

/// معاينة بطاقة المصحف الشريف الأصيلة بتصميم فاخر مطابق للمصحف الشريف،
/// تدعم مشاركة صفحة مصحف كاملة أو آيات محددة، واختيار خلفية مخصصة من الجهاز
/// أو خلفيات فخمة مدمجة (عنبر، ليل مذهب، زمردي، مصحف عتيق).
class AyahMushafImagePreview extends StatelessWidget {
  final bool isDark;
  final List<Ayah> ayahs;
  final String cleanSurahName;
  final int surahId;
  final int fromAyah;
  final int? toAyah;
  final String selectedTafsirKey;
  final double fontSize;
  final WidgetRef ref;

  // إضافات دعم مشاركة الصفحة الكاملة والخلفية المخصصة
  final bool isFullPage;
  final int? pageNumber;
  final int? juzNumber;
  final String? hizbFraction;
  final String? customBgPath;
  final MushafShareBgTheme bgTheme;
  final double overlayDarkness;
  final Map<int, String>? surahNamesMap;

  const AyahMushafImagePreview({
    super.key,
    required this.isDark,
    required this.ayahs,
    required this.cleanSurahName,
    required this.surahId,
    required this.fromAyah,
    this.toAyah,
    required this.selectedTafsirKey,
    required this.fontSize,
    required this.ref,
    this.isFullPage = false,
    this.pageNumber,
    this.juzNumber,
    this.hizbFraction,
    this.customBgPath,
    this.bgTheme = MushafShareBgTheme.parchment,
    this.overlayDarkness = 0.55,
    this.surahNamesMap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomBg = customBgPath != null && File(customBgPath!).existsSync();
    final effectiveIsDark = hasCustomBg ? true : bgTheme.isDark;
    final textColor = hasCustomBg ? const Color(0xFFFFF9EE) : bgTheme.textColor;
    final frameColor = hasCustomBg ? const Color(0xFFE2C974) : bgTheme.frameBorderColor;
    final bannerBg = hasCustomBg ? const Color(0x33D4AF37) : bgTheme.bannerBgColor;
    final bannerBorder = hasCustomBg ? const Color(0x88E2C974) : bgTheme.bannerBorderColor;
    final bannerTextColor = hasCustomBg ? const Color(0xFFFFDF88) : bgTheme.bannerTextColor;
    final endCircleColor = hasCustomBg ? const Color(0xFFE2C974) : bgTheme.endCircleColor;

    final rangeStr = (toAyah != null && fromAyah != toAyah) ? '$fromAyah - $toAyah' : '$fromAyah';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // 1. طبقة الخلفية (صورة مخصصة أو تدرج جاهز)
          Positioned.fill(
            child: hasCustomBg
                ? Image.file(
                    File(customBgPath!),
                    fit: BoxFit.cover,
                  )
                : Container(decoration: bgTheme.backgroundDecoration),
          ),

          // 2. طبقة التعتيم الناعم فوق الصورة المخصصة لضمان وضوح النص القرآني
          if (hasCustomBg)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: overlayDarkness),
              ),
            ),

          // 3. الإطار المزدوج الفاخر والمحتوى القرآني
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: frameColor, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: effectiveIsDark ? 0.45 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: frameColor.withValues(alpha: 0.5), width: 1.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // شريط هوية الصفحة العلوي (في حال مشاركة صفحة كاملة)
                  if (isFullPage && pageNumber != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سُورَةُ $cleanSurahName',
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: bannerTextColor,
                          ),
                        ),
                        Text(
                          'الجُزْءُ ${toArabicDigits(juzNumber ?? 1)}${hizbFraction != null && hizbFraction!.isNotEmpty ? ' · $hizbFraction' : ''}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Divider(color: frameColor.withValues(alpha: 0.4), height: 1),
                    const SizedBox(height: 8),
                  ],

                  // عرض الآيات واللافتات (يدعم السور المتعددة في الصفحة الواحدة)
                  _buildAyahsContent(
                    bannerBg: bannerBg,
                    bannerBorder: bannerBorder,
                    bannerTextColor: bannerTextColor,
                    textColor: textColor,
                    endCircleColor: endCircleColor,
                  ),

                  // التفسير المختار إن وُجد
                  if (selectedTafsirKey != 'none' && ayahs.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Divider(color: frameColor.withValues(alpha: 0.4), height: 1),
                    const SizedBox(height: 8),
                    FutureBuilder<Tafsir?>(
                      future: ref.read(quranRepositoryProvider).tafsirForAyah(ayahs.first.id, edition: selectedTafsirKey),
                      builder: (ctx, snap) {
                        final content = snap.data?.content ?? '';
                        if (content.isEmpty) return const SizedBox.shrink();
                        return Text(
                          content,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.45,
                            color: textColor.withValues(alpha: 0.85),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(color: frameColor.withValues(alpha: 0.3), height: 1),
                  const SizedBox(height: 6),

                  // التذييل السفلي: رقم الصفحة أو نطاق الآيات + شعار هُمَام
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isFullPage && pageNumber != null
                            ? '— ${toArabicDigits(pageNumber!)} —'
                            : '[ سورة $cleanSurahName : $rangeStr ]',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: frameColor,
                        ),
                      ),
                      Text(
                        'تطبيق هُمَام ✨',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahsContent({
    required Color bannerBg,
    required Color bannerBorder,
    required Color bannerTextColor,
    required Color textColor,
    required Color endCircleColor,
  }) {
    if (!isFullPage) {
      // وضع آيات محددة: لافتة السورة بالأعلى ثم البسملة إن لزم ثم الآيات
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSurahBanner(
            title: 'سُورَةُ $cleanSurahName',
            bg: bannerBg,
            border: bannerBorder,
            textColor: bannerTextColor,
          ),
          const SizedBox(height: 10),
          if (fromAyah == 1 && surahId != 9 && surahId != 1) ...[
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 16.5,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _buildTextRich(ayahs, textColor, endCircleColor),
        ],
      );
    }

    // وضع صفحة كاملة: فحص هل تبدأ سورة جديدة بهذه الصفحة
    final widgets = <Widget>[];
    final currentAyahGroup = <Ayah>[];

    for (int i = 0; i < ayahs.length; i++) {
      final a = ayahs[i];
      if (a.ayah == 1) {
        // تفريغ المجموعة السابقة قبل إدراج لافتة السورة الجديدة
        if (currentAyahGroup.isNotEmpty) {
          widgets.add(_buildTextRich(List.from(currentAyahGroup), textColor, endCircleColor));
          widgets.add(const SizedBox(height: 10));
          currentAyahGroup.clear();
        }

        final sName = surahNamesMap?[a.surah] ?? cleanSurahName;
        widgets.add(_buildSurahBanner(
          title: 'سُورَةُ $sName',
          bg: bannerBg,
          border: bannerBorder,
          textColor: bannerTextColor,
        ));
        widgets.add(const SizedBox(height: 8));

        if (a.surah != 9 && a.surah != 1) {
          widgets.add(
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 16.5,
                color: textColor,
              ),
            ),
          );
          widgets.add(const SizedBox(height: 8));
        }
      }
      currentAyahGroup.add(a);
    }

    if (currentAyahGroup.isNotEmpty) {
      widgets.add(_buildTextRich(currentAyahGroup, textColor, endCircleColor));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _buildSurahBanner({
    required String title,
    required Color bg,
    required Color border,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.3),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextRich(List<Ayah> list, Color textColor, Color endCircleColor) {
    return Text.rich(
      TextSpan(
        children: [
          for (final a in list) ...[
            TextSpan(text: '${a.textUthmani} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AyahEndCircle(
                ayahId: a.id,
                ayahNumber: a.ayah,
                pageNumber: a.page,
                size: 26,
                color: endCircleColor,
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
        color: textColor,
      ),
    );
  }
}
