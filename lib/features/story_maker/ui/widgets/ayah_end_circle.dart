import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/quran/quran_providers.dart';
import '../../../mushaf/mushaf_font_service.dart';

/// علامة نهاية آية بمظهر مصحفي — تستخدم رمز نهاية الآية الفعلي من خط
/// الصفحة (QCF) لو متوفر (الصفحة مُنزَّلة محلياً)، وإلا ترسم بديلاً زخرفياً
/// مماثلاً بـ[_AyahEndCirclePainter]. استُخرجت من `ayah_story_maker_screen.dart`
/// أثناء تفكيك الملف بلا أي تغيير سلوكي.
final storyAyahGlyphProvider = FutureProvider.family<String?, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahMarkerGlyph(ayahId);
});

class AyahEndCircle extends ConsumerWidget {
  final int ayahId;
  final int ayahNumber;
  final int pageNumber;
  final double size;

  const AyahEndCircle({
    super.key,
    required this.ayahId,
    required this.ayahNumber,
    required this.pageNumber,
    this.size = 26,
  });

  String _toArabic(int num) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontAsync = ref.watch(pageFontFamilyProvider(pageNumber));
    final glyphAsync = ref.watch(storyAyahGlyphProvider(ayahId));

    if (fontAsync.hasValue && glyphAsync.hasValue && glyphAsync.value != null && glyphAsync.value!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Text(
          glyphAsync.value!,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: fontAsync.value,
            fontSize: size * 1.05,
            color: const Color(0xFF1E1912),
            height: 1.0,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: CustomPaint(
        size: Size(size, size * 1.15),
        painter: _AyahEndCirclePainter(color: const Color(0xFF1E1912)),
        child: SizedBox(
          width: size,
          height: size * 1.15,
          child: Center(
            child: Text(
              _toArabic(ayahNumber),
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: size * 0.40,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E1912),
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AyahEndCirclePainter extends CustomPainter {
  final Color color;

  _AyahEndCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. الإطار البيضاوي المركزي
    final ovalRect = Rect.fromCenter(center: Offset(cx, cy), width: w * 0.76, height: h * 0.76);
    canvas.drawOval(ovalRect, paint);

    // 2. التاج الزخرفي العلوي (3 فصوص مصحفية)
    final topY = cy - h * 0.38;
    final topPath = Path();
    topPath.moveTo(cx - w * 0.22, topY + h * 0.08);
    topPath.quadraticBezierTo(cx - w * 0.18, topY - h * 0.06, cx - w * 0.08, topY - h * 0.08);
    topPath.quadraticBezierTo(cx - w * 0.03, topY - h * 0.16, cx, topY - h * 0.18);
    topPath.quadraticBezierTo(cx + w * 0.03, topY - h * 0.16, cx + w * 0.08, topY - h * 0.08);
    topPath.quadraticBezierTo(cx + w * 0.18, topY - h * 0.06, cx + w * 0.22, topY + h * 0.08);
    canvas.drawPath(topPath, paint);

    canvas.drawCircle(Offset(cx, topY - h * 0.08), 0.9, fillPaint);

    // 3. الزخرفتان السفليتان المنحنيتان (أجنحة زهرة المصحف)
    final bottomY = cy + h * 0.38;
    final bottomPath = Path();
    bottomPath.moveTo(cx - w * 0.25, bottomY - h * 0.10);
    bottomPath.cubicTo(
      cx - w * 0.28, bottomY + h * 0.08,
      cx - w * 0.12, bottomY + h * 0.16,
      cx, bottomY + h * 0.18,
    );
    bottomPath.cubicTo(
      cx + w * 0.12, bottomY + h * 0.16,
      cx + w * 0.28, bottomY + h * 0.08,
      cx + w * 0.25, bottomY - h * 0.10,
    );
    canvas.drawPath(bottomPath, paint);

    // حلقتان زخرفيتان سفليتان
    final scrollPath = Path();
    scrollPath.moveTo(cx - w * 0.18, bottomY - h * 0.02);
    scrollPath.quadraticBezierTo(cx - w * 0.08, bottomY + h * 0.07, cx, bottomY + h * 0.07);
    scrollPath.quadraticBezierTo(cx + w * 0.08, bottomY + h * 0.07, cx + w * 0.18, bottomY - h * 0.02);
    canvas.drawPath(scrollPath, paint..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
