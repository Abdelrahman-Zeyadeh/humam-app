/// نماذج بيانات المستخدم المستخدمة مع [UserRepository] — مفكّكة من
/// `user_repository.dart` الأصلي لتقليل حجم الملف، مع إعادة تصديرها
/// من `user_repository.dart` نفسها حتى لا ينكسر أي مستهلك قديم.
library;

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
