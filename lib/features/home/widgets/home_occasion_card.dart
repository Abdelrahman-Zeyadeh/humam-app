import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/hijri/hijri_occasions.dart';
import '../../../core/theme/app_colors.dart';

/// بطاقة مناسبة هجرية (زي "ترقّب ليلة القدر") — بمعالجة ذهبية مميّزة
/// (تدرّج + نقشة نجوم صغيرة) بدل بطاقة بيضاء إضافية، مطابقة لأسلوب لوحة
/// التصميم المعتمدة (راجع الكانفاس، بطاقة "Occasion banner"). استُخرجت
/// من `home_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
class HomeOccasionCard extends StatelessWidget {
  const HomeOccasionCard({super.key, required this.occasion});
  final HijriOccasion occasion;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.gold, AppColors.goldSoft],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _OccasionPatternPainter()),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occasion.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        occasion.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// نقشة نجوم صغيرة على بطاقة المناسبة الذهبية — راجع [HomeOccasionCard].
class _OccasionPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    const spacing = 30.0;
    const angle = 20 * math.pi / 180;
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle);
        canvas.drawPath(_smallStar(9), paint);
        canvas.restore();
      }
    }
  }

  Path _smallStar(double outerR) {
    final innerR = outerR * 0.42;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = (math.pi / 4) * i;
      final r = i.isEven ? outerR : innerR;
      final point = Offset(r * math.cos(a), r * math.sin(a));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _OccasionPatternPainter oldDelegate) => false;
}
