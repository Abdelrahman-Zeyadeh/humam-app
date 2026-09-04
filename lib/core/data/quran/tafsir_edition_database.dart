import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tafsir_edition_tables.dart';

part 'tafsir_edition_database.g.dart';

/// اتصال drift مستقل بملف تفسير مُنزَّل واحد (`tafsir_{edition}.db`) —
/// **بلا** مزامنة asset (الملف نفسه نزّله `TafsirDownloadController`
/// فعلاً، هو المصدر النهائي)، وبلا فحص `PRAGMA user_version` (الملفات
/// تُنشأ بسكربت بايثون مباشرة لا drift، راجع `tools/split_tafsir_
/// editions.py`). نفس نمط `HadithDatabase.forDownloadedBook` بالضبط.
@DriftDatabase(tables: [TafsirTexts])
class TafsirEditionDatabase extends _$TafsirEditionDatabase {
  TafsirEditionDatabase(File file) : super(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 1;
}
