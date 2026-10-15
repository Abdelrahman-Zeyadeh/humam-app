import 'package:adhan_dart/adhan_dart.dart';

/// اسم عرض عربي + الدالة المطابقة بـ`adhan_dart` لكل طريقة حساب مواقيت
/// مدعومة. المفتاح (`key`) هو ما يُخزَّن بـ`LocationPrefs.calculationMethod`.
class CalculationMethodOption {
  const CalculationMethodOption({
    required this.key,
    required this.nameAr,
    required this.build,
  });
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
    kCalculationMethods.firstWhere(
      (m) => m.key == key,
      orElse: () => kCalculationMethods.first,
    );

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
  final times = PrayerTimes(
    coordinates: coordinates,
    date: date,
    calculationParameters: params,
  );

  // ⚠️ `adhan_dart` يرجّع كل الأوقات بصيغة UTC (`DateTime.utc(...)` داخلياً)
  // — لازم `.toLocal()` هون قبل أي عرض، وإلا الساعة المعروضة تكون ساعة
  // UTC لا ساعة المستخدم الفعلية (كان هذا سبب "مواقيت الصلاة خطأ" المُبلَّغ).
  return [
    PrayerMomentTime(PrayerMoment.fajr, times.fajr.toLocal()),
    PrayerMomentTime(PrayerMoment.sunrise, times.sunrise.toLocal()),
    PrayerMomentTime(PrayerMoment.dhuhr, times.dhuhr.toLocal()),
    PrayerMomentTime(PrayerMoment.asr, times.asr.toLocal()),
    PrayerMomentTime(PrayerMoment.maghrib, times.maghrib.toLocal()),
    PrayerMomentTime(PrayerMoment.isha, times.isha.toLocal()),
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

/// إحداثيات افتراضية بديلة (عمان / مكة المكرمة) عند عدم تحديد الموقع بعد،
/// لضمان عدم فتح الصلوات والسنن قبل دخول وقتها حتى لو لم يفعل المستخدم GPS بعد.
const double kDefaultFallbackLat = 31.9539;
const double kDefaultFallbackLon = 35.9106;

/// وقت دخول [moment] اليوم — يستخدم إحداثيات افتراضية احتياطية لو الموقع غير مضبوط.
DateTime? prayerMomentTimeToday({
  required double? lat,
  required double? lon,
  required String methodKey,
  required PrayerMoment moment,
}) {
  final effectiveLat = lat ?? kDefaultFallbackLat;
  final effectiveLon = lon ?? kDefaultFallbackLon;
  final times = computeDayTimes(
    lat: effectiveLat,
    lon: effectiveLon,
    date: DateTime.now(),
    methodKey: methodKey,
  );
  return times.firstWhere((t) => t.moment == moment).time;
}

/// هل حان وقت [moment] اليوم بعد؟ — بطلب صاحب المشروع: "كل اشي بوقته
/// واللي ما اجا وقته عليه قفل" (الصلوات والسنن الرواتب وأذكار الصباح/
/// المساء والقيام لا تُفتح للتسجيل إلا بعد دخول وقتها).
bool hasMomentArrivedToday({
  required double? lat,
  required double? lon,
  required String methodKey,
  required PrayerMoment moment,
  bool isDuha = false,
}) {
  final t = prayerMomentTimeToday(
    lat: lat,
    lon: lon,
    methodKey: methodKey,
    moment: moment,
  );
  if (t == null) return false;
  final effectiveTime = isDuha ? t.add(const Duration(minutes: 15)) : t;
  return !DateTime.now().isBefore(effectiveTime);
}

/// هل الوقت الحالي ضمن نافذة قيام الليل (من دخول العشاء حتى دخول الفجر،
/// عابرة منتصف الليل)؟ — بطلب صاحب المشروع "خليه المدة تبعته من العشا
/// الى الفجر": كانت شاشة القيام تفتح التسجيل بدخول العشاء ولا تُغلقه
/// إطلاقاً بعدها (يبقى متاحاً كل اليوم التالي)، فتوسّعنا [hasMomentArrivedToday]
/// بموقّت زمن واحد لا يكفي لنافذة تعبر منتصف الليل (عشاء الليلة → فجر
/// الغد).
bool isWithinQiyamWindow({
  required double? lat,
  required double? lon,
  required String methodKey,
}) {
  final effectiveLat = lat ?? kDefaultFallbackLat;
  final effectiveLon = lon ?? kDefaultFallbackLon;
  final now = DateTime.now();
  final todayTimes = computeDayTimes(
    lat: effectiveLat,
    lon: effectiveLon,
    date: now,
    methodKey: methodKey,
  );
  final todayFajr = todayTimes
      .firstWhere((t) => t.moment == PrayerMoment.fajr)
      .time;
  final todayIsha = todayTimes
      .firstWhere((t) => t.moment == PrayerMoment.isha)
      .time;

  // قبل فجر اليوم — يعني إحنا بالساعات الأولى من اليوم (بعد منتصف الليل)،
  // وهذا يقع دائماً بعد عشاء الأمس زمنياً (العشاء دائماً مساءً)، فالنافذة
  // لسا مفتوحة (عشاء الأمس → فجر اليوم) بلا حاجة لحساب عشاء الأمس فعلياً.
  if (now.isBefore(todayFajr)) return true;

  // بعد فجر اليوم — مفتوحة فقط لو دخل عشاء الليلة (حتى فجر الغد).
  return !now.isBefore(todayIsha);
}
