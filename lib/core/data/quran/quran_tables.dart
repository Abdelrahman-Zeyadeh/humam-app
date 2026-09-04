import 'package:drift/drift.dart';

/// تعريفات drift لجداول `quran.db` — **للقراءة فقط**. المخطط الفعلي
/// يُنشئه `tools/build_quran_db.py`، وهذه التعريفات يجب أن تطابقه حرفياً
/// (الأسماء والأنواع) ولا تُستخدم لإنشاء الجدول فعلياً؛ راجع
/// `QuranDatabase.schemaVersion` وملاحظة `PRAGMA user_version` بالسكربت.
class Surahs extends Table {
  IntColumn get id => integer()();
  TextColumn get nameAr => text().named('name_ar')();
  TextColumn get nameArPlain => text().named('name_ar_plain')();
  TextColumn get nameEn => text().named('name_en')();
  TextColumn get revelationPlace => text().named('revelation_place')();
  IntColumn get revelationOrder => integer().named('revelation_order').nullable()();
  IntColumn get ayahCount => integer().named('ayah_count')();
  IntColumn get startPage => integer().named('start_page')();
  IntColumn get bismillahPre => integer().named('bismillah_pre')();

  @override
  Set<Column> get primaryKey => {id};
}

/// سطر واحد من سطور الصفحة الخمسة عشر (تخطيط QCF V2). النطاق
/// `firstWordId..lastWordId` فارغ لسطور اسم السورة والبسملة (لا كلمات).
class PageLines extends Table {
  IntColumn get page => integer()();
  IntColumn get lineNo => integer().named('line_no')();
  TextColumn get lineType => text().named('line_type')(); // ayah | surah_name | basmallah
  IntColumn get isCentered => integer().named('is_centered')();
  IntColumn get firstWordId => integer().named('first_word_id').nullable()();
  IntColumn get lastWordId => integer().named('last_word_id').nullable()();
  IntColumn get surahRef => integer().named('surah_ref').nullable()();

  @override
  Set<Column> get primaryKey => {page, lineNo};
}

/// كلمة واحدة برمز غليف خط QCF V2 الخاص بصفحتها (`p{page}.ttf`).
/// `charType == ayahMarker` لآخر عنصر بكل آية (رمز نهاية الآية الزخرفي)
/// — راجع `tools/quran_layout.py` لسبب عدم وجود نص عثماني عادي هنا.
class Words extends Table {
  IntColumn get id => integer()();
  IntColumn get ayahId => integer().named('ayah_id')();
  IntColumn get position => integer()();
  IntColumn get page => integer()();
  IntColumn get lineNo => integer().named('line_no')();
  TextColumn get glyph => text()();
  TextColumn get glyphV1 => text().named('glyph_v1').nullable()();
  TextColumn get charType => text().named('char_type')(); // word | ayah_marker

  @override
  Set<Column> get primaryKey => {id};
}

/// سطر واحد من سطور صفحة **طبعة V4 Tajweed** (١٤٤١هـ، خط عثمان طه، ألوان
/// التجويد مدمجة بالglyph نفسه — راجع `mushaf_settings.dart` توثيق
/// `MushafFontEdition.v4Tajweed`). تخطيط صفحات/أسطر **مستقل تماماً** عن
/// `PageLines` (V2) — طبعة مطبوعة مختلفة، لا تتشارك ترقيم الصفحات/الأسطر
/// إطلاقاً، بعكس V1 يلي بيتشارك مع V2 (راجع `Words.glyphV1`). أُضيف عبر
/// `tools/add_qcf_v4_tajweed.py` (`PRAGMA user_version = 5`).
class PageLinesV4 extends Table {
  IntColumn get page => integer()();
  IntColumn get lineNo => integer().named('line_no')();
  TextColumn get lineType => text().named('line_type')(); // ayah | surah_name | basmallah
  IntColumn get isCentered => integer().named('is_centered')();
  IntColumn get firstWordId => integer().named('first_word_id').nullable()();
  IntColumn get lastWordId => integer().named('last_word_id').nullable()();
  IntColumn get surahRef => integer().named('surah_ref').nullable()();

  @override
  Set<Column> get primaryKey => {page, lineNo};
}

/// كلمة واحدة برمز غليف خط QCF V4 Tajweed — نفس بنية [Words] لكن معرّفات
/// `id`/`ayahId` **مستقلة بمساحتها الخاصة** (لا تطابق `Words.id` رقمياً
/// رغم تطابق العدد الإجمالي صدفة: ٨٣٦٦٨ كلمة بكلا الطبعتين). راجع توثيق
/// [PageLinesV4].
class WordsV4 extends Table {
  IntColumn get id => integer()();
  IntColumn get ayahId => integer().named('ayah_id')();
  IntColumn get position => integer()();
  IntColumn get page => integer()();
  IntColumn get lineNo => integer().named('line_no')();
  TextColumn get glyph => text()();
  TextColumn get charType => text().named('char_type')(); // word | ayah_marker

  @override
  Set<Column> get primaryKey => {id};
}

/// تفسير آية واحدة من كتاب معيّن. `edition` مفتاح ثابت (`jalalayn` حالياً)
/// لا رقم — يسمح بإضافة كتب تفسير أخرى لاحقاً بلا تغيير المخطط. المصدر:
/// نسخة نصية من تفسير الجلالين، راجع `tools/raw/README.md`.
class Tafsirs extends Table {
  IntColumn get id => integer()();
  IntColumn get ayahId => integer().named('ayah_id')();
  TextColumn get edition => text()();
  TextColumn get content => text().named('text')();

  @override
  Set<Column> get primaryKey => {id};
}

/// ترجمة آية واحدة بلغة معيّنة. `edition` حالياً `en_sahih` فقط (ترجمة
/// صحيح إنترناشونال الإنجليزية) — نفس ملاحظة `Tafsirs` بخصوص التوسّع لاحقاً.
class Translations extends Table {
  IntColumn get id => integer()();
  IntColumn get ayahId => integer().named('ayah_id')();
  TextColumn get edition => text()();
  TextColumn get lang => text()();
  TextColumn get content => text().named('text')();

  @override
  Set<Column> get primaryKey => {id};
}

/// زوج آيتين متشابهتين لفظاً (قد تكونان بسورتين مختلفتين). كل صف اتجاه
/// واحد فقط — المصدر (QUL، راجع `tools/raw/README.md` "المتشابهات")
/// يخزّن الاتجاهين كصفّين مستقلّين بالفعل، فلا حاجة لاستعلام `OR`.
class Mutashabihat extends Table {
  IntColumn get ayahId => integer().named('ayah_id')();
  IntColumn get similarAyahId => integer().named('similar_ayah_id')();
  TextColumn get matchWordsRange => text().named('match_words_range').nullable()();
}

class Ayahs extends Table {
  IntColumn get id => integer()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get page => integer()();
  IntColumn get juz => integer()();
  // `nullable()` تاريخياً فقط — مُعبَّآن بالكامل فعلياً بـ`quran.db` (٦٢٣٦/٦٢٣٦
  // آية، ٦٠ حزباً و٢٤٠ ربعاً، راجع `tools/build_quran_db.py`)، لا TODO متبقٍّ.
  IntColumn get hizb => integer().nullable()();
  IntColumn get rub => integer().nullable()();
  IntColumn get manzil => integer()();
  TextColumn get sajdaType => text().named('sajda_type').nullable()();
  TextColumn get textUthmani => text().named('text_uthmani')();
  TextColumn get textSearch => text().named('text_search')();

  @override
  Set<Column> get primaryKey => {id};
}
