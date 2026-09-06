import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service.dart';
import 'user_database.dart';

/// خطة ختمة — **أكثر من خطة ممكنة بنفس الوقت** (`id` يميّز كل واحدة)، نفس
/// مبدأ [HifzPlan] بالضبط. **تقدّم مستقل لكل خطة** (`currentPage`) عن
/// `ReadingProgress.lastPage` العام — بطلب صاحب المشروع صراحة: خطة الختمة
/// تبدأ من نقطة يختارها المستخدم بنفسه ([startPage]، ليست بالضرورة
/// صفحة ١)، و"التقدّم يكون مختلف عن التقدّم الحالي" — نفس مبدأ
/// [HifzPlan.currentAyahId] بالضبط، يُحدَّث فقط أثناء "تابع القراءة" لهذه
/// الخطة تحديداً (`MushafScreen.khatmaPracticeMode`/`khatmaPlanId`)، لا
/// أي تصفّح عادي آخر.
class KhatmaPlan {
  const KhatmaPlan({
    required this.id,
    required this.startDate,
    required this.targetDays,
    required this.startPage,
    required this.currentPage,
  });
  final int id;
  final DateTime startDate;
  final int targetDays;
  final int startPage;
  final int currentPage;

  /// عدد الصفحات المتبقّية للختمة كاملة من نقطة البداية المختارة —
  /// ٦٠٤ لو بدأت من الصفحة ١ (نفس الحساب القديم قبل إضافة [startPage]).
  int get totalPagesToRead => 604 - startPage + 1;

  int get dailyPages => (totalPagesToRead / targetDays).ceil();

  DateTime get expectedEndDate => startDate.add(Duration(days: targetDays));

  int get daysElapsed {
    final d = DateTime.now().difference(startDate).inDays + 1;
    return d.clamp(1, targetDays);
  }

  /// الصفحة المتوقّع الوصول إليها اليوم لو الالتزام تام بالورد اليومي.
  int get expectedPageByNow =>
      (startPage - 1 + daysElapsed * dailyPages).clamp(startPage, 604);

  /// نسبة تقدّم **هذه الخطة تحديداً** (لا القراءة العامة) — من [startPage]
  /// إلى [currentPage] مقارنة بـ[totalPagesToRead].
  double get progress {
    if (totalPagesToRead <= 0) return 1;
    return ((currentPage - startPage + 1) / totalPagesToRead).clamp(0.0, 1.0);
  }
}

/// خطة حفظ — نطاق آيات (`ayah_id` عام) ضمن سورة واحدة، ومؤشر تقدّم
/// (`currentAyahId`) مستقل تماماً عن `ReadingProgress.lastPage` (راجع
/// `HifzPlans` بـ`user_tables.dart`). **أكثر من خطة ممكنة بنفس الوقت**
/// (`id` يميّز كل واحدة) — بطلب صاحب المشروع الصريح: بدء خطة جديدة لا
/// يحذف أو يُعطِّل خططاً سابقة، كل خطة تبقى بتقدّمها وتاريخها الخاص حتى
/// يحذفها المستخدم صراحة (`UserRepository.cancelHifzPlan`).
class HifzPlan {
  const HifzPlan({
    required this.id,
    required this.fromAyahId,
    required this.toAyahId,
    required this.currentAyahId,
    required this.createdAt,
  });
  final int id;
  final int fromAyahId;
  final int toAyahId;
  final int currentAyahId;
  final DateTime createdAt;

  int get totalAyahs => toAyahId - fromAyahId + 1;

  double get progress {
    if (totalAyahs <= 0) return 0;
    return ((currentAyahId - fromAyahId + 1) / totalAyahs).clamp(0.0, 1.0);
  }
}

/// مفاتيح فئات سلاسل الاستمرار المستقلة (`CategoryStreaks.category`) —
/// ثابتة هون بدل تكرار النصوص الحرفية عبر الملفات. **`dailyWird` استثناء
/// عمداً**: لا صف له بـ`CategoryStreaks` أصلاً، يبقى مخزَّناً بعمود
/// `ReadingProgress.streakDays`/`streakLastDay` القديم (`streakDays`/
/// `bumpStreakIfNewDay` أسفله) — كان موجوداً قبل تقسيم الفئات ولا داعي
/// لهجرته لتفادي فقد سلسلة المستخدم الحالية.
class UserCategories {
  UserCategories._();
  static const morningAzkar = 'morning_azkar';
  static const eveningAzkar = 'evening_azkar';
  static const dailyWird = 'daily_wird';
  static const hifz = 'hifz';
  static const nightAzkar = 'night_azkar';
  static const qiyam = 'qiyam';

  // تذكيرا "حديث اليوم" و"اسم من أسماء الله الحسنى" — يستخدمان نظام
  // [ActivityReminders] العام نفسه (بلا عمود قاعدة بيانات جديد)، راجع
  // `reminders_screen.dart` و`adhan_notification_service.dart`
  // (`scheduleDailyHadithReminder`/`scheduleDailyNameOfAllahReminder`).
  static const dailyHadith = 'daily_hadith';
  static const dailyNameOfAllah = 'daily_name_of_allah';

  /// سلسلة استمرار **مجمَّعة**: "هل أُتمَّت أي عادة مخصّصة اليوم؟" — تخصّ
  /// بطاقة الداشبورد العامة "عاداتي" فقط (راجع `_StreaksRow`)، لا كل عادة
  /// بمفردها (لكل عادة مخصّصة سلسلتها الخاصة عبر `CustomHabitLogs.count`،
  /// راجع `UserRepository.customHabitStreakDays`). تُستدعى من
  /// `addCustomHabitProgress` عند وصول **أي** عادة لهدفها اليومي — يعيد
  /// استخدام آلية [CategoryStreaks]/[CategoryDailyLog] المختبَرة أصلاً بدل
  /// بناء كاش مجمَّع جديد.
  static const customHabitsAny = 'custom_habits_any';

  // --- قسم الصلوات والعبادات (راجع `prayer_screen.dart`) — سلسلة استمرار
  // مستقلة لكل صلاة فرض على حدة (بطلب صاحب المشروع صراحة: "كل صلاة
  // منفصلة إذا تمت أو لا").
  static const fajr = 'prayer_fajr';
  static const dhuhr = 'prayer_dhuhr';
  static const asr = 'prayer_asr';
  static const maghrib = 'prayer_maghrib';
  static const isha = 'prayer_isha';

  /// **مُستبدَلة** بسبع فئات السنن الفردية أدناه (بطلب صاحب المشروع
  /// "ضيف كل سنة صلاة... ولا تهبد كم راسك" — تفصيل السنن الرواتب بدل
  /// خانة واحدة مجمَّعة). أُبقيت الثابتة نفسها كي لا ينكسر أي كود قديم
  /// يشير إليها، لكن `_PrayersChecklist` لم يعد يستخدمها؛ بيانات
  /// المستخدمين السابقة تحتها (إن وُجدت) تبقى باسمها بلا هجرة، غير
  /// معروضة بالواجهة فقط.
  static const rawatib = 'prayer_rawatib';

  // السبع سنن الفردية (قبلية/بعدية) — راجع تعليق `_PrayersChecklist` بـ
  // `prayer_screen.dart` لتصنيف كل واحدة (مؤكدة ضمن الاثنتي عشرة، أو
  // مستحبة غير مؤكدة من "السنن المهجورة") ومصدرها الحديثي.
  static const sunnahFajrQabliyah = 'sunnah_fajr_qabliyah';
  static const sunnahDhuhrQabliyah = 'sunnah_dhuhr_qabliyah';
  static const sunnahDhuhrBadiyah = 'sunnah_dhuhr_badiyah';
  static const sunnahAsrQabliyah = 'sunnah_asr_qabliyah';
  static const sunnahMaghribQabliyah = 'sunnah_maghrib_qabliyah';
  static const sunnahMaghribBadiyah = 'sunnah_maghrib_badiyah';
  static const sunnahIshaBadiyah = 'sunnah_isha_badiyah';
  static const sunnahDuha = 'sunnah_duha';
}

/// عادة مخصّصة يعرّفها المستخدم بنفسه — راجع توثيق [CustomHabits] بـ
/// `user_tables.dart`. **قابلة للتعدّد** (`id` مستقل)، نفس مبدأ [HifzPlan]/
/// [KhatmaPlan] بالضبط.
class CustomHabit {
  const CustomHabit({
    required this.id,
    required this.title,
    required this.targetDaily,
    required this.reminderHour,
    required this.reminderMinute,
    required this.remindersEnabled,
    required this.createdAt,
  });
  final int id;
  final String title;
  final int targetDaily;
  final int? reminderHour;
  final int reminderMinute;
  final bool remindersEnabled;
  final DateTime createdAt;
}

/// مفاتيح أنواع "الفواصل" (`ActivityBookmarks.type`) — فاصلة واحدة فقط
/// لكل نوع بأي لحظة، بخلاف [UserCategories] (سلاسل استمرار) أو خطط الحفظ
/// (`HifzPlan`، نطاق كامل بتقدّم). راجع توثيق `ActivityBookmarks`
/// بـ`user_tables.dart`.
class BookmarkTypes {
  BookmarkTypes._();
  static const reading = 'reading';
  static const hifz = 'hifz';
  static const review = 'review';
  static const tadabbur = 'tadabbur';
  static const all = [reading, hifz, review, tadabbur];
}

/// واجهة واحدة فوق `user.db` تحلّ محل خمس فئات `*_prefs.dart` كانت تغلّف
/// `SharedPreferences` مباشرة. تحتفظ بنسخة كاملة بالذاكرة (`_bookmarks`،
/// `_lastPage`...) تُحمَّل مرة واحدة بـ [preload] عند إقلاع التطبيق —
/// نفس نمط `await SharedPreferences.getInstance()` قبل `runApp` — حتى
/// تبقى القراءات **متزامنة** لكل الشاشات المستهلِكة (`user_prefs.dart`
/// وأخواتها) بلا إعادة كتابتها كلها بـ `FutureProvider`/`AsyncValue`. كل
/// كتابة تُحدِّث الذاكرة فوراً ثم تُخزَّن بـdrift بالخلفية.
class UserRepository {
  static UserRepository? currentInstance;

  UserRepository(this._db) {
    currentInstance = this;
  }
  final UserDatabase _db;

  Set<int> _bookmarks = {};
  int? _lastPage;
  int _streakDays = 0;
  String? _streakLastDay;
  List<KhatmaPlan> _khatmaPlans = [];
  String _reciterId = 'husary';
  double _speed = 1.0;
  bool _liveListenEnabled = false;
  double? _lat;
  double? _lon;
  String? _cityName;
  String _calcMethod = 'ummAlQura';
  int _tasbihCount = 0;
  final Map<String, int> _categoryStreakDays = {};
  final Map<String, String?> _categoryStreakLastDay = {};
  bool _qiyamEnabled = false;
  int? _qiyamHour;
  int _qiyamMinute = 0;
  final Map<String, ({bool enabled, int? hour, int minute})>
  _activityReminders = {};
  Set<int> _azkarFavoriteCategoryIds = {};
  List<HifzPlan> _hifzPlans = [];
  bool _hifzEnabled = false;
  int? _hifzHour;
  int _hifzMinute = 0;
  String _adhanVoiceId = 'system';
  final Map<String, int> _activityBookmarks = {};
  final Map<String, bool> _adhanNotifEnabled = {};
  String _mushafPaletteId = 'default';
  String _mushafNightMode = 'auto';
  String _accentColorId = 'emerald';
  bool _prayerCheckinEnabled = false;
  int _prayerCheckinFirstDelayMinutes = 15;
  // تنبيه "أذكار بعد الصلاة" — إعداد مستقل تماماً عن متابعة "هل صليت؟"
  // وعن تنبيه الأذان نفسه (بطلب صريح بالتودو)، بطلق إشعاراً واحداً لكل
  // صلاة بعد دخول وقتها بمدة [_postPrayerAzkarDelayMinutes] القابلة
  // للتخصيص، بغضّ النظر عن تفعيل متابعة "هل صليت؟" من عدمه.
  bool _postPrayerAzkarEnabled = true;
  int _postPrayerAzkarDelayMinutes = 5;
  List<CustomHabit> _customHabits = [];
  String _userName = '';
  String _userAvatar = '';
  bool _hourlyDhikrEnabled = true;
  int _hourlyDhikrStartHour = 8;
  int _hourlyDhikrEndHour = 23;
  // كل كم ساعة يتكرر إشعار الذكر/الدعاء ضمن الفترة أعلاه — بطلب صاحب
  // المشروع "خلي المستخدم يقرر... كل كم يبعث ذكر او اشعار" (كان ثابتاً
  // كل ساعة بلا أي تحكّم).
  int _hourlyDhikrIntervalHours = 1;

  /// تكرار كل تذكير عام (بالدقائق) — `null` يعني "مرة واحدة باليوم/الأسبوع"
  /// (السلوك الافتراضي القديم). مفتاح الخريطة هو نفس مفتاح الفئة المستخدَم
  /// بـ[ActivityReminders] أو مفتاح مخصَّص للسنن (`sunnah_kahf` مثلاً) —
  /// **مخزَّنة كخريطة JSON واحدة بـSharedPreferences** لا عمود drift جديد
  /// (تُستخدَم بمفاتيح ديناميكية غير معروفة سلفاً)، بطلب صاحب المشروع
  /// "بقدر اضيف التكرارات على كل التذكيرات... الصلاة على النبي وغيرها".
  Map<String, int> _reminderIntervalMinutes = {};

  int _preAdhanMinutes = 10;
  final Map<String, int> _iqamahMinutes = {
    'fajr': 20,
    'dhuhr': 15,
    'asr': 15,
    'maghrib': 10,
    'isha': 15,
  };
  final Map<String, String> _perPrayerVoices = {};
  final Map<String, String> _perPrayerModes = {};
  final Map<String, int> _prayerOffsets = {};

  bool _preloaded = false;

  /// النسخ الاحتياطي المحلي (`backup_service.dart`) يحتاج وصولاً مباشراً
  /// لاتصال drift الحقيقي — لا نسخة منفصلة عبر `userDatabaseProvider`
  /// (غير مستخدَم فعلياً بالتشغيل، راجع توثيقه بـ`user_providers.dart`؛
  /// `main()` يبني `_db` يدوياً ويمرّره هون مباشرة).
  BackupService get backup => BackupService(_db);

  /// يُستدعى مرة واحدة بـ`main()` بعد الهجرة (`prefs_migration.dart`)
  /// وقبل `runApp` — يملأ كل الحقول أعلاه من `user.db` دفعة واحدة.
  Future<void> preload() async {
    if (_preloaded) return;

    try {
      final sp = await SharedPreferences.getInstance();
      _userName = sp.getString('user_display_name') ?? '';
      _userAvatar = sp.getString('user_profile_avatar') ?? '';
      _hourlyDhikrEnabled = sp.getBool('hourly_dhikr_enabled') ?? true;
      _hourlyDhikrStartHour = sp.getInt('hourly_dhikr_start_hour') ?? 8;
      _hourlyDhikrEndHour = sp.getInt('hourly_dhikr_end_hour') ?? 23;
      _hourlyDhikrIntervalHours = sp.getInt('hourly_dhikr_interval_hours') ?? 1;
      final rawIntervals = sp.getString('reminder_interval_minutes_map');
      if (rawIntervals != null) {
        final decoded = jsonDecode(rawIntervals) as Map<String, dynamic>;
        _reminderIntervalMinutes = decoded.map((k, v) => MapEntry(k, v as int));
      }
    } catch (_) {}

    // كل استعلام هون مستقل عن البقية — نبدأها كلها دفعة وحدة (بلا `await`
    // فوري) بدل انتظار كل وحدة الثانية اللي قبلها بالتسلسل. اتصال drift
    // (`NativeDatabase.createInBackground`) بيصف تنفيذها على عزل الخلفية
    // بالتتالي برضو، بس بلا فجوة رحلة-ذهاب-وإياب لكل استعلام (العزل
    // الرئيسي ما بينتظر رد كل استعلام قبل ما يرسل التالي) — فرق حقيقي على
    // وقت الإقلاع مع تراكم عدد الجداول. الاستهلاك (await) تحت بنفس ترتيب
    // الكود الأصلي تماماً حتى تبقى منطقياً مطابقة.
    final bookmarksF = _db.select(_db.bookmarks).get();
    final progressF = (_db.select(
      _db.readingProgress,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final khatmaF = (_db.select(
      _db.khatmaPlans,
    )..where((t) => t.active.equals(true))).get();
    final audioF = (_db.select(
      _db.audioSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final locationF = (_db.select(
      _db.locationSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final tasbihF = (_db.select(
      _db.tasbihCounter,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final streaksF = _db.select(_db.categoryStreaks).get();
    final qiyamF = (_db.select(
      _db.qiyamSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final azkarFavF = _db.select(_db.azkarFavorites).get();
    final hifzPlansF = (_db.select(
      _db.hifzPlans,
    )..where((t) => t.active.equals(true))).get();
    final hifzSettingsF = (_db.select(
      _db.hifzSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final remindersF = _db.select(_db.activityReminders).get();
    final adhanSettingsF = (_db.select(
      _db.adhanSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final activityBookmarksF = _db.select(_db.activityBookmarks).get();
    final adhanNotifF = _db.select(_db.adhanNotificationSettings).get();
    final mushafColorF = (_db.select(
      _db.mushafColorSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final appThemeF = (_db.select(
      _db.appThemeSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final checkinF = (_db.select(
      _db.prayerCheckinSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final customHabitsF = (_db.select(
      _db.customHabits,
    )..where((t) => t.active.equals(true))).get();

    final bookmarkRows = await bookmarksF;
    _bookmarks = bookmarkRows.map((r) => r.ayahId).toSet();

    final progress = await progressF;
    _lastPage = progress?.lastPage;
    _streakDays = progress?.streakDays ?? 0;
    _streakLastDay = progress?.streakLastDay;

    final khatmaRows = await khatmaF;
    _khatmaPlans = [
      for (final r in khatmaRows)
        KhatmaPlan(
          id: r.id,
          startDate: r.startDate,
          targetDays: r.targetDays,
          startPage: r.startPage,
          currentPage: r.currentPage,
        ),
    ]..sort((a, b) => b.startDate.compareTo(a.startDate));

    final audio = await audioF;
    _reciterId = audio?.reciterId ?? 'husary';
    _speed = audio?.speed ?? 1.0;
    _liveListenEnabled = audio?.liveListenEnabled ?? false;

    final location = await locationF;
    _lat = location?.lat;
    _lon = location?.lon;
    _cityName = location?.cityName;
    _calcMethod = location?.calcMethod ?? 'ummAlQura';

    final tasbih = await tasbihF;
    _tasbihCount = tasbih?.count ?? 0;

    final streakRows = await streaksF;
    for (final row in streakRows) {
      _categoryStreakDays[row.category] = row.streakDays;
      _categoryStreakLastDay[row.category] = row.streakLastDay;
    }

    final qiyam = await qiyamF;
    _qiyamEnabled = qiyam?.enabled ?? false;
    _qiyamHour = qiyam?.reminderHour;
    _qiyamMinute = qiyam?.reminderMinute ?? 0;

    final favoriteRows = await azkarFavF;
    _azkarFavoriteCategoryIds = favoriteRows.map((r) => r.categoryId).toSet();

    final hifzRows = await hifzPlansF;
    _hifzPlans = [
      for (final r in hifzRows)
        HifzPlan(
          id: r.id,
          fromAyahId: r.fromAyahId,
          toAyahId: r.toAyahId,
          currentAyahId: r.currentAyahId,
          createdAt: r.createdAt,
        ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final hifzSettings = await hifzSettingsF;
    _hifzEnabled = hifzSettings?.enabled ?? false;
    _hifzHour = hifzSettings?.reminderHour;
    _hifzMinute = hifzSettings?.reminderMinute ?? 0;

    // بذر مراجعة SRS **رجعي** لخطط حفظ موجودة من قبل إضافة هذه الميزة —
    // `startHifzPlan`/`updateHifzCurrentAyah` وحدهما لا يكفيان لأي خطة
    // أُنشئت قبلهما (لا صف واحد بـ`HifzAyahReviews`، فيبقى زر "مراجعة
    // اليوم" مخفياً للأبد رغم أن الخطة فيها تقدّم حقيقي بالفعل). تحقّق
    // بلا صفوف إطلاقاً لهذه الخطة تحديداً (استعلام واحد رخيص) قبل بذر
    // نطاقها كاملاً (`fromAyahId..currentAyahId`) — مرّة واحدة فقط لكل
    // خطة قديمة، الإطلاقات التالية تجد صفوفاً موجودة فتتخطّى هذا كلياً.
    // خطط مختلفة مستقلة عن بعضها — تُفحص/تُبذَر بالتوازي فيما بينها.
    //
    // **`try/catch` إلزامي هون — باج حقيقي حصل فعلياً على جهاز حقيقي**:
    // `preload()` يُنتظَر بـ`main()` **قبل** `runApp` (راجع `main.dart:42`)،
    // فأي استثناء غير مُمسَك هون يقتل `main()` كاملاً قبل ما يصل `runApp`
    // إطلاقاً — يعني التطبيق ما يرسم ولا فريم واحد أبداً (لا كراش واضح
    // بسجلّ Android العادي، فقط شاشة إقلاع أصلية عالقة للأبد لأن Flutter
    // نفسه ما بدأ). حصل هذا حرفياً: `SqliteException: no such table:
    // hifz_ayah_reviews` بعد هجرة جزئية/مقاطَعة (`force-stop` أثناء جلسة
    // تجربة سابقة على الأغلب) — فشل جدول SRS مؤقتاً يجب ألا يمنع فتح
    // التطبيق كلياً أبداً.
    await Future.wait(
      _hifzPlans.map((plan) async {
        try {
          final anyReview = await (_db.select(
            _db.hifzAyahReviews,
          )..where((t) => t.planId.equals(plan.id))).get();
          if (anyReview.isEmpty) {
            await _seedHifzReviewRange(
              plan.id,
              plan.fromAyahId,
              plan.currentAyahId,
            );
          }
        } catch (e) {
          debugPrint('تعذّر تحميل/بذر مراجعة SRS لخطة الحفظ ${plan.id}: $e');
        }
      }),
    );

    final reminderRows = await remindersF;
    for (final row in reminderRows) {
      _activityReminders[row.category] = (
        enabled: row.enabled,
        hour: row.reminderHour,
        minute: row.reminderMinute,
      );
    }

    final adhanSettings = await adhanSettingsF;
    _adhanVoiceId = adhanSettings?.voiceId ?? 'system';

    final activityBookmarkRows = await activityBookmarksF;
    for (final row in activityBookmarkRows) {
      _activityBookmarks[row.type] = row.ayahId;
    }

    final adhanNotifRows = await adhanNotifF;
    for (final row in adhanNotifRows) {
      _adhanNotifEnabled[row.prayer] = row.enabled;
    }

    final mushafColor = await mushafColorF;
    _mushafPaletteId = mushafColor?.paletteId ?? 'default';
    _mushafNightMode = mushafColor?.nightMode ?? 'auto';

    final appTheme = await appThemeF;
    _accentColorId = appTheme?.accentColorId ?? 'gold';

    final checkinSettings = await checkinF;
    _prayerCheckinEnabled = checkinSettings?.enabled ?? false;
    _prayerCheckinFirstDelayMinutes = checkinSettings?.firstDelayMinutes ?? 15;

    final customHabitRows = await customHabitsF;
    _customHabits = [
      for (final r in customHabitRows)
        CustomHabit(
          id: r.id,
          title: r.title,
          targetDaily: r.targetDaily,
          reminderHour: r.reminderHour,
          reminderMinute: r.reminderMinute,
          remindersEnabled: r.remindersEnabled,
          createdAt: r.createdAt,
        ),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    try {
      final sp = await SharedPreferences.getInstance();
      _preAdhanMinutes = sp.getInt('pre_adhan_minutes') ?? 10;
      _postPrayerAzkarEnabled = sp.getBool('post_prayer_azkar_enabled') ?? true;
      _postPrayerAzkarDelayMinutes =
          sp.getInt('post_prayer_azkar_delay_minutes') ?? 5;
      for (final m in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        final iq = sp.getInt('iqamah_minutes_$m');
        if (iq != null) _iqamahMinutes[m] = iq;
        final v = sp.getString('voice_id_$m');
        if (v != null) _perPrayerVoices[m] = v;
        final mode = sp.getString('mode_$m');
        if (mode != null) _perPrayerModes[m] = mode;
        final off = sp.getInt('offset_$m');
        if (off != null) _prayerOffsets[m] = off;
      }
    } catch (_) {}

    _preloaded = true;
  }

  // --- إعدادات الإقامة والتذكير المبكر والأصوات لكل صلاة ---

  int prayerOffsetFor(String prayerKey) => _prayerOffsets[prayerKey] ?? 0;

  Future<void> setPrayerOffsetFor(String prayerKey, int minutes) async {
    _prayerOffsets[prayerKey] = minutes;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('offset_$prayerKey', minutes);
    } catch (_) {}
  }

  int get preAdhanMinutes => _preAdhanMinutes;
  Future<void> setPreAdhanMinutes(int minutes) async {
    _preAdhanMinutes = minutes;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('pre_adhan_minutes', minutes);
    } catch (_) {}
  }

  int iqamahMinutesFor(String prayerKey) =>
      _iqamahMinutes[prayerKey] ??
      (prayerKey == 'fajr' ? 20 : (prayerKey == 'maghrib' ? 10 : 15));

  Future<void> setIqamahMinutesFor(String prayerKey, int minutes) async {
    _iqamahMinutes[prayerKey] = minutes;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('iqamah_minutes_$prayerKey', minutes);
    } catch (_) {}
  }

  String adhanVoiceFor(String prayerKey) =>
      _perPrayerVoices[prayerKey] ?? _adhanVoiceId;

  Future<void> setAdhanVoiceFor(String prayerKey, String voiceId) async {
    _perPrayerVoices[prayerKey] = voiceId;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('voice_id_$prayerKey', voiceId);
    } catch (_) {}
  }

  String adhanModeFor(String prayerKey) =>
      _perPrayerModes[prayerKey] ?? 'adhan';

  Future<void> setAdhanModeFor(String prayerKey, String mode) async {
    _perPrayerModes[prayerKey] = mode;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('mode_$prayerKey', mode);
    } catch (_) {}
  }

  // --- علامات مرجعية وآخر صفحة وسلسلة الأيام ---

  Set<int> get bookmarkedAyahIds => _bookmarks;

  bool isBookmarked(int ayahId) => _bookmarks.contains(ayahId);

  Future<void> toggleBookmark(int ayahId) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.bookmarks,
      )..where((t) => t.ayahId.equals(ayahId))).getSingleOrNull();
      if (existing != null) {
        await (_db.delete(
          _db.bookmarks,
        )..where((t) => t.ayahId.equals(ayahId))).go();
        _bookmarks = {..._bookmarks}..remove(ayahId);
      } else {
        await _db
            .into(_db.bookmarks)
            .insert(
              BookmarksCompanion.insert(
                ayahId: ayahId,
                createdAt: DateTime.now(),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        _bookmarks = {..._bookmarks, ayahId};
      }
    });
  }

  /// إدراج صريح للعلامة المرجعية فقط إن لم تكن موجودة مسبقاً (INSERT OR IGNORE)
  /// لضمان أمان الهجرات والعمليات المكرّرة (Idempotent).
  Future<void> addBookmarkIfAbsent(int ayahId, {DateTime? createdAt}) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.bookmarks,
      )..where((t) => t.ayahId.equals(ayahId))).getSingleOrNull();
      if (existing == null) {
        await _db
            .into(_db.bookmarks)
            .insert(
              BookmarksCompanion.insert(
                ayahId: ayahId,
                createdAt: createdAt ?? DateTime.now(),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        _bookmarks = {..._bookmarks, ayahId};
      }
    });
  }

  int? get lastReadPage => _lastPage;

  Future<void> setLastReadPage(int page) async {
    _lastPage = page;
    await _db
        .into(_db.readingProgress)
        .insertOnConflictUpdate(
          ReadingProgressCompanion(id: const Value(1), lastPage: Value(page)),
        );
  }

  int get streakDays => _streakDays;

  /// هل تمّت قراءة المصحف اليوم فعلاً؟ (الورد اليومي) — نفس منطق
  /// [completedTodayFor] لكن على `ReadingProgress.streakLastDay` القديم
  /// عمداً لا `CategoryStreaks` (راجع تعليق `UserCategories.dailyWird`).
  bool get readToday => _streakLastDay == _dateKey(DateTime.now());

  /// يُستدعى عند كل تغيير صفحة بالمصحف — يزيد السلسلة يوماً واحداً بأول
  /// زيارة كل يوم تقويمي، ويصفّرها لو انقطع يوم كامل أو أكثر بين آخر
  /// زيارة واليوم — لا حساب دقيق بالساعات، فقط تاريخ التقويم المحلي.
  Future<void> bumpStreakIfNewDay() async {
    final today = _dateKey(DateTime.now());
    if (_streakLastDay == today) return;

    final yesterday = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final continued = _streakLastDay == yesterday;
    final newCount = continued ? _streakDays + 1 : 1;

    _streakDays = newCount;
    _streakLastDay = today;
    await _db
        .into(_db.readingProgress)
        .insertOnConflictUpdate(
          ReadingProgressCompanion(
            id: const Value(1),
            streakDays: Value(newCount),
            streakLastDay: Value(today),
          ),
        );
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// **مختلفة عمداً عن [_dateKey]** — مبطَّنة بالأصفار (`yyyy-MM-dd`) فتصحّ
  /// للمقارنة/الترتيب النصي المباشر (`dueDate <= اليوم`)، لا للمساواة فقط.
  /// راجع توثيق [HifzAyahReviews] بـ`user_tables.dart` لسبب الحاجة لصيغة
  /// منفصلة. **لا تستخدمها لأي شيء غير `HifzAyahReviews.dueDate`** — بقية
  /// الجدول بالمشروع تستخدم [_dateKey] القديمة، وخلط الصيغتين لنفس الغرض
  /// يكسر المقارنة بالتساوي مع بيانات موجودة فعلاً.
  static String _isoDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// نفس [_dateKey] لكن عام — تحتاجه الودجتات أحياناً (مثلاً `qiyam_screen.dart`
  /// لقراءة عدّاد آيات اليوم) بدل تكرار تنسيق التاريخ يدوياً بمكان آخر.
  static String dateKeyFor(DateTime d) => _dateKey(d);

  // --- سلاسل استمرار مستقلة لكل نشاط (راجع [UserCategories]) ---

  int streakDaysFor(String category) => _categoryStreakDays[category] ?? 0;

  /// **أفضل سلسلة نشاط حالية** عبر كل الفئات — لا يوجد بالتطبيق مفهوم
  /// "سلسلة واحدة موحَّدة" (كل نشاط له سلسلته المستقلة عمداً، راجع تعليق
  /// [UserCategories])، فأي مكان يحتاج **رقماً واحداً يمثّل** مدى التزام
  /// المستخدم (مثلاً عرضه لأعضاء مجموعة صحبة بـ`GroupsService`) ياخد أقوى
  /// سلسلة نشطة حالياً بدل اختيار فئة واحدة عشوائياً (قد تكون صفراً لمستخدم
  /// ملتزم بنشاط آخر تماماً). يشمل نفس المجموعة المعروضة بالداشبورد
  /// (`kAvailableDashboardStreaks`) + [streakDays] (سلسلة القراءة القديمة،
  /// مخزَّنة بعمود مستقل خارج [_categoryStreakDays] — راجع تعليق
  /// [UserCategories]).
  int bestCurrentStreakDays() {
    var best = streakDays;
    for (final days in _categoryStreakDays.values) {
      if (days > best) best = days;
    }
    return best;
  }

  /// هل سُجِّل هذا النشاط اليوم فعلاً؟ (مفيد لتعطيل زر "سجّل اليوم" بعد
  /// أول تسجيل — قيام الليل مثلاً لا يُعاد تسجيله مرتين بنفس اليوم).
  bool completedTodayFor(String category) =>
      _categoryStreakLastDay[category] == _dateKey(DateTime.now());

  /// نفس منطق [bumpStreakIfNewDay] بالضبط لكن معمَّم لأي فئة — يُستدعى
  /// عند اكتمال نشاط اليوم (كل أذكار الصباح مثلاً) أو تسجيل يدوي (قيام
  /// الليل). لا شيء لو استُدعي مرتين بنفس اليوم.
  Future<void> bumpCategoryStreakIfNewDay(String category) async {
    final today = _dateKey(DateTime.now());
    final lastDay = _categoryStreakLastDay[category];
    if (lastDay == today) return;

    final yesterday = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final continued = lastDay == yesterday;
    final newCount = continued ? streakDaysFor(category) + 1 : 1;

    _categoryStreakDays[category] = newCount;
    _categoryStreakLastDay[category] = today;
    await _db
        .into(_db.categoryStreaks)
        .insertOnConflictUpdate(
          CategoryStreaksCompanion(
            category: Value(category),
            streakDays: Value(newCount),
            streakLastDay: Value(today),
          ),
        );
    await _db
        .into(_db.categoryDailyLog)
        .insertOnConflictUpdate(
          CategoryDailyLogCompanion(
            category: Value(category),
            dateKey: Value(today),
          ),
        );
  }

  /// إعادة مزامنة الذاكرة المؤقتة لسلاسل الاستمرار من قاعدة البيانات
  Future<void> reloadCategoryStreaks() async {
    final rows = await _db.select(_db.categoryStreaks).get();
    _categoryStreakDays.clear();
    _categoryStreakLastDay.clear();
    for (final row in rows) {
      _categoryStreakDays[row.category] = row.streakDays;
      _categoryStreakLastDay[row.category] = row.streakLastDay;
    }
  }

  /// إتمام آخر ٧ أيام تقويمية (اليوم آخر عنصر) لفئة معيّنة — لعرض صف "أيام
  /// الأسبوع" (`قيام الليل` مثلاً). استعلام مباشر لا تحميل بالذاكرة عمداً:
  /// [CategoryDailyLog] يكبر بلا حدّ مع الوقت خلافاً لبقية حقول هذا الكلاس
  /// المحمَّلة أصلاً بـ[preload] (راجع تعليق الجدول بـ`user_tables.dart`).
  Future<List<bool>> weekCompletionFor(String category) async {
    final keys = List.generate(
      7,
      (i) => _dateKey(DateTime.now().subtract(Duration(days: 6 - i))),
    );
    final rows = await (_db.select(
      _db.categoryDailyLog,
    )..where((t) => t.category.equals(category) & t.dateKey.isIn(keys))).get();
    final done = rows.map((r) => r.dateKey).toSet();
    return [for (final k in keys) done.contains(k)];
  }

  /// إتمام أيام الأسبوع الثابتة السبعة (من السبت إلى الجمعة) للأسبوع الحالي
  Future<List<bool>> fixedWeekCompletionFor(String category) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceSaturday = (today.weekday % 7 + 1) % 7;
    final saturday = today.subtract(Duration(days: daysSinceSaturday));

    final keys = List.generate(
      7,
      (i) => _dateKey(saturday.add(Duration(days: i))),
    );
    final rows = await (_db.select(
      _db.categoryDailyLog,
    )..where((t) => t.category.equals(category) & t.dateKey.isIn(keys))).get();
    final done = rows.map((r) => r.dateKey).toSet();
    return [for (final k in keys) done.contains(k)];
  }

  // --- تذكير قيام الليل ---

  bool get qiyamEnabled => _qiyamEnabled;
  int? get qiyamHour => _qiyamHour;
  int get qiyamMinute => _qiyamMinute;

  Future<void> setQiyamReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    _qiyamEnabled = enabled;
    if (hour != null) _qiyamHour = hour;
    if (minute != null) _qiyamMinute = minute;
    await _db
        .into(_db.qiyamSettings)
        .insertOnConflictUpdate(
          QiyamSettingsCompanion(
            id: const Value(1),
            enabled: Value(enabled),
            reminderHour: _qiyamHour == null
                ? const Value.absent()
                : Value(_qiyamHour),
            reminderMinute: Value(_qiyamMinute),
          ),
        );
  }

  // --- أقسام مفضَّلة من مكتبة حصن المسلم ---

  Set<int> get azkarFavoriteCategoryIds => _azkarFavoriteCategoryIds;

  bool isAzkarFavorite(int categoryId) =>
      _azkarFavoriteCategoryIds.contains(categoryId);

  Future<void> toggleAzkarFavorite(int categoryId) async {
    if (_azkarFavoriteCategoryIds.contains(categoryId)) {
      await (_db.delete(
        _db.azkarFavorites,
      )..where((t) => t.categoryId.equals(categoryId))).go();
      _azkarFavoriteCategoryIds = {..._azkarFavoriteCategoryIds}
        ..remove(categoryId);
    } else {
      await _db
          .into(_db.azkarFavorites)
          .insert(
            AzkarFavoritesCompanion.insert(
              categoryId: categoryId,
              createdAt: DateTime.now(),
            ),
          );
      _azkarFavoriteCategoryIds = {..._azkarFavoriteCategoryIds, categoryId};
    }
  }

  // --- خطط الختمة (أكثر من خطة بنفس الوقت، راجع توثيق [KhatmaPlan]) ---

  List<KhatmaPlan> get khatmaPlans => List.unmodifiable(_khatmaPlans);

  /// **لا تلمس أي خطة سابقة** — نفس مبدأ `startHifzPlan` بالضبط، بطلب
  /// صاحب المشروع توحيد سلوك الختمة مع الحفظ: بدء خطة جديدة لا يلغي
  /// خططاً قائمة.
  Future<KhatmaPlan> startKhatma(
    int targetDays, {
    required int startPage,
  }) async {
    final now = DateTime.now();
    final id = await _db
        .into(_db.khatmaPlans)
        .insert(
          KhatmaPlansCompanion.insert(
            startDate: now,
            targetDays: targetDays,
            startPage: Value(startPage),
            currentPage: Value(startPage),
          ),
        );
    final plan = KhatmaPlan(
      id: id,
      startDate: now,
      targetDays: targetDays,
      startPage: startPage,
      currentPage: startPage,
    );
    _khatmaPlans = [plan, ..._khatmaPlans];
    return plan;
  }

  /// حذف خطة واحدة بعينها (`planId`) — الخطط الأخرى تبقى بلا تغيير، نفس
  /// `cancelHifzPlan`.
  Future<void> cancelKhatmaPlan(int planId) async {
    _khatmaPlans = _khatmaPlans.where((p) => p.id != planId).toList();
    await (_db.update(_db.khatmaPlans)..where((t) => t.id.equals(planId)))
        .write(const KhatmaPlansCompanion(active: Value(false)));
  }

  /// يُستدعى **فقط** أثناء "تابع القراءة" لهذه الخطة تحديداً
  /// (`khatmaPracticeMode` بـ`mushaf_screen.dart`) — لا علاقة له بـ
  /// `setLastReadPage`/`bumpStreakIfNewDay` العاديين، نفس مبدأ
  /// `updateHifzCurrentAyah` بالضبط. لا شيء لو الخطة غير موجودة (حُذفت
  /// مثلاً بتبويب آخر أثناء القراءة).
  Future<void> updateKhatmaCurrentPage(int planId, int page) async {
    final index = _khatmaPlans.indexWhere((p) => p.id == planId);
    if (index == -1) return;
    final plan = _khatmaPlans[index];
    final clamped = page.clamp(plan.startPage, 604);
    final updated = KhatmaPlan(
      id: plan.id,
      startDate: plan.startDate,
      targetDays: plan.targetDays,
      startPage: plan.startPage,
      currentPage: clamped,
    );
    _khatmaPlans = [..._khatmaPlans]..[index] = updated;
    await (_db.update(_db.khatmaPlans)..where((t) => t.id.equals(planId)))
        .write(KhatmaPlansCompanion(currentPage: Value(clamped)));
  }

  // --- خطط الحفظ (أكثر من خطة بنفس الوقت، راجع توثيق [HifzPlan]) ---

  List<HifzPlan> get hifzPlans => List.unmodifiable(_hifzPlans);

  /// **لا تلمس أي خطة سابقة** — بخلاف `startKhatma` (يفرض صفاً نشطاً
  /// واحداً)، هون كل استدعاء يضيف خطة مستقلة جديدة فوق القائمة، بطلب
  /// صاحب المشروع الصريح: "خليه بقدر اعمل من غير ما احذف القديمة واحفظ
  /// القديمة ومعلوماتها والتاريخ تبعها".
  Future<HifzPlan> startHifzPlan({
    required int fromAyahId,
    required int toAyahId,
  }) async {
    final now = DateTime.now();
    final id = await _db
        .into(_db.hifzPlans)
        .insert(
          HifzPlansCompanion.insert(
            fromAyahId: fromAyahId,
            toAyahId: toAyahId,
            currentAyahId: fromAyahId,
            createdAt: now,
          ),
        );
    final plan = HifzPlan(
      id: id,
      fromAyahId: fromAyahId,
      toAyahId: toAyahId,
      currentAyahId: fromAyahId,
      createdAt: now,
    );
    _hifzPlans = [plan, ..._hifzPlans];
    // بذر مراجعة الآية الأولى فوراً — [updateHifzCurrentAyah] وحدها لا تبذر
    // إلا عند **تقدّم** فعلي بعد `fromAyahId`، فلولا هذا كانت أول آية بأي
    // خطة لا تحصل على صفّ مراجعة أبداً لو بقي المستخدم بنفس الصفحة الأولى.
    await _seedHifzReviewRange(id, fromAyahId, fromAyahId);
    return plan;
  }

  /// حذف خطة واحدة بعينها (`planId`) — الخطط الأخرى تبقى بلا تغيير. حذف
  /// حقيقي (`active = false`، لا تُقرأ ثانية بـ[preload]) لا مجرّد إخفاء —
  /// المستخدم اختار الحذف صراحة (زر "حذف الخطة" بـ`HifzScreen` يؤكِّد أولاً).
  Future<void> cancelHifzPlan(int planId) async {
    _hifzPlans = _hifzPlans.where((p) => p.id != planId).toList();
    await (_db.update(_db.hifzPlans)..where((t) => t.id.equals(planId))).write(
      const HifzPlansCompanion(active: Value(false)),
    );
  }

  /// يُستدعى **فقط** أثناء "تابع الحفظ" (`hifzPracticeMode` بـ
  /// `mushaf_screen.dart`) — لا علاقة له بـ`setLastReadPage`/`bumpStreakIfNewDay`
  /// العاديين، هذا صلب فصل تقدّم الحفظ عن تقدّم القراءة. `planId` يحدّد
  /// أي خطة (من عدّة خطط ممكنة الآن) يخصّها هذا التقدّم. لا شيء لو الخطة
  /// غير موجودة (حُذفت مثلاً بتبويب آخر أثناء الممارسة).
  Future<void> updateHifzCurrentAyah(int planId, int ayahId) async {
    final index = _hifzPlans.indexWhere((p) => p.id == planId);
    if (index == -1) return;
    final plan = _hifzPlans[index];
    final clamped = ayahId.clamp(plan.fromAyahId, plan.toAyahId);
    final updated = HifzPlan(
      id: plan.id,
      fromAyahId: plan.fromAyahId,
      toAyahId: plan.toAyahId,
      currentAyahId: clamped,
      createdAt: plan.createdAt,
    );
    _hifzPlans = [..._hifzPlans]..[index] = updated;
    await (_db.update(_db.hifzPlans)..where((t) => t.id.equals(planId))).write(
      HifzPlansCompanion(currentAyahId: Value(clamped)),
    );
    // بذر صفوف مراجعة SM-2 (راجع [HifzAyahReviews]) لكل آية وصل لها التقدّم
    // **لأول مرة** — فقط عند تقدّم فعلي للأمام (لا رجوع لصفحة سابقة)، ولكل
    // آية بالنطاق المقطوع بين الموضع القديم والجديد (صفحة واحدة قد تحوي
    // عدة آيات، لا الآية الأولى فقط).
    if (clamped > plan.currentAyahId) {
      await _seedHifzReviewRange(planId, plan.currentAyahId + 1, clamped);
    }
  }

  /// `INSERT OR IGNORE` لكل آية بالنطاق `[fromAyahId, toAyahId]` — لا يمسّ
  /// صفاً موجوداً مسبقاً (لو رجع المستخدم لنفس النطاق مرة أخرى). `dueDate`
  /// الابتدائي = اليوم (متاحة للمراجعة فوراً)، لا تأخير أول.
  ///
  /// **`batch()` إلزامي هون لا حلقة `insert` مفردة بـ`await` لكل صفّ** —
  /// باج أداء حقيقي مُكتشَف على جهاز فعلي: `preload()` (يستدعي هذا عبر
  /// البذر الرجعي لخطط قديمة) يُنتظَر **قبل** `runApp` بـ`main.dart`، فحلقة
  /// مئات/آلاف عمليات `await` متسلسلة (نطاق خطة حفظ كبير موجودة فعلاً)
  /// كانت تُجمِّد إقلاع التطبيق كاملاً بلا أي شاشة تظهر ("بطل يفتح" —
  /// بلاغ صاحب المشروع الحقيقي). دفعة واحدة (`batch`) تُنفَّذ بمعاملة
  /// SQLite واحدة بغض النظر عن عدد الصفوف.
  Future<void> _seedHifzReviewRange(
    int planId,
    int fromAyahId,
    int toAyahId,
  ) async {
    if (toAyahId < fromAyahId) return;
    final today = _isoDateKey(DateTime.now());
    try {
      await _db.batch((batch) {
        batch.insertAll(_db.hifzAyahReviews, [
          for (var id = fromAyahId; id <= toAyahId; id++)
            HifzAyahReviewsCompanion.insert(
              planId: planId,
              ayahId: id,
              dueDate: today,
            ),
        ], mode: InsertMode.insertOrIgnore);
      });
    } catch (e) {
      debugPrint('تعذّر بذر مراجعة الحفظ للنطاق $fromAyahId..$toAyahId: $e');
    }
  }

  /// آيات خطة `planId` المستحقّة للمراجعة اليوم (`dueDate <= اليوم`)، مرتّبة
  /// بترتيب الآيات. راجع "مراجعة ذكية (SRS)" بخطة الميزة.
  Future<List<int>> dueHifzAyahIdsForPlan(int planId) async {
    try {
      final today = _isoDateKey(DateTime.now());
      final rows =
          await (_db.select(_db.hifzAyahReviews)
                ..where(
                  (t) =>
                      t.planId.equals(planId) &
                      t.dueDate.isSmallerOrEqualValue(today),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.ayahId)]))
              .get();
      return rows.map((r) => r.ayahId).toList();
    } catch (e) {
      debugPrint('تعذّر جلب آيات المراجعة المستحقة: $e');
      return const [];
    }
  }

  /// عدد آيات خطة `planId` المستحقّة اليوم — لشارة "N آية للمراجعة" بـ
  /// `HifzScreen` بلا جلب القائمة كاملة.
  Future<int> dueHifzAyahCountForPlan(int planId) async {
    try {
      final today = _isoDateKey(DateTime.now());
      final rows =
          await (_db.select(_db.hifzAyahReviews)..where(
                (t) =>
                    t.planId.equals(planId) &
                    t.dueDate.isSmallerOrEqualValue(today),
              ))
              .get();
      return rows.length;
    } catch (e) {
      debugPrint('تعذّر حساب عدد آيات المراجعة المستحقة: $e');
      return 0;
    }
  }

  /// خوارزمية SM-2 مبسّطة بـ٤ درجات تقييم (نمط Anki الشائع، لا مقياس ٠-٥
  /// الأصلي كاملاً): `0`=لم أتذكر، `1`=بصعوبة، `2`=جيد، `3`=سهل. دالة نقيّة
  /// (بلا آثار جانبية) لسهولة الاختبار المستقل عن قاعدة البيانات.
  static ({double ease, int intervalDays, int repetitions}) applySm2({
    required double ease,
    required int intervalDays,
    required int repetitions,
    required int quality,
  }) {
    if (quality <= 0) {
      return (ease: ease, intervalDays: 1, repetitions: 0);
    }
    final newRepetitions = repetitions + 1;
    final int newInterval;
    if (newRepetitions == 1) {
      newInterval = 1;
    } else if (newRepetitions == 2) {
      newInterval = 6;
    } else {
      newInterval = (intervalDays * ease).round();
    }
    final gap = 3 - quality;
    final newEase = (ease + (0.1 - gap * (0.08 + gap * 0.02))).clamp(1.3, 2.8);
    return (
      ease: newEase,
      intervalDays: newInterval < 1 ? 1 : newInterval,
      repetitions: newRepetitions,
    );
  }

  /// يقيّم آية واحدة بخطة `planId` بدرجة `quality` (راجع [applySm2]) ويحدّث
  /// جدولتها. لو لا صف سابق لها (لم تُبذَر بعد — مثلاً استُدعيت بلا مرور
  /// بـ[updateHifzCurrentAyah] أولاً) يبدأ بالقيم الافتراضية (`ease=2.5`).
  Future<void> gradeHifzAyahReview(int planId, int ayahId, int quality) async {
    try {
      final existing =
          await (_db.select(_db.hifzAyahReviews)..where(
                (t) => t.planId.equals(planId) & t.ayahId.equals(ayahId),
              ))
              .getSingleOrNull();

      final result = applySm2(
        ease: existing?.easeFactor ?? 2.5,
        intervalDays: existing?.intervalDays ?? 0,
        repetitions: existing?.repetitions ?? 0,
        quality: quality,
      );
      final dueDate = _isoDateKey(
        DateTime.now().add(Duration(days: result.intervalDays)),
      );

      await _db
          .into(_db.hifzAyahReviews)
          .insertOnConflictUpdate(
            HifzAyahReviewsCompanion.insert(
              planId: planId,
              ayahId: ayahId,
              easeFactor: Value(result.ease),
              intervalDays: Value(result.intervalDays),
              repetitions: Value(result.repetitions),
              dueDate: dueDate,
              lastReviewedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      debugPrint('تعذّر تسجيل تقييم مراجعة الحفظ: $e');
    }
  }

  // --- تذكير يومي للحفظ ---

  /// هل راجع المستخدم آية حفظ واحدة على الأقل اليوم (أي صف `lastReviewedAt`
  /// بحدود اليوم التقويمي الحالي)؟ يُستخدَم لجعل تذكير الحفظ واعياً بالإنجاز
  /// الفعلي بنفس فكرة `readToday`/`syncDailyWirdReminder` — لا حاجة لعمود
  /// "سلسلة" مخصَّص، صف واحد اليوم يكفي دليلاً.
  Future<bool> hifzReviewedToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final row = await (_db.select(_db.hifzAyahReviews)
            ..where((t) => t.lastReviewedAt.isBiggerOrEqualValue(startOfDay))
            ..limit(1))
          .getSingleOrNull();
      return row != null;
    } catch (e) {
      debugPrint('تعذّر التحقق من مراجعة الحفظ اليوم: $e');
      return false;
    }
  }

  bool get hifzEnabled => _hifzEnabled;
  int? get hifzHour => _hifzHour;
  int get hifzMinute => _hifzMinute;

  Future<void> setHifzReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    _hifzEnabled = enabled;
    if (hour != null) _hifzHour = hour;
    if (minute != null) _hifzMinute = minute;
    await _db
        .into(_db.hifzSettings)
        .insertOnConflictUpdate(
          HifzSettingsCompanion(
            id: const Value(1),
            enabled: Value(enabled),
            reminderHour: _hifzHour == null
                ? const Value.absent()
                : Value(_hifzHour),
            reminderMinute: Value(_hifzMinute),
          ),
        );
  }

  // --- تذكيرات أنشطة عامة (أذكار الصباح/المساء، الورد اليومي...) ---
  // بمفتاح `category` — راجع توثيق [ActivityReminders] بـ`user_tables.dart`.

  bool reminderEnabledFor(String category) =>
      _activityReminders[category]?.enabled ?? false;
  int? reminderHourFor(String category) => _activityReminders[category]?.hour;
  int reminderMinuteFor(String category) =>
      _activityReminders[category]?.minute ?? 0;

  Future<void> setActivityReminder(
    String category, {
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    final current = _activityReminders[category];
    final newHour = hour ?? current?.hour;
    final newMinute = minute ?? current?.minute ?? 0;
    _activityReminders[category] = (
      enabled: enabled,
      hour: newHour,
      minute: newMinute,
    );
    await _db
        .into(_db.activityReminders)
        .insertOnConflictUpdate(
          ActivityRemindersCompanion(
            category: Value(category),
            enabled: Value(enabled),
            reminderHour: newHour == null
                ? const Value.absent()
                : Value(newHour),
            reminderMinute: Value(newMinute),
          ),
        );
  }

  // --- إعدادات الصوت ---

  String get reciterId => _reciterId;

  Future<void> setReciterId(String id) async {
    _reciterId = id;
    await _db
        .into(_db.audioSettings)
        .insertOnConflictUpdate(
          AudioSettingsCompanion(id: const Value(1), reciterId: Value(id)),
        );
  }

  double get speed => _speed;

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _db
        .into(_db.audioSettings)
        .insertOnConflictUpdate(
          AudioSettingsCompanion(id: const Value(1), speed: Value(speed)),
        );
  }

  /// وضع "سماع مباشر" — راجع توثيق `AudioSettings.liveListenEnabled`.
  bool get liveListenEnabled => _liveListenEnabled;

  Future<void> setLiveListenEnabled(bool value) async {
    _liveListenEnabled = value;
    await _db
        .into(_db.audioSettings)
        .insertOnConflictUpdate(
          AudioSettingsCompanion(
            id: const Value(1),
            liveListenEnabled: Value(value),
          ),
        );
  }

  // --- اسم المستخدم والملف الشخصي ---
  String get userName => _userName;

  Future<void> setUserName(String name) async {
    _userName = name.trim();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('user_display_name', _userName);
    } catch (_) {}
  }

  String get userAvatar => _userAvatar;

  Future<void> setUserAvatar(String avatar) async {
    _userAvatar = avatar.trim();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('user_profile_avatar', _userAvatar);
    } catch (_) {}
  }

  // --- صوت الأذان (المؤذن) — راجع adhan_voices.dart ---

  String get adhanVoiceId => _adhanVoiceId;

  Future<void> setAdhanVoiceId(String id) async {
    _adhanVoiceId = id;
    await _db
        .into(_db.adhanSettings)
        .insertOnConflictUpdate(
          AdhanSettingsCompanion(id: const Value(1), voiceId: Value(id)),
        );
  }

  // --- فواصل المصحف (راجع BookmarkTypes) ---

  int? activityBookmarkAyah(String type) => _activityBookmarks[type];

  /// يضبط فاصلة `type` على `ayahId` — يستبدل أي فاصلة سابقة لنفس النوع
  /// (مخزن أحادي، لا قائمة). راجع توثيق `ActivityBookmarks`.
  Future<void> setActivityBookmark(String type, int ayahId) async {
    _activityBookmarks[type] = ayahId;
    await _db
        .into(_db.activityBookmarks)
        .insertOnConflictUpdate(
          ActivityBookmarksCompanion.insert(
            type: type,
            ayahId: ayahId,
            setAt: DateTime.now(),
          ),
        );
  }

  Future<void> clearActivityBookmark(String type) async {
    _activityBookmarks.remove(type);
    await (_db.delete(
      _db.activityBookmarks,
    )..where((t) => t.type.equals(type))).go();
  }

  // --- تفعيل إشعارات الأذان — بمفتاح `prayer` ('master' + خمس صلوات) ---
  // راجع توثيق [AdhanNotificationSettings] بـ`user_tables.dart` وغلاف
  // `AdhanNotificationPrefs` بـ`adhan_notification_prefs.dart`.

  /// `true` افتراضياً (لا صفّ بعد = مفعَّل) — نفس افتراض `SharedPreferences`
  /// القديم (`_prefs.getBool(...) ?? true`) الذي هُجِر عنه هذا الحقل.
  bool adhanNotifEnabled(String prayerKey) =>
      _adhanNotifEnabled[prayerKey] ?? true;

  Future<void> setAdhanNotifEnabled(String prayerKey, bool value) async {
    _adhanNotifEnabled[prayerKey] = value;
    await _db
        .into(_db.adhanNotificationSettings)
        .insertOnConflictUpdate(
          AdhanNotificationSettingsCompanion(
            prayer: Value(prayerKey),
            enabled: Value(value),
          ),
        );
  }

  // --- عدد آيات جلسات قيام الليل (راجع QiyamAyahLog) ---
  // استعلام مباشر لا تحميل بالذاكرة — نفس منطق [weekCompletionFor].

  Future<int> qiyamAyahCountFor(String dateKey) async {
    final row = await (_db.select(
      _db.qiyamAyahLog,
    )..where((t) => t.dateKey.equals(dateKey))).getSingleOrNull();
    return row?.ayahCount ?? 0;
  }

  /// يضيف `delta` لعدّاد آيات اليوم (لا يستبدله) في معاملة ذرّية — جلسات متعدّدة بنفس
  /// الليلة تتراكم بأمان بلا سباق قراءة-تعديل-كتابة.
  Future<int> addQiyamAyahCount(String dateKey, int delta) async {
    return await _db.transaction(() async {
      final row = await (_db.select(
        _db.qiyamAyahLog,
      )..where((t) => t.dateKey.equals(dateKey))).getSingleOrNull();
      final current = row?.ayahCount ?? 0;
      final next = current + delta;
      await _db
          .into(_db.qiyamAyahLog)
          .insertOnConflictUpdate(
            QiyamAyahLogCompanion.insert(
              dateKey: dateKey,
              ayahCount: Value(next),
            ),
          );
      return next;
    });
  }

  // --- إحصاء استخدام أدوات شاشة "أدواتي" (راجع ToolUsageStats) ---
  // استعلام مباشر لا تحميل بالذاكرة — نفس منطق [qiyamAyahCountFor].

  /// يسجّل ضغطة على أداة `toolId` (يزيد العدّاد بمعاملة ذرّية، نفس مبدأ
  /// [addQiyamAyahCount]) — يغذّي صف "الأكثر استخدامًا" بشاشة "أدواتي".
  Future<void> recordToolTap(String toolId) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.toolUsageStats,
      )..where((t) => t.toolId.equals(toolId))).getSingleOrNull();
      final next = (row?.tapCount ?? 0) + 1;
      await _db
          .into(_db.toolUsageStats)
          .insertOnConflictUpdate(
            ToolUsageStatsCompanion.insert(
              toolId: toolId,
              tapCount: Value(next),
              lastUsedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  /// أعلى [limit] أدوات استخداماً (الأكثر ضغطاً أولاً، وعند التساوي
  /// الأحدث استخداماً) — لصف "الأكثر استخدامًا" المثبَّت بشاشة "أدواتي".
  /// فارغة قبل أول ضغطة على أي أداة؛ الشاشة تتعامل مع هذا كحالة ابتدائية.
  Future<List<String>> mostUsedToolIds({int limit = 4}) async {
    final rows =
        await (_db.select(_db.toolUsageStats)
              ..orderBy([
                (t) => OrderingTerm.desc(t.tapCount),
                (t) => OrderingTerm.desc(t.lastUsedAt),
              ])
              ..limit(limit))
            .get();
    return rows.map((r) => r.toolId).toList();
  }

  // --- لوحة ألوان صفحة المصحف (راجع MushafColorSettings/mushaf_palettes.dart) ---

  String get mushafPaletteId => _mushafPaletteId;

  Future<void> setMushafPaletteId(String id) async {
    _mushafPaletteId = id;
    await _db
        .into(_db.mushafColorSettings)
        .insertOnConflictUpdate(
          MushafColorSettingsCompanion(
            id: const Value(1),
            paletteId: Value(id),
          ),
        );
  }

  /// وضع "المصحف الليلي" — `off`/`on`/`auto` (راجع توثيق `MushafColorSettings.nightMode`).
  String get mushafNightMode => _mushafNightMode;

  Future<void> setMushafNightMode(String mode) async {
    _mushafNightMode = mode;
    await _db
        .into(_db.mushafColorSettings)
        .insertOnConflictUpdate(
          MushafColorSettingsCompanion(
            id: const Value(1),
            nightMode: Value(mode),
          ),
        );
  }

  // --- لون تمييز التطبيق العام (راجع AppThemeSettings/app_accent_colors.dart) ---

  String get accentColorId => _accentColorId;

  Future<void> setAccentColorId(String id) async {
    _accentColorId = id;
    await _db
        .into(_db.appThemeSettings)
        .insertOnConflictUpdate(
          AppThemeSettingsCompanion(
            id: const Value(1),
            accentColorId: Value(id),
          ),
        );
  }

  // --- إعداد أذكار وأدعية كل ساعة ---

  bool get hourlyDhikrEnabled => _hourlyDhikrEnabled;
  int get hourlyDhikrStartHour => _hourlyDhikrStartHour;
  int get hourlyDhikrEndHour => _hourlyDhikrEndHour;
  int get hourlyDhikrIntervalHours => _hourlyDhikrIntervalHours;

  Future<void> setHourlyDhikr({
    required bool enabled,
    int? startHour,
    int? endHour,
    int? intervalHours,
  }) async {
    _hourlyDhikrEnabled = enabled;
    if (startHour != null) _hourlyDhikrStartHour = startHour;
    if (endHour != null) _hourlyDhikrEndHour = endHour;
    if (intervalHours != null) _hourlyDhikrIntervalHours = intervalHours;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('hourly_dhikr_enabled', _hourlyDhikrEnabled);
      await sp.setInt('hourly_dhikr_start_hour', _hourlyDhikrStartHour);
      await sp.setInt('hourly_dhikr_end_hour', _hourlyDhikrEndHour);
      await sp.setInt('hourly_dhikr_interval_hours', _hourlyDhikrIntervalHours);
    } catch (_) {}
  }

  // --- تكرار عام (بالدقائق) لأي تذكير — راجع توثيق [_reminderIntervalMinutes] ---

  /// `null` = مرة واحدة (السلوك الافتراضي، بلا تكرار).
  int? reminderIntervalMinutesFor(String category) =>
      _reminderIntervalMinutes[category];

  Future<void> setReminderIntervalMinutes(String category, int? minutes) async {
    if (minutes == null) {
      _reminderIntervalMinutes.remove(category);
    } else {
      _reminderIntervalMinutes[category] = minutes;
    }
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
        'reminder_interval_minutes_map',
        jsonEncode(_reminderIntervalMinutes),
      );
    } catch (_) {}
  }

  // --- إعداد متابعة "هل صليت؟" (راجع PrayerCheckinSettings) ---

  bool get prayerCheckinEnabled => _prayerCheckinEnabled;
  int get prayerCheckinFirstDelayMinutes => _prayerCheckinFirstDelayMinutes;

  Future<void> setPrayerCheckinSettings({
    required bool enabled,
    int? firstDelayMinutes,
  }) async {
    _prayerCheckinEnabled = enabled;
    if (firstDelayMinutes != null) {
      _prayerCheckinFirstDelayMinutes = firstDelayMinutes;
    }
    await _db
        .into(_db.prayerCheckinSettings)
        .insertOnConflictUpdate(
          PrayerCheckinSettingsCompanion(
            id: const Value(1),
            enabled: Value(_prayerCheckinEnabled),
            firstDelayMinutes: Value(_prayerCheckinFirstDelayMinutes),
          ),
        );
  }

  // --- تنبيه "أذكار بعد الصلاة" (مستقل عن متابعة "هل صليت؟" أعلاه) ---

  bool get postPrayerAzkarEnabled => _postPrayerAzkarEnabled;
  int get postPrayerAzkarDelayMinutes => _postPrayerAzkarDelayMinutes;

  Future<void> setPostPrayerAzkarSettings({
    required bool enabled,
    int? delayMinutes,
  }) async {
    _postPrayerAzkarEnabled = enabled;
    if (delayMinutes != null) _postPrayerAzkarDelayMinutes = delayMinutes;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('post_prayer_azkar_enabled', _postPrayerAzkarEnabled);
      await sp.setInt(
        'post_prayer_azkar_delay_minutes',
        _postPrayerAzkarDelayMinutes,
      );
    } catch (_) {}
  }

  // --- الموقع لمواقيت الصلاة/القبلة ---

  double? get lat => _lat;
  double? get lon => _lon;
  String? get cityName => _cityName;
  bool get hasLocation => _lat != null && _lon != null;

  Future<void> setLocation({
    required double lat,
    required double lon,
    required String cityName,
  }) async {
    _lat = lat;
    _lon = lon;
    _cityName = cityName;
    await _db
        .into(_db.locationSettings)
        .insertOnConflictUpdate(
          LocationSettingsCompanion(
            id: const Value(1),
            lat: Value(lat),
            lon: Value(lon),
            cityName: Value(cityName),
          ),
        );
  }

  String get calculationMethod => _calcMethod;

  Future<void> setCalculationMethod(String key) async {
    _calcMethod = key;
    await _db
        .into(_db.locationSettings)
        .insertOnConflictUpdate(
          LocationSettingsCompanion(id: const Value(1), calcMethod: Value(key)),
        );
  }

  // --- المسبحة ---

  int get tasbihCount => _tasbihCount;

  Future<void> setTasbihCount(int value) async {
    _tasbihCount = value;
    await _db
        .into(_db.tasbihCounter)
        .insertOnConflictUpdate(
          TasbihCounterCompanion(id: const Value(1), count: Value(value)),
        );
  }

  // --- هجرة لمرة واحدة من SharedPreferences (راجع prefs_migration.dart) ---

  /// يكتب قيماً خاماً مباشرة إلى drift بلا لمس الذاكرة المؤقتة (تُحمَّل
  /// أصلاً بـ[preload] بعد الهجرة مباشرة) وبلا منطق الأعمال المعتاد
  /// (مثلاً بتاريخ بدء ختمة أصلي محفوظ لا `DateTime.now()`). يُستخدم
  /// **فقط** أثناء الهجرة لمرة واحدة.
  Future<void> restoreMigratedData({
    int? lastPage,
    int? streakDays,
    String? streakLastDay,
    DateTime? khatmaStartDate,
    int? khatmaTargetDays,
  }) async {
    await _db.transaction(() async {
      if (lastPage != null || streakDays != null || streakLastDay != null) {
        await _db
            .into(_db.readingProgress)
            .insertOnConflictUpdate(
              ReadingProgressCompanion(
                id: const Value(1),
                lastPage: lastPage == null
                    ? const Value.absent()
                    : Value(lastPage),
                streakDays: streakDays == null
                    ? const Value.absent()
                    : Value(streakDays),
                streakLastDay: streakLastDay == null
                    ? const Value.absent()
                    : Value(streakLastDay),
              ),
            );
      }
      if (khatmaStartDate != null && khatmaTargetDays != null) {
        final existingKhatma = await (_db.select(
          _db.khatmaPlans,
        )..where((t) => t.startDate.equals(khatmaStartDate))).get();
        if (existingKhatma.isEmpty) {
          await _db
              .into(_db.khatmaPlans)
              .insert(
                KhatmaPlansCompanion.insert(
                  startDate: khatmaStartDate,
                  targetDays: khatmaTargetDays,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
    });
  }

  // --- ملاحظات الآيات (راجع AyahNotes/ayah_actions_sheet.dart) ---
  // استعلام مباشر عند الطلب لا تحميل بالذاكرة — ملاحظات نادرة العدد مقارنة
  // بالفواصل، لا حاجة preload بالإقلاع.

  Future<String?> noteForAyah(int ayahId) async {
    final row = await (_db.select(
      _db.ayahNotes,
    )..where((t) => t.ayahId.equals(ayahId))).getSingleOrNull();
    return row?.noteText;
  }

  Future<void> setNoteForAyah(int ayahId, String text) async {
    await _db
        .into(_db.ayahNotes)
        .insertOnConflictUpdate(
          AyahNotesCompanion.insert(
            ayahId: Value(ayahId),
            noteText: text,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> clearNoteForAyah(int ayahId) async {
    await (_db.delete(
      _db.ayahNotes,
    )..where((t) => t.ayahId.equals(ayahId))).go();
  }

  /// كل معرّفات الآيات التي عليها ملاحظة — لعلامة صغيرة على الآية بصفحة
  /// المصحف نفسها (بلا تحميل نص الملاحظات، فقط المعرّفات). راجع
  /// `mushaf_page_widget.dart` (`_notedAyahIdsProvider`).
  Future<Set<int>> notedAyahIds() async {
    final rows = await _db.select(_db.ayahNotes).get();
    return rows.map((r) => r.ayahId).toSet();
  }

  /// كل الملاحظات، الأحدث تعديلاً أولاً — لشاشة "ملاحظاتي" (`notes_screen.dart`).
  Future<List<AyahNote>> allNotes() async {
    return (_db.select(
      _db.ayahNotes,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  // --- عادات مخصّصة (راجع توثيق [CustomHabit]/[CustomHabits]) ---

  List<CustomHabit> get customHabits => List.unmodifiable(_customHabits);

  Future<CustomHabit> createCustomHabit({
    required String title,
    int targetDaily = 1,
    int? reminderHour,
    int reminderMinute = 0,
  }) async {
    final now = DateTime.now();
    final id = await _db
        .into(_db.customHabits)
        .insert(
          CustomHabitsCompanion.insert(
            title: title,
            targetDaily: Value(targetDaily),
            reminderHour: Value(reminderHour),
            reminderMinute: Value(reminderMinute),
            remindersEnabled: Value(reminderHour != null),
            createdAt: now,
          ),
        );
    final habit = CustomHabit(
      id: id,
      title: title,
      targetDaily: targetDaily,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      remindersEnabled: reminderHour != null,
      createdAt: now,
    );
    _customHabits = [..._customHabits, habit];
    return habit;
  }

  /// حذف حقيقي (`active = false`، لا تُقرأ ثانية بـ[preload]) — نفس
  /// `cancelHifzPlan`. سجلّات `CustomHabitLogs` القديمة تبقى بقاعدة البيانات
  /// (لا فائدة حذفها، ولا تُقرأ ثانية لعادة غير نشطة).
  Future<void> deleteCustomHabit(int habitId) async {
    _customHabits = _customHabits.where((h) => h.id != habitId).toList();
    await (_db.update(_db.customHabits)..where((t) => t.id.equals(habitId)))
        .write(const CustomHabitsCompanion(active: Value(false)));
  }

  Future<void> setCustomHabitReminder(
    int habitId, {
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    final index = _customHabits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;
    final habit = _customHabits[index];
    final newHour = hour ?? habit.reminderHour;
    final newMinute = minute ?? habit.reminderMinute;
    final updated = CustomHabit(
      id: habit.id,
      title: habit.title,
      targetDaily: habit.targetDaily,
      reminderHour: newHour,
      reminderMinute: newMinute,
      remindersEnabled: enabled,
      createdAt: habit.createdAt,
    );
    _customHabits = [..._customHabits]..[index] = updated;
    await (_db.update(
      _db.customHabits,
    )..where((t) => t.id.equals(habitId))).write(
      CustomHabitsCompanion(
        remindersEnabled: Value(enabled),
        reminderHour: newHour == null ? const Value.absent() : Value(newHour),
        reminderMinute: Value(newMinute),
      ),
    );
  }

  Future<int> customHabitProgressFor(int habitId, String dateKey) async {
    final row =
        await (_db.select(_db.customHabitLogs)..where(
              (t) => t.habitId.equals(habitId) & t.dateKey.equals(dateKey),
            ))
            .getSingleOrNull();
    return row?.count ?? 0;
  }

  Future<int> customHabitProgressToday(int habitId) =>
      customHabitProgressFor(habitId, _dateKey(DateTime.now()));

  /// يضيف `delta` لتقدّم اليوم (لا يستبدله) في معاملة ذرّية — نفس مبدأ [addQiyamAyahCount].
  /// لو وصل التقدّم الجديد لهدف العادة اليومي، يبمب سلسلة الاستمرار
  /// المجمَّعة [UserCategories.customHabitsAny] (راجع توثيقها) — دفاعي
  /// بلا شرط "أول مرة اليوم" هون تحديداً، [bumpCategoryStreakIfNewDay]
  /// نفسها لا تفعل شيئاً لو نُودِيت مرتين بنفس اليوم.
  Future<int> addCustomHabitProgress(int habitId, {int delta = 1}) async {
    final today = _dateKey(DateTime.now());
    final next = await _db.transaction(() async {
      final row =
          await (_db.select(_db.customHabitLogs)..where(
                (t) => t.habitId.equals(habitId) & t.dateKey.equals(today),
              ))
              .getSingleOrNull();
      final current = row?.count ?? 0;
      final calculated = (current + delta).clamp(0, 1 << 30);
      await _db
          .into(_db.customHabitLogs)
          .insertOnConflictUpdate(
            CustomHabitLogsCompanion.insert(
              habitId: habitId,
              dateKey: today,
              count: Value(calculated),
            ),
          );
      return calculated;
    });

    final habitIndex = _customHabits.indexWhere((h) => h.id == habitId);
    final habit = habitIndex == -1 ? null : _customHabits[habitIndex];
    if (habit != null && next >= habit.targetDaily) {
      await bumpCategoryStreakIfNewDay(UserCategories.customHabitsAny);
    }
    return next;
  }

  /// سلسلة الاستمرار **تُحسَب مباشرة من `CustomHabitLogs`** (لا كاش منفصل
  /// كـ[CategoryStreaks]) — عدد صحيح متوقَّع لعدد عادات صغير، راجع توثيق
  /// الجدول بـ`user_tables.dart`. يومٌ "تمّ" فيه = وصل تقدّمه لهدفه اليومي
  /// (`targetDaily`) أو أكثر. يتوقّف عند أول يوم مقطوع بالرجوع للخلف من
  /// اليوم (أو من أمس لو اليوم لسا ناقص، حتى لا تُصفَّر السلسلة بمجرّد عدم
  /// إتمام هدف اليوم بعد قبل انتهائه).
  Future<int> customHabitStreakDays(int habitId, int targetDaily) async {
    final rows = await (_db.select(
      _db.customHabitLogs,
    )..where((t) => t.habitId.equals(habitId))).get();
    final doneByDate = {
      for (final r in rows) r.dateKey: r.count >= targetDaily,
    };
    var cursor = DateTime.now();
    if (doneByDate[_dateKey(cursor)] != true) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (doneByDate[_dateKey(cursor)] == true) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // --- سجل القراءة/الاستماع/السبحات التراكمي (راجع ReadingLog/AudioLog/
  // TasbihLog بـ`user_tables.dart`) — دفاتر تراكمية (صف لكل جلسة/دفعة، لا
  // صف محدَّث لكل يوم كـ[CategoryDailyLog])، تُجمَّع بالاستعلام عند الطلب.
  // نتائج التجميع (لا الصفوف الخام) تُخزَّن بذاكرة مؤقتة قصيرة العمر
  // (دقيقة واحدة) بمفتاح المدى المطلوب — أكثر من مستهلك (بطاقة "ورد
  // اليوم"، التقرير الأسبوعي، الرئيسية) يطلب نفس المدى تقريباً بنفس اللحظة.

  final Map<int, ({int pages, int ayahs, int minutes, DateTime cachedAt})>
  _readingLogCache = {};
  final Map<int, ({int minutes, DateTime cachedAt})> _audioLogCache = {};
  final Map<String, DateTime?> _tasbihLastCompletedCache = {};

  static const _logCacheTtl = Duration(minutes: 1);

  /// يسجّل جلسة قراءة واحدة (فرق صفحات موجب عادةً) — لا شيء لو كل القيم
  /// صفر (تجنّباً لصفوف فارغة عديمة الفائدة عند كل زيارة صفحة بلا تقدّم فعلي).
  Future<void> logReadingSession({
    required int pagesRead,
    int ayahsRead = 0,
    int minutesSpent = 0,
  }) async {
    if (pagesRead <= 0 && ayahsRead <= 0 && minutesSpent <= 0) return;
    try {
      await _db
          .into(_db.readingLog)
          .insert(
            ReadingLogCompanion.insert(
              dateDay: _isoDateKey(DateTime.now()),
              pagesRead: Value(pagesRead),
              ayahsRead: Value(ayahsRead),
              minutesSpent: Value(minutesSpent),
            ),
          );
      _readingLogCache.clear();
    } catch (e) {
      debugPrint('تعذّر تسجيل جلسة قراءة: $e');
    }
  }

  /// يسجّل دفعة ثوانٍ استماع فعلي (كل ٣٠ ثانية تشغيل أو عند الإيقاف، راجع
  /// `quran_audio_controller.dart`).
  Future<void> logAudioSeconds(int seconds) async {
    if (seconds <= 0) return;
    try {
      await _db
          .into(_db.audioLog)
          .insert(
            AudioLogCompanion.insert(
              dateDay: _isoDateKey(DateTime.now()),
              seconds: Value(seconds),
            ),
          );
      _audioLogCache.clear();
    } catch (e) {
      debugPrint('تعذّر تسجيل ثواني استماع: $e');
    }
  }

  /// يسجّل إتمام سبحة/ذكر بعدد مستهدف (`azkarKey` يطابق مفتاح السبحة
  /// الثابت بمكتبة `tasbih_screen.dart`).
  Future<void> logTasbihCompletion(String azkarKey, int count) async {
    try {
      await _db
          .into(_db.tasbihLog)
          .insert(
            TasbihLogCompanion.insert(
              dateDay: _isoDateKey(DateTime.now()),
              azkarKey: azkarKey,
              count: Value(count),
              completedAt: DateTime.now(),
            ),
          );
      _tasbihLastCompletedCache.remove(azkarKey);
    } catch (e) {
      debugPrint('تعذّر تسجيل إتمام سبحة "$azkarKey": $e');
    }
  }

  /// إجمالي الصفحات/الآيات/الدقائق المقروءة خلال آخر [days] يوماً تقويمياً
  /// (اليوم ضمنها).
  Future<({int pages, int ayahs, int minutes})> getReadingLog(int days) async {
    final cached = _readingLogCache[days];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _logCacheTtl) {
      return (
        pages: cached.pages,
        ayahs: cached.ayahs,
        minutes: cached.minutes,
      );
    }
    try {
      final keys = {
        for (var i = 0; i < days; i++)
          _isoDateKey(DateTime.now().subtract(Duration(days: i))),
      };
      final rows = await (_db.select(
        _db.readingLog,
      )..where((t) => t.dateDay.isIn(keys))).get();
      var pages = 0, ayahs = 0, minutes = 0;
      for (final r in rows) {
        pages += r.pagesRead;
        ayahs += r.ayahsRead;
        minutes += r.minutesSpent;
      }
      _readingLogCache[days] = (
        pages: pages,
        ayahs: ayahs,
        minutes: minutes,
        cachedAt: DateTime.now(),
      );
      return (pages: pages, ayahs: ayahs, minutes: minutes);
    } catch (e) {
      debugPrint('تعذّر جلب سجل القراءة لآخر $days يوم: $e');
      return (pages: 0, ayahs: 0, minutes: 0);
    }
  }

  /// إجمالي دقائق الاستماع للتلاوة خلال آخر [days] يوماً تقويمياً (اليوم ضمنها).
  Future<int> getAudioMinutes(int days) async {
    final cached = _audioLogCache[days];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _logCacheTtl) {
      return cached.minutes;
    }
    try {
      final keys = {
        for (var i = 0; i < days; i++)
          _isoDateKey(DateTime.now().subtract(Duration(days: i))),
      };
      final rows = await (_db.select(
        _db.audioLog,
      )..where((t) => t.dateDay.isIn(keys))).get();
      final totalSeconds = rows.fold<int>(0, (sum, r) => sum + r.seconds);
      final minutes = totalSeconds ~/ 60;
      _audioLogCache[days] = (minutes: minutes, cachedAt: DateTime.now());
      return minutes;
    } catch (e) {
      debugPrint('تعذّر جلب دقائق الاستماع لآخر $days يوم: $e');
      return 0;
    }
  }

  // --- استعادة/دمج من مزامنة سحابية اختيارية (راجع cloud_sync_service.dart) ---
  // بلا حلّ تعارض عام على مستوى كل حقل — راجع توثيق `CloudSyncController.
  // syncNow` لسبب هذا التبسيط المتعمَّد. القوائم/المجموعات (بحكم طبيعتها
  // المستقلة عن بعضها) تُدمَج اتحادياً بأمان (لا فقدان بيانات محلية)،
  // أما خطط الختمة/الحفظ (كيانات ذات تقدّم حيّ معقّد) فتُستعاد **فقط** لو
  // الجهاز الحالي بلا أي خطة محلية أصلاً (لا خطر استبدال تقدّم حقيقي).

  Future<void> restoreKhatmaPlansIfEmpty(
    List<Map<String, dynamic>> plans,
  ) async {
    if (_khatmaPlans.isNotEmpty || plans.isEmpty) return;
    try {
      await _db.batch((batch) {
        batch.insertAll(_db.khatmaPlans, [
          for (final p in plans)
            KhatmaPlansCompanion.insert(
              startDate: DateTime.parse(p['startDate'] as String),
              targetDays: p['targetDays'] as int,
              startPage: Value(p['startPage'] as int? ?? 1),
              currentPage: Value(p['currentPage'] as int? ?? 1),
            ),
        ]);
      });
      final rows = await (_db.select(
        _db.khatmaPlans,
      )..where((t) => t.active.equals(true))).get();
      _khatmaPlans = [
        for (final r in rows)
          KhatmaPlan(
            id: r.id,
            startDate: r.startDate,
            targetDays: r.targetDays,
            startPage: r.startPage,
            currentPage: r.currentPage,
          ),
      ]..sort((a, b) => b.startDate.compareTo(a.startDate));
    } catch (e) {
      debugPrint('تعذّر استعادة خطط الختمة من السحابة: $e');
    }
  }

  Future<void> restoreHifzPlansIfEmpty(List<Map<String, dynamic>> plans) async {
    if (_hifzPlans.isNotEmpty || plans.isEmpty) return;
    try {
      await _db.batch((batch) {
        batch.insertAll(_db.hifzPlans, [
          for (final p in plans)
            HifzPlansCompanion.insert(
              fromAyahId: p['fromAyahId'] as int,
              toAyahId: p['toAyahId'] as int,
              currentAyahId: p['currentAyahId'] as int,
              createdAt: DateTime.parse(p['createdAt'] as String),
            ),
        ]);
      });
      final rows = await (_db.select(
        _db.hifzPlans,
      )..where((t) => t.active.equals(true))).get();
      _hifzPlans = [
        for (final r in rows)
          HifzPlan(
            id: r.id,
            fromAyahId: r.fromAyahId,
            toAyahId: r.toAyahId,
            currentAyahId: r.currentAyahId,
            createdAt: r.createdAt,
          ),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      for (final plan in _hifzPlans) {
        await _seedHifzReviewRange(
          plan.id,
          plan.fromAyahId,
          plan.currentAyahId,
        );
      }
    } catch (e) {
      debugPrint('تعذّر استعادة خطط الحفظ من السحابة: $e');
    }
  }

  /// دمج اتحادي آمن — يضيف فقط علامات غير موجودة محلياً، لا يحذف شيئاً.
  Future<void> mergeBookmarksFromCloud(List<int> ayahIds) async {
    for (final id in ayahIds) {
      await addBookmarkIfAbsent(id);
    }
  }

  /// نفس مبدأ [mergeBookmarksFromCloud] لكن للأقسام المفضَّلة بمكتبة الأذكار.
  Future<void> mergeAzkarFavoritesFromCloud(List<int> categoryIds) async {
    for (final id in categoryIds) {
      if (!_azkarFavoriteCategoryIds.contains(id)) {
        await toggleAzkarFavorite(id);
      }
    }
  }

  /// إحصاءات اليوم الحالي للملخّص المسائي (راجع `evening_summary_text.dart`)
  /// — تجميعة خفيفة من مصادر موجودة أصلاً (سجلّات القراءة/الاستماع/السبحات
  /// + سلاسل الاستمرار اليومية للصلوات/الأذكار)، بلا جدول مخصَّص جديد.
  Future<({int pages, int minutes, int azkarCount, int prayersConfirmed})>
  eveningSummaryStatsToday() async {
    try {
      final reading = await getReadingLog(1);
      final minutes = await getAudioMinutes(1);

      final today = _isoDateKey(DateTime.now());
      final tasbihRows = await (_db.select(
        _db.tasbihLog,
      )..where((t) => t.dateDay.equals(today))).get();

      const azkarCategories = [
        UserCategories.morningAzkar,
        UserCategories.eveningAzkar,
        UserCategories.nightAzkar,
      ];
      final azkarCount =
          tasbihRows.length + azkarCategories.where(completedTodayFor).length;

      const prayerCategories = [
        UserCategories.fajr,
        UserCategories.dhuhr,
        UserCategories.asr,
        UserCategories.maghrib,
        UserCategories.isha,
      ];
      final prayersConfirmed = prayerCategories.where(completedTodayFor).length;

      return (
        pages: reading.pages,
        minutes: minutes,
        azkarCount: azkarCount,
        prayersConfirmed: prayersConfirmed,
      );
    } catch (e) {
      debugPrint('تعذّر حساب إحصاءات الملخّص المسائي: $e');
      return (pages: 0, minutes: 0, azkarCount: 0, prayersConfirmed: 0);
    }
  }

  /// آخر وقت اكتملت فيه سبحة `azkarKey` (`null` لو لم تكتمل قط).
  Future<DateTime?> getTasbihLastCompleted(String azkarKey) async {
    if (_tasbihLastCompletedCache.containsKey(azkarKey)) {
      return _tasbihLastCompletedCache[azkarKey];
    }
    try {
      final row =
          await (_db.select(_db.tasbihLog)
                ..where((t) => t.azkarKey.equals(azkarKey))
                ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
                ..limit(1))
              .getSingleOrNull();
      final result = row?.completedAt;
      _tasbihLastCompletedCache[azkarKey] = result;
      return result;
    } catch (e) {
      debugPrint('تعذّر جلب آخر إتمام لسبحة "$azkarKey": $e');
      return null;
    }
  }
}
