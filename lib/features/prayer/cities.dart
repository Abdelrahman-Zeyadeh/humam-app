/// مدينة بإحداثيات معروفة (خط عرض/طول عاصمة أو مدينة رئيسية) — بديل يدوي
/// عن GPS لحساب مواقيت الصلاة والقبلة. إحداثيات جغرافية عامة موثّقة
/// (ليست بيانات دينية) — لا علاقة لها بقاعدة قيود "لا تخمين نص قرآني".
class PrayerCity {
  const PrayerCity({required this.nameAr, required this.lat, required this.lon});
  final String nameAr;
  final double lat;
  final double lon;
}

const List<PrayerCity> kPrayerCities = [
  PrayerCity(nameAr: 'مكة المكرمة', lat: 21.4225, lon: 39.8262),
  PrayerCity(nameAr: 'المدينة المنورة', lat: 24.4672, lon: 39.6024),
  PrayerCity(nameAr: 'الرياض', lat: 24.7136, lon: 46.6753),
  PrayerCity(nameAr: 'جدة', lat: 21.4858, lon: 39.1925),
  PrayerCity(nameAr: 'عمّان', lat: 31.9454, lon: 35.9284),
  PrayerCity(nameAr: 'بيروت', lat: 33.8938, lon: 35.5018),
  PrayerCity(nameAr: 'دمشق', lat: 33.5138, lon: 36.2765),
  PrayerCity(nameAr: 'بغداد', lat: 33.3152, lon: 44.3661),
  PrayerCity(nameAr: 'القاهرة', lat: 30.0444, lon: 31.2357),
  PrayerCity(nameAr: 'الإسكندرية', lat: 31.2001, lon: 29.9187),
  PrayerCity(nameAr: 'الخرطوم', lat: 15.5007, lon: 32.5599),
  PrayerCity(nameAr: 'صنعاء', lat: 15.3694, lon: 44.1910),
  PrayerCity(nameAr: 'مسقط', lat: 23.5880, lon: 58.3829),
  PrayerCity(nameAr: 'أبوظبي', lat: 24.4539, lon: 54.3773),
  PrayerCity(nameAr: 'دبي', lat: 25.2048, lon: 55.2708),
  PrayerCity(nameAr: 'الدوحة', lat: 25.2854, lon: 51.5310),
  PrayerCity(nameAr: 'المنامة', lat: 26.0667, lon: 50.5577),
  PrayerCity(nameAr: 'الكويت', lat: 29.3759, lon: 47.9774),
  PrayerCity(nameAr: 'الرباط', lat: 34.0209, lon: -6.8416),
  PrayerCity(nameAr: 'الدار البيضاء', lat: 33.5731, lon: -7.5898),
  PrayerCity(nameAr: 'الجزائر', lat: 36.7538, lon: 3.0588),
  PrayerCity(nameAr: 'تونس', lat: 36.8065, lon: 10.1815),
  PrayerCity(nameAr: 'طرابلس', lat: 32.8872, lon: 13.1913),
  PrayerCity(nameAr: 'إسطنبول', lat: 41.0082, lon: 28.9784),
  PrayerCity(nameAr: 'أنقرة', lat: 39.9334, lon: 32.8597),
  PrayerCity(nameAr: 'جاكرتا', lat: -6.2088, lon: 106.8456),
  PrayerCity(nameAr: 'كوالالمبور', lat: 3.1390, lon: 101.6869),
  PrayerCity(nameAr: 'إسلام آباد', lat: 33.6844, lon: 73.0479),
  PrayerCity(nameAr: 'القدس', lat: 31.7683, lon: 35.2137),
  PrayerCity(nameAr: 'لندن', lat: 51.5074, lon: -0.1278),
];
