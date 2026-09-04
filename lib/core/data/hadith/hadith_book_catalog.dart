/// كتالوج ثابت لكل كتب الأحاديث التسعة — مصدر الحقيقة الوحيد لقائمتها
/// بشاشة `hadith_books_screen.dart`، **قبل** معرفة أي كتاب منزَّل فعلياً.
/// الأسماء والمعرّفات والأعداد نفسها من `hadith_books`/`hadiths` الأصلية
/// (راجع `tools/split_hadith_shards.py`) — ثابتة تماماً (لا تتغيّر إلا
/// ببناء قاعدة بيانات جديد)، فتضمينها هنا حرفياً أبسط وأرخص من استعلام
/// قاعدة بيانات لكل كتاب غير منزَّل أصلاً (لا يوجد ملف نقرأ منه بعد).
class HadithBookCatalogEntry {
  const HadithBookCatalogEntry({
    required this.id,
    required this.key,
    required this.nameAr,
    required this.hadithCount,
    required this.embedded,
    this.approxDownloadBytes = 0,
  });

  final int id;
  final String key;
  final String nameAr;
  final int hadithCount;

  /// `true` لكتاب مضمَّن دائماً بـ`assets/hadith/hadith.db` (لا يحتاج تنزيلاً
  /// إطلاقاً). راجع `kEmbeddedHadithBookKeys` أدناه — نفس المجموعة حرفياً.
  final bool embedded;

  /// حجم ملف الشظية تقريباً بالبايت (`tools/hadith_shards/{key}.db`) —
  /// للعرض فقط ("~١٩ ميجا")، لا يُستخدَم للتحقّق.
  final int approxDownloadBytes;
}

/// مفاتيح الكتابين المضمَّنين دائماً — طابق `EMBEDDED_KEYS` بـ
/// `tools/build_hadith_db_slim.py` حرفياً لو تغيّر أحدهما.
const Set<String> kEmbeddedHadithBookKeys = {'nawawi', 'qudsi'};

const List<HadithBookCatalogEntry> kHadithBookCatalog = [
  HadithBookCatalogEntry(
    id: 1,
    key: 'bukhari',
    nameAr: 'صحيح البخاري',
    hadithCount: 7580,
    embedded: false,
    approxDownloadBytes: 19427328,
  ),
  HadithBookCatalogEntry(
    id: 2,
    key: 'muslim',
    nameAr: 'صحيح مسلم',
    hadithCount: 7360,
    embedded: false,
    approxDownloadBytes: 16809984,
  ),
  HadithBookCatalogEntry(
    id: 3,
    key: 'nawawi',
    nameAr: 'الأربعون النووية',
    hadithCount: 42,
    embedded: true,
  ),
  HadithBookCatalogEntry(
    id: 4,
    key: 'abudawud',
    nameAr: 'سنن أبي داود',
    hadithCount: 5272,
    embedded: false,
    approxDownloadBytes: 11804672,
  ),
  HadithBookCatalogEntry(
    id: 5,
    key: 'tirmidhi',
    nameAr: 'جامع الترمذي',
    hadithCount: 3924,
    embedded: false,
    approxDownloadBytes: 12890112,
  ),
  HadithBookCatalogEntry(
    id: 6,
    key: 'nasai',
    nameAr: 'سنن النسائي',
    hadithCount: 5679,
    embedded: false,
    approxDownloadBytes: 11706368,
  ),
  HadithBookCatalogEntry(
    id: 7,
    key: 'ibnmajah',
    nameAr: 'سنن ابن ماجه',
    hadithCount: 4338,
    embedded: false,
    approxDownloadBytes: 8552448,
  ),
  HadithBookCatalogEntry(
    id: 8,
    key: 'malik',
    nameAr: 'موطأ مالك',
    hadithCount: 1829,
    embedded: false,
    approxDownloadBytes: 3858432,
  ),
  HadithBookCatalogEntry(
    id: 9,
    key: 'qudsi',
    nameAr: 'الأربعون القدسية',
    hadithCount: 40,
    embedded: true,
  ),
];

HadithBookCatalogEntry hadithBookCatalogById(int id) =>
    kHadithBookCatalog.firstWhere((b) => b.id == id, orElse: () => throw StateError('كتاب أحاديث غير معروف: $id'));

HadithBookCatalogEntry hadithBookCatalogByKey(String key) => kHadithBookCatalog
    .firstWhere((b) => b.key == key, orElse: () => throw StateError('كتاب أحاديث غير معروف: $key'));
