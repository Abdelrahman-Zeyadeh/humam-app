// اختبار سلاسل الاستمرار المستقلة لكل نشاط (CategoryStreaks) وتذكير قيام
// الليل (QiyamSettings) — جداول أُضيفت بترقية مخطط user.db من 1 إلى 2.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/user/user_database.dart';
import 'package:humam_app/core/data/user/user_repository.dart';

void main() {
  late UserDatabase db;
  late UserRepository repo;

  setUp(() async {
    db = UserDatabase.forTesting(NativeDatabase.memory());
    repo = UserRepository(db);
    await repo.preload();
  });

  tearDown(() => db.close());

  test('سلسلة فئة جديدة تبدأ بصفر ولا تُسجَّل قبل أول استدعاء', () {
    expect(repo.streakDaysFor(UserCategories.morningAzkar), 0);
    expect(repo.completedTodayFor(UserCategories.morningAzkar), isFalse);
  });

  test('أول استدعاء بيوم واحد يرفع السلسلة لـ١ ويسجّل اكتمال اليوم', () async {
    await repo.bumpCategoryStreakIfNewDay(UserCategories.hifz);
    expect(repo.streakDaysFor(UserCategories.hifz), 1);
    expect(repo.completedTodayFor(UserCategories.hifz), isTrue);
  });

  test('استدعاء ثانٍ بنفس اليوم لا يزيد السلسلة (لا تكرار)', () async {
    await repo.bumpCategoryStreakIfNewDay(UserCategories.qiyam);
    await repo.bumpCategoryStreakIfNewDay(UserCategories.qiyam);
    expect(repo.streakDaysFor(UserCategories.qiyam), 1);
  });

  test('فئتان مستقلتان تماماً — تحديث واحدة لا يغيّر الأخرى', () async {
    await repo.bumpCategoryStreakIfNewDay(UserCategories.morningAzkar);
    expect(repo.streakDaysFor(UserCategories.eveningAzkar), 0);
    expect(repo.streakDaysFor(UserCategories.nightAzkar), 0);
  });

  test('القيمة تُحفَظ فعلياً بـuser.db وتُقرَأ بعد preload جديد على نفس الاتصال', () async {
    await repo.bumpCategoryStreakIfNewDay(UserCategories.nightAzkar);
    final repo2 = UserRepository(db);
    await repo2.preload();
    expect(repo2.streakDaysFor(UserCategories.nightAzkar), 1);
  });

  test('تذكير قيام الليل: القيمة الافتراضية معطّلة وبلا ساعة', () {
    expect(repo.qiyamEnabled, isFalse);
    expect(repo.qiyamHour, isNull);
  });

  test('setQiyamReminder يحفظ الساعة/الدقيقة والتفعيل ويبقى بعد preload جديد', () async {
    await repo.setQiyamReminder(enabled: true, hour: 2, minute: 30);
    expect(repo.qiyamEnabled, isTrue);
    expect(repo.qiyamHour, 2);
    expect(repo.qiyamMinute, 30);

    final repo2 = UserRepository(db);
    await repo2.preload();
    expect(repo2.qiyamEnabled, isTrue);
    expect(repo2.qiyamHour, 2);
    expect(repo2.qiyamMinute, 30);
  });

  test('تعطيل التذكير لا يمسح الساعة المختارة سابقاً', () async {
    await repo.setQiyamReminder(enabled: true, hour: 3, minute: 0);
    await repo.setQiyamReminder(enabled: false);
    expect(repo.qiyamEnabled, isFalse);
    expect(repo.qiyamHour, 3);
  });

  test('مفضّلة مكتبة الأذكار: تبديل يضيف ويزيل، ويبقى بعد preload جديد', () async {
    expect(repo.isAzkarFavorite(28), isFalse);
    await repo.toggleAzkarFavorite(28);
    expect(repo.isAzkarFavorite(28), isTrue);
    expect(repo.azkarFavoriteCategoryIds, contains(28));

    final repo2 = UserRepository(db);
    await repo2.preload();
    expect(repo2.isAzkarFavorite(28), isTrue);

    await repo.toggleAzkarFavorite(28);
    expect(repo.isAzkarFavorite(28), isFalse);
  });

  test('"الورد اليومي" يبقى بآلية ReadingProgress القديمة، لا CategoryStreaks', () async {
    await repo.bumpStreakIfNewDay();
    expect(repo.streakDays, 1);
    // dailyWird لا صف له بجدول الفئات المستقلة أصلاً.
    expect(repo.streakDaysFor(UserCategories.dailyWird), 0);
  });

  group('خطة الحفظ', () {
    test('لا خطط افتراضياً', () {
      expect(repo.hifzPlans, isEmpty);
    });

    test('startHifzPlan تبدأ خطة بمؤشر تقدّم = آية البداية', () async {
      await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      final plan = repo.hifzPlans.single;
      expect(plan.fromAyahId, 10);
      expect(plan.toAyahId, 20);
      expect(plan.currentAyahId, 10);
      expect(plan.progress, closeTo(1 / 11, 0.0001));
    });

    test('updateHifzCurrentAyah تحدّث المؤشر **بلا لمس** lastReadPage/سلسلة القراءة', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 15);
      expect(repo.hifzPlans.single.currentAyahId, 15);
      expect(repo.lastReadPage, isNull);
      expect(repo.streakDays, 0);
    });

    test('updateHifzCurrentAyah تُحصر ضمن حدود النطاق', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 999);
      expect(repo.hifzPlans.single.currentAyahId, 20);
      await repo.updateHifzCurrentAyah(plan.id, 1);
      expect(repo.hifzPlans.single.currentAyahId, 10);
    });

    test('خطة جديدة تُضاف فوق القديمة — لا تحذفها ولا تُعطِّلها (بطلب صاحب المشروع)', () async {
      final first = await repo.startHifzPlan(fromAyahId: 1, toAyahId: 5);
      final second = await repo.startHifzPlan(fromAyahId: 50, toAyahId: 60);
      expect(repo.hifzPlans.map((p) => p.id), containsAll([first.id, second.id]));
      expect(repo.hifzPlans.length, 2);

      final repo2 = UserRepository(db);
      await repo2.preload();
      expect(repo2.hifzPlans.length, 2);
      expect(repo2.hifzPlans.map((p) => p.fromAyahId), containsAll([1, 50]));
    });

    test('cancelHifzPlan تحذف خطة واحدة بعينها فقط، وتترك الأخرى بتقدّمها وتاريخها', () async {
      final first = await repo.startHifzPlan(fromAyahId: 1, toAyahId: 5);
      final second = await repo.startHifzPlan(fromAyahId: 50, toAyahId: 60);
      await repo.updateHifzCurrentAyah(second.id, 55);

      await repo.cancelHifzPlan(first.id);

      expect(repo.hifzPlans.length, 1);
      expect(repo.hifzPlans.single.id, second.id);
      expect(repo.hifzPlans.single.currentAyahId, 55);
    });

    test('setHifzReminder يحفظ الساعة/الدقيقة والتفعيل ويبقى بعد preload جديد', () async {
      await repo.setHifzReminder(enabled: true, hour: 20, minute: 15);
      expect(repo.hifzEnabled, isTrue);
      expect(repo.hifzHour, 20);

      final repo2 = UserRepository(db);
      await repo2.preload();
      expect(repo2.hifzEnabled, isTrue);
      expect(repo2.hifzHour, 20);
      expect(repo2.hifzMinute, 15);
    });
  });

  group('تذكيرات أنشطة عامة (أذكار الصباح/المساء، الورد اليومي)', () {
    test('لا تفعيل افتراضياً', () {
      expect(repo.reminderEnabledFor(UserCategories.morningAzkar), isFalse);
      expect(repo.reminderHourFor(UserCategories.morningAzkar), isNull);
    });

    test('setActivityReminder يحفظ الساعة/الدقيقة والتفعيل ويبقى بعد preload جديد', () async {
      await repo.setActivityReminder(UserCategories.morningAzkar, enabled: true, hour: 6, minute: 30);
      expect(repo.reminderEnabledFor(UserCategories.morningAzkar), isTrue);
      expect(repo.reminderHourFor(UserCategories.morningAzkar), 6);

      final repo2 = UserRepository(db);
      await repo2.preload();
      expect(repo2.reminderEnabledFor(UserCategories.morningAzkar), isTrue);
      expect(repo2.reminderHourFor(UserCategories.morningAzkar), 6);
      expect(repo2.reminderMinuteFor(UserCategories.morningAzkar), 30);
    });

    test('فئتان مستقلتان تماماً — تحديث واحدة لا يغيّر الأخرى', () async {
      await repo.setActivityReminder(UserCategories.morningAzkar, enabled: true, hour: 6, minute: 0);
      await repo.setActivityReminder(UserCategories.eveningAzkar, enabled: true, hour: 18, minute: 0);
      expect(repo.reminderHourFor(UserCategories.morningAzkar), 6);
      expect(repo.reminderHourFor(UserCategories.eveningAzkar), 18);
    });

    test('تعطيل التذكير لا يمسح الساعة المختارة سابقاً', () async {
      await repo.setActivityReminder(UserCategories.dailyWird, enabled: true, hour: 21, minute: 0);
      await repo.setActivityReminder(UserCategories.dailyWird, enabled: false);
      expect(repo.reminderEnabledFor(UserCategories.dailyWird), isFalse);
      expect(repo.reminderHourFor(UserCategories.dailyWird), 21);
    });
  });

  test('سلاسل الصلوات الخمس والسنن الرواتب مستقلة تماماً عن بعضها', () async {
    await repo.bumpCategoryStreakIfNewDay(UserCategories.fajr);
    expect(repo.completedTodayFor(UserCategories.fajr), isTrue);
    expect(repo.completedTodayFor(UserCategories.dhuhr), isFalse);
    expect(repo.completedTodayFor(UserCategories.rawatib), isFalse);
  });

  group('صوت الأذان (المؤذن)', () {
    test('الافتراضي "system" بلا اختيار سابق', () {
      expect(repo.adhanVoiceId, 'system');
    });

    test('setAdhanVoiceId يحفظ الاختيار ويبقى بعد preload جديد', () async {
      await repo.setAdhanVoiceId('adhan_saqqaf');
      expect(repo.adhanVoiceId, 'adhan_saqqaf');

      final repo2 = UserRepository(db);
      await repo2.preload();
      expect(repo2.adhanVoiceId, 'adhan_saqqaf');
    });
  });

  group('تفعيل إشعارات الأذان (AdhanNotificationSettings)', () {
    test('مفعَّل افتراضياً بلا صف بعد ("master" وكل صلاة)', () {
      expect(repo.adhanNotifEnabled('master'), isTrue);
      expect(repo.adhanNotifEnabled('fajr'), isTrue);
    });

    test('setAdhanNotifEnabled يحفظ التعطيل ويبقى بعد preload جديد', () async {
      await repo.setAdhanNotifEnabled('fajr', false);
      expect(repo.adhanNotifEnabled('fajr'), isFalse);
      // صلاة أخرى تبقى بلا أثر — مفتاح مستقل لكل صلاة.
      expect(repo.adhanNotifEnabled('dhuhr'), isTrue);

      final repo2 = UserRepository(db);
      await repo2.preload();
      expect(repo2.adhanNotifEnabled('fajr'), isFalse);
      expect(repo2.adhanNotifEnabled('dhuhr'), isTrue);
    });

    test('تعطيل المفتاح العام "master" لا يمسّ مفاتيح الصلوات المستقلة', () async {
      await repo.setAdhanNotifEnabled('master', false);
      expect(repo.adhanNotifEnabled('master'), isFalse);
      expect(repo.adhanNotifEnabled('isha'), isTrue);
    });
  });

  group('فواصل المصحف (BookmarkTypes)', () {
    test('لا فاصلة مضبوطة افتراضياً لأي نوع', () {
      for (final type in BookmarkTypes.all) {
        expect(repo.activityBookmarkAyah(type), isNull);
      }
    });

    test('setActivityBookmark يضبط الفاصلة ويبقى بعد preload جديد', () async {
      await repo.setActivityBookmark(BookmarkTypes.hifz, 500);
      expect(repo.activityBookmarkAyah(BookmarkTypes.hifz), 500);

      final repo2 = UserRepository(db);
      await repo2.preload();
      expect(repo2.activityBookmarkAyah(BookmarkTypes.hifz), 500);
    });

    test('ضبط فاصلة جديدة لنفس النوع يستبدل القديمة (مخزن أحادي)', () async {
      await repo.setActivityBookmark(BookmarkTypes.reading, 10);
      await repo.setActivityBookmark(BookmarkTypes.reading, 20);
      expect(repo.activityBookmarkAyah(BookmarkTypes.reading), 20);
    });

    test('الأنواع مستقلة تماماً عن بعضها', () async {
      await repo.setActivityBookmark(BookmarkTypes.tadabbur, 7);
      expect(repo.activityBookmarkAyah(BookmarkTypes.review), isNull);
      expect(repo.activityBookmarkAyah(BookmarkTypes.hifz), isNull);
    });

    test('clearActivityBookmark تمسح الفاصلة', () async {
      await repo.setActivityBookmark(BookmarkTypes.review, 99);
      await repo.clearActivityBookmark(BookmarkTypes.review);
      expect(repo.activityBookmarkAyah(BookmarkTypes.review), isNull);
    });
  });

  group('سجلّ الإتمام الأسبوعي (weekCompletionFor)', () {
    test('٧ عناصر كلها false قبل أي تسجيل', () async {
      final week = await repo.weekCompletionFor(UserCategories.qiyam);
      expect(week, hasLength(7));
      expect(week.every((d) => d == false), isTrue);
    });

    test('بعد bumpCategoryStreakIfNewDay اليوم (آخر عنصر) يصير true فقط', () async {
      await repo.bumpCategoryStreakIfNewDay(UserCategories.qiyam);
      final week = await repo.weekCompletionFor(UserCategories.qiyam);
      expect(week.last, isTrue);
      expect(week.sublist(0, 6).every((d) => d == false), isTrue);
    });

    test('فئتان مستقلتان — تسجيل واحدة لا يظهر بسجلّ الأخرى', () async {
      await repo.bumpCategoryStreakIfNewDay(UserCategories.sunnahFajrQabliyah);
      final week = await repo.weekCompletionFor(UserCategories.sunnahAsrQabliyah);
      expect(week.every((d) => d == false), isTrue);
    });
  });

  group('عادات مخصّصة (CustomHabits)', () {
    test('لا عادات افتراضياً', () {
      expect(repo.customHabits, isEmpty);
    });

    test('createCustomHabit تنشئ عادة بالقيم الافتراضية (هدف=١، بلا تذكير)', () async {
      final habit = await repo.createCustomHabit(title: 'قراءة كتاب ديني');
      expect(habit.title, 'قراءة كتاب ديني');
      expect(habit.targetDaily, 1);
      expect(habit.reminderHour, isNull);
      expect(habit.remindersEnabled, isFalse);
      expect(repo.customHabits.single.id, habit.id);
    });

    test('addCustomHabitProgress يتراكم بدل الاستبدال، ويُقرأ بنفس اليوم', () async {
      final habit = await repo.createCustomHabit(title: 'أذكار إضافية', targetDaily: 3);
      await repo.addCustomHabitProgress(habit.id);
      final next = await repo.addCustomHabitProgress(habit.id, delta: 2);
      expect(next, 3);
      expect(await repo.customHabitProgressToday(habit.id), 3);
    });

    test('عادتان مستقلتان تماماً — تقدّم واحدة لا يغيّر الأخرى', () async {
      final a = await repo.createCustomHabit(title: 'أ');
      final b = await repo.createCustomHabit(title: 'ب');
      await repo.addCustomHabitProgress(a.id, delta: 5);
      expect(await repo.customHabitProgressToday(b.id), 0);
    });

    test('الوصول للهدف اليومي يبمب سلسلة customHabitsAny المجمَّعة', () async {
      final habit = await repo.createCustomHabit(title: 'مشي', targetDaily: 2);
      expect(repo.completedTodayFor(UserCategories.customHabitsAny), isFalse);
      await repo.addCustomHabitProgress(habit.id); // ١ من ٢ — لسا لم يكتمل
      expect(repo.completedTodayFor(UserCategories.customHabitsAny), isFalse);
      await repo.addCustomHabitProgress(habit.id); // ٢ من ٢ — اكتمل
      expect(repo.completedTodayFor(UserCategories.customHabitsAny), isTrue);
      expect(repo.streakDaysFor(UserCategories.customHabitsAny), 1);
    });

    test('customHabitStreakDays: صفر بلا أي تسجيل، ١ بعد تسجيل اليوم فقط', () async {
      final habit = await repo.createCustomHabit(title: 'تسبيح');
      expect(await repo.customHabitStreakDays(habit.id, habit.targetDaily), 0);
      await repo.addCustomHabitProgress(habit.id);
      expect(await repo.customHabitStreakDays(habit.id, habit.targetDaily), 1);
    });

    test('deleteCustomHabit تحذف عادة واحدة بعينها فقط، وتترك الأخرى', () async {
      final a = await repo.createCustomHabit(title: 'أ');
      final b = await repo.createCustomHabit(title: 'ب');
      await repo.deleteCustomHabit(a.id);
      expect(repo.customHabits.map((h) => h.id), [b.id]);

      final repo2 = UserRepository(db);
      await repo2.preload();
      expect(repo2.customHabits.length, 1);
      expect(repo2.customHabits.single.id, b.id);
    });

    test('setCustomHabitReminder يحفظ الساعة/الدقيقة والتفعيل ويبقى بعد preload جديد', () async {
      final habit = await repo.createCustomHabit(title: 'قيام فرعي');
      await repo.setCustomHabitReminder(habit.id, enabled: true, hour: 21, minute: 15);
      expect(repo.customHabits.single.remindersEnabled, isTrue);
      expect(repo.customHabits.single.reminderHour, 21);

      final repo2 = UserRepository(db);
      await repo2.preload();
      final reloaded = repo2.customHabits.single;
      expect(reloaded.remindersEnabled, isTrue);
      expect(reloaded.reminderHour, 21);
      expect(reloaded.reminderMinute, 15);
    });

    test('القيم تُحفَظ فعلياً بـuser.db وتُقرَأ بعد preload جديد على نفس الاتصال', () async {
      final habit = await repo.createCustomHabit(title: 'مراجعة', targetDaily: 4);
      await repo.addCustomHabitProgress(habit.id, delta: 2);

      final repo2 = UserRepository(db);
      await repo2.preload();
      expect(repo2.customHabits.single.title, 'مراجعة');
      expect(repo2.customHabits.single.targetDaily, 4);
      expect(await repo2.customHabitProgressToday(habit.id), 2);
    });
  });

  group('خوارزمية SM-2 المبسّطة (applySm2)', () {
    test('quality=0 (لم أتذكر): يصفّر التكرار ويجعل الفاصل يوماً واحداً', () {
      final r = UserRepository.applySm2(
        ease: 2.5,
        intervalDays: 10,
        repetitions: 3,
        quality: 0,
      );
      expect(r.repetitions, 0);
      expect(r.intervalDays, 1);
      expect(r.ease, 2.5); // بلا تغيير على السهولة عند الفشل
    });

    test('أول مراجعة ناجحة: فاصل يوم واحد وتكرار=١', () {
      final r = UserRepository.applySm2(
        ease: 2.5,
        intervalDays: 0,
        repetitions: 0,
        quality: 2,
      );
      expect(r.repetitions, 1);
      expect(r.intervalDays, 1);
    });

    test('ثاني مراجعة ناجحة: فاصل ٦ أيام', () {
      final r = UserRepository.applySm2(
        ease: 2.5,
        intervalDays: 1,
        repetitions: 1,
        quality: 2,
      );
      expect(r.repetitions, 2);
      expect(r.intervalDays, 6);
    });

    test('ثالث مراجعة ناجحة: فاصل = الفاصل السابق × السهولة', () {
      final r = UserRepository.applySm2(
        ease: 2.5,
        intervalDays: 6,
        repetitions: 2,
        quality: 2,
      );
      expect(r.repetitions, 3);
      expect(r.intervalDays, 15); // round(6 * 2.5)
    });

    test('quality=3 (سهل) يزيد السهولة، quality=1 (بصعوبة) يخفّضها', () {
      final easy = UserRepository.applySm2(
        ease: 2.5,
        intervalDays: 1,
        repetitions: 1,
        quality: 3,
      );
      final hard = UserRepository.applySm2(
        ease: 2.5,
        intervalDays: 1,
        repetitions: 1,
        quality: 1,
      );
      expect(easy.ease, greaterThan(2.5));
      expect(hard.ease, lessThan(2.5));
    });

    test('السهولة لا تنزل تحت ١.٣ مهما تكرّر الفشل الطفيف', () {
      var ease = 1.3;
      for (var i = 0; i < 20; i++) {
        ease = UserRepository.applySm2(
          ease: ease,
          intervalDays: 1,
          repetitions: 1,
          quality: 1,
        ).ease;
      }
      expect(ease, greaterThanOrEqualTo(1.3));
    });
  });

  group('مراجعة ذكية لخطط الحفظ (HifzAyahReviews)', () {
    test('بدء خطة يبذر مراجعة الآية الأولى فوراً (بلا انتظار أي تقدّم)', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      expect(await repo.dueHifzAyahIdsForPlan(plan.id), [10]);
    });

    test('updateHifzCurrentAyah يبذر مراجعة لكل آية جديدة بالنطاق المتقدَّم', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 13);
      // ١٠ مبذورة عند بدء الخطة نفسها + ١١،١٢،١٣ من التقدّم الجديد.
      expect(await repo.dueHifzAyahIdsForPlan(plan.id), [10, 11, 12, 13]);
    });

    test('الرجوع لآية سابقة لا يبذر شيئاً جديداً (تقدّم للخلف فقط)', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 15);
      await repo.updateHifzCurrentAyah(plan.id, 12);
      expect(
        await repo.dueHifzAyahIdsForPlan(plan.id),
        [10, 11, 12, 13, 14, 15],
      );
    });

    test('gradeHifzAyahReview بلا صف سابق يبدأ بسهولة ٢.٥ ويحدّد موعداً قادماً', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 10);
      expect(await repo.dueHifzAyahIdsForPlan(plan.id), [10]);

      await repo.gradeHifzAyahReview(plan.id, 10, 2); // جيد — أول مراجعة
      // فاصل يوم واحد بعد أول تقييم ناجح، فلا تظهر ثانية اليوم.
      expect(await repo.dueHifzAyahIdsForPlan(plan.id), isEmpty);
    });

    test('quality=0 (لم أتذكر) يبقيها مستحقّة غداً لا اليوم (فاصل يوم واحد)', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 10);
      await repo.gradeHifzAyahReview(plan.id, 10, 0);
      expect(await repo.dueHifzAyahIdsForPlan(plan.id), isEmpty);
    });

    test('hifzReviewedToday يرجع false بلا أي مراجعة بعد', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 10);
      expect(await repo.hifzReviewedToday(), isFalse);
    });

    test('hifzReviewedToday يرجع true بعد أي تقييم مراجعة اليوم', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 10);
      await repo.gradeHifzAyahReview(plan.id, 10, 2);
      expect(await repo.hifzReviewedToday(), isTrue);
    });

    test('خطتان مستقلتان تماماً — تقدّم واحدة لا يبذر مراجعات بالأخرى', () async {
      final a = await repo.startHifzPlan(fromAyahId: 1, toAyahId: 10);
      final b = await repo.startHifzPlan(fromAyahId: 100, toAyahId: 110);
      await repo.updateHifzCurrentAyah(a.id, 5);
      // (ب) تحصل فقط على بذرة آيتها الأولى (١٠٠) من إنشائها هي، بلا أي أثر
      // لتقدّم (أ).
      expect(await repo.dueHifzAyahIdsForPlan(b.id), [100]);
      expect(await repo.dueHifzAyahIdsForPlan(a.id), [1, 2, 3, 4, 5]);
    });

    test('dueHifzAyahCountForPlan يطابق طول القائمة الفعلية', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.updateHifzCurrentAyah(plan.id, 14);
      expect(await repo.dueHifzAyahCountForPlan(plan.id), 5);
    });

    test(
      'preload يبذر رجعياً لخطة قديمة أُنشئت قبل هذه الميزة (بلا أي صف مراجعة أصلاً)',
      () async {
        // إدخال مباشر بلا المرور بـstartHifzPlan — يحاكي خطة أُنشئت
        // بإصدار سابق للتطبيق لا يعرف HifzAyahReviews إطلاقاً.
        final planId = await db
            .into(db.hifzPlans)
            .insert(
              HifzPlansCompanion.insert(
                fromAyahId: 30,
                toAyahId: 50,
                currentAyahId: 35,
                createdAt: DateTime.now(),
              ),
            );
        expect(await repo.dueHifzAyahIdsForPlan(planId), isEmpty);

        final repo2 = UserRepository(db);
        await repo2.preload();

        expect(
          await repo2.dueHifzAyahIdsForPlan(planId),
          [30, 31, 32, 33, 34, 35],
        );
      },
    );

    test('preload لا يبذر مرّتين لخطة سبق بذرها (لا تكرار عند كل إطلاق)', () async {
      final plan = await repo.startHifzPlan(fromAyahId: 10, toAyahId: 20);
      await repo.gradeHifzAyahReview(plan.id, 10, 3); // يغيّر جدولتها

      final repo2 = UserRepository(db);
      await repo2.preload();

      // لو أعاد preload بذر الآية ١٠ لكانت رجعت لموعد اليوم بلا قصد،
      // ماسحاً تقييم SM-2 الحقيقي اللي عملناه للتو.
      expect(await repo2.dueHifzAyahIdsForPlan(plan.id), isEmpty);
    });
  });

  group('User Name & Sunnah Duha', () {
    test('UserCategories.sunnahDuha قيمة ثابتة ومعرّفة', () {
      expect(UserCategories.sunnahDuha, 'sunnah_duha');
    });

    test('setUserName يحفظ الاسم ويقرؤه عبر repo', () async {
      expect(repo.userName, '');
      await repo.setUserName('أحمد');
      expect(repo.userName, 'أحمد');
    });
  });

  group('إحصاء استخدام أدوات شاشة "أدواتي" (ToolUsageStats)', () {
    test('لا أدوات "أكثر استخدامًا" قبل أي ضغطة', () async {
      expect(await repo.mostUsedToolIds(), isEmpty);
    });

    test('recordToolTap يزيد العدّاد ذرّياً بلا استبدال', () async {
      await repo.recordToolTap('khatma');
      await repo.recordToolTap('khatma');
      await repo.recordToolTap('khatma');
      await repo.recordToolTap('hifz');

      final mostUsed = await repo.mostUsedToolIds();
      // الأكثر ضغطاً أولاً.
      expect(mostUsed.first, 'khatma');
      expect(mostUsed, contains('hifz'));
    });

    test('mostUsedToolIds يحترم limit', () async {
      for (final id in ['a', 'b', 'c', 'd', 'e']) {
        await repo.recordToolTap(id);
      }
      expect(await repo.mostUsedToolIds(limit: 3), hasLength(3));
    });

    test('عند تساوي عدد الضغطات، الأداة الأحدث استخدامًا تسبق', () async {
      // `lastUsedAt` مخزَّن بدقّة الثانية (تخزين drift الافتراضي لـ
      // `DateTimeColumn`) — فارق أقل من ثانية لا يظهر بالترتيب، فاصل
      // الاختبار يتجاوز ثانية كاملة عمداً.
      await repo.recordToolTap('old');
      await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
      await repo.recordToolTap('recent');

      final mostUsed = await repo.mostUsedToolIds();
      expect(mostUsed.first, 'recent');
    });
  });

  group('سجل القراءة/الاستماع/السبحات التراكمي (ReadingLog/AudioLog/TasbihLog)', () {
    test('logAudioSeconds يجمع دفعات متعددة بنفس اليوم — getAudioMinutes(1) يطابق المجموع بالدقائق', () async {
      await repo.logAudioSeconds(30);
      await repo.logAudioSeconds(30);
      await repo.logAudioSeconds(60);
      // ٣٠+٣٠+٦٠ = ١٢٠ ثانية = دقيقتان بالضبط.
      expect(await repo.getAudioMinutes(1), 2);
    });

    test('logAudioSeconds بقيمة صفر أو سالبة لا تُسجَّل (لا صفوف فارغة)', () async {
      await repo.logAudioSeconds(0);
      await repo.logAudioSeconds(-5);
      expect(await repo.getAudioMinutes(30), 0);
    });

    test('getAudioMinutes(days) لا يحسب ثواني خارج المدى المطلوب', () async {
      // صفّ بتاريخ بعيد (قبل ٣٠ يوماً) يُدخَل مباشرة بلا المرور بـ
      // logAudioSeconds (اليوم دائماً "الآن" هناك) — يحاكي نشاطاً قديماً.
      final oldDay = DateTime.now().subtract(const Duration(days: 60));
      final oldKey =
          '${oldDay.year.toString().padLeft(4, '0')}-'
          '${oldDay.month.toString().padLeft(2, '0')}-'
          '${oldDay.day.toString().padLeft(2, '0')}';
      await db.into(db.audioLog).insert(AudioLogCompanion.insert(dateDay: oldKey, seconds: const Value(600)));
      await repo.logAudioSeconds(60);
      expect(await repo.getAudioMinutes(7), 1);
    });

    test('logReadingSession يجمع الصفحات — getReadingLog(1) يطابق المجموع', () async {
      await repo.logReadingSession(pagesRead: 2);
      await repo.logReadingSession(pagesRead: 3, ayahsRead: 10);
      final today = await repo.getReadingLog(1);
      expect(today.pages, 5);
      expect(today.ayahs, 10);
    });

    test('logTasbihCompletion يسجّل و getTasbihLastCompleted يرجع آخر وقت إتمام', () async {
      expect(await repo.getTasbihLastCompleted('istighfar_100'), isNull);
      await repo.logTasbihCompletion('istighfar_100', 100);
      final last = await repo.getTasbihLastCompleted('istighfar_100');
      expect(last, isNotNull);
      expect(DateTime.now().difference(last!).inMinutes, lessThan(1));
    });

    test('سبحتان مستقلتان — إتمام واحدة لا يظهر بسجلّ الأخرى', () async {
      await repo.logTasbihCompletion('morning_tasbih', 100);
      expect(await repo.getTasbihLastCompleted('salawat_100'), isNull);
    });
  });
}
