import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../asset_sqlite_sync.dart';
import 'quran_tables.dart';

part 'quran_database.g.dart';

/// يطابق `PRAGMA user_version` الذي يضعه سكربت البناء — راجع توثيق
/// `schemaVersion` بالأسفل و[syncAssetSqliteDatabase].
const _kSchemaVersion = 4;

/// قاعدة بيانات المصحف — **للقراءة فقط**. تُنسخ من الـ asset المضمّن إلى
/// مجلد التطبيق عند أول تشغيل فقط، ثم تُفتح من هناك مباشرة (لا تُنشأ ولا
/// تُهاجَر عبر drift؛ المخطط جاهز مسبقاً بواسطة `tools/build_quran_db.py`).
@DriftDatabase(tables: [Surahs, Ayahs, PageLines, Words, Tafsirs, Translations, Mutashabihat])
class QuranDatabase extends _$QuranDatabase {
  QuranDatabase() : super(_openConnection());

  /// للاختبارات فقط: يسمح بحقن اتصال مباشر بدل نسخ الـ asset (الذي يحتاج
  /// محرك Flutter كاملاً عبر `rootBundle`، وغير متاح باختبارات الوحدة الصرفة).
  @visibleForTesting
  QuranDatabase.forTesting(super.executor);

  /// يطابق `PRAGMA user_version` الذي يضعه سكربت البناء — يمنع drift من
  /// محاولة تشغيل `onCreate` على قاعدة منشأة مسبقاً وممتلئة بالبيانات.
  /// رُفعت لـ٤ عند إضافة عمود `glyph_v1` بجدول `words`.
  @override
  int get schemaVersion => _kSchemaVersion;

  /// **شبكة أمان فقط، لا هجرة حقيقية.** النسخ/الاستبدال الفعلي للملف كاملاً
  /// عند تغيّر البنية يحصل بـ[syncAssetSqliteDatabase] (`_openConnection`
  /// أسفل)، قبل ما drift يفتح الاتصال أصلاً — فمن المفروض لا يصل تعارض
  /// إصدار لهون إطلاقاً. لكن **بلا هذه الدالة، السلوك الافتراضي لـdrift
  /// عند أي تعارض إصدار هو رمي استثناء صريح** ("didn't provide a strategy
  /// for schema updates") يعطّل كل استعلام على القاعدة فوراً — وهذا
  /// بالضبط ما حصل فعلياً على جهاز حقيقي (٢٠٢٦-٠٨-٢١، راجع توثيق
  /// [syncAssetSqliteDatabase] لتفاصيل الحادثة). لا شيء حقيقي يُنفَّذ هون
  /// عمداً — القاعدة للقراءة فقط ومُدارة بالكامل كملف واحد يُستبدَل كاملاً.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {},
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await syncAssetSqliteDatabase(
      fileName: 'quran.db',
      assetDbPath: 'assets/quran/quran.db',
      assetVersionPath: 'assets/quran/quran_db_version.txt',
      expectedSchemaVersion: _kSchemaVersion,
    );
    return NativeDatabase.createInBackground(file);
  });
}
