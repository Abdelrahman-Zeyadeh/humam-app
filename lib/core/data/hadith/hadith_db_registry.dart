import 'package:flutter/foundation.dart' show visibleForTesting;

import 'hadith_book_catalog.dart';
import 'hadith_book_files.dart';
import 'hadith_database.dart';

/// يحلّ أي طلب متعلّق بكتاب أحاديث (بمفتاحه) إلى اتصال drift الصحيح —
/// الاتصال المضمَّن الواحد لكتابي الأربعين النووية/القدسية، أو اتصال مفتوح
/// حديثاً على ملف كتاب مُنزَّل (يُفتح مرّة واحدة فقط ويُخزَّن مؤقتاً، لا
/// يُفتح من جديد كل استعلام). راجع `hadith_database.dart` لملاحظة أن نفس
/// تعريفات الجداول تصلح للاتصالين معاً.
class HadithDbRegistry {
  HadithDbRegistry(this._embedded) : _downloaded = {}, _isTesting = false;

  /// للاختبارات فقط — يمرّر خرائط اتصالات جاهزة مباشرة (مثلاً على ملفات
  /// `tools/hadith_shards/*.db`) بدل البحث عن ملفات مُنزَّلة فعلياً عبر
  /// `path_provider` (غير متاح بسهولة ببيئة اختبار وحدة، وغير مطلوب أصلاً —
  /// الخريطة الممرَّرة هون تمثّل **كل** الكتب "المتاحة" بالاختبار). راجع
  /// `test/hadith_repository_test.dart`.
  @visibleForTesting
  HadithDbRegistry.forTesting(this._embedded, Map<String, HadithDatabase> downloaded)
    : _downloaded = downloaded,
      _isTesting = true;

  final HadithDatabase _embedded;
  final Map<String, HadithDatabase> _downloaded;
  final bool _isTesting;

  /// `null` لو الكتاب غير متاح حالياً (لا مضمَّن ولا منزَّل بعد) — على
  /// المستدعي التعامل مع هذه الحالة (رسالة "نزّل الكتاب أولاً" بالواجهة،
  /// أو الرجوع للنسخة الاحتياطية `essential_hadith_fallback.dart` لو كان
  /// الاستدعاء عبر `hadithByBookAndNumber`).
  Future<HadithDatabase?> dbForBookKey(String bookKey) async {
    if (kEmbeddedHadithBookKeys.contains(bookKey)) return _embedded;
    final cached = _downloaded[bookKey];
    if (cached != null) return cached;
    final file = await hadithBookLocalFile(bookKey);
    if (!await file.exists()) return null;
    final db = HadithDatabase.forDownloadedBook(file);
    _downloaded[bookKey] = db;
    return db;
  }

  Future<HadithDatabase?> dbForBookId(int bookId) => dbForBookKey(hadithBookCatalogById(bookId).key);

  /// كل الاتصالات المتاحة حالياً (المضمَّن + **كل** كتاب مُنزَّل على القرص،
  /// حتى لو لم يُفتَح من واجهة المستخدم بهذه الجلسة بعد) — يفتح أي اتصال
  /// ناقص أولاً، يُستخدَم للبحث النصي عبر كل المحتوى المتاح فعلياً.
  Future<List<HadithDatabase>> get activeDatabases async {
    // بالاختبارات، `_downloaded` مُمرَّرة جاهزة كاملة بالمُنشئ (راجع
    // `forTesting` أعلاه) — لا داعي، بل لا إمكانية، لمسح القرص الفعلي
    // عبر `path_provider` (غير مُهيَّأ ببيئة اختبار وحدة أصلاً).
    if (!_isTesting) {
      for (final key in await scanDownloadedHadithBookKeys()) {
        await dbForBookKey(key);
      }
    }
    return [_embedded, ..._downloaded.values];
  }

  /// يغلق اتصالات الكتب المنزَّلة فقط — الاتصال المضمَّن يُغلَق منفصلاً عبر
  /// `hadithEmbeddedDatabaseProvider` (راجع `hadith_providers.dart`) تجنّباً
  /// لإغلاقه مرّتين.
  Future<void> closeDownloadedConnections() async {
    for (final db in _downloaded.values) {
      await db.close();
    }
    _downloaded.clear();
  }
}
