import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/quran/quran_providers.dart';
import '../mushaf_font_service.dart';
import 'ayah_share_format.dart';

final _ayahGlyphProvider = FutureProvider.family<String?, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahMarkerGlyph(ayahId);
});

/// علامة نهاية الآية الدائرية المطابقة تماماً للمصحف الشريف (زهرة المصحف
/// الأصلية بـ QCF V2 أو الرسم المتجهي الدقيق كبديل عند غياب الخط/الرمز).
class AyahEndCircle extends ConsumerWidget {
  final int ayahId;
  final int ayahNumber;
  final int pageNumber;
  final double size;
  final Color? color;

  const AyahEndCircle({
    super.key,
    required this.ayahId,
    required this.ayahNumber,
    required this.pageNumber,
    this.size = 26,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveColor = color ?? const Color(0xFF1E1912);
    final fontAsync = ref.watch(pageFontFamilyProvider(pageNumber));
    final glyphAsync = ref.watch(_ayahGlyphProvider(ayahId));

    if (fontAsync.hasValue && glyphAsync.hasValue && glyphAsync.value != null && glyphAsync.value!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Text(
          glyphAsync.value!,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: fontAsync.value,
            fontSize: size * 1.05,
            color: effectiveColor,
            height: 1.0,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: CustomPaint(
        size: Size(size, size * 1.15),
        painter: _AyahEndCirclePainter(color: effectiveColor),
        child: SizedBox(
          width: size,
          height: size * 1.15,
          child: Center(
            child: Text(
              toArabicDigits(ayahNumber),
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: size * 0.40,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
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

    // 2. التاج الزخرفي العلوي (3 فصوص مصحفية متناسقة)
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
