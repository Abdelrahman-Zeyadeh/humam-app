import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kChannel = MethodChannel('com.humam.humam_app/floating_dhikr');

/// خدمة التحكم في عداد الذكر والتسبيح العائم فوق التطبيقات في نظام أندرويد
class FloatingDhikrService {
  const FloatingDhikrService._();

  static bool get isSupported => Platform.isAndroid;

  /// هل يمتلك التطبيق إذن الظهور فوق التطبيقات الأخرى؟
  static Future<bool> canDrawOverlays() async {
    if (!isSupported) return false;
    try {
      final res = await _kChannel.invokeMethod<bool>('canDrawOverlays');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// فتح شاشة إعدادات النظام لمنح إذن الظهور فوق التطبيقات
  static Future<bool> requestOverlayPermission() async {
    if (!isSupported) return false;
    try {
      final res = await _kChannel.invokeMethod<bool>('requestOverlayPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// تشغيل عداد الذكر العائم فوق التطبيقات
  static Future<bool> start({String? dhikrText}) async {
    if (!isSupported) return false;
    try {
      final res = await _kChannel.invokeMethod<bool>(
        'startFloatingDhikr',
        {'dhikrText': dhikrText},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// إيقاف عداد الذكر العائم
  static Future<bool> stop() async {
    if (!isSupported) return false;
    try {
      final res = await _kChannel.invokeMethod<bool>('stopFloatingDhikr');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// هل العداد العائم يعمل حالياً على الشاشة؟
  static Future<bool> isActive() async {
    if (!isSupported) return false;
    try {
      final res = await _kChannel.invokeMethod<bool>('isFloatingDhikrActive');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}

class FloatingDhikrNotifier extends Notifier<bool> {
  @override
  bool build() {
    _checkStatus();
    return false;
  }

  Future<void> _checkStatus() async {
    final active = await FloatingDhikrService.isActive();
    state = active;
  }

  Future<bool> toggle({String? dhikrText}) async {
    if (state) {
      final ok = await FloatingDhikrService.stop();
      if (ok) state = false;
      return false;
    } else {
      final hasPerm = await FloatingDhikrService.canDrawOverlays();
      if (!hasPerm) {
        await FloatingDhikrService.requestOverlayPermission();
        return false;
      }
      final ok = await FloatingDhikrService.start(dhikrText: dhikrText);
      if (ok) state = true;
      return ok;
    }
  }

  Future<void> refresh() async => _checkStatus();
}

final floatingDhikrProvider = NotifierProvider<FloatingDhikrNotifier, bool>(
  FloatingDhikrNotifier.new,
);
