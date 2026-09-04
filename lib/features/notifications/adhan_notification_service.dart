import 'dart:async' show unawaited;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:hijri/hijri_calendar.dart';
import '../../core/data/user/user_database.dart';
import '../../core/data/user/user_repository.dart'
    show UserCategories, UserRepository;
import '../../core/hijri/hijri_occasions.dart' show isRamadan;
import '../prayer/adhan_voices.dart';
import '../prayer/prayer_times_service.dart';

const _kNotifIdBase = 9000;
const _kMaxScheduledPerCall = 20; // يومان × ٥ صلوات + هامش

/// معرّف القناة/اسمها لصوت أذان معيّن — قناة مستقلة لكل [AdhanVoice] لأن
/// صوت القناة بأندرويد 8+ **ثابت عند الإنشاء** ولا يتغيّر لاحقاً؛ التبديل
/// بين الأصوات فعلياً هو تبديل القناة المستخدَمة عند الجدولة، لا تعديلها.
String _adhanChannelId(String voiceId) => 'adhan_ch_$voiceId';
String _adhanChannelName(String voiceId) =>
    'أذان مواقيت الصلاة — ${adhanVoiceById(voiceId).label}';

const _kQiyamChannelId = 'qiyam_reminder_ch';
const _kQiyamChannelName = 'تذكير قيام الليل';
const _kQiyamNotifIdBase = 9100; // بعيد عن مدى إشعارات الأذان (٩٠٠٠-٩٠١٩) عمداً

const _kHifzChannelId = 'hifz_reminder_ch';
const _kHifzChannelName = 'تذكير الحفظ';
const _kHifzNotifIdBase =
    9200; // بعيد عن مدى الأذان وقيام الليل (٩١٠٠-٩١٢٩) عمداً

// حديث اليوم واسم من أسماء الله الحسنى — بطلب صاحب المشروع "حديث اليوم
// بحب ينبعث كاشعار... واسماء الله الحسنى كذلك".
// **باج حقيقي مُصلَح هون**: كانا ٩٤٠٠/٩٥٠٠ أصلاً — يتصادمان فعلياً مع مدى
// متابعة "هل صليت؟" (٩٤٠٠-٩٤٩٩) ومعرّف إشعار أذكار ما بعد الصلاة (٩٥٠٠
// حرفياً) بالأسفل، فكان أي جدولة/إلغاء لأحد النظامين يمسح إشعارات
// النظام الآخر بصمت. نُقلا لمدى ١١٠٠٠+ الخالي تماماً.
const _kDailyHadithChannelId = 'daily_hadith_reminder_ch';
const _kDailyHadithChannelName = 'تذكير حديث اليوم';
const _kDailyHadithNotifIdBase = 11000;
const _kDailyNameOfAllahChannelId = 'daily_name_reminder_ch';
const _kDailyNameOfAllahChannelName = 'تذكير اسم من أسماء الله الحسنى';
const _kDailyNameOfAllahNotifIdBase = 11100;

/// عدد أيام دوران محتوى تذكيرَي قيام الليل/الحفظ — بطلب صاحب المشروع
/// "خليهن متغيرات مش ثابتات كل يوم". كل يوم إشعار مستقل بمحتوى مختلف (فهرس
/// دائري ضمن قائمة الرسائل المُمرَّرة) بدل إشعار واحد متكرر آلياً بنفس النص
/// (`matchDateTimeComponents: DateTimeComponents.time` القديمة لا تسمح
/// بتغيير المحتوى بين التكرارات). الثمن: يحتاج فتح التطبيق مرة كل ٣٠ يوماً
/// كحدّ أقصى لإعادة تعبئة الدوران (خلافاً للتكرار الأزلي القديم) — لذا
/// `main.dart` يعيد الجدولة أيضاً عند كل إقلاع تطبيق (راجع
/// `_initAdhanNotificationsInBackground`)، لا فقط عند تبديل المستخدم للإعداد
/// يدوياً.
const _kReminderRotationDays = 30;

const _kCheckinChannelId = 'prayer_checkin_ch';
const _kCheckinChannelName = 'متابعة "هل صليت؟"';
const _kCheckinIdBase = 9400; // بعيد عن كل المدايات المستخدَمة (٩٠٠٠-٩٣٠٢)
const _kCheckinMaxSlots = 10; // يومان × ٥ صلوات — نفس حدّ `rescheduleUpcoming`
const _kCheckinMaxRepeatsPerSlot = 6; // ~ساعة تكرار كل ١٠د، يغطي فاصل عشاء-فجر
const _kCheckinYesAction = 'prayer_checkin_yes';
const _kCheckinNoAction = 'prayer_checkin_no';
const _kPostPrayerAzkarNotifId = 9500; // بعيد عن مدى المتابعة (٩٤٠٠-٩٤٩٩) عمداً

const _kImsakChannelId = 'ramadan_imsak_ch';
const _kImsakChannelName = 'تذكير السحور/الإمساك (رمضان)';
const _kImsakIdBase = 9600; // يومان بحدّ أقصى، بعيد عن كل المدايات الأخرى
const _kImsakMinutesBeforeFajr = 10;

const _kEveningSummaryChannelId = 'evening_summary_ch';
const _kEveningSummaryChannelName = 'الملخّص المسائي';
const _kEveningSummaryNotifId =
    9650; // بين مدى الإمساك (٩٦٠٠+) ومدى السنن (٩٧٠٠+) عمداً

const _kSunnahChannelId = 'sunnah_reminder_ch';
const _kSunnahChannelName = 'تذكير السنن والأيام الفاضلة';
const _kKahfNotifId = 9700;
const _kThursdaySalawatNotifId = 9701;
const _kFridaySalawatNotifId = 9705;
const _kMondayFastingNotifId = 9702;
const _kThursdayFastingNotifId = 9703;
const _kWhiteDaysNotifId = 9704;

/// تذكيرات العادات المخصّصة (عدد ديناميكي بلا حدّ معروف مسبقاً، بخلاف بقية
/// الأنشطة أعلاه ذات المعرّفات اليدوية الثابتة) — قناة واحدة مشتركة لكل
/// العادات (لا قناة لكل عادة، Android يعتبر القناة "تصنيفاً" لا نسخة فردية)
/// بمعرّف إشعار **مُشتَق** من `habitId` نفسه: `9800 + habitId`. بعيد عن كل
/// المدايات المستخدَمة أعلاه (أقصاها ٩٧٠٥) — يفترض عدد عادات المستخدم
/// الواحد محلياً لن يقارب ١٩٩ (`9800-9999`) عملياً.
const _kCustomHabitChannelId = 'custom_habit_reminder_ch';
const _kCustomHabitChannelName = 'تذكير العادات المخصّصة';
const _kCustomHabitNotifIdBase = 9800;

const _kHourlyDhikrChannelId = 'hourly_dhikr_ch';
const _kHourlyDhikrChannelName = 'أذكار وأدعية كل ساعة';
const _kHourlyDhikrNotifIdBase = 10000;
const _kMaxHourlySlots = 48; // يومان × ٢٤ ساعة

/// معرّفات إشعار "التكرار العام" (راجع [AdhanNotificationService.
/// scheduleRepeatingReminder]) — بلوك ١٠٠ معرّف لكل فئة، بعيد تماماً عن
/// كل المدايات أعلاه (أقصاها ١١١٢٩). بطلب صاحب المشروع "بقدر اضيف
/// التكرارات على كل التذكيرات... الصلاة على النبي وغيرها".
const _kRepeatingReminderIdBases = {
  UserCategories.morningAzkar: 12000,
  UserCategories.eveningAzkar: 12100,
  UserCategories.dailyWird: 12200,
  'evening_summary': 12300,
  UserCategories.qiyam: 12400,
  UserCategories.hifz: 12500,
  UserCategories.dailyHadith: 12600,
  UserCategories.dailyNameOfAllah: 12700,
  'sunnah_kahf': 12800,
  'sunnah_salawat_friday': 12900,
  'sunnah_salawat_eve': 13000,
};
const _kMaxRepeatingSlots = 100;

class _RepeatingReminderMeta {
  const _RepeatingReminderMeta({
    required this.channelId,
    required this.channelName,
    required this.title,
  });
  final String channelId;
  final String channelName;
  final String title;
}

/// عنوان/قناة كل فئة تدعم التكرار العام — راجع [_kRepeatingReminderIdBases].
const _kRepeatingReminderMeta = {
  UserCategories.morningAzkar: _RepeatingReminderMeta(
    channelId: 'morning_azkar_repeat_ch',
    channelName: 'تكرار تذكير أذكار الصباح',
    title: 'أذكار الصباح',
  ),
  UserCategories.eveningAzkar: _RepeatingReminderMeta(
    channelId: 'evening_azkar_repeat_ch',
    channelName: 'تكرار تذكير أذكار المساء',
    title: 'أذكار المساء',
  ),
  UserCategories.dailyWird: _RepeatingReminderMeta(
    channelId: 'daily_wird_repeat_ch',
    channelName: 'تكرار تذكير الورد اليومي',
    title: 'الورد اليومي',
  ),
  'evening_summary': _RepeatingReminderMeta(
    channelId: 'evening_summary_repeat_ch',
    channelName: 'تكرار الملخّص المسائي',
    title: 'الملخّص المسائي',
  ),
  UserCategories.qiyam: _RepeatingReminderMeta(
    channelId: 'qiyam_repeat_ch',
    channelName: 'تكرار تذكير قيام الليل',
    title: 'قيام الليل',
  ),
  UserCategories.hifz: _RepeatingReminderMeta(
    channelId: 'hifz_repeat_ch',
    channelName: 'تكرار تذكير الحفظ',
    title: 'تذكير الحفظ',
  ),
  UserCategories.dailyHadith: _RepeatingReminderMeta(
    channelId: 'daily_hadith_repeat_ch',
    channelName: 'تكرار تذكير حديث اليوم',
    title: 'حديث اليوم 📖',
  ),
  UserCategories.dailyNameOfAllah: _RepeatingReminderMeta(
    channelId: 'daily_name_repeat_ch',
    channelName: 'تكرار تذكير اسم من أسماء الله',
    title: 'اسم من أسماء الله الحسنى ✨',
  ),
  'sunnah_kahf': _RepeatingReminderMeta(
    channelId: 'sunnah_kahf_repeat_ch',
    channelName: 'تكرار تذكير سورة الكهف',
    title: 'سورة الكهف',
  ),
  'sunnah_salawat_friday': _RepeatingReminderMeta(
    channelId: 'sunnah_salawat_repeat_ch',
    channelName: 'تكرار تذكير الصلاة على النبي',
    title: 'الصلاة على النبي ﷺ',
  ),
  'sunnah_salawat_eve': _RepeatingReminderMeta(
    channelId: 'sunnah_salawat_repeat_ch',
    channelName: 'تكرار تذكير الصلاة على النبي',
    title: 'الصلاة على النبي ﷺ',
  ),
};

const List<({String title, String body})> kHourlyDhikrPool = [
  (
    title: '📿 ذكر وتثقيل الميزان',
    body: '«سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ»',
  ),
  (
    title: '🤲 دعاء العافية والستر',
    body:
        '«اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ»',
  ),
  (
    title: '🌸 الصلاة على النبي ﷺ',
    body: '«اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ»',
  ),
  (
    title: '🕊️ كنز من كنوز الجنة',
    body: '«لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ»',
  ),
  (
    title: '🌿 استغفار وتوبة',
    body: '«أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ»',
  ),
  (
    title: '✨ توحيد وذكر جامع',
    body:
        '«لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ»',
  ),
  (
    title: '🤲 دعاء تفريج الكرب',
    body:
        '«لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ»',
  ),
  (
    title: '🤍 الباقيات الصالحات',
    body:
        '«سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ»',
  ),
  (
    title: '🤲 دعاء الثبات والقلب',
    body: '«يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ»',
  ),
  (
    title: '💎 دعاء تيسير الأمور',
    body:
        '«اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا»',
  ),
  (
    title: '🌾 غراس الجنة',
    body:
        '«سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ» (تُغرس لك بها نخلة في الجنة)',
  ),
  (
    title: '🤲 دعاء المغفرة والرحمة',
    body:
        '«رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ»',
  ),
  (
    title: '🌟 شكر النعمة والفضل',
    body: '«الْحَمْدُ لِلَّهِ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ»',
  ),
  (
    title: '🤲 دعاء الهداية والتقى',
    body:
        '«اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى»',
  ),
];

/// معالج رد فعل زرّي إشعار متابعة "هل صليت؟" — **دالة top-level مستقلة**
/// (لا داخل الصنف) بموسم `@pragma('vm:entry-point')` لأنها **قد تُستدعى
/// بمعزل (isolate) خلفي منفصل كلياً** لو ضغط المستخدم الزرّ والتطبيق مغلَق
/// تماماً (قيد فعلي بمكتبة `flutter_local_notifications`، راجع "⚠️ قيود
/// معروفة، غير مُختبرة بجهاز فعلي" أعلى الملف — هذا القيد لم يُختبر بإغلاق
/// فعلي كامل للتطبيق بعد). لا وصول لحاوية Riverpod هون، فالكتابة تفتح
/// اتصال `UserDatabase` مستقل قصير العمر بدل المرور بـ`UserRepository`
/// المحمَّل مسبقاً بالتطبيق الرئيسي.
@pragma('vm:entry-point')
void onPrayerCheckinNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;
  final payload = response.payload;
  if (payload == null) return;

  // إذا ضغط المستخدم على زر "صليت" أو ضغط على جسم الإشعار مباشرة (actionId == null)
  final isYes =
      (actionId == _kCheckinYesAction || actionId == null || actionId.isEmpty);
  unawaited(
    _handlePrayerCheckinResponse(
      payload,
      prayed: isYes,
      notificationId: response.id,
    ),
  );
}

Future<void> _handlePrayerCheckinResponse(
  String payload, {
  required bool prayed,
  int? notificationId,
}) async {
  final parts = payload.split('|');
  if (parts.length != 3) return;
  final dateKey = parts[0];
  final rawCategory = parts[1];
  final category = rawCategory.startsWith('prayer_')
      ? rawCategory
      : 'prayer_$rawCategory'; // يطابق UserCategories.fajr/dhuhr/asr/maghrib/isha
  final slotIndex = int.tryParse(parts[2]);
  if (slotIndex == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  try {
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: onPrayerCheckinNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onPrayerCheckinNotificationResponse,
    );
  } catch (e) {
    debugPrint('تعذّر تهيئة الإشعارات بمعزل خلفي: $e');
  }

  // إخفاء وحذف الإشعار فوراً من شريط الإشعارات عند الضغط
  if (notificationId != null) {
    try {
      await plugin.cancel(id: notificationId);
    } catch (_) {}
  }
  if (slotIndex == 99) {
    try {
      await plugin.cancel(id: 9998);
    } catch (_) {}
  }

  // "صليت" فقط يكتب شيئاً — "لسا" يلغي التكرار بلا تسجيل
  if (prayed) {
    final db = UserDatabase();
    try {
      await _bumpCategoryStreakIfNewDay(db, category, dateKey);
      if (UserRepository.currentInstance != null) {
        await UserRepository.currentInstance!.reloadCategoryStreaks();
      }
    } catch (e) {
      debugPrint('تعذّر تسجيل "صليت" من الإشعار: $e');
    } finally {
      await db.close();
    }

    try {
      await plugin.show(
        id: _kPostPrayerAzkarNotifId,
        title: 'أذكار ما بعد الصلاة',
        body: 'تقبّل الله طاعتك — لا تنسَ أذكار ما بعد الصلاة 🌿',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _kCheckinChannelId,
            _kCheckinChannelName,
            channelDescription: 'سؤال متابعة بعد كل صلاة، بزرّي "صليت"/"لسا"',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('تعذّر عرض تذكير أذكار ما بعد الصلاة: $e');
    }
  }

  // ألغِ بقية إشعارات هذه الصلاة/اليوم
  if (slotIndex != 99) {
    for (var i = 0; i < _kCheckinMaxRepeatsPerSlot; i++) {
      try {
        await plugin.cancel(id: _kCheckinIdBase + slotIndex * 10 + i);
      } catch (_) {}
    }
  }
}

/// نسخة طبق الأصل من منطق `UserRepository.bumpCategoryStreakIfNewDay` —
/// **معاد كتابتها هون عمداً** لا مستدعاة مباشرة، لأن هذا الرد قد يصل بمعزل
/// خلفي منفصل كلياً بلا وصول لمثيل `UserRepository` المحمَّل مسبقاً بالتطبيق
/// الرئيسي (راجع توثيق [onPrayerCheckinNotificationResponse]). `dateKey`
/// يصل جاهزاً من وقت جدولة الإشعار نفسه (لا `DateTime.now()` هون) — قد
/// يُضغَط الزرّ بعد منتصف الليل لصلاة كان وقتها أمس.
Future<void> _bumpCategoryStreakIfNewDay(
  UserDatabase db,
  String category,
  String dateKey,
) async {
  final alreadyLogged =
      await (db.select(db.categoryDailyLog)..where(
            (t) => t.category.equals(category) & t.dateKey.equals(dateKey),
          ))
          .getSingleOrNull();
  if (alreadyLogged != null) return;

  final row = await (db.select(
    db.categoryStreaks,
  )..where((t) => t.category.equals(category))).getSingleOrNull();
  final yesterday = _yesterdayOf(dateKey);
  final continued = row?.streakLastDay == yesterday;
  final newCount = continued ? (row?.streakDays ?? 0) + 1 : 1;

  await db
      .into(db.categoryStreaks)
      .insertOnConflictUpdate(
        CategoryStreaksCompanion(
          category: Value(category),
          streakDays: Value(newCount),
          streakLastDay: Value(dateKey),
        ),
      );
  await db
      .into(db.categoryDailyLog)
      .insertOnConflictUpdate(
        CategoryDailyLogCompanion(
          category: Value(category),
          dateKey: Value(dateKey),
        ),
      );
}

/// نفس تنسيق `UserRepository._dateKey` حرفياً (بلا حشو أصفار) — يحسب مفتاح
/// اليوم السابق من نص `dateKey` مباشرة بدل `DateTime.now()`.
String _yesterdayOf(String dateKey) {
  final parts = dateKey.split('-');
  final d = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final y = d.subtract(const Duration(days: 1));
  return '${y.year}-${y.month}-${y.day}';
}

class _ActivityReminderMeta {
  const _ActivityReminderMeta({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.notifId,
    required this.title,
    required this.body,
  });
  final String channelId;
  final String channelName;
  final String channelDescription;
  final int notifId;
  final String title;
  final String body;
}

/// تذكيرات أنشطة إضافية (أذكار الصباح/المساء، الورد اليومي) — معرّفات
/// إشعار ٩٣٠٠-٩٣٠٢ (بعيدة عن مدى الأذان/قيام الليل/الحفظ أعلاه عمداً).
/// معمَّمة بخريطة واحدة بدل ٣ دوال منسوخة (كـ`scheduleQiyamReminder`/
/// `scheduleHifzReminder` أسفل) — نفس المنطق يتكرر حرفياً لكل فئة هون،
/// وهاي أول نقطة تكراره ٣ مرّات فعلاً فاستحقّ التعميم.
const Map<String, _ActivityReminderMeta> _kActivityReminderMeta = {
  UserCategories.morningAzkar: _ActivityReminderMeta(
    channelId: 'morning_azkar_reminder_ch',
    channelName: 'تذكير أذكار الصباح',
    channelDescription:
        'تذكير يومي بالساعة التي يختارها المستخدم لأذكار الصباح',
    notifId: 9300,
    title: 'أذكار الصباح',
    body: 'حان وقت التذكير الذي اخترته لأذكار الصباح',
  ),
  UserCategories.eveningAzkar: _ActivityReminderMeta(
    channelId: 'evening_azkar_reminder_ch',
    channelName: 'تذكير أذكار المساء',
    channelDescription:
        'تذكير يومي بالساعة التي يختارها المستخدم لأذكار المساء',
    notifId: 9301,
    title: 'أذكار المساء',
    body: 'حان وقت التذكير الذي اخترته لأذكار المساء',
  ),
  UserCategories.dailyWird: _ActivityReminderMeta(
    channelId: 'daily_wird_reminder_ch',
    channelName: 'تذكير الورد اليومي',
    channelDescription:
        'تذكير يومي بالساعة التي يختارها المستخدم للورد اليومي من القرآن',
    notifId: 9302,
    title: 'الورد اليومي',
    body: 'حان وقت التذكير الذي اخترته لورد اليوم من القرآن',
  ),
};

/// إشعارات دخول وقت الصلاة — محلية بالكامل (`flutter_local_notifications`
/// + حساب `computeDayTimes` نفسه المستخدَم بشاشة الصلاة)، بلا خادم وبلا
/// اعتماد شبكي. **تملك أيضاً تذكيرَي قيام الليل والحفظ** (`scheduleQiyamReminder`/
/// `scheduleHifzReminder` أسفله) — نفس نسخة `FlutterLocalNotificationsPlugin`
/// المهيَّأة هون (تهيئة واحدة فقط بكل التطبيق) بدل مثيل منفصل لكل واحد،
/// كل تذكير بقناة إشعار خاصة به.
///
/// **صوت الأذان قابل للاختيار** (راجع `adhan_voices.dart`) — ملفان أرسلهما
/// صاحب المشروع مباشرة (اختيار شخصي صريح، لا بحث ترخيص هون خلافاً لمحاولة
/// سابقة رُفضت لغموض الحقوق، ما زالت موثَّقة بـ`adhan_voices.dart`)، بجانب
/// صوت الإشعار الافتراضي للنظام. قناة Android مستقلة لكل صوت — راجع
/// [_adhanChannelId].
///
/// ⚠️ **قيود أخرى معروفة، غير مُختبرة بجهاز فعلي:**
/// - الجدولة تغطي يومين فقط (اليوم والغد) وتُعاد عند كل إقلاع أو تغيير
///   موقع/طريقة حساب — لو لم يُفتح التطبيق يومين متتاليين تتوقف الإشعارات
///   حتى يُفتح من جديد. لا آلية إعادة جدولة بالخلفية دون فتح التطبيق.
/// - `SCHEDULE_EXACT_ALARM` قد يحتاج تفعيلاً يدوياً من المستخدم بأندرويد
///   12+ ("التنبيهات والتذكيرات") — الخدمة تتراجع تلقائياً لجدولة غير
///   دقيقة (`inexactAllowWhileIdle`) لو رُفض، بلا فشل صامت كامل.
/// - إعادة الجدولة بعد إعادة تشغيل الجهاز (`ScheduledNotificationBootReceiver`
///   بـ`AndroidManifest.xml`) لم تُختبر بإعادة تشغيل فعلية.
class AdhanNotificationService {
  AdhanNotificationService._();
  static final instance = AdhanNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// يحذف القناة أولاً ثم يعيد إنشاءها — **إلزامي**، لا `createNotificationChannel`
  /// وحدها. سبب حقيقي مكتشَف: إعدادات القناة (خصوصاً الصوت) بأندرويد 8+
  /// **ثابتة عند أول إنشاء فعلي على الجهاز** ولا تتحدّث بإعادة استدعاء
  /// `createNotificationChannel` بنفس المعرّف لاحقاً — لو أُنشئت القناة
  /// مرة بإعدادات قديمة (مثلاً قبل إضافة ملف الصوت الخام، أو بنسخة سابقة
  /// من الكود)، تبقى عالقة على تلك الإعدادات عبر كل تحديثات التطبيق التالية
  /// (`adb install -r` لا يمسح قنوات الإشعار — تحتاج حذف بيانات التطبيق
  /// أو إعادة تثبيت كاملة). بلاغ صاحب المشروع "صوت الأذان ما طلع بعث بس
  /// اشعار مع اني حاط قارئ" **كان بالضبط بهذا السبب** على الأغلب: قناة
  /// المؤذن المختار أُنشئت بجلسة تجربة سابقة بلا صوت صالح وقتها. الحذف
  /// قبل الإنشاء بكل `initialize()` يضمن مطابقة القناة للكود الحالي
  /// دائماً — مكلفة الأداء صفر عملياً (يحصل مرة واحدة عند إقلاع التطبيق).
  Future<void> _recreateChannel(AndroidNotificationChannel channel) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await android?.deleteNotificationChannel(channelId: channel.id);
    } catch (e) {
      // قناة غير موجودة أصلاً (أول تشغيل) — متوقَّع، ليس خطأً.
      debugPrint('حذف قناة إشعار (${channel.id}) قبل إعادة الإنشاء: $e');
    }
    await android?.createNotificationChannel(channel);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // فشل صامت — تبقى المنطقة الزمنية الافتراضية لحزمة timezone، ما
      // يعني إشعارات بوقت خاطئ لا انهياراً. راجع القيود بالأعلى.
      debugPrint('تعذّر تحديد المنطقة الزمنية المحلية للإشعارات: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      // كلاهما نفس الدالة top-level — راجع توثيق [onPrayerCheckinNotificationResponse]:
      // `onDidReceiveNotificationResponse` يعالج ردود الأزرار والتطبيق حيّ
      // بالخلفية/الواجهة، و`onDidReceiveBackgroundNotificationResponse`
      // (معزل خلفي منفصل) لو كان مغلَقاً تماماً. أزرار الإجراء الوحيدة
      // بالتطبيق حالياً (متابعة "هل صليت؟") فلا حاجة لتفريق حسب `actionId`
      // هون — الدالة نفسها تتجاهل أي `actionId` غير معروف أصلاً.
      onDidReceiveNotificationResponse: onPrayerCheckinNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onPrayerCheckinNotificationResponse,
    );

    // قناة أذان مستقلة لكل صوت مؤذن (راجع تعليق [_adhanChannelId]) — صوت
    // القناة ثابت عند الإنشاء بأندرويد 8+، فالتبديل الفعلي يحصل عند
    // الجدولة (`_scheduleOne`) باختيار القناة المطابقة لتفضيل المستخدم
    // الحالي، لا بتعديل قناة موجودة.
    for (final voice in kAdhanVoices) {
      await _recreateChannel(
        AndroidNotificationChannel(
          _adhanChannelId(voice.id),
          _adhanChannelName(voice.id),
          description: 'تنبيه عند دخول وقت كل صلاة',
          importance: Importance.max,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound:
              (voice.isSystemDefault || voice.notificationSoundResource == null)
              ? null
              : RawResourceAndroidNotificationSound(
                  voice.notificationSoundResource!,
                ),
        ),
      );
    }

    await _recreateChannel(
      const AndroidNotificationChannel(
        _kQiyamChannelId,
        _kQiyamChannelName,
        description: 'تذكير يومي بالساعة التي يختارها المستخدم لقيام الليل',
        importance: Importance.high,
      ),
    );

    await _recreateChannel(
      const AndroidNotificationChannel(
        _kHifzChannelId,
        _kHifzChannelName,
        description: 'تذكير يومي بالساعة التي يختارها المستخدم لمتابعة الحفظ',
        importance: Importance.high,
      ),
    );

    await _recreateChannel(
      const AndroidNotificationChannel(
        _kCheckinChannelId,
        _kCheckinChannelName,
        description:
            'سؤال متابعة بعد كل صلاة، بزرّي "صليت"/"لسا"، يتكرر كل ١٠ دقائق حتى الإجابة',
        importance: Importance.high,
      ),
    );

    await _recreateChannel(
      const AndroidNotificationChannel(
        _kImsakChannelId,
        _kImsakChannelName,
        description: 'تذكير قرب الإمساك خلال شهر رمضان فقط، تلقائياً بلا إعداد',
        importance: Importance.high,
      ),
    );

    await _recreateChannel(
      const AndroidNotificationChannel(
        _kSunnahChannelId,
        _kSunnahChannelName,
        description: 'تذكيرات بسنن يوم الجمعة وصيام النوافل والأيام البيض',
        importance: Importance.high,
      ),
    );

    await _recreateChannel(
      const AndroidNotificationChannel(
        _kCustomHabitChannelId,
        _kCustomHabitChannelName,
        description:
            'تذكير يومي بالساعة التي يختارها المستخدم لعاداته المخصّصة',
        importance: Importance.high,
      ),
    );

    for (final meta in _kActivityReminderMeta.values) {
      await _recreateChannel(
        AndroidNotificationChannel(
          meta.channelId,
          meta.channelName,
          description: meta.channelDescription,
          importance: Importance.high,
        ),
      );
    }

    // قنوات "التكرار العام" — راجع [scheduleRepeatingReminder].
    for (final meta in _kRepeatingReminderMeta.values.toSet()) {
      await _recreateChannel(
        AndroidNotificationChannel(
          meta.channelId,
          meta.channelName,
          description: 'تذكير متكرر — ${meta.title}',
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  /// يطلب أذونات النظام اللازمة — لا يفشل التطبيق ولا يرمي استثناءً لو
  /// رُفضت، فقط لا تصل الإشعارات (أو تصل بجدولة غير دقيقة).
  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('طلب إذن إشعارات الأذان فشل/تعذّر: $e');
    }
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('طلب إذن إشعارات الأذان (iOS) فشل/تعذّر: $e');
    }
  }

  /// يلغي كل إشعارات الأذان المجدولة حالياً — يُستخدم مباشرة عند تعطيل
  /// الإشعارات كلياً، وداخلياً أول كل [rescheduleUpcoming].
  Future<void> cancelAll() async {
    for (var i = 0; i < _kMaxScheduledPerCall; i++) {
      await _plugin.cancel(id: _kNotifIdBase + i);
    }
  }

  /// يلغي كل سلاسل إشعارات متابعة "هل صليت؟" المجدولة — نفس نمط [cancelAll]
  /// لكن بمدى معرّفات مستقل (راجع [_scheduleCheckinSeries]).
  Future<void> cancelAllPrayerCheckins() async {
    for (var slot = 0; slot < _kCheckinMaxSlots; slot++) {
      for (var i = 0; i < _kCheckinMaxRepeatsPerSlot; i++) {
        await _plugin.cancel(id: _kCheckinIdBase + slot * 10 + i);
      }
    }
  }

  /// يلغي تذكيرَي الإمساك المجدولَين (يومان بحدّ أقصى) — راجع
  /// [_scheduleImsakIfRamadan].
  Future<void> cancelAllImsakReminders() async {
    for (var i = 0; i < 2; i++) {
      await _plugin.cancel(id: _kImsakIdBase + i);
    }
  }

  /// يلغي كل إشعارات أذكار كل ساعة المجدولة
  Future<void> cancelAllHourlyDhikr() async {
    for (var i = 0; i < _kMaxHourlySlots; i++) {
      await _plugin.cancel(id: _kHourlyDhikrNotifIdBase + i);
    }
  }

  /// يجدول إشعارات أذكار وأدعية كل ساعة في الفترات النشطة — `intervalHours`
  /// يحدّد كل كم ساعة يتكرر الإشعار ضمن الفترة (١ = كل ساعة، الافتراضي
  /// القديم؛ بطلب صاحب المشروع "خلي المستخدم يقرر... كل كم يبعث ذكر او
  /// اشعار" صار قابلاً للتغيير، لا ثابتاً).
  Future<void> rescheduleHourlyDhikr({
    bool isEnabled = true,
    int startHour = 8,
    int endHour = 23,
    int intervalHours = 1,
  }) async {
    if (!_initialized) await initialize();
    await cancelAllHourlyDhikr();
    if (!isEnabled) return;
    final step = intervalHours < 1 ? 1 : intervalHours;

    final now = DateTime.now();
    var slotIndex = 0;

    for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
      final baseDate = now.add(Duration(days: dayOffset));
      for (var hour = startHour; hour <= endHour; hour += step) {
        final targetTime = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          hour,
          0,
        );
        if (targetTime.isBefore(now.add(const Duration(minutes: 2)))) continue;
        if (slotIndex >= _kMaxHourlySlots) break;

        final notifId = _kHourlyDhikrNotifIdBase + slotIndex;
        final item =
            kHourlyDhikrPool[(targetTime.day * 24 + hour) %
                kHourlyDhikrPool.length];

        try {
          final tzTarget = tz.TZDateTime.from(targetTime, tz.local);
          await _plugin.zonedSchedule(
            id: notifId,
            title: item.title,
            body: item.body,
            scheduledDate: tzTarget,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                _kHourlyDhikrChannelId,
                _kHourlyDhikrChannelName,
                channelDescription: 'إشعار لطيف كل ساعة بذكر ودعاء مأثور',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                styleInformation: BigTextStyleInformation(''),
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: false,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          slotIndex++;
        } catch (e) {
          debugPrint('خطأ في جدولة تذكير الساعة ($hour:00): $e');
        }
      }
    }
  }

  /// إرسال إشعار تجريبي فوري لذكر ودعاء الساعة
  Future<void> sendTestHourlyDhikrNotification() async {
    if (!_initialized) await initialize();
    final item =
        kHourlyDhikrPool[DateTime.now().minute % kHourlyDhikrPool.length];
    await _plugin.show(
      id: 9991,
      title: item.title,
      body: item.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _kHourlyDhikrChannelId,
          _kHourlyDhikrChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// معرّف الإشعار الأساسي المخصَّص لتكرار فئة معيّنة — `null` لو الفئة
  /// لا تدعم التكرار العام (راجع [_kRepeatingReminderIdBases]).
  static int? repeatingReminderIdBaseFor(String category) =>
      _kRepeatingReminderIdBases[category];

  /// يجدول تذكيراً يتكرر كل [intervalMinutes] دقيقة بدءاً من [startHour]:
  /// [startMinute] وحتى [endHour]:[endMinute] لنفس اليوم — بطلب صاحب
  /// المشروع "بقدر اضيف التكرارات على كل التذكيرات... الصلاة على النبي
  /// وغيرها" (كان التكرار الدقيق بالدقائق حكراً على أذكار الساعة فقط).
  ///
  /// نافذة يومين قادمين فقط (`onlyWeekday` يوسّعها لأسبوع بحثاً عن أول
  /// يوم مطابق — الجمعة مثلاً)، تُعاد جدولتها تلقائياً عند فتح التطبيق أو
  /// تغيير الإعداد — نفس نمط [rescheduleHourlyDhikr] العام. محتوى واحد
  /// ثابت لكل التكرارات (`body`) عمداً — لا رسائل دوّارة هون، تبسيطاً؛
  /// المحتوى الدوّار (حديث/اسم مختلف يومياً) يبقى محصوراً بوضع "مرة واحدة"
  /// (الدوال المخصَّصة كـ[scheduleQiyamReminder]).
  Future<void> scheduleRepeatingReminder({
    required String category,
    required String body,
    required int startHour,
    required int startMinute,
    required int intervalMinutes,
    int endHour = 23,
    int endMinute = 59,
    int? onlyWeekday,
  }) async {
    final idBase = _kRepeatingReminderIdBases[category];
    final meta = _kRepeatingReminderMeta[category];
    if (idBase == null || meta == null) return;
    if (!_initialized) await initialize();
    await cancelRepeatingReminder(category);

    final now = DateTime.now();
    var slotIndex = 0;
    final step = intervalMinutes < 1 ? 1 : intervalMinutes;

    for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
      if (slotIndex >= _kMaxRepeatingSlots) break;
      final day = now.add(Duration(days: dayOffset));
      if (onlyWeekday != null && day.weekday != onlyWeekday) continue;

      var t = DateTime(day.year, day.month, day.day, startHour, startMinute);
      final dayEnd = DateTime(day.year, day.month, day.day, endHour, endMinute);
      while (!t.isAfter(dayEnd)) {
        if (slotIndex >= _kMaxRepeatingSlots) break;
        if (t.isAfter(now.add(const Duration(minutes: 1)))) {
          final id = idBase + slotIndex;
          try {
            final tzTarget = tz.TZDateTime.from(t, tz.local);
            await _plugin.zonedSchedule(
              id: id,
              title: meta.title,
              body: body,
              scheduledDate: tzTarget,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  meta.channelId,
                  meta.channelName,
                  channelDescription: 'تذكير متكرر — ${meta.title}',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
                iOS: const DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } catch (e) {
            debugPrint(
              'جدولة تذكير متكرر ($category) فشلت لسلوت $slotIndex: $e',
            );
          }
          slotIndex++;
        }
        t = t.add(Duration(minutes: step));
      }
      // نافذة يومين فقط لو بلا قيد يوم أسبوع مُحدَّد — كافية لبقاء
      // التذكيرات مجدولة حتى فتح التطبيق التالي (نفس منطق أذكار الساعة).
      if (onlyWeekday == null && dayOffset >= 1) break;
      if (onlyWeekday != null) break; // أول يوم مطابق كافٍ (أسبوعي بطبيعته)
    }
  }

  Future<void> cancelRepeatingReminder(String category) async {
    final idBase = _kRepeatingReminderIdBases[category];
    if (idBase == null) return;
    for (var i = 0; i < _kMaxRepeatingSlots; i++) {
      await _plugin.cancel(id: idBase + i);
    }
  }

  /// يلغي كل الإشعارات المجدولة القديمة، ويعيد جدولة ما تبقّى من صلوات
  /// اليوم وكل صلوات الغد. يُستدعى عند إقلاع التطبيق وعند تغيير الموقع
  /// أو طريقة الحساب (راجع `prayer_location_controller.dart`).
  ///
  /// `checkinEnabled`/`checkinFirstDelayMinutes` (راجع `PrayerCheckinSettings`)
  /// يفعّلان جدولة سلسلة متابعة "هل صليت؟" **إضافية** بجانب إشعار الأذان
  /// نفسه لكل صلاة — إعداد مستقل عمداً (راجع توثيق [_scheduleCheckinSeries]).
  Future<void> rescheduleUpcoming({
    required double lat,
    required double lon,
    required String methodKey,
    required bool Function(PrayerMoment) isEnabled,
    String voiceId = 'system',
    String Function(PrayerMoment)? getVoiceIdFor,
    String Function(PrayerMoment)? getModeFor,
    int preAdhanMinutes = 0,
    bool checkinEnabled = false,
    int checkinFirstDelayMinutes = 15,
  }) async {
    if (!_initialized) await initialize();
    await cancelAll();
    await cancelAllPrayerCheckins();
    await cancelAllImsakReminders();

    final now = DateTime.now();

    // نجمع كل مواقيت الصلاة (اليوم والغد) بشكل متسلسل لمعرفة نافذة كل صلاة
    final allPrayers =
        <
          ({
            PrayerMoment moment,
            DateTime time,
            DateTime boundary,
            DateTime date,
          })
        >[];
    final todayTimes = computeDayTimes(
      lat: lat,
      lon: lon,
      date: now,
      methodKey: methodKey,
    ).where((t) => t.moment.isPrayer).toList();

    final tomorrowTimes = computeDayTimes(
      lat: lat,
      lon: lon,
      date: now.add(const Duration(days: 1)),
      methodKey: methodKey,
    ).where((t) => t.moment.isPrayer).toList();

    final combined = [...todayTimes, ...tomorrowTimes];
    for (var i = 0; i < combined.length; i++) {
      final cur = combined[i];
      final boundary = i + 1 < combined.length
          ? combined[i + 1].time
          : cur.time.add(const Duration(hours: 3));
      allPrayers.add((
        moment: cur.moment,
        time: cur.time,
        boundary: boundary,
        date: i >= 5 ? now.add(const Duration(days: 1)) : now,
      ));
    }

    // تذكير السحور في رمضان
    for (final dayOffset in [0, 1]) {
      final date = now.add(Duration(days: dayOffset));
      if (isRamadan(date)) {
        final list = dayOffset == 0 ? todayTimes : tomorrowTimes;
        final fTime = list
            .firstWhere((t) => t.moment == PrayerMoment.fajr)
            .time;
        await _scheduleImsakReminder(dayOffset, fTime);
      }
    }

    var id = _kNotifIdBase;
    for (var i = 0; i < allPrayers.length; i++) {
      final p = allPrayers[i];

      final prayerVoice = getVoiceIdFor?.call(p.moment) ?? voiceId;
      final mode = getModeFor?.call(p.moment) ?? 'adhan';

      // 1. إشعار الأذان: إذا كان وقت الأذان في المستقبل ومفعّل بالنمط المختار
      if (p.time.isAfter(now) && isEnabled(p.moment) && mode != 'off') {
        await _scheduleOne(id++, p.moment, p.time, prayerVoice, mode: mode);
      }

      // 2. تذكير قبل الأذان (الاستعداد والوضوء)
      if (preAdhanMinutes > 0 && isEnabled(p.moment) && mode != 'off') {
        final preTime = p.time.subtract(Duration(minutes: preAdhanMinutes));
        if (preTime.isAfter(now)) {
          await _schedulePreAdhanOne(
            id + 200,
            p.moment,
            preTime,
            preAdhanMinutes,
          );
        }
      }

      // 3. سلسلة متابعة "هل صليت؟": إذا كانت متابعة الصلاة مفعلة، ونافذة الصلاة ما تزال نشطة في المستقبل
      if (checkinEnabled && p.boundary.isAfter(now) && i < _kCheckinMaxSlots) {
        await _scheduleCheckinSeries(
          slotIndex: i,
          prayer: p.moment,
          prayerTime: p.time,
          boundary: p.boundary,
          firstDelayMinutes: checkinFirstDelayMinutes,
        );
      }
    }
  }

  /// يجدوِل سلسلة إشعارات متابعة "هل صليت؟" لصلاة واحدة: أول سؤال بعد
  /// `firstDelayMinutes` من دخول الوقت، ثم كل ١٠ دقائق حتى `boundary`
  /// (وقت الصلاة التالية عادة) أو [_kCheckinMaxRepeatsPerSlot] أيّهما أقرب.
  /// كل إشعار بزرّي إجراء مباشرين ("صليت ✓"/"لسا") — راجع
  /// [onPrayerCheckinNotificationResponse] لمعالجة الرد وإلغاء الباقي.
  Future<void> _scheduleCheckinSeries({
    required int slotIndex,
    required PrayerMoment prayer,
    required DateTime prayerTime,
    required DateTime boundary,
    required int firstDelayMinutes,
  }) async {
    final dateKey = '${prayerTime.year}-${prayerTime.month}-${prayerTime.day}';
    final payload = '$dateKey|${prayer.name}|$slotIndex';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kCheckinChannelId,
        _kCheckinChannelName,
        channelDescription: 'سؤال متابعة بعد كل صلاة، بزرّي "صليت"/"لسا"',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        ongoing: false,
        actions: const [
          AndroidNotificationAction(
            _kCheckinYesAction,
            'صليت ✓',
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _kCheckinNoAction,
            'لسا',
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final now = DateTime.now();
    for (var repeat = 0; repeat < _kCheckinMaxRepeatsPerSlot; repeat++) {
      final fireTime = prayerTime.add(
        Duration(minutes: firstDelayMinutes + repeat * 10),
      );
      if (!fireTime.isBefore(boundary)) break;
      if (!fireTime.isAfter(now)) continue; // لا نجدول مواعيد مضت

      final scheduled = tz.TZDateTime.from(fireTime, tz.local);
      final id = _kCheckinIdBase + slotIndex * 10 + repeat;
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: 'هل صليت ${prayer.nameAr}؟',
          body: 'اضغط "صليت" لو أدّيتها، أو تجاهل ليُعاد السؤال بعد ١٠ دقائق',
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } catch (e) {
        debugPrint(
          'جدولة دقيقة لمتابعة صلاة ${prayer.nameAr} فشلت، تراجع لجدولة تقريبية: $e',
        );
        await _plugin.zonedSchedule(
          id: id,
          title: 'هل صليت ${prayer.nameAr}؟',
          body: 'اضغط "صليت" لو أدّيتها، أو تجاهل ليُعاد السؤال بعد ١٠ دقائق',
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      }
    }
  }

  /// إرسال إشعار فوري (لتشجيعات المجموعات وتنبيهات العبادات)
  Future<void> showInstantAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'humam_instant_alerts',
            'تنبيهات وتشجيعات هُمَام',
            channelDescription: 'إشعارات تشجيع المجموعات والتذكيرات الفورية',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('showInstantAlert error: $e');
    }
  }

  /// إشعار فوري تجريبي لمتابعة "هل صليت؟"
  Future<void> sendTestCheckinNotification({PrayerMoment? moment}) async {
    if (!_initialized) await initialize();
    final now = DateTime.now();
    final targetMoment = moment ?? _detectCurrentPrayerMoment(now);
    final scheduled = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 3));
    final dateKey = '${scheduled.year}-${scheduled.month}-${scheduled.day}';
    final payload = '$dateKey|${targetMoment.name}|99';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kCheckinChannelId,
        _kCheckinChannelName,
        channelDescription: 'سؤال متابعة بعد كل صلاة، بزرّي "صليت"/"لسا"',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        ongoing: false,
        actions: const [
          AndroidNotificationAction(
            _kCheckinYesAction,
            'صليت ✓',
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _kCheckinNoAction,
            'لسا',
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: 9998,
      title: 'هل صليت ${targetMoment.nameAr}؟',
      body: 'اضغط "صليت" لو أدّيتها، أو "لسا"',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  PrayerMoment _detectCurrentPrayerMoment(DateTime now) {
    final h = now.hour;
    if (h >= 4 && h < 12) return PrayerMoment.fajr;
    if (h >= 12 && h < 15) return PrayerMoment.dhuhr;
    if (h >= 15 && h < 18) return PrayerMoment.asr;
    if (h >= 18 && h < 20) return PrayerMoment.maghrib;
    return PrayerMoment.isha;
  }

  /// تذكير قيام الليل — **جدولة دوّارة** (`_kReminderRotationDays` يوماً،
  /// إشعار مستقل بمعرّف مختلف لكل يوم) بدل التكرار الآلي القديم على مستوى
  /// النظام (`matchDateTimeComponents: DateTimeComponents.time`)، لأن ذاك
  /// النمط يُلزم كل التكرارات بنفس النص المُجدوَل أول مرة — لا يسمح بتنويع
  /// المحتوى يومياً. [messages] (راجع `reminder_messages.dart`) تُقرأ فهرسياً
  /// بالدوران (`day % messages.length`) — بطلب صاحب المشروع "خليهن متغيرات
  /// مش ثابتات كل يوم حديث او مقولة اسلامية". لا علاقة بحساب مواقيت الصلاة —
  /// وقت اختياري بحت يحدّده المستخدم بشاشة قيام الليل (`qiyam_screen.dart`).
  Future<void> scheduleQiyamReminder({
    required int hour,
    required int minute,
    List<String> messages = const [],
  }) async {
    if (!_initialized) await initialize();
    await cancelQiyamReminder();

    final body = messages.isEmpty
        ? const ['حان وقت التذكير الذي اخترته لقيام الليل']
        : messages;

    final now = tz.TZDateTime.now(tz.local);
    final todayAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final startOffset = todayAt.isAfter(now) ? 0 : 1;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kQiyamChannelId,
        _kQiyamChannelName,
        channelDescription:
            'تذكير يومي بالساعة التي يختارها المستخدم لقيام الليل، بمحتوى متجدّد (حديث/مقولة مختلفة كل يوم)',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (var day = 0; day < _kReminderRotationDays; day++) {
      final scheduled = todayAt.add(Duration(days: startOffset + day));
      final id = _kQiyamNotifIdBase + day;
      final text = body[day % body.length];

      Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
        id: id,
        title: 'وقت قيام الليل',
        body: text,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: mode,
      );

      try {
        await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (e) {
        debugPrint(
          'جدولة دقيقة لتذكير قيام الليل (يوم $day) فشلت، تراجع لجدولة تقريبية: $e',
        );
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
  }

  Future<void> cancelQiyamReminder() async {
    for (var day = 0; day < _kReminderRotationDays; day++) {
      await _plugin.cancel(id: _kQiyamNotifIdBase + day);
    }
  }

  /// راجع توثيق [scheduleQiyamReminder] أعلاه — نفس المبدأ بالضبط (جدولة
  /// دوّارة، محتوى متجدّد يومياً)، بقناة/مدى معرّفات مستقلَّين لتذكير الحفظ.
  Future<void> scheduleHifzReminder({
    required int hour,
    required int minute,
    List<String> messages = const [],
  }) async {
    if (!_initialized) await initialize();
    await cancelHifzReminder();

    final body = messages.isEmpty
        ? const ['حان وقت التذكير الذي اخترته لمتابعة حفظك']
        : messages;

    final now = tz.TZDateTime.now(tz.local);
    final todayAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final startOffset = todayAt.isAfter(now) ? 0 : 1;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kHifzChannelId,
        _kHifzChannelName,
        channelDescription:
            'تذكير يومي بالساعة التي يختارها المستخدم لمتابعة الحفظ، بمحتوى متجدّد (حديث مختلف كل يوم)',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (var day = 0; day < _kReminderRotationDays; day++) {
      final scheduled = todayAt.add(Duration(days: startOffset + day));
      final id = _kHifzNotifIdBase + day;
      final text = body[day % body.length];

      Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
        id: id,
        title: 'وقت الحفظ',
        body: text,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: mode,
      );

      try {
        await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (e) {
        debugPrint(
          'جدولة دقيقة لتذكير الحفظ (يوم $day) فشلت، تراجع لجدولة تقريبية: $e',
        );
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
  }

  Future<void> cancelHifzReminder() async {
    for (var day = 0; day < _kReminderRotationDays; day++) {
      await _plugin.cancel(id: _kHifzNotifIdBase + day);
    }
  }

  /// تذكير "حديث اليوم" — نفس مبدأ [scheduleQiyamReminder]/
  /// [scheduleHifzReminder] بالضبط (جدولة دوّارة، حديث مختلف كل يوم من
  /// `kCuratedDailyHadiths`)، بطلب صاحب المشروع "حديث اليوم بحب ينبعث
  /// كاشعار".
  Future<void> scheduleDailyHadithReminder({
    required int hour,
    required int minute,
    List<String> messages = const [],
  }) async {
    if (!_initialized) await initialize();
    await cancelDailyHadithReminder();

    final body = messages.isEmpty
        ? const ['حديث اليوم بانتظارك في التطبيق']
        : messages;

    final now = tz.TZDateTime.now(tz.local);
    final todayAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final startOffset = todayAt.isAfter(now) ? 0 : 1;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kDailyHadithChannelId,
        _kDailyHadithChannelName,
        channelDescription:
            'تذكير يومي بحديث نبوي مختلف كل يوم بالساعة التي يختارها المستخدم',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (var day = 0; day < _kReminderRotationDays; day++) {
      final scheduled = todayAt.add(Duration(days: startOffset + day));
      final id = _kDailyHadithNotifIdBase + day;
      final text = body[day % body.length];

      Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
        id: id,
        title: 'حديث اليوم 📖',
        body: text,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: mode,
      );

      try {
        await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (e) {
        debugPrint(
          'جدولة دقيقة لتذكير حديث اليوم (يوم $day) فشلت، تراجع لجدولة تقريبية: $e',
        );
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
  }

  Future<void> cancelDailyHadithReminder() async {
    for (var day = 0; day < _kReminderRotationDays; day++) {
      await _plugin.cancel(id: _kDailyHadithNotifIdBase + day);
    }
  }

  /// تذكير "اسم من أسماء الله الحسنى" — نفس المبدأ تماماً، اسم مختلف كل
  /// يوم من الـ٩٩ اسماً (`NamesOfAllahData.items`).
  Future<void> scheduleDailyNameOfAllahReminder({
    required int hour,
    required int minute,
    List<String> messages = const [],
  }) async {
    if (!_initialized) await initialize();
    await cancelDailyNameOfAllahReminder();

    final body = messages.isEmpty
        ? const ['اسم من أسماء الله الحسنى بانتظارك في التطبيق']
        : messages;

    final now = tz.TZDateTime.now(tz.local);
    final todayAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final startOffset = todayAt.isAfter(now) ? 0 : 1;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kDailyNameOfAllahChannelId,
        _kDailyNameOfAllahChannelName,
        channelDescription:
            'تذكير يومي باسم مختلف من أسماء الله الحسنى بالساعة التي يختارها المستخدم',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (var day = 0; day < _kReminderRotationDays; day++) {
      final scheduled = todayAt.add(Duration(days: startOffset + day));
      final id = _kDailyNameOfAllahNotifIdBase + day;
      final text = body[day % body.length];

      Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
        id: id,
        title: 'اسم من أسماء الله الحسنى ✨',
        body: text,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: mode,
      );

      try {
        await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (e) {
        debugPrint(
          'جدولة دقيقة لتذكير اسم من أسماء الله (يوم $day) فشلت، تراجع لجدولة تقريبية: $e',
        );
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
  }

  Future<void> cancelDailyNameOfAllahReminder() async {
    for (var day = 0; day < _kReminderRotationDays; day++) {
      await _plugin.cancel(id: _kDailyNameOfAllahNotifIdBase + day);
    }
  }

  /// إشعار فوري تجريبي — "اختبر الآن" (بطلب صاحب المشروع "كيف بدي اتاكد من
  /// اشعارات الصلاة؟"): يعرض إشعاراً حقيقياً خلال ثوانٍ بنفس قناة/صوت صوت
  /// الأذان المختار حالياً، بلا انتظار دخول وقت صلاة فعلي. `voiceId` فارغ
  /// = صوت النظام الافتراضي (نفس دلالة `voiceId` بباقي الدوال).
  Future<void> sendTestNotification({required String voiceId}) async {
    if (!_initialized) await initialize();
    final scheduled = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 3));
    final voice = adhanVoiceById(voiceId);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _adhanChannelId(voiceId),
        _adhanChannelName(voiceId),
        channelDescription: 'تنبيه عند دخول وقت كل صلاة',
        importance: Importance.max,
        priority: Priority.max,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound:
            (voice.isSystemDefault || voice.notificationSoundResource == null)
            ? null
            : RawResourceAndroidNotificationSound(
                voice.notificationSoundResource!,
              ),
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id: 9999,
      title: 'إشعار تجريبي',
      body:
          'هذا اختبار — لو سمعت صوت الأذان ووصلك هذا الإشعار فكل شيء يعمل بشكل صحيح',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// تذكير يومي عام بمفتاح `category` (أذكار الصباح/المساء، الورد اليومي)
  /// — راجع [_kActivityReminderMeta]. لا شيء لو `category` غير مسجَّلة
  /// بالخريطة (دفاعي، لا يجب أن يحصل).
  Future<void> scheduleActivityReminder(
    String category, {
    required int hour,
    required int minute,
  }) async {
    final meta = _kActivityReminderMeta[category];
    if (meta == null) return;
    if (!_initialized) await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        meta.channelId,
        meta.channelName,
        channelDescription: meta.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: meta.notifId,
      title: meta.title,
      body: meta.body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint('جدولة دقيقة لتذكير $category فشلت، تراجع لجدولة تقريبية: $e');
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelActivityReminder(String category) async {
    final meta = _kActivityReminderMeta[category];
    if (meta == null) return;
    await _plugin.cancel(id: meta.notifId);
  }

  /// الملخّص المسائي — **مختلف جوهرياً عن [scheduleActivityReminder]**: نص
  /// [body] هون **محسوب فعلياً وقت الاستدعاء** (صفحات/دقائق/أذكار/صلوات
  /// اليوم الحقيقية، راجع `UserRepository.eveningSummaryStatsToday`) لا
  /// نص ثابت من خريطة — فلا نستخدم `matchDateTimeComponents: .time`
  /// (يعني "كرّر نفس هذا الإشعار كل يوم بنفس المحتوى")، بل جدولة **مرّة
  /// واحدة فقط** لأقرب موعد `hour:minute` قادم. **الحل الوحيد المتاح
  /// لمحتوى "حيّ" بلا حزمة مهام خلفية جديدة**: يُعاد استدعاء هذه الدالة
  /// (تُلغي القديمة وتُجدوِل بمحتوى مُحدَّث) عند كل إقلاع تطبيق **وكل مرّة
  /// يُفتح فيها التطبيق** (راجع `main.dart`) — فالمحتوى يعكس نشاط المستخدم
  /// حتى آخر مرّة فتح التطبيق قبل الموعد، لا اللحظة الفعلية للإشعار (نفس
  /// قيد "يحتاج فتح التطبيق لتحديث المحتوى" الموثَّق لتذكيرَي القيام/الحفظ).
  Future<void> scheduleEveningSummary({
    required int hour,
    required int minute,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kEveningSummaryChannelId,
        _kEveningSummaryChannelName,
        channelDescription:
            'ملخّص يومي محفّز لصفحات القراءة/دقائق التلاوة/الأذكار/الصلوات',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: _kEveningSummaryNotifId,
      title: 'ملخّص يومك 🌙',
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: mode,
    );

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint('جدولة دقيقة للملخّص المسائي فشلت، تراجع لجدولة تقريبية: $e');
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelEveningSummary() async {
    await _plugin.cancel(id: _kEveningSummaryNotifId);
  }

  /// تذكير يومي لعادة مخصّصة واحدة (`habitId`) — راجع توثيق
  /// [_kCustomHabitNotifIdBase]. نفس بنية [scheduleActivityReminder] حرفياً،
  /// بمعرّف/عنوان مُشتقَّين من العادة نفسها بدل خريطة ثابتة.
  Future<void> scheduleCustomHabitReminder(
    int habitId, {
    required String title,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kCustomHabitChannelId,
        _kCustomHabitChannelName,
        channelDescription:
            'تذكير يومي بالساعة التي يختارها المستخدم لعاداته المخصّصة',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: _kCustomHabitNotifIdBase + habitId,
      title: title,
      body: 'حان وقت التذكير الذي اخترته لعادة "$title"',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint(
        'جدولة دقيقة لتذكير عادة "$title" فشلت، تراجع لجدولة تقريبية: $e',
      );
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelCustomHabitReminder(int habitId) async {
    await _plugin.cancel(id: _kCustomHabitNotifIdBase + habitId);
  }

  /// راجع توثيق [_kImsakChannelId] بالأعلى وموقع الاستدعاء بـ[rescheduleUpcoming]
  /// — إشعار عادي بلا صوت أذان (قناة/أهمية منفصلتان)، `_kImsakMinutesBeforeFajr`
  /// دقيقة قبل وقت الفجر المحسوب فعلياً.
  Future<void> _scheduleImsakReminder(int dayOffset, DateTime fajrTime) async {
    final fireTime = fajrTime.subtract(
      const Duration(minutes: _kImsakMinutesBeforeFajr),
    );
    if (!fireTime.isAfter(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(fireTime, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kImsakChannelId,
        _kImsakChannelName,
        channelDescription:
            'تذكير قرب الإمساك خلال شهر رمضان فقط، تلقائياً بلا إعداد',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: _kImsakIdBase + dayOffset,
      title: 'قرب وقت الإمساك',
      body:
          'تبقّى $_kImsakMinutesBeforeFajr دقائق على أذان الفجر — تذكير بالسحور',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: mode,
    );

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint('جدولة دقيقة لتذكير الإمساك فشلت، تراجع لجدولة تقريبية: $e');
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> _schedulePreAdhanOne(
    int id,
    PrayerMoment moment,
    DateTime preTime,
    int minutesBefore,
  ) async {
    final scheduled = tz.TZDateTime.from(preTime, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kSunnahChannelId,
        _kSunnahChannelName,
        channelDescription: 'تذكير قبل أذان الصلاة للاستعداد والوضوء',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'تذكير قبل صلاة ${moment.nameAr}',
        body:
            'متبقي $minutesBefore دقائق على أذان ${moment.nameAr} — وقت الاستعداد والوضوء 🧼',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('جدولة تذكير قبل الأذان: $e');
    }
  }

  Future<void> _scheduleOne(
    int id,
    PrayerMoment moment,
    DateTime time,
    String voiceId, {
    String mode = 'adhan',
  }) async {
    final scheduled = tz.TZDateTime.from(time, tz.local);
    final voice = adhanVoiceById(voiceId);

    NotificationDetails details;
    if (mode == 'silent') {
      details = const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_silent_ch',
          'إشعارات صامتة للصلاة',
          channelDescription: 'تنبيه صامت عند دخول وقت الصلاة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
        ),
        iOS: DarwinNotificationDetails(presentSound: false),
      );
    } else if (mode == 'tone') {
      details = const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_tone_ch',
          'تنبيهات قصيرة للصلاة',
          channelDescription: 'نغمة إشعار قصيرة عند دخول وقت الصلاة',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
    } else {
      details = NotificationDetails(
        android: AndroidNotificationDetails(
          _adhanChannelId(voiceId),
          _adhanChannelName(voiceId),
          channelDescription: 'تنبيه عند دخول وقت كل صلاة',
          importance: Importance.max,
          priority: Priority.max,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound:
              (voice.isSystemDefault || voice.notificationSoundResource == null)
              ? null
              : RawResourceAndroidNotificationSound(
                  voice.notificationSoundResource!,
                ),
        ),
        iOS: const DarwinNotificationDetails(),
      );
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'حان وقت صلاة ${moment.nameAr}',
        body: 'حيّ على الصلاة، حيّ على الفلاح',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // غالباً رفض `SCHEDULE_EXACT_ALARM` (بحاجة موافقة يدوية بأندرويد
      // 12+) — نتراجع لجدولة غير دقيقة بدل ما تُفقد الإشعارات بالكامل.
      debugPrint(
        'جدولة دقيقة لإشعار ${moment.nameAr} فشلت، تراجع لجدولة تقريبية: $e',
      );
      await _plugin.zonedSchedule(
        id: id,
        title: 'حان وقت صلاة ${moment.nameAr}',
        body: 'حيّ على الصلاة، حيّ على الفلاح',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  // =========================================================================
  // --- تنبيهات السنن والأيام الفاضلة (الكهف، الصلاة على النبي، الصيام) ---
  // =========================================================================

  /// تذكير سورة الكهف صباح كل يوم جمعة (الساعة 09:00 صباحاً)
  Future<void> scheduleFridayKahfReminder({
    required bool enabled,
    int hour = 9,
    int minute = 0,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(id: _kKahfNotifId);
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != DateTime.friday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kSunnahChannelId,
        _kSunnahChannelName,
        channelDescription: 'تذكير بقراءة سورة الكهف يوم الجمعة',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: _kKahfNotifId,
        title: 'سورة الكهف',
        body: 'نورٌ ما بين الجمعتين — لا تنسَ قراءة سورة الكهف اليوم',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('جدولة تذكير سورة الكهف: $e');
      await _plugin.zonedSchedule(
        id: _kKahfNotifId,
        title: 'سورة الكهف',
        body: 'نورٌ ما بين الجمعتين — لا تنسَ قراءة سورة الكهف اليوم',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// تذكير الصلاة على النبي ﷺ: ليلة الجمعة (الخميس 08:30 م) وصباح الجمعة
  /// (10:00 ص). `scheduleEve`/`scheduleFriday` يسمحان بتعطيل أحد الوقتين
  /// فقط بينما يبقى الآخر — تُستخدَم لو أحد الوقتين تحوّل لتكرار عام
  /// (راجع [scheduleRepeatingReminder]) والآخر بقي "مرة واحدة".
  Future<void> scheduleFridaySalawatReminder({
    required bool enabled,
    int fridayHour = 10,
    int fridayMinute = 0,
    int eveHour = 20,
    int eveMinute = 30,
    bool scheduleEve = true,
    bool scheduleFriday = true,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(id: _kThursdaySalawatNotifId);
    await _plugin.cancel(id: _kFridaySalawatNotifId);
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);

    // 1. تذكير ليلة الجمعة (مساء الخميس)
    var thursdayNight = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      eveHour,
      eveMinute,
    );
    while (thursdayNight.weekday != DateTime.thursday ||
        !thursdayNight.isAfter(now)) {
      thursdayNight = thursdayNight.add(const Duration(days: 1));
    }

    // 2. تذكير يوم الجمعة (صباح الجمعة)
    var friday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      fridayHour,
      fridayMinute,
    );
    while (friday.weekday != DateTime.friday || !friday.isAfter(now)) {
      friday = friday.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kSunnahChannelId,
        _kSunnahChannelName,
        channelDescription: 'تذكير بالصلاة على النبي ﷺ ليلة الجمعة ويوم الجمعة',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      // جدولة ليلة الجمعة
      if (scheduleEve) {
        await _plugin.zonedSchedule(
          id: _kThursdaySalawatNotifId,
          title: 'ليلة الجمعة المباركة — الصلاة على النبي ﷺ',
          body:
              'إن من أفضل أيامكم يوم الجمعة، فأكثروا عليّ من الصلاة فيه فإن صلاتكم معروضة عليّ',
          scheduledDate: thursdayNight,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }

      // جدولة يوم الجمعة صباحاً
      if (scheduleFriday) {
        await _plugin.zonedSchedule(
          id: _kFridaySalawatNotifId,
          title: 'يوم الجمعة — الصلاة على النبي ﷺ',
          body:
              'أكثروا من الصلاة والسلام على نبينا محمد ﷺ في هذا اليوم المبارك',
          scheduledDate: friday,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      debugPrint('جدولة تذكير الصلاة على النبي: $e');
      if (scheduleEve) {
        await _plugin.zonedSchedule(
          id: _kThursdaySalawatNotifId,
          title: 'ليلة الجمعة المباركة — الصلاة على النبي ﷺ',
          body:
              'إن من أفضل أيامكم يوم الجمعة، فأكثروا عليّ من الصلاة فيه فإن صلاتكم معروضة عليّ',
          scheduledDate: thursdayNight,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      if (scheduleFriday) {
        await _plugin.zonedSchedule(
          id: _kFridaySalawatNotifId,
          title: 'يوم الجمعة — الصلاة على النبي ﷺ',
          body:
              'أكثروا من الصلاة والسلام على نبينا محمد ﷺ في هذا اليوم المبارك',
          scheduledDate: friday,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// تذكير صيام الإثنين والخميس (مساء الأحد والأربعاء الساعة 20:30)
  Future<void> scheduleFastingReminders({
    required bool enabled,
    int hour = 20,
    int minute = 30,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(id: _kMondayFastingNotifId);
    await _plugin.cancel(id: _kThursdayFastingNotifId);
    if (!enabled) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kSunnahChannelId,
        _kSunnahChannelName,
        channelDescription: 'تذكير بصيام الإثنين والخميس',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);

    // تذكير الإثنين (يُجدوَل مساء الأحد)
    var sunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (sunday.weekday != DateTime.sunday || !sunday.isAfter(now)) {
      sunday = sunday.add(const Duration(days: 1));
    }

    // تذكير الخميس (يُجدوَل مساء الأربعاء)
    var wednesday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (wednesday.weekday != DateTime.wednesday || !wednesday.isAfter(now)) {
      wednesday = wednesday.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: _kMondayFastingNotifId,
        title: 'تذكير بصيام غداً الإثنين',
        body:
            'تُعرض الأعمال يوم الإثنين والخميس، فأحب أن يُعرض عملي وأنا صائم — نوِّ الصيام',
        scheduledDate: sunday,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      await _plugin.zonedSchedule(
        id: _kThursdayFastingNotifId,
        title: 'تذكير بصيام غداً الخميس',
        body: 'سنة نبوية مباركة — تذكير بصيام يوم الخميس غداً',
        scheduledDate: wednesday,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('جدولة تذكير صيام الإثنين والخميس: $e');
    }
  }

  /// تذكير صيام الأيام البيض (١٣، ١٤، ١٥ من كل شهر هجري)
  Future<void> scheduleWhiteDaysReminder({
    required bool enabled,
    int hour = 20,
    int minute = 30,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(id: _kWhiteDaysNotifId);
    if (!enabled) return;

    final now = DateTime.now();
    DateTime? targetGregorian;

    for (var dayOffset = 0; dayOffset < 35; dayOffset++) {
      final d = now.add(Duration(days: dayOffset));
      final h = HijriCalendar.fromDate(d);
      if (h.hDay == 12) {
        // ليلة 13
        targetGregorian = d;
        break;
      }
    }

    if (targetGregorian == null) return;
    var scheduled = tz.TZDateTime(
      tz.local,
      targetGregorian.year,
      targetGregorian.month,
      targetGregorian.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _kSunnahChannelId,
        _kSunnahChannelName,
        channelDescription: 'تذكير بصيام الأيام البيض (١٣، ١٤، ١٥ هجري)',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: _kWhiteDaysNotifId,
        title: 'تذكير بصيام الأيام البيض',
        body:
            'صيام ثلاثة أيام من كل شهر صيام الدهر كله (١٣، ١٤، ١٥) — تبدأ غداً بإذن الله',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('جدولة تذكير الأيام البيض: $e');
    }
  }
}
