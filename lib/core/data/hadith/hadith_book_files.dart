import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// مسار ملف كتاب أحاديث مُنزَّل (بغضّ النظر عن كونه منزَّلاً فعلاً أم لا) —
/// طبقة مشتركة بين `HadithDownloadController` (يكتب إليه) و`HadithDbRegistry`
/// (يقرأ منه، راجع `hadith_db_registry.dart`) عمداً هنا بـ`core/data` لا
/// `features/hadith` كي لا يستورد كود `core` من `features` (عكس ترتيب
/// الطبقات المعتمد بالمشروع).
Future<Directory> hadithBooksDir() async {
  final dir = await getApplicationDocumentsDirectory();
  final booksDir = Directory(p.join(dir.path, 'downloaded_hadith_books'));
  if (!await booksDir.exists()) await booksDir.create(recursive: true);
  return booksDir;
}

Future<File> hadithBookLocalFile(String bookKey) async {
  final dir = await hadithBooksDir();
  return File(p.join(dir.path, '$bookKey.db'));
}

/// مفاتيح كل كتب الأحاديث المنزَّلة فعلياً حسب الملفات الموجودة (لا علم
/// SharedPreferences) — مستخدَمة من `HadithDownloadController._scanExisting`
/// **و**`HadithDbRegistry` (لضمان فتح اتصال بكل كتاب مُنزَّل قبل البحث
/// النصي عبره، حتى لو لم يُفتَح كتابه من واجهة المستخدم بهذه الجلسة بعد).
Future<Set<String>> scanDownloadedHadithBookKeys() async {
  final dir = await hadithBooksDir();
  final found = <String>{};
  await for (final entity in dir.list()) {
    final match = RegExp(r'^([a-z]+)\.db$').firstMatch(p.basename(entity.path));
    if (match != null) found.add(match.group(1)!);
  }
  return found;
}
