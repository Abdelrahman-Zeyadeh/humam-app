import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'user_tables.dart';

part 'user_database.g.dart';

/// `user.db` — **الوحيدة القابلة للكتابة** (تصميم-النظام.md §٢.٢). تُنشأ
/// فارغة عند أول تشغيل وتُهاجَر إليها مفاتيح `SharedPreferences` القديمة
/// مرة واحدة (راجع `prefs_migration.dart`) — المفاتيح القديمة نفسها **لا
/// تُحذف** لإصدارين، شبكة أمان حسب §٢.٥.
@DriftDatabase(
  tables: [
    Bookmarks,
    ReadingProgress,
    KhatmaPlans,
    AudioSettings,
    LocationSettings,
    TasbihCounter,
    CategoryStreaks,
    QiyamSettings,
    AzkarFavorites,
    HifzPlans,
    HifzSettings,
    ActivityReminders,
    AdhanSettings,
    ActivityBookmarks,
    CategoryDailyLog,
    AdhanNotificationSettings,
    MushafColorSettings,
    PrayerCheckinSettings,
    QiyamAyahLog,
    AyahNotes,
    AppThemeSettings,
    CustomHabits,
    CustomHabitLogs,
    HifzAyahReviews,
    ToolUsageStats,
    ReadingLog,
    AudioLog,
    TasbihLog,
    AyahColorTags,
  ],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase() : super(_openConnection());

  /// للاختبارات فقط: اتصال بالذاكرة بدل ملف حقيقي على القرص.
  @visibleForTesting
  UserDatabase.forTesting(super.executor);

  // رُفعت لـ٢١ لإضافة جدول `AyahColorTags` — تصنيف ملوَّن حرّ متعدّد الآيات
  // (راجع توثيقه بـ`user_tables.dart`).
  @override
  int get schemaVersion => 21;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(categoryStreaks);
        await m.createTable(qiyamSettings);
      }
      if (from < 3) {
        await m.createTable(azkarFavorites);
      }
      if (from < 4) {
        await m.createTable(hifzPlans);
        await m.createTable(hifzSettings);
      }
      if (from < 5) {
        await m.createTable(activityReminders);
      }
      if (from < 6) {
        await m.createTable(adhanSettings);
      }
      if (from < 7) {
        await m.createTable(activityBookmarks);
      }
      if (from < 8) {
        await m.createTable(categoryDailyLog);
      }
      if (from < 9) {
        await m.createTable(adhanNotificationSettings);
      }
      if (from < 10) {
        await m.createTable(mushafColorSettings);
        await m.createTable(prayerCheckinSettings);
        await m.createTable(qiyamAyahLog);
      }
      if (from < 11) {
        await m.createTable(ayahNotes);
      }
      if (from < 12) {
        try {
          await m.addColumn(khatmaPlans, khatmaPlans.startPage);
        } catch (_) {}
        try {
          await m.addColumn(khatmaPlans, khatmaPlans.currentPage);
        } catch (_) {}
        // ترحيل: خطط موجودة قبل هذا العمود لا معلومة حقيقية عن نقطة
        // بدايتها (تبقى الافتراضي ١)، لكن **تقدّمها الحالي** معروف —
        // كانت تُحسَب من `ReadingProgress.lastPage` العام، فنطابق
        // `currentPage` معه الآن كي لا يظهر تقدّمها صفراً فجأة بعد
        // الترقية.
        final progress = await (select(
          readingProgress,
        )..where((t) => t.id.equals(1))).getSingleOrNull();
        if (progress?.lastPage case final lastPage?) {
          await (update(khatmaPlans)..where((t) => t.active.equals(true)))
              .write(KhatmaPlansCompanion(currentPage: Value(lastPage)));
        }
      }
      if (from < 13) {
        await m.createTable(appThemeSettings);
      }
      if (from < 14) {
        await m.createTable(customHabits);
        await m.createTable(customHabitLogs);
      }
      if (from < 16) {
        await m.createTable(hifzAyahReviews);
      }
      if (from < 17) {
        await m.createTable(toolUsageStats);
      }
      if (from < 18) {
        await m.createTable(readingLog);
        await m.createTable(audioLog);
        await m.createTable(tasbihLog);
      }
      if (from < 19) {
        try {
          await m.addColumn(mushafColorSettings, mushafColorSettings.nightMode);
        } catch (_) {}
      }
      if (from < 20) {
        try {
          await m.addColumn(audioSettings, audioSettings.liveListenEnabled);
        } catch (_) {}
      }
      if (from < 21) {
        await m.createTable(ayahColorTags);
      }
    },
    beforeOpen: (details) async {
      // شبكة أمان دفاعية لضمان وجود الجداول حتى لو تم تخطي الهجرة أو حدث انقطاع
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "hifz_ayah_reviews" (
          "plan_id" INTEGER NOT NULL,
          "ayah_id" INTEGER NOT NULL,
          "ease_factor" REAL NOT NULL DEFAULT 2.5,
          "interval_days" INTEGER NOT NULL DEFAULT 0,
          "repetitions" INTEGER NOT NULL DEFAULT 0,
          "due_date" TEXT NOT NULL,
          "last_reviewed_at" INTEGER,
          PRIMARY KEY ("plan_id", "ayah_id")
        );
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "custom_habits" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "title" TEXT NOT NULL,
          "target_daily" INTEGER NOT NULL DEFAULT 1,
          "reminder_hour" INTEGER,
          "reminder_minute" INTEGER NOT NULL DEFAULT 0,
          "reminders_enabled" INTEGER NOT NULL DEFAULT 0,
          "active" INTEGER NOT NULL DEFAULT 1,
          "created_at" INTEGER NOT NULL
        );
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "custom_habit_logs" (
          "habit_id" INTEGER NOT NULL,
          "date_key" TEXT NOT NULL,
          "count" INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY ("habit_id", "date_key")
        );
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "tool_usage_stats" (
          "tool_id" TEXT NOT NULL PRIMARY KEY,
          "tap_count" INTEGER NOT NULL DEFAULT 0,
          "last_used_at" INTEGER
        );
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "reading_log" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "date_day" TEXT NOT NULL,
          "pages_read" INTEGER NOT NULL DEFAULT 0,
          "ayahs_read" INTEGER NOT NULL DEFAULT 0,
          "minutes_spent" INTEGER NOT NULL DEFAULT 0
        );
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "audio_log" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "date_day" TEXT NOT NULL,
          "seconds" INTEGER NOT NULL DEFAULT 0
        );
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "tasbih_log" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "date_day" TEXT NOT NULL,
          "azkar_key" TEXT NOT NULL,
          "count" INTEGER NOT NULL DEFAULT 0,
          "completed_at" INTEGER NOT NULL
        );
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "ayah_color_tags" (
          "type" TEXT NOT NULL,
          "ayah_id" INTEGER NOT NULL,
          "tagged_at" INTEGER NOT NULL,
          PRIMARY KEY ("type", "ayah_id")
        );
      ''');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'user.db'));
    return NativeDatabase.createInBackground(file);
  });
}
