import 'package:drift/drift.dart';

import '../../text/arabic_normalizer.dart';
import 'hadith_database.dart';

/// نتيجة بحث بالأحاديث: الحديث + اسم كتابه للعرض.
class HadithSearchResult {
  const HadithSearchResult({required this.hadith, required this.bookNameAr});
  final Hadith hadith;
  final String bookNameAr;
}

class HadithRepository {
  HadithRepository(this._db);
  final HadithDatabase _db;

  Future<List<HadithBook>> allBooks() => _db.select(_db.hadithBooks).get();

  Future<HadithBook> bookById(int id) =>
      (_db.select(_db.hadithBooks)..where((b) => b.id.equals(id))).getSingle();

  Future<int> countForBook(int bookId) async {
    final count = _db.hadiths.id.count();
    final query = _db.selectOnly(_db.hadiths)
      ..addColumns([count])
      ..where(_db.hadiths.bookId.equals(bookId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<Hadith>> hadithsForBook(int bookId, {int limit = 50, int offset = 0}) =>
      (_db.select(_db.hadiths)
            ..where((h) => h.bookId.equals(bookId))
            ..orderBy([(h) => OrderingTerm.asc(h.hadithNumber)])
            ..limit(limit, offset: offset))
          .get();

  Future<Hadith> hadithById(int id) =>
      (_db.select(_db.hadiths)..where((h) => h.id.equals(id))).getSingle();

  /// بحث نصي عبر فهرس FTS5 `fts_hadiths` عبر كل الكتب — نفس منطق تطبيع
  /// النص المستخدم بالبحث القرآني (`arabic_normalizer.dart`).
  Future<List<HadithSearchResult>> search(String query, {int limit = 50}) async {
    final normalized = normalizeArabicSearch(query.trim());
    if (normalized.isEmpty) return const [];

    final rows = await _db
        .customSelect(
          '''
          SELECT hadiths.*, hadith_books.name_ar AS book_name_ar
          FROM fts_hadiths
          JOIN hadiths ON hadiths.id = fts_hadiths.rowid
          JOIN hadith_books ON hadith_books.id = hadiths.book_id
          WHERE fts_hadiths MATCH ?
          ORDER BY hadiths.id
          LIMIT ?
          ''',
          variables: [Variable.withString('$normalized*'), Variable.withInt(limit)],
          readsFrom: {_db.hadiths, _db.hadithBooks},
        )
        .get();

    return rows.map((row) {
      final hadith = _db.hadiths.map(row.data);
      return HadithSearchResult(hadith: hadith, bookNameAr: row.read<String>('book_name_ar'));
    }).toList();
  }
}
