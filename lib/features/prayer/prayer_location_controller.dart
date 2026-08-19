import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/data/user/location_prefs.dart';
import '../notifications/adhan_notification_prefs.dart';
import '../notifications/adhan_notification_service.dart';

/// إشعار بسيط يُعاد بناؤه عند تغيير الموقع/طريقة الحساب — نفس نمط
/// `bookmarkVersionProvider` (تخزين متزامن بلا Stream خاص به).
class LocationVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final locationVersionProvider = NotifierProvider<LocationVersionNotifier, int>(
  LocationVersionNotifier.new,
);

/// يجلب موقع GPS الفعلي أو يضبط مدينة يدوية، ويخزّنه بـ`LocationPrefs`.
/// حالة `AsyncValue<void>` تعكس فقط عملية "استخدام GPS" (تحتاج انتظار
/// إذن/قراءة حسّاس)؛ اختيار مدينة يدوي فوري لا يحتاج حالة تحميل.
///
/// **لم يُختبر تدفّق إذن GPS على جهاز فعلي** — لا هاتف متّصل الليلة. مبني
/// حسب توثيق `geolocator` الرسمي (فحص/طلب إذن ثم قراءة الموقع).
class LocationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> useGps() async {
    state = const AsyncValue.loading();
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw StateError(
          'خدمة الموقع غير مفعّلة بالجهاز — فعّلها من الإعدادات',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw StateError('إذن الموقع مرفوض');
      }
      if (permission == LocationPermission.deniedForever) {
        throw StateError('إذن الموقع مرفوض دائماً — فعّله من إعدادات النظام');
      }

      final position = await Geolocator.getCurrentPosition();
      await ref
          .read(locationPrefsProvider)
          .setLocation(
            lat: position.latitude,
            lon: position.longitude,
            cityName: 'الموقع الحالي (GPS)',
          );
      ref.read(locationVersionProvider.notifier).bump();
      await _rescheduleAdhanNotifications();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setCalculationMethod(String key) async {
    await ref.read(locationPrefsProvider).setCalculationMethod(key);
    ref.read(locationVersionProvider.notifier).bump();
    await _rescheduleAdhanNotifications();
  }

  /// يعيد جدولة إشعارات الأذان لتطابق الموقع/الطريقة الجديدة — فشل صامت
  /// (استثناء لا يوقف تحديث الموقع نفسه، فقط الإشعارات قد تتأخر لإعادة
  /// جدولة لاحقة). راجع تحذيرات `AdhanNotificationService`.
  Future<void> _rescheduleAdhanNotifications() async {
    try {
      final loc = ref.read(locationPrefsProvider);
      if (!loc.hasLocation) return;
      final notifPrefs = ref.read(adhanNotificationPrefsProvider);
      await AdhanNotificationService.instance.rescheduleUpcoming(
        lat: loc.lat!,
        lon: loc.lon!,
        methodKey: loc.calculationMethod,
        isEnabled: notifPrefs.effectivelyEnabled,
      );
    } catch (_) {
      // راجع تعليق الدالة — لا نُفشل تحديث الموقع بسبب الإشعارات.
    }
  }
}

final locationControllerProvider =
    NotifierProvider<LocationController, AsyncValue<void>>(
      LocationController.new,
    );
