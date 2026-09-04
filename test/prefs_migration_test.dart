import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/user/prefs_migration.dart';
import 'package:humam_app/core/data/user/user_database.dart';
import 'package:humam_app/core/data/user/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late UserDatabase db;
  late UserRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'bookmarked_ayah_ids': ['1', '2', '3'],
      'last_read_page': 42,
      'reading_streak_days': 5,
      'reading_streak_last_day': '2026-8-24',
      'khatma_start_date_millis': DateTime(2026, 8, 1).millisecondsSinceEpoch,
      'khatma_target_days': 30,
      'audio_reciter_id': 'minshawi',
      'audio_playback_speed': 1.25,
      'prayer_lat': 31.95,
      'prayer_lon': 35.91,
      'prayer_city_name': 'عمان',
      'prayer_calc_method': 'ummAlQura',
      'tasbih_count': 100,
    });
    db = UserDatabase.forTesting(NativeDatabase.memory());
    repo = UserRepository(db);
  });

  tearDown(() => db.close());

  test('الهجرة تنقل البيانات لأول مرة بنجاح وتضبط علم الهجرة', () async {
    final prefs = await SharedPreferences.getInstance();
    // 1. الهجرة تُنفّذ أولاً
    await migrateSharedPreferencesToUserDb(prefs: prefs, repo: repo);
    // 2. التحميل المسبق يُنفّذ بعدها كما في main.dart
    await repo.preload();

    expect(repo.bookmarkedAyahIds, containsAll([1, 2, 3]));
    expect(repo.lastReadPage, 42);
    expect(repo.streakDays, 5);
    expect(repo.khatmaPlans.length, 1);
    expect(repo.khatmaPlans.first.targetDays, 30);
    expect(prefs.getBool('migrated_user_db_v1'), isTrue);
  });

  test('تشغيل الهجرة مرتين متتاليتين لا يكرر أو يمسح البيانات (Idempotent)', () async {
    final prefs = await SharedPreferences.getInstance();
    await migrateSharedPreferencesToUserDb(prefs: prefs, repo: repo);
    await migrateSharedPreferencesToUserDb(prefs: prefs, repo: repo);

    await repo.preload();
    expect(repo.bookmarkedAyahIds.length, 3);
    expect(repo.bookmarkedAyahIds, {1, 2, 3});
    expect(repo.lastReadPage, 42);
    expect(repo.khatmaPlans.length, 1);
  });

  test('addBookmarkIfAbsent تدرج فقط ولا تزيل العلامة إن كانت موجودة مسبقاً', () async {
    await repo.addBookmarkIfAbsent(10);
    expect(repo.isBookmarked(10), isTrue);

    // استدعاء ثانٍ بنفس المعرف
    await repo.addBookmarkIfAbsent(10);
    expect(repo.isBookmarked(10), isTrue);
    expect(repo.bookmarkedAyahIds.where((id) => id == 10).length, 1);
  });

  test('addQiyamAyahCount يراكم الآيات ذرياً في نفس اليوم', () async {
    const today = '2026-8-24';
    final count1 = await repo.addQiyamAyahCount(today, 10);
    expect(count1, 10);

    final count2 = await repo.addQiyamAyahCount(today, 15);
    expect(count2, 25);
    expect(await repo.qiyamAyahCountFor(today), 25);
  });

  test('addCustomHabitProgress يراكم التقدم ويحدث السلسلة عند بلوغ الهدف', () async {
    final habit = await repo.createCustomHabit(title: 'قراءة سورة الملك', targetDaily: 2);
    final count1 = await repo.addCustomHabitProgress(habit.id, delta: 1);
    expect(count1, 1);
    expect(repo.streakDaysFor(UserCategories.customHabitsAny), 0);

    final count2 = await repo.addCustomHabitProgress(habit.id, delta: 1);
    expect(count2, 2);
    expect(repo.streakDaysFor(UserCategories.customHabitsAny), 1);
  });
}
