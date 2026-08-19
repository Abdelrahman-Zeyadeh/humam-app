import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'quran_tables.dart';

part 'quran_database.g.dart';

/// قاعدة بيانات المصحف — **للقراءة فقط**. تُنسخ من الـ asset المضمّن إلى
/// مجلد التطبيق عند أول تشغيل فقط، ثم تُفتح من هناك مباشرة (لا تُنشأ ولا
/// تُهاجَر عبر drift؛ المخطط جاهز مسبقاً بواسطة `tools/build_quran_db.py`).
@DriftDatabase(tables: [Surahs, Ayahs, PageLines, Words, Tafsirs, Translations])
class QuranDatabase extends _$QuranDatabase {
  QuranDatabase() : super(_openConnection());

  /// للاختبارات فقط: يسمح بحقن اتصال مباشر بدل نسخ الـ asset (الذي يحتاج
  /// محرك Flutter كاملاً عبر `rootBundle`، وغير متاح باختبارات الوحدة الصرفة).
  @visibleForTesting
  QuranDatabase.forTesting(super.executor);

  /// يطابق `PRAGMA user_version` الذي يضعه سكربت البناء — يمنع drift من
  /// محاولة تشغيل `onCreate` على قاعدة منشأة مسبقاً وممتلئة بالبيانات.
  @override
  int get schemaVersion => 2;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'quran.db'));
    final versionFile = File(p.join(dir.path, 'quran.db.version'));

    // `assets/quran/quran_db_version.txt` رقم يضعه tools/build_quran_db.py
    // ويرفعه كل ما يضيف جدولاً/عموداً بالمخطط. بدون هالفحص، جهاز جرّب
    // التطبيق قبل تحديث المخطط (مثلاً قبل إضافة tafsirs/translations)
    // كان رح يفضل يستخدم نسخته المحفوظة بمجلد المستندات للأبد — لأن الشرط
    // القديم كان فقط "الملف موجود؟" بلا مقارنة إصدار، فيطلع خطأ "no such
    // table" عند أول استعلام على الجدول الجديد.
    final bundledVersion = await rootBundle.loadString('assets/quran/quran_db_version.txt');
    final storedVersion = await file.exists() && await versionFile.exists()
        ? await versionFile.readAsString()
        : null;

    if (!await file.exists() || storedVersion != bundledVersion) {
      final data = await rootBundle.load('assets/quran/quran.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes, flush: true);
      await versionFile.writeAsString(bundledVersion, flush: true);
    }

    return NativeDatabase.createInBackground(file);
  });
}
