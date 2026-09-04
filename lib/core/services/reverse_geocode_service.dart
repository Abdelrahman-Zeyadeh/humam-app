import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// اسم المنطقة الحقيقي من إحداثيات GPS (Reverse Geocoding) — Nominatim
/// (OpenStreetMap)، نفس المصدر المستخدَم برادار المساجد لإيجاد المساجد
/// القريبة. **مشتركة بين `prayer_location_controller.dart` و
/// `mosque_radar_screen.dart`** — كانت كل شاشة تحفظ اسم مكان مختلف
/// (شاشة الصلاة تحلّل الاسم الحقيقي، رادار المساجد كان يكتب نصاً ثابتاً
/// "الموقع الحالي" فوق الاسم الحقيقي المحفوظ سابقاً)، فيظهر اسم المنطقة
/// ثم يختفي بلا سبب ظاهر حسب الشاشة الأخيرة التي حدّثت الموقع — بطلب
/// صاحب المشروع "تظهر اسم المنطقة بدون الضغط... لانه اصلا محدد". فشل
/// الشبكة/المهلة يرجع `null` بصمت.
Future<String?> reverseGeocodeCityName(double lat, double lon) async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        headers: {
          'User-Agent': 'HumamIslamicApp/1.0 (https://humam.app)',
          // بطلب صاحب المشروع "خليه بالعربي" — بلا `en` احتياطي إطلاقاً.
          'Accept-Language': 'ar',
        },
      ),
    );
    final res = await dio.get(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'format': 'jsonv2',
        'lat': lat,
        'lon': lon,
        'zoom': 10,
        'accept-language': 'ar',
      },
    );
    final address =
        (res.data as Map<String, dynamic>?)?['address']
            as Map<String, dynamic>?;
    if (address == null) return null;
    // بعض المستويات الإدارية الصغيرة (لواء/قضاء) ما إلها اسم عربي مسجَّل
    // بأوبن ستريت ماب، فيرجّع نوميناتيم الاسم المحلي/الإنجليزي رغم طلب
    // `ar` — نتجاهل أي حقل ما فيه حرف عربي وننزل للحقل الأوسع (المحافظة
    // ثم الدولة) لحد ما نلاقي اسم عربي فعلاً.
    final arabic = RegExp(r'[؀-ۿ]');
    String? arabicOnly(dynamic v) {
      final s = v as String?;
      if (s == null || !arabic.hasMatch(s)) return null;
      return s;
    }

    final city =
        arabicOnly(address['city']) ??
        arabicOnly(address['town']) ??
        arabicOnly(address['village']) ??
        arabicOnly(address['county']) ??
        arabicOnly(address['state']);
    final country = arabicOnly(address['country']);
    if (city == null && country == null) return null;
    if (city == null) return country;
    if (country == null) return city;
    return '$city، $country';
  } catch (e) {
    debugPrint('[Location] Reverse geocoding error: $e');
    return null;
  }
}
