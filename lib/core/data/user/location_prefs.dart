import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_providers.dart';
import 'user_repository.dart';

/// موقع محفوظ لحساب مواقيت الصلاة/القبلة (GPS أو مدينة مختارة يدوياً)،
/// وطريقة الحساب المفضّلة — واجهة رقيقة فوق [UserRepository]. كانت
/// تُخزَّن بـSharedPreferences؛ الهجرة كاملة الآن، أُبقيت بنفس التوقيعات.
class LocationPrefs {
  LocationPrefs(this._repo);
  final UserRepository _repo;

  double? get lat => _repo.lat;
  double? get lon => _repo.lon;
  String? get cityName => _repo.cityName;

  bool get hasLocation => _repo.hasLocation;

  Future<void> setLocation({required double lat, required double lon, required String cityName}) =>
      _repo.setLocation(lat: lat, lon: lon, cityName: cityName);

  /// مفتاح طريقة حساب المواقيت — يطابق أحد مفاتيح `kCalculationMethods`
  /// بـ `prayer_times_service.dart`. الافتراضي أم القرى (الأشيع بالمنطقة).
  String get calculationMethod => _repo.calculationMethod;

  Future<void> setCalculationMethod(String key) => _repo.setCalculationMethod(key);
}

final locationPrefsProvider = Provider<LocationPrefs>((ref) {
  return LocationPrefs(ref.watch(userRepositoryProvider));
});
