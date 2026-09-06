import 'package:flutter/services.dart';

/// وضع "لا تُزعجني وقت القراءة" — كتم إشعارات الجهاز تلقائياً أثناء فتح
/// المصحف (بطلب صريح، بنفس فكرة تطبيقات Digital Detox). تفعيل/تعطيل فلتر
/// المقاطعة الفعلي (`NotificationManager.setInterruptionFilter`) يحتاج
/// **تصريح وصول لسياسة الإشعارات** (Notification Policy Access) — تصريح
/// خاص يمنحه المستخدم يدوياً من إعدادات النظام (لا رسالة إذن قياسية)،
/// فبدونه `setActive` تفشل بصمت (`false`) بدل رمي استثناء.
///
/// **iOS بلا دعم مكافئ حقيقي** — لا API عام مماثل لـ`setInterruptionFilter`
/// (Focus Modes على iOS مغلقة أمام تطبيقات الطرف الثالث)، فكل استدعاءات
/// هذا الصنف تعيد `false` بأمان على iOS بدل رمي استثناء (`MissingPluginException`
/// يُمسَك ضمنياً بمحاولة القناة).
///
/// غير مُختبر بجهاز أندرويد فعلي بعد — راجع `MainActivity.kt`.
abstract final class DndService {
  static const _channel = MethodChannel('com.humam.humam_app/dnd');

  static Future<bool> isPolicyAccessGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isPolicyAccessGranted') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// يفتح شاشة إعدادات النظام لمنح "الوصول لسياسة الإشعارات" يدوياً —
  /// لا رسالة إذن قياسية بديلة تفتح هذا التصريح تحديداً.
  static Future<bool> openPolicyAccessSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openPolicyAccessSettings') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// يفعّل/يعطّل الكتم الفعلي. يرجع `false` بأمان (بلا استثناء) لو التصريح
  /// غير ممنوح بعد أو المنصّة لا تدعم القناة أصلاً (iOS).
  static Future<bool> setActive(bool active) async {
    try {
      return await _channel.invokeMethod<bool>('setDndActive', {
            'active': active,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
