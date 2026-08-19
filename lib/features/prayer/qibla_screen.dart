import 'dart:async';
import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/theme/app_colors.dart';

/// اتجاه القبلة: زاوية رقمية دايماً (محسوبة محلياً بـ`Qibla.qibla` من
/// `adhan_dart` — لا تحتاج بوصلة)، وبوصلة دوّارة اختيارية لو توفّر حسّاس
/// اتجاه بالجهاز (`flutter_compass`). **لم تُختبر البوصلة على جهاز فعلي
/// بحسّاس مغناطيسي حقيقي الليلة** — راجع `tools/raw/README.md`.
class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(locationPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (!prefs.hasLocation) {
      return Scaffold(
        appBar: AppBar(title: const Text('اتجاه القبلة')),
        body: Center(
          child: Text('حدّد موقعك أولاً من شاشة مواقيت الصلاة', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
        ),
      );
    }

    final qiblaBearing = Qibla.qibla(Coordinates(prefs.lat!, prefs.lon!));

    return Scaffold(
      appBar: AppBar(title: const Text('اتجاه القبلة')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompassDial(qiblaBearing: qiblaBearing),
              const SizedBox(height: 24),
              Text('${qiblaBearing.toStringAsFixed(1)}° من الشمال', style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'وجّه أعلى الدائرة الذهبية باتجاه إبرة الشمال بجهازك ليتطابق مع القبلة',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassDial extends StatefulWidget {
  const _CompassDial({required this.qiblaBearing});
  final double qiblaBearing;

  @override
  State<_CompassDial> createState() => _CompassDialState();
}

class _CompassDialState extends State<_CompassDial> {
  StreamSubscription<CompassEvent>? _sub;
  double? _heading;
  bool _compassUnavailable = false;

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
        if (event.heading != null) setState(() => _heading = event.heading);
      },
      onError: (_) => setState(() => _compassUnavailable = true),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // بلا بوصلة: نثبّت المؤشر باتجاه القبلة كرقم مطلق (٠ = شمال بالأعلى)
    // بدل تدوير حي — أفضل من عرض شي مكسور لو الحسّاس غير متوفّر (مكتبي
    // مثلاً، أو جهاز بلا مغناطيسي).
    final rotation = _heading == null ? widget.qiblaBearing : widget.qiblaBearing - _heading!;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: onSurface.withValues(alpha: 0.15), width: 2),
            ),
          ),
          const Positioned(top: 8, child: Text('ش', style: TextStyle(fontWeight: FontWeight.bold))),
          Transform.rotate(
            angle: rotation * math.pi / 180,
            child: Icon(Icons.navigation, size: 90, color: AppColors.gold),
          ),
          if (_compassUnavailable)
            Positioned(
              bottom: 8,
              child: Text('لا يوجد حسّاس بوصلة بهذا الجهاز — الاتجاه رقمي فقط', style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.5))),
            ),
        ],
      ),
    );
  }
}
