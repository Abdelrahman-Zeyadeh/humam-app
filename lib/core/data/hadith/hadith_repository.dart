import 'package:drift/drift.dart';

import '../../text/arabic_normalizer.dart';
import 'essential_hadith_fallback.dart';
import 'hadith_book_catalog.dart';
import 'hadith_database.dart';
import 'hadith_db_registry.dart';

/// يقصّ متن الحديث فقط من نصّه الكامل (بلا سلسلة الإسناد "حَدَّثَنَا فلان
/// عن فلان..."), اعتماداً على أن نصوص `hadith.db` تتبع صيغة قياسية: [سند]
/// ... صلى الله عليه وسلم [قَالَ] "[متن]" [تذييل تحريري اختياري]. يقصّ عند
/// آخر ظهور لعبارة "صلى الله عليه وسلم" ويُسقط أي "قَالَ" مباشر بعدها (لفظ
/// انتقال للمتن، لا جزء منه)، وأي تذييل تحريري لاحق يبدأ بـ"قَالَ أَبُو"
/// (ملاحظة المُصنِّف عن أحد الرواة، كحديث أبي داود ١٣٩٨ — راجع تعليقه عن
/// "ابن حُجَيْرَة الأصغر"). النص المتبقّي **حرفي كما ورد بالمصدر**، لا إعادة
/// صياغة. بطلب صاحب المشروع "اختصر السند اجعله فقط الراوي عن رسول الله ﷺ
/// والحديث" — يُستخدم بشاشتَي `qiyam_screen.dart`/`hifz_screen.dart` مع
/// عبارة راوٍ قصيرة مُعدَّة يدوياً لكل حديث (موثَّقة بموقع الاستخدام)،
/// موثوق فقط للأحاديث الأربعة الثابتة المستخدَمة هناك (لا استخدام عام على
/// نص حديث اعتباطي — تركيبة "قَالَ أَبُو" التحريرية قد تتطابق خطأً بمتن
/// حديث آخر يذكرها ضمن كلامه فعلاً).
String hadithMatnOnly(String rawText) {
  const marker = 'صلى الله عليه وسلم';
  final idx = rawText.lastIndexOf(marker);
  if (idx == -1) return rawText.trim();
  var tail = rawText.substring(idx + marker.length).trim();
  tail = tail.replaceFirst(RegExp(r'^قَالَ\s*'), '');
  final editorialIdx = tail.indexOf('قَالَ أَبُو');
  if (editorialIdx > 0) tail = tail.substring(0, editorialIdx).trim();
  return tail.trim();
}

/// نتيجة بحث بالأحاديث: الحديث + اسم كتابه للعرض.
class HadithSearchResult {
  const HadithSearchResult({required this.hadith, required this.bookNameAr});
  final Hadith hadith;
  final String bookNameAr;
}

class HadithChapterWithCount {
  const HadithChapterWithCount({required this.chapter, required this.hadithCount});
  final HadithChapter chapter;
  final int hadithCount;
}

/// يُرمى حين يُطلب محتوى كتاب **غير متاح حالياً** (لا مضمَّن ولا منزَّل بعد)
/// — راجع `hadith_book_catalog.dart`/`HadithDownloadController`. الشاشات
/// يجب أن تمنع الوصول لهذا المسار أصلاً (تعرض زر تنزيل بدل فتح الكتاب)،
/// هذا خط دفاع أخير يظهر كرسالة خطأ واضحة بدل استثناء drift مبهم.
class HadithBookNotDownloadedException implements Exception {
  const HadithBookNotDownloadedException(this.bookNameAr);
  final String bookNameAr;

  @override
  String toString() => 'كتاب "$bookNameAr" غير منزَّل بعد';
}

class HadithRepository {
  HadithRepository(this._registry);
  final HadithDbRegistry _registry;

  /// كتالوج الكتب التسعة كاملاً — راجع `hadith_book_catalog.dart`، لا
  /// استعلام قاعدة بيانات (بعض الكتب غير منزَّل أصلاً فلا ملف نقرأ منه).
  List<HadithBookCatalogEntry> allBooks() => kHadithBookCatalog;

  HadithBookCatalogEntry bookById(int id) => hadithBookCatalogById(id);

  Future<HadithDatabase> _requireDb(int bookId) async {
    final entry = hadithBookCatalogById(bookId);
    final db = await _registry.dbForBookId(bookId);
    if (db == null) throw HadithBookNotDownloadedException(entry.nameAr);
    return db;
  }

  Future<int> countForBook(int bookId) async {
    final db = await _requireDb(bookId);
    final count = db.hadiths.id.count();
    final query = db.selectOnly(db.hadiths)
      ..addColumns([count])
      ..where(db.hadiths.bookId.equals(bookId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// أبواب كتاب واحد (مرتّبة برقمها الأصلي) مع عدد أحاديث كل باب —
  /// راجع `HadithChapters` بـ`hadith_tables.dart` لملاحظة الاسم المؤقت.
  // ⚠️ كانت مكتوبة سابقاً بـ`selectOnly(hadithChapters).join(innerJoin(...))
  // ..groupBy(...)` ثم `row.readTable(hadithChapters)` — يرمي فعلياً
  // "This row does not contain values for that table" وقت التشغيل (جُرِّب
  // بجهاز فعلي: شاشة أبواب أي كتاب تظهر فارغة/"تعذّر تحميل الأبواب" دائماً).
  // لا اختبار سابق كان يستدعي `chaptersForBook` فمرّ العطل بلا رصد. الحل
  // هون أبسط وأصلب: استعلامان منفصلان (الأبواب، ثم عدّ الأحاديث لكل باب)
  // يُجمَعان بـDart — يتفادى تعقيد join+groupBy+readTable كلياً، ويعرض
  // أبواباً بلا أحاديث كـ"٠" بدل إخفائها صامتاً (innerJoin القديم كان يُسقطها).
  Future<List<HadithChapterWithCount>> chaptersForBook(int bookId) async {
    final db = await _requireDb(bookId);
    final chapters = await (db.select(db.hadithChapters)
          ..where((c) => c.bookId.equals(bookId))
          ..orderBy([(c) => OrderingTerm.asc(c.chapterNumber)]))
        .get();

    final count = db.hadiths.id.count();
    final countQuery = db.selectOnly(db.hadiths)
      ..addColumns([db.hadiths.chapterId, count])
      ..where(db.hadiths.bookId.equals(bookId))
      ..groupBy([db.hadiths.chapterId]);
    final countRows = await countQuery.get();
    final countByChapter = <int, int>{
      for (final row in countRows)
        if (row.read(db.hadiths.chapterId) case final chapterId?) chapterId: row.read(count) ?? 0,
    };

    return [
      for (final chapter in chapters)
        HadithChapterWithCount(chapter: chapter, hadithCount: countByChapter[chapter.id] ?? 0),
    ];
  }

  Future<List<Hadith>> hadithsForBook(int bookId, {int limit = 50, int offset = 0}) async {
    final db = await _requireDb(bookId);
    return (db.select(db.hadiths)
          ..where((h) => h.bookId.equals(bookId))
          ..orderBy([(h) => OrderingTerm.asc(h.hadithNumber)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// كل أحاديث باب واحد — أكبر باب فعلياً ~٥٨٠ حديثاً، تحميل دفعة وحدة
  /// بلا ترقيم تدريجي أبسط وكافٍ (خلافاً لكتاب كامل، راجع `hadithsForBook`).
  Future<List<Hadith>> hadithsForChapter(int bookId, int chapterId) async {
    final db = await _requireDb(bookId);
    return (db.select(db.hadiths)
          ..where((h) => h.chapterId.equals(chapterId))
          ..orderBy([(h) => OrderingTerm.asc(h.hadithNumber)]))
        .get();
  }

  Future<Hadith> hadithById(int bookId, int id) async {
    final db = await _requireDb(bookId);
    return (db.select(db.hadiths)..where((h) => h.id.equals(id))).getSingle();
  }

  /// حديث محدَّد برقمه ضمن كتاب معيّن (رقم الحديث المعياري بالكتاب، لا
  /// `id` الداخلي) — يُستخدم لعرض أحاديث حقيقية بمكان ثابت بالواجهة (فضل
  /// قيام الليل/الحفظ بشاشتَي `qiyam_screen.dart`/`hifz_screen.dart`) بلا
  /// نسخ نصها كنص ثابت بالكود، فتبقى مصدرها الوحيد قاعدة البيانات المرخّصة.
  ///
  /// **لو كتاب الحديث المطلوب غير متاح حالياً** (لم يُنزَّل بعد — راجع
  /// `hadith_book_catalog.dart`)، يرجع من النسخة الاحتياطية الثابتة
  /// `essential_hadith_fallback.dart` **لو** كان هذا الاستشهاد بالذات
  /// مسجَّلاً فيها (الاستشهادات الثابتة بالكود فقط، لا أي حديث اعتباطي)،
  /// وإلا `null` كسابقاً. هذا يضمن عمل تذكيرات القيام/الحفظ الدوّارة بلا
  /// إنترنت وبلا تنزيل حتى لو المستخدم لم يفتح قسم الأحاديث إطلاقاً.
  Future<Hadith?> hadithByBookAndNumber(int bookId, int hadithNumber) async {
    final db = await _registry.dbForBookId(bookId);
    if (db == null) {
      final key = hadithBookCatalogById(bookId).key;
      return kEssentialHadithFallback['$key:$hadithNumber'];
    }
    return (db.select(db.hadiths)
          ..where((h) => h.bookId.equals(bookId) & h.hadithNumber.equals(hadithNumber)))
        .getSingleOrNull();
  }

  /// بحث نصي عبر فهرس FTS5 `fts_hadiths` — عبر **كل الكتب المتاحة حالياً**
  /// فقط (المضمَّنة + أي كتاب مُنزَّل فُتح اتصاله من قبل بهذه الجلسة؛ كتاب
  /// لم يُنزَّل إطلاقاً لا يظهر بنتائج البحث حتى يُنزَّل — لا فهرس محلي عنه).
  /// نفس منطق تطبيع النص المستخدم بالبحث القرآني (`arabic_normalizer.dart`).
  Future<List<HadithSearchResult>> search(String query, {int limit = 50}) async {
    final normalized = normalizeArabicSearch(query.trim());
    if (normalized.isEmpty) return const [];

    final results = <HadithSearchResult>[];
    for (final db in await _registry.activeDatabases) {
      final rows = await db
          .customSelect(
            '''
            SELECT hadiths.* FROM fts_hadiths
            JOIN hadiths ON hadiths.id = fts_hadiths.rowid
            WHERE fts_hadiths MATCH ?
            ORDER BY hadiths.id
            LIMIT ?
            ''',
            variables: [Variable.withString('$normalized*'), Variable.withInt(limit)],
            readsFrom: {db.hadiths},
          )
          .get();
      for (final row in rows) {
        final hadith = db.hadiths.map(row.data);
        results.add(HadithSearchResult(hadith: hadith, bookNameAr: hadithBookCatalogById(hadith.bookId).nameAr));
      }
    }
    // **لا** يُعاد قصّ النتيجة المدموجة لـ`limit` هون — كل قاعدة أعلاه
    // مقصوصة بـ`limit` أصلاً على مستوى SQL، فلو أُعيد القصّ بعد الدمج
    // والترتيب بـ`id` تصاعدياً، كتاب كبير بمعرّفات منخفضة (كالبخاري، أول
    // كتاب بالترقيم الأصلي) يمكن يستحوذ وحده على كل النتائج المسموحة
    // ويُسقط تطابقات حقيقية من كتاب صغير بمعرّفات أعلى (كالأربعين
    // النووية) رغم أن قاعدته هي نفسها رجّعت التطابق ضمن حدّها. أسوأ حالة
    // عملياً: `limit` × عدد القواعد المتاحة (تسعة كحد أقصى) — مقبول تماماً
    // لقائمة بحث تُعرض بالتمرير.
    results.sort((a, b) => a.hadith.id.compareTo(b.hadith.id));
    return results;
  }
}
