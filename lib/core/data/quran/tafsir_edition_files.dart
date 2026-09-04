import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// طبقة مسارات ملفات مشتركة بين `TafsirDownloadController` (يكتب إليها)
/// و`TafsirEditionRegistry` (يقرأ منها) — بـ`core/data` لا `features/mushaf`
/// عمداً كي لا يستورد كود `core` من `features` (عكس ترتيب الطبقات
/// المعتمد بالمشروع). نفس نمط `hadith_book_files.dart` بالضبط.
Future<Directory> tafsirEditionsDir() async {
  final dir = await getApplicationDocumentsDirectory();
  final editionsDir = Directory(p.join(dir.path, 'downloaded_tafsir_editions'));
  if (!await editionsDir.exists()) await editionsDir.create(recursive: true);
  return editionsDir;
}

Future<File> tafsirEditionLocalFile(String editionKey) async {
  final dir = await tafsirEditionsDir();
  return File(p.join(dir.path, 'tafsir_$editionKey.db'));
}

/// مفاتيح كل إصدارات التفسير المنزَّلة فعلياً حسب الملفات الموجودة — راجع
/// توثيق `scanDownloadedHadithBookKeys` بـ`hadith_book_files.dart` لنفس
/// المنطق ولماذا هو ضروري (لا يكفي الاعتماد على الاتصالات المفتوحة
/// بالذاكرة فقط، كتاب/تفسير نُزِّل بجلسة سابقة يجب أن يظهر بالبحث/الفتح
/// فوراً بلا لمسه يدوياً أولاً هالجلسة).
Future<Set<String>> scanDownloadedTafsirEditionKeys() async {
  final dir = await tafsirEditionsDir();
  final found = <String>{};
  await for (final entity in dir.list()) {
    final match = RegExp(r'^tafsir_([a-z]+)\.db$').firstMatch(p.basename(entity.path));
    if (match != null) found.add(match.group(1)!);
  }
  return found;
}
