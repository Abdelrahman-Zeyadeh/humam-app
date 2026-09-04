import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/services/reverse_geocode_service.dart';
import '../notifications/adhan_notification_prefs.dart';
import '../notifications/adhan_notification_service.dart';

/// نصوص GPS الثابتة القديمة — أي موقع محفوظ بأحد هذه الأسماء حرفياً معناه
/// لم يُحلَّل باسم منطقة حقيقي بعد (إما اتحدَّد **قبل** إضافة الـReverse
/// Geocoding، أو كتبه رادار المساجد بنص ثابت — راجع
/// `mosque_radar_screen.dart`)، فيحتاج تحديثاً تلقائياً.
const _kLegacyCityNamePlaceholders = {'الموقع الحالي (GPS)', 'الموقع الحالي'};

/// يحلّل اسم المنطقة تلقائياً **بلا أي ضغطة من المستخدم** — بطلب صاحب
/// المشروع "خليه بالعربي من غير ما اضغط زر التحديث": لو الموقع محفوظ
/// مسبقاً بأحد الأسماء الثابتة القديمة [_kLegacyCityNamePlaceholders]،
/// يعيد تحليله بنفس الإحداثيات المحفوظة فعلياً — بلا طلب موقع GPS جديد،
/// فقط استدعاء شبكة صغير. يُشاهَد (`ref.watch`) من شاشة الصلاة فيعمل
/// مرّة تلقائياً عند فتحها، ولا يعيد نفسه بعد النجاح (`cityName` يصير
/// غير الاسم الثابت فتتوقف الحاجة له).
final cityNameBackfillProvider = FutureProvider<void>((ref) async {
  final loc = ref.watch(locationPrefsProvider);
  if (!loc.hasLocation) return;
  if (!_kLegacyCityNamePlaceholders.contains(loc.cityName)) return;
  final resolved = await reverseGeocodeCityName(loc.lat!, loc.lon!);
  if (resolved == null) return;
  await loc.setLocation(lat: loc.lat!, lon: loc.lon!, cityName: resolved);
  ref.read(locationVersionProvider.notifier).bump();
});

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
      final resolvedName = await reverseGeocodeCityName(
        position.latitude,
        position.longitude,
      );
      await ref
          .read(locationPrefsProvider)
          .setLocation(
            lat: position.latitude,
            lon: position.longitude,
            cityName: resolvedName ?? 'الموقع الحالي (GPS)',
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
      final userPrefs = ref.read(userPrefsProvider);
      await AdhanNotificationService.instance.rescheduleUpcoming(
        lat: loc.lat!,
        lon: loc.lon!,
        methodKey: loc.calculationMethod,
        isEnabled: notifPrefs.effectivelyEnabled,
        voiceId: userPrefs.adhanVoiceId,
        checkinEnabled: userPrefs.prayerCheckinEnabled,
        checkinFirstDelayMinutes: userPrefs.prayerCheckinFirstDelayMinutes,
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
