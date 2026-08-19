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
  ],
)
class UserDatabase extends _$UserDatabase {
  UserDatabase() : super(_openConnection());

  /// للاختبارات فقط: اتصال بالذاكرة بدل ملف حقيقي على القرص.
  @visibleForTesting
  UserDatabase.forTesting(super.executor);

  // رُفعت لـ٣ بإضافة AzkarFavorites (أقسام مفضَّلة بمكتبة حصن المسلم) —
  // فوق ترقية ٢ (CategoryStreaks + QiyamSettings). كل ترقية تنشئ جدولها
  // الجديد فقط بدل إعادة بناء كامل.
  @override
  int get schemaVersion => 3;

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
