// اختبار سلاسل الاستمرار المستقلة لكل نشاط (CategoryStreaks) وتذكير قيام
// الليل (QiyamSettings) — جداول أُضيفت بترقية مخطط user.db من 1 إلى 2.

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
}
