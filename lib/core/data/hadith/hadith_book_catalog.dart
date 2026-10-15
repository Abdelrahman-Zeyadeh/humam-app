/// كتالوج ثابت لكل كتب الأحاديث التسعة — مصدر الحقيقة الوحيد لقائمتها
/// بشاشة `hadith_books_screen.dart`، **قبل** معرفة أي كتاب منزَّل فعلياً.
/// الأسماء والمعرّفات والأعداد نفسها من `hadith_books`/`hadiths` الأصلية
/// (راجع `tools/split_hadith_shards.py`) — ثابتة تماماً (لا تتغيّر إلا
/// ببناء قاعدة بيانات جديد)، فتضمينها هنا حرفياً أبسط وأرخص من استعلام
/// قاعدة بيانات لكل كتاب غير منزَّل أصلاً (لا يوجد ملف نقرأ منه بعد).
enum HadithBookCategory {
  all('الكل'),
  sahih('الصحيحان'),
  sunan('السنن الأربعة'),
  muwatta('الموطأ'),
  forty('الأربعينيات');

  const HadithBookCategory(this.label);
  final String label;
}

class HadithBookCatalogEntry {
  const HadithBookCatalogEntry({
    required this.id,
    required this.key,
    required this.nameAr,
    required this.hadithCount,
    required this.embedded,
    this.approxDownloadBytes = 0,
    this.authorAr = '',
    this.authorDeath = '',
    this.category = HadithBookCategory.all,
    this.description = '',
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

  /// اسم الإمام أو المصنّف
  final String authorAr;

  /// سنة الوفاة التاريخية المعتمدة
  final String authorDeath;

  /// تصنيف الكتاب التراثي
  final HadithBookCategory category;

  /// نبذة مختصرة عن مكانة الكتاب ومحتواه
  final String description;
}

/// مفاتيح الكتابين المضمَّنين دائماً — طابق `EMBEDDED_KEYS` بـ
/// `tools/build_hadith_db_slim.py` حرفياً لو تغيّر أحدهما.
const Set<String> kEmbeddedHadithBookKeys = {'nawawi', 'qudsi'};

const List<HadithBookCatalogEntry> kHadithBookCatalog = [
  HadithBookCatalogEntry(
    id: 1,
    key: 'bukhari',
    nameAr: 'صحيح البخاري',
    authorAr: 'الإمام البخاري',
    authorDeath: 'ت ٢٥٦ هـ',
    category: HadithBookCategory.sahih,
    description: 'الجامع المسند الصحيح المختصر، أصح كتاب بعد كتاب الله عز وجل.',
    hadithCount: 7580,
    embedded: false,
    approxDownloadBytes: 19427328,
  ),
  HadithBookCatalogEntry(
    id: 2,
    key: 'muslim',
    nameAr: 'صحيح مسلم',
    authorAr: 'الإمام مسلم النيسابوري',
    authorDeath: 'ت ٢٦١ هـ',
    category: HadithBookCategory.sahih,
    description: 'المسند الصحيح المختصر، تميز بحسن الصنعة والترتيب وطرق الحديث.',
    hadithCount: 7360,
    embedded: false,
    approxDownloadBytes: 16809984,
  ),
  HadithBookCatalogEntry(
    id: 3,
    key: 'nawawi',
    nameAr: 'الأربعون النووية',
    authorAr: 'الإمام يحيى بن شرف النووي',
    authorDeath: 'ت ٦٧٦ هـ',
    category: HadithBookCategory.forty,
    description: 'اثنان وأربعون حديثاً نبوياً تدور عليها أصول وقواعد الدين الإسلامي.',
    hadithCount: 42,
    embedded: true,
  ),
  HadithBookCatalogEntry(
    id: 4,
    key: 'abudawud',
    nameAr: 'سنن أبي داود',
    authorAr: 'الإمام أبو داود السجستاني',
    authorDeath: 'ت ٢٧٥ هـ',
    category: HadithBookCategory.sunan,
    description: 'كتاب السنن المعتمد في أحاديث الأحكام والفقه والعبادات.',
    hadithCount: 5272,
    embedded: false,
    approxDownloadBytes: 11804672,
  ),
  HadithBookCatalogEntry(
    id: 5,
    key: 'tirmidhi',
    nameAr: 'جامع الترمذي',
    authorAr: 'الإمام أبو عيسى الترمذي',
    authorDeath: 'ت ٢٧٩ هـ',
    category: HadithBookCategory.sunan,
    description: 'الجامع المختصر مع بيان درجة الحديث والعلل ومذاهب الفقهاء.',
    hadithCount: 3924,
    embedded: false,
    approxDownloadBytes: 12890112,
  ),
  HadithBookCatalogEntry(
    id: 6,
    key: 'nasai',
    nameAr: 'سنن النسائي',
    authorAr: 'الإمام أحمد بن شعيب النسائي',
    authorDeath: 'ت ٣٠٣ هـ',
    category: HadithBookCategory.sunan,
    description: 'المجتبى من السنن الصغرى، أشد كتب السنن الأربعة شرطاً وتثبتاً.',
    hadithCount: 5679,
    embedded: false,
    approxDownloadBytes: 11706368,
  ),
  HadithBookCatalogEntry(
    id: 7,
    key: 'ibnmajah',
    nameAr: 'سنن ابن ماجه',
    authorAr: 'الإمام ابن ماجه القزويني',
    authorDeath: 'ت ٢٧٣ هـ',
    category: HadithBookCategory.sunan,
    description: 'رابع كتب السنن، امتاز ببراعة التبويب وحسن الترتيب للأبواب الفقهية.',
    hadithCount: 4338,
    embedded: false,
    approxDownloadBytes: 8552448,
  ),
  HadithBookCatalogEntry(
    id: 8,
    key: 'malik',
    nameAr: 'موطأ مالك',
    authorAr: 'الإمام مالك بن أنس',
    authorDeath: 'ت ١٧٩ هـ',
    category: HadithBookCategory.muwatta,
    description: 'أقدم ديوان حديثي جامع، جمع بين حديث النبي ﷺ وفقه أهل المدينة.',
    hadithCount: 1829,
    embedded: false,
    approxDownloadBytes: 3858432,
  ),
  HadithBookCatalogEntry(
    id: 9,
    key: 'qudsi',
    nameAr: 'الأربعون القدسية',
    authorAr: 'مرويات قدسية مسندة',
    authorDeath: 'عن رب العزة',
    category: HadithBookCategory.forty,
    description: 'أحاديث مسندة جليلة يرويها رسول الله ﷺ عن ربه تبارك وتعالى.',
    hadithCount: 40,
    embedded: true,
  ),
];

HadithBookCatalogEntry hadithBookCatalogById(int id) =>
    kHadithBookCatalog.firstWhere((b) => b.id == id, orElse: () => throw StateError('كتاب أحاديث غير معروف: $id'));

HadithBookCatalogEntry hadithBookCatalogByKey(String key) => kHadithBookCatalog
    .firstWhere((b) => b.key == key, orElse: () => throw StateError('كتاب أحاديث غير معروف: $key'));
