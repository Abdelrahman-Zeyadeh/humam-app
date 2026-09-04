import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const List<int> _kSqliteHeaderBytes = [
  0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66,
  0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00,
];

/// يقرأ `PRAGMA user_version` من ملف SQLite موجود فعلاً على القرص، بلا فتح
/// اتصال drift/sqlite3 كامل — يتحقّق أولاً من ترويسة SQLite ("SQLite format 3\0")
/// ثم يقرأ ٤ بايتات بموضع ثابت (٦٠) بترويسة ملف SQLite (موثّق رسمياً:
/// sqlite.org/fileformat.html#user_version). يرجع null فوراً لو الملف غير صالح.
Future<int?> readSqliteUserVersion(File file) async {
  RandomAccessFile? raf;
  try {
    if (!await file.exists() || (await file.length()) < 64) return null;
    raf = await file.open();
    final header = await raf.read(16);
    if (header.length != 16) return null;
    for (var i = 0; i < 16; i++) {
      if (header[i] != _kSqliteHeaderBytes[i]) return null;
    }
    await raf.setPosition(60);
    final bytes = await raf.read(4);
    if (bytes.length != 4) return null;
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  } catch (_) {
    return null;
  } finally {
    await raf?.close();
  }
}

/// ينسخ قاعدة SQLite **للقراءة فقط** من الـ asset إلى مجلد المستندات عند
/// أول تشغيل، ويعيد نسخها كلما تغيّر محتواها (`assetVersionPath` نص حر
/// يُقارَن بالمساواة فقط). يستخدمها `QuranDatabase`/`HadithDatabase`.
///
/// يعتمد نمط الكتابة الذرّية: كتابة لملف مؤقت (`.tmp`) ثم `rename` فوق الملف
/// النهائي، ولا يُكتب ملف `.version` إلا بعد نجاح الاستبدال تماماً لتفادي
/// أي ملفات غير مكتملة في حال انقطاع الكتابة.
Future<File> syncAssetSqliteDatabase({
  required String fileName,
  required String assetDbPath,
  required String assetVersionPath,
  required int expectedSchemaVersion,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, fileName));
  final versionFile = File(p.join(dir.path, '$fileName.version'));

  final bundledVersion = await rootBundle.loadString(assetVersionPath);
  final exists = await file.exists();
  final storedVersion = exists && await versionFile.exists() ? await versionFile.readAsString() : null;
  final schemaMismatch = exists && await readSqliteUserVersion(file) != expectedSchemaVersion;

  if (!exists || storedVersion != bundledVersion || schemaMismatch) {
    final data = await rootBundle.load(assetDbPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final tempFile = File(p.join(dir.path, '$fileName.tmp'));
    await tempFile.writeAsBytes(bytes, flush: true);
    await tempFile.rename(file.path);
    await versionFile.writeAsString(bundledVersion, flush: true);
  }

  return file;
}

