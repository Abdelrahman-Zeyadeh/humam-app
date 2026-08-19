import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_prefs.dart';

/// موقع محفوظ لحساب مواقيت الصلاة/القبلة (GPS أو مدينة مختارة يدوياً)،
/// وطريقة الحساب المفضّلة. مؤقت بـ SharedPreferences — نفس ملاحظة `UserPrefs`.
class LocationPrefs {
  LocationPrefs(this._prefs);
  final SharedPreferences _prefs;

  static const _kLat = 'prayer_lat';
  static const _kLon = 'prayer_lon';
  static const _kCityName = 'prayer_city_name';
  static const _kMethod = 'prayer_calc_method';

  double? get lat => _prefs.getDouble(_kLat);
  double? get lon => _prefs.getDouble(_kLon);
  String? get cityName => _prefs.getString(_kCityName);

  bool get hasLocation => lat != null && lon != null;

  Future<void> setLocation({required double lat, required double lon, required String cityName}) async {
    await _prefs.setDouble(_kLat, lat);
    await _prefs.setDouble(_kLon, lon);
    await _prefs.setString(_kCityName, cityName);
  }

  /// مفتاح طريقة حساب المواقيت — يطابق أحد مفاتيح `kCalculationMethods`
  /// بـ `prayer_times_service.dart`. الافتراضي أم القرى (الأشيع بالمنطقة).
  String get calculationMethod => _prefs.getString(_kMethod) ?? 'ummAlQura';

  Future<void> setCalculationMethod(String key) => _prefs.setString(_kMethod, key);
}

final locationPrefsProvider = Provider<LocationPrefs>((ref) {
  return LocationPrefs(ref.watch(sharedPreferencesProvider));
});
