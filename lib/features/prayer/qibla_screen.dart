import 'dart:async';
import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/theme/app_colors.dart';

/// اتجاه القبلة وحساب المسافة بدقة إلى الكعبة المشرفة بمكة المكرمة
class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  // إحداثيات الكعبة المشرفة في المسجد الحرام
  static const double _makkahLat = 21.422487;
  static const double _makkahLon = 39.826206;

  /// حساب المسافة بالكيلومترات وفق صيغة Haversine
  static double _distanceToMakkah(double lat, double lon) {
    const double earthRadiusKm = 6371.0;
    final dLat = (lat - _makkahLat) * math.pi / 180.0;
    final dLon = (lon - _makkahLon) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_makkahLat * math.pi / 180.0) *
            math.cos(lat * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(locationPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!prefs.hasLocation) {
      return Scaffold(
        appBar: AppBar(title: const Text('اتجاه القبلة')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined, size: 64, color: onSurface.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'يرجى تحديد موقعك أولاً من شاشة مواقيت الصلاة',
                style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final lat = prefs.lat!;
    final lon = prefs.lon!;
    final qiblaBearing = Qibla.qibla(Coordinates(lat, lon));
    final distanceKm = _distanceToMakkah(lat, lon);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اتجاه القبلة الشريفة'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // بطاقة المعلومات العلوية
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B232E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoItem(
                    icon: Icons.explore_outlined,
                    title: 'زاوية القبلة',
                    value: '${qiblaBearing.toStringAsFixed(1)}°',
                    color: AppColors.goldDeep,
                  ),
                  Container(height: 32, width: 1, color: isDark ? AppColors.lineDark : AppColors.line),
                  _InfoItem(
                    icon: Icons.mosque_outlined,
                    title: 'المسافة لمكة',
                    value: '${distanceKm.round()} كم',
                    color: const Color(0xFF1B8A72),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // قرص البوصلة المتطور
            _EnhancedCompassDial(qiblaBearing: qiblaBearing),

            const SizedBox(height: 32),
            // تنبيه للمستخدم للمعايرة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ضع الهاتف بشكل أفقي مستوٍ وقم بتحريكه برسم رقم 8 لمعايرة الحساس المغناطيسي.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: onSurface.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}

class _EnhancedCompassDial extends StatefulWidget {
  const _EnhancedCompassDial({required this.qiblaBearing});
  final double qiblaBearing;

  @override
  State<_EnhancedCompassDial> createState() => _EnhancedCompassDialState();
}

// عتبة "الاقتراب من القبلة" — راجع [_EnhancedCompassDialState._checkAlignment].
const double _kQiblaAlignmentThresholdDeg = 2.0;

class _EnhancedCompassDialState extends State<_EnhancedCompassDial> {
  StreamSubscription<CompassEvent>? _sub;
  double? _heading;
  bool _compassUnavailable = false;

  // اهتزاز قصير **متكرر** طالما الاتجاه ضمن العتبة (لا نبضة واحدة فقط) —
  // يتوقّف تلقائياً بمجرّد الخروج من العتبة أو إغلاق الشاشة (`dispose`).
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    final events = FlutterCompass.events;
    if (events == null) {
      _compassUnavailable = true;
      return;
    }
    _sub = events.listen(
      (event) {
        if (!mounted) return;
        final h = event.heading;
        if (h != null) {
          setState(() => _heading = h);
          _checkAlignment(h);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _compassUnavailable = true);
      },
    );
  }

  void _checkAlignment(double heading) {
    // الفرق بين اتجاه الجهاز وزاوية القبلة
    double diff = (heading - widget.qiblaBearing).abs();
    if (diff > 180) diff = 360 - diff;

    final isAligned = diff <= _kQiblaAlignmentThresholdDeg;
    if (isAligned) {
      _hapticTimer ??= Timer.periodic(const Duration(milliseconds: 700), (_) {
        HapticFeedback.lightImpact();
      });
    } else {
      _hapticTimer?.cancel();
      _hapticTimer = null;
    }
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final heading = _heading ?? 0.0;
    // زاوية تدوير قرص البوصلة
    final compassRotation = -heading * (math.pi / 180.0);
    // زاوية مؤشر القبلة بالنسبة للشاشة
    final qiblaAngle = (widget.qiblaBearing - heading) * (math.pi / 180.0);

    double diff = (_heading != null ? (_heading! - widget.qiblaBearing).abs() : 100);
    if (diff > 180) diff = 360 - diff;
    final isAligned = _heading != null && diff <= _kQiblaAlignmentThresholdDeg;

    return Column(
      children: [
        // شارة التطابق
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isAligned
                ? const Color(0xFF1B8A72).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isAligned ? const Color(0xFF1B8A72) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAligned ? Icons.check_circle : Icons.navigation_outlined,
                size: 18,
                color: isAligned ? const Color(0xFF1B8A72) : onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                isAligned
                    ? 'أنت باتجاه القبلة تماماً 🕋 ✓'
                    : 'وجّه إبرة الكعبة الذهبية للأعلى',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isAligned ? const Color(0xFF1B8A72) : onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // قرص البوصلة الكبير
        SizedBox(
          width: 270,
          height: 270,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // قرص الدرجات والجهات الدوار
              Transform.rotate(
                angle: compassRotation,
                child: CustomPaint(
                  size: const Size(270, 270),
                  painter: _CompassDialPainter(
                    isDark: isDark,
                    onSurface: onSurface,
                    qiblaBearing: widget.qiblaBearing,
                  ),
                ),
              ),

              // مؤشر الكعبة الشريفة الذهبي
              Transform.rotate(
                angle: qiblaAngle,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Text('🕋', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),

              // دائرة المركز الفخمة
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1B232E) : Colors.white,
                  border: Border.all(
                    color: isAligned ? const Color(0xFF1B8A72) : AppColors.gold,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isAligned ? const Color(0xFF1B8A72) : Colors.black)
                          .withValues(alpha: isAligned ? 0.35 : 0.15),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${heading.round()}°',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isAligned ? const Color(0xFF1B8A72) : onSurface,
                        ),
                      ),
                      Text(
                        _headingName(heading),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_compassUnavailable)
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'حساس البوصلة غير متوفر — الاتجاه ثابت',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _headingName(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'شمال';
    if (deg >= 22.5 && deg < 67.5) return 'شمال شرق';
    if (deg >= 67.5 && deg < 112.5) return 'شرق';
    if (deg >= 112.5 && deg < 157.5) return 'جنوب شرق';
    if (deg >= 157.5 && deg < 202.5) return 'جنوب';
    if (deg >= 202.5 && deg < 247.5) return 'جنوب غرب';
    if (deg >= 247.5 && deg < 292.5) return 'غرب';
    return 'شمال غرب';
  }
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({
    required this.isDark,
    required this.onSurface,
    required this.qiblaBearing,
  });

  final bool isDark;
  final Color onSurface;
  final double qiblaBearing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // الخلفية الدائرية مع التدرج
    final bgPaint = Paint()
      ..color = (isDark ? const Color(0xFF141A23) : const Color(0xFFF7F8FA))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // الحلقة الخارجية
    final ringPaint = Paint()
      ..color = (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, ringPaint);

    // حلقة ثانوية داخلية
    final innerRingPaint = Paint()
      ..color = onSurface.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 30, innerRingPaint);

    // رسم علامات الدرجات والجهات
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    final textPainter = TextPainter(textDirection: TextDirection.rtl);

    for (int i = 0; i < 360; i += 5) {
      final angle = (i - 90) * math.pi / 180;
      final isMajor = i % 30 == 0;
      final isCardinal = i % 90 == 0;

      final tickLength = isCardinal ? 14.0 : (isMajor ? 9.0 : 5.0);
      tickPaint.strokeWidth = isCardinal ? 2.5 : (isMajor ? 1.8 : 1.0);
      tickPaint.color = isCardinal
          ? (i == 0 ? const Color(0xFFE53935) : onSurface)
          : onSurface.withValues(alpha: isMajor ? 0.45 : 0.2);

      final p1 = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 4 - tickLength) * math.cos(angle),
        center.dy + (radius - 4 - tickLength) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);

      // رسم الحروف الرئيسية (شمال N، شرق E، جنوب S، غرب W)
      if (isCardinal) {
        String label = switch (i) {
          0 => 'ش',
          90 => 'شر',
          180 => 'ج',
          270 => 'غ',
          _ => '',
        };
        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: i == 0 ? const Color(0xFFE53935) : onSurface.withValues(alpha: 0.8),
          ),
        );
        textPainter.layout();
        final textOffset = Offset(
          center.dx + (radius - 24) * math.cos(angle) - (textPainter.width / 2),
          center.dy + (radius - 24) * math.sin(angle) - (textPainter.height / 2),
        );
        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.qiblaBearing != qiblaBearing;
}
