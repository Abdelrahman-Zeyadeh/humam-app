import 'package:flutter/services.dart';

/// خدمة التحكم بإبقاء الشاشة مضاءة أثناء القراءة (Wakelock)
class ScreenWakelockService {
  static const _channel = MethodChannel('com.humam.humam_app/screen');

  /// تفعيل أو إلغاء إبقاء الشاشة مضاءة
  static Future<void> setKeepScreenOn(bool enable) async {
    try {
      await _channel.invokeMethod('keepScreenOn', {'enable': enable});
    } catch (_) {}
  }
}
