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

class Ayahs extends Table {
  IntColumn get id => integer()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  IntColumn get page => integer()();
  IntColumn get juz => integer()();
  IntColumn get hizb => integer().nullable()(); // TODO: مصدر بيانات منفصل
  IntColumn get rub => integer().nullable()(); // TODO: مصدر بيانات منفصل
  IntColumn get manzil => integer()();
  TextColumn get sajdaType => text().named('sajda_type').nullable()();
  TextColumn get textUthmani => text().named('text_uthmani')();
  TextColumn get textSearch => text().named('text_search')();

  @override
  Set<Column> get primaryKey => {id};
}
