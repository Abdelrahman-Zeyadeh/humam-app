import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'hadith_tables.dart';

part 'hadith_database.g.dart';

/// قاعدة أحاديث مستقلة عن `quran.db` — **للقراءة فقط**، نفس نمط النسخ من
/// الـ asset عند أول تشغيل (راجع `QuranDatabase` لشرح مفصّل لنفس النمط
/// ولماذا فحص إصدار الملف ضروري).
@DriftDatabase(tables: [HadithBooks, Hadiths])
class HadithDatabase extends _$HadithDatabase {
  HadithDatabase() : super(_openConnection());

  @visibleForTesting
  HadithDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hadith.db'));
    final versionFile = File(p.join(dir.path, 'hadith.db.version'));

    final bundledVersion = await rootBundle.loadString('assets/hadith/hadith_db_version.txt');
    final storedVersion =
        await file.exists() && await versionFile.exists() ? await versionFile.readAsString() : null;

    if (!await file.exists() || storedVersion != bundledVersion) {
      final data = await rootBundle.load('assets/hadith/hadith.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes, flush: true);
      await versionFile.writeAsString(bundledVersion, flush: true);
    }

    return NativeDatabase.createInBackground(file);
  });
}
