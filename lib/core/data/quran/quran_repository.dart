import 'package:drift/drift.dart';

import '../../text/arabic_normalizer.dart';
import 'quran_database.dart';

/// نتيجة بحث في نص المصحف: الآية + رقم صفحتها للانتقال والتظليل.
class AyahSearchResult {
  const AyahSearchResult({required this.ayah, required this.surahNameAr});
  final Ayah ayah;
  final String surahNameAr;
}

/// تخطيط صفحة مصحف كامل جاهز للعرض: سطورها بالترتيب، وكلمات كل سطر
/// (بغليف خط QCF V2 الخاص بهذه الصفحة تحديداً — `p{page}.ttf`).
class MushafPage {
  const MushafPage({required this.page, required this.lines, required this.wordsByLine});
  final int page;
  final List<PageLine> lines;
  final Map<int, List<Word>> wordsByLine; // lineNo -> كلماته بالترتيب
}

/// طبقة الوصول لقاعدة `quran.db`. كل الاستعلامات تُنفَّذ على isolate drift
/// المنفصل (`NativeDatabase.createInBackground`) — لا تحجب الخيط الرئيسي.
class QuranRepository {
  QuranRepository(this._db);
  final QuranDatabase _db;

  Future<List<Surah>> allSurahs() => _db.select(_db.surahs).get();

  Future<Surah> surahById(int id) =>
      (_db.select(_db.surahs)..where((s) => s.id.equals(id))).getSingle();

  Future<Ayah> ayahById(int id) =>
      (_db.select(_db.ayahs)..where((a) => a.id.equals(id))).getSingle();

  /// تفسير الجلالين لآية واحدة — `null` لو غير متوفّر (لا يجب أن يحصل،
  /// كل آية لها صف تفسير واحد على الأقل حالياً، لكن الاستدعاء الآمن أفضل
  /// من افتراض دايماً موجود).
  Future<Tafsir?> tafsirForAyah(int ayahId, {String edition = 'jalalayn'}) =>
      (_db.select(_db.tafsirs)
            ..where((t) => t.ayahId.equals(ayahId) & t.edition.equals(edition)))
          .getSingleOrNull();

  /// ترجمة صحيح إنترناشونال الإنجليزية لآية واحدة.
  Future<Translation?> translationForAyah(int ayahId, {String edition = 'en_sahih'}) =>
      (_db.select(_db.translations)
            ..where((t) => t.ayahId.equals(ayahId) & t.edition.equals(edition)))
          .getSingleOrNull();

  Future<List<Ayah>> ayahsForPage(int page) => (_db.select(_db.ayahs)
        ..where((a) => a.page.equals(page))
        ..orderBy([(a) => OrderingTerm.asc(a.ayah)]))
      .get();

  Future<List<Ayah>> ayahsForSurah(int surah) => (_db.select(_db.ayahs)
        ..where((a) => a.surah.equals(surah))
        ..orderBy([(a) => OrderingTerm.asc(a.ayah)]))
      .get();

  /// تخطيط صفحة كاملة: سطورها وكلماتها، جاهزة للرسم بخط `p{page}.ttf`.
  Future<MushafPage> pageLayout(int page) async {
    final lines = await (_db.select(_db.pageLines)
          ..where((l) => l.page.equals(page))
          ..orderBy([(l) => OrderingTerm.asc(l.lineNo)]))
        .get();

    // الترتيب بـ `id` (تسلسل عام بالمصحف كله) لا `position` — الأخير رقم
    // الكلمة داخل آيتها فقط ويرجع لـ١ بكل آية جديدة، فلو رتّبنا به وسطر
    // واحد فيه جزء من آيتين، تختلط كلمات الآية التالية قبل تمام السابقة.
    final words = await (_db.select(_db.words)
          ..where((w) => w.page.equals(page))
          ..orderBy([(w) => OrderingTerm.asc(w.id)]))
        .get();

    final wordsByLine = <int, List<Word>>{};
    for (final w in words) {
      wordsByLine.putIfAbsent(w.lineNo, () => []).add(w);
    }

    return MushafPage(page: page, lines: lines, wordsByLine: wordsByLine);
  }

  /// بحث نصي عبر فهرس FTS5 `fts_ayahs`. يطبّق نفس دالة التطبيع المستخدمة
  /// عند بناء الفهرس على مدخل المستخدم قبل المطابقة.
  Future<List<AyahSearchResult>> search(String query, {int limit = 50}) async {
    final normalized = normalizeArabicSearch(query.trim());
    if (normalized.isEmpty) return const [];

    final rows = await _db
        .customSelect(
          '''
          SELECT ayahs.*, surahs.name_ar AS surah_name_ar
          FROM fts_ayahs
          JOIN ayahs ON ayahs.id = fts_ayahs.rowid
          JOIN surahs ON surahs.id = ayahs.surah
          WHERE fts_ayahs MATCH ?
          ORDER BY ayahs.id
          LIMIT ?
          ''',
          variables: [Variable.withString('$normalized*'), Variable.withInt(limit)],
          readsFrom: {_db.ayahs, _db.surahs},
        )
        .get();

    return rows.map((row) {
      final ayah = _db.ayahs.map(row.data);
      return AyahSearchResult(ayah: ayah, surahNameAr: row.read<String>('surah_name_ar'));
    }).toList();
  }
}
