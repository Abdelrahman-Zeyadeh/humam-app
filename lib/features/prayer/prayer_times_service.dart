import 'package:adhan_dart/adhan_dart.dart';

/// اسم عرض عربي + الدالة المطابقة بـ`adhan_dart` لكل طريقة حساب مواقيت
/// مدعومة. المفتاح (`key`) هو ما يُخزَّن بـ`LocationPrefs.calculationMethod`.
class CalculationMethodOption {
  const CalculationMethodOption({required this.key, required this.nameAr, required this.build});
  final String key;
  final String nameAr;
  final CalculationParameters Function() build;
}

final List<CalculationMethodOption> kCalculationMethods = [
  CalculationMethodOption(
    key: 'ummAlQura',
    nameAr: 'أم القرى (السعودية)',
    build: CalculationMethodParameters.ummAlQura,
  ),
  CalculationMethodOption(
    key: 'muslimWorldLeague',
    nameAr: 'رابطة العالم الإسلامي',
    build: CalculationMethodParameters.muslimWorldLeague,
  ),
  CalculationMethodOption(
    key: 'egyptian',
    nameAr: 'الهيئة المصرية العامة للمساحة',
    build: CalculationMethodParameters.egyptian,
  ),
  CalculationMethodOption(
    key: 'karachi',
    nameAr: 'جامعة العلوم الإسلامية - كراتشي',
    build: CalculationMethodParameters.karachi,
  ),
  CalculationMethodOption(
    key: 'gulfRegion',
    nameAr: 'منطقة الخليج',
    build: CalculationMethodParameters.gulfRegion,
  ),
  CalculationMethodOption(
    key: 'kuwait',
    nameAr: 'الكويت',
    build: CalculationMethodParameters.kuwait,
  ),
  CalculationMethodOption(
    key: 'qatar',
    nameAr: 'قطر',
    build: CalculationMethodParameters.qatar,
  ),
  CalculationMethodOption(
    key: 'jordan',
    nameAr: 'الأردن',
    build: CalculationMethodParameters.jordan,
  ),
  CalculationMethodOption(
    key: 'northAmerica',
    nameAr: 'أمريكا الشمالية (ISNA)',
    build: CalculationMethodParameters.northAmerica,
  ),
  CalculationMethodOption(
    key: 'moonsightingCommittee',
    nameAr: 'لجنة رؤية الهلال',
    build: CalculationMethodParameters.moonsightingCommittee,
  ),
];

CalculationMethodOption calculationMethodByKey(String key) =>
    kCalculationMethods.firstWhere((m) => m.key == key, orElse: () => kCalculationMethods.first);

/// أسماء الصلوات الخمس بالعربية بترتيب اليوم (يشمل الشروق للعرض فقط —
/// ليس وقت صلاة). راجع `PrayerMoment.isPrayer`.
enum PrayerMoment {
  fajr('الفجر', isPrayer: true),
  sunrise('الشروق', isPrayer: false),
  dhuhr('الظهر', isPrayer: true),
  asr('العصر', isPrayer: true),
  maghrib('المغرب', isPrayer: true),
  isha('العشاء', isPrayer: true);

  const PrayerMoment(this.nameAr, {required this.isPrayer});
  final String nameAr;
  final bool isPrayer;
}

class PrayerMomentTime {
  const PrayerMomentTime(this.moment, this.time);
  final PrayerMoment moment;
  final DateTime time;
}

/// يحسب مواقيت يوم واحد محلياً بلا إنترنت (`adhan_dart`) — راجع
/// `tools/raw/README.md` لسبب اختيار المصدر.
List<PrayerMomentTime> computeDayTimes({
  required double lat,
  required double lon,
  required DateTime date,
  required String methodKey,
}) {
  final coordinates = Coordinates(lat, lon);
  final params = calculationMethodByKey(methodKey).build();
  final times = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params);

  return [
    PrayerMomentTime(PrayerMoment.fajr, times.fajr),
    PrayerMomentTime(PrayerMoment.sunrise, times.sunrise),
    PrayerMomentTime(PrayerMoment.dhuhr, times.dhuhr),
    PrayerMomentTime(PrayerMoment.asr, times.asr),
    PrayerMomentTime(PrayerMoment.maghrib, times.maghrib),
    PrayerMomentTime(PrayerMoment.isha, times.isha),
  ];
}

/// أول وقت صلاة (`isPrayer == true`) لسا ما جا بعد ضمن قائمة اليوم —
/// `null` لو كل صلوات اليوم فاتت (يحتاج المتصل جلب يوم الغد حينها).
PrayerMomentTime? nextPrayer(List<PrayerMomentTime> dayTimes, DateTime now) {
  for (final t in dayTimes) {
    if (t.moment.isPrayer && t.time.isAfter(now)) return t;
  }
  return null;
}
