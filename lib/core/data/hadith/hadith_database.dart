import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../asset_sqlite_sync.dart';
import 'hadith_tables.dart';

part 'hadith_database.g.dart';

const _kSchemaVersion = 3;

/// قاعدة أحاديث مستقلة عن `quran.db` — **للقراءة فقط**، نفس نمط النسخ من
/// الـ asset عند أول تشغيل (راجع `QuranDatabase`/[syncAssetSqliteDatabase]
/// لشرح مفصّل لنفس النمط، ولماذا فحص إصدار الملف الإضافي عبر الـpragma
/// ضروري لا فحص علم المحتوى وحده).
///
/// **هذا الصف يُستخدَم لاتصالين مختلفين تماماً الآن** (راجع
/// `hadith_db_registry.dart`): الاتصال الافتراضي (asset مضمَّن، الأربعون
/// النووية/القدسية فقط بعد تحويل بقية الكتب لتنزيل حسب الحاجة) عبر
/// المُنشئ الافتراضي، **و**اتصال مباشر بملف كتاب مُنزَّل عبر
/// [HadithDatabase.forDownloadedBook] — نفس تعريفات الجداول تماماً تصلح
/// للاثنين لأن كل ملف شظية (`tools/split_hadith_shards.py`) بنفس المخطط
/// حرفياً.
@DriftDatabase(tables: [HadithBooks, HadithChapters, Hadiths])
class HadithDatabase extends _$HadithDatabase {
  HadithDatabase() : super(_openConnection());

  /// اتصال بملف كتاب مُنزَّل مباشرةً — **بلا** مزامنة asset (الملف نفسه
  /// هو المصدر النهائي، نزّله `HadithDownloadController` فعلاً)، وبلا
  /// فحص `PRAGMA user_version` (الشظايا لا تحمل هذا الرقم أصلاً، تُنشأ
  /// بسكربت بايثون مباشرة لا drift).
  HadithDatabase.forDownloadedBook(File file) : super(NativeDatabase.createInBackground(file));

  @visibleForTesting
  HadithDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => _kSchemaVersion;

  /// شبكة أمان فقط — نفس توثيق `QuranDatabase.migration` حرفياً، نفس
  /// السبب: بلا هذه الدالة drift يرمي استثناءً افتراضياً عند أي تعارض
  /// إصدار بدل أن يبقى بلا أثر (لا هجرة حقيقية مطلوبة لقاعدة للقراءة فقط
  /// تُستبدَل كملف واحد كامل).
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {},
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await syncAssetSqliteDatabase(
      fileName: 'hadith.db',
      assetDbPath: 'assets/hadith/hadith.db',
      assetVersionPath: 'assets/hadith/hadith_db_version.txt',
      expectedSchemaVersion: _kSchemaVersion,
    );
    return NativeDatabase.createInBackground(file);
  });
}
