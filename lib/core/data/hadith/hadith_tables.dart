import 'package:drift/drift.dart';

/// تعريفات drift لجداول `hadith.db` — **للقراءة فقط**، المخطط الفعلي
/// من `tools/build_hadith_db.py`. راجع `tools/raw/README.md` لمصدر البيانات
/// (`fawazahmed0/hadith-api`، رخصة Unlicense) وحدوده (لا تشكيل/تدرّج أحياناً
/// كما بمصدره، ولا تصنيف صحة لكل حديث لأن الكتابين الأساسيين "صحيح" أصلاً).
class HadithBooks extends Table {
  IntColumn get id => integer()();
  TextColumn get key => text()(); // bukhari | muslim | nawawi
  TextColumn get nameAr => text().named('name_ar')();

  @override
  Set<Column> get primaryKey => {id};
}

class Hadiths extends Table {
  IntColumn get id => integer()();
  IntColumn get bookId => integer().named('book_id')();
  IntColumn get hadithNumber => integer().named('hadith_number')();
  TextColumn get content => text().named('text')();
  TextColumn get textSearch => text().named('text_search')();

  @override
  Set<Column> get primaryKey => {id};
}
