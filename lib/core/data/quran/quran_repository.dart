import 'package:drift/drift.dart';

import '../../text/arabic_normalizer.dart';
import 'quran_database.dart';
import 'tafsir_edition_catalog.dart';
import 'tafsir_edition_registry.dart';

/// نتيجة بحث في نص المصحف: الآية + رقم صفحتها للانتقال والتظليل.
class AyahSearchResult {
  const AyahSearchResult({required this.ayah, required this.surahNameAr});
  final Ayah ayah;
  final String surahNameAr;
}

/// آية متشابهة لفظاً بآية أخرى (قد تكون بسورة مختلفة) — راجع توثيق
/// [QuranRepository.similarAyahsFor].
class SimilarAyahResult {
  const SimilarAyahResult({required this.ayah, required this.surahNameAr});
  final Ayah ayah;
  final String surahNameAr;
}

/// ربع واحد ضمن جزء (١-٤) — راجع توثيق [QuranRepository.rubDetailsForJuz].
class RubDetail {
  const RubDetail({required this.rubInJuz, required this.startAyah, required this.startPage});
  final int rubInJuz;
  final Ayah startAyah;
  final int startPage;
}

/// سطر واحد من سطور صفحة مصحف — تجريد موحّد فوق [PageLine]/[PageLinesV4Data]
/// (الجدولان متطابقا الأعمدة اسماً ونوعاً، بس درift بيولّد صنفاً منفصلاً
/// لكل جدول) ليتعامل [MushafPage] وواجهة العرض مع طبعة واحدة بغض النظر عن
/// مصدرها الفعلي — راجع [QuranRepository.pageLayout]/[pageLayoutV4].
class MushafPageLineInfo {
  const MushafPageLineInfo({
    required this.page,
    required this.lineNo,
    required this.lineType,
    required this.isCentered,
    this.surahRef,
  });
  final int page;
  final int lineNo;
  final String lineType;
  final int isCentered;
  final int? surahRef;
}

/// كلمة واحدة جاهزة للرسم — تجريد موحّد فوق [Word]/[WordsV4Data] بنفس
/// فكرة [MushafPageLineInfo]. [glyph] هو **الرمز النهائي المطلوب رسمه
/// فعلياً** بالطبعة المطلوبة (اختيار glyph/glyphV1 لطبعتَي V1/V2
/// يُحسَم هنا بـ[QuranRepository.pageLayout]، لا بواجهة العرض).
class MushafWord {
  const MushafWord({
    required this.id,
    required this.ayahId,
    required this.lineNo,
    required this.charType,
    required this.glyph,
  });

  /// معرّف الكلمة العام (تسلسل بكل المصحف) — الترتيب الصحيح داخل السطر،
  /// **ليس** `position` (رقم الكلمة داخل آيتها فقط، يرجع لـ١ بكل آية).
  final int id;
  final int ayahId;
  final int lineNo;
  final String charType; // word | ayah_marker
  final String glyph;
}

/// تخطيط صفحة مصحف كامل جاهز للعرض: سطورها بالترتيب، وكلمات كل سطر.
class MushafPage {
  const MushafPage({required this.page, required this.lines, required this.wordsByLine});
  final int page;
  final List<MushafPageLineInfo> lines;
  final Map<int, List<MushafWord>> wordsByLine; // lineNo -> كلماته بالترتيب
}

/// طبقة الوصول لقاعدة `quran.db`. كل الاستعلامات تُنفَّذ على isolate drift
/// المنفصل (`NativeDatabase.createInBackground`) — لا تحجب الخيط الرئيسي.
class QuranRepository {
  QuranRepository(this._db, [TafsirEditionRegistry? tafsirRegistry])
    : _tafsirRegistry = tafsirRegistry ?? TafsirEditionRegistry();
  final QuranDatabase _db;
  final TafsirEditionRegistry _tafsirRegistry;

  Future<List<Surah>> allSurahs() => _db.select(_db.surahs).get();

  Future<Surah> surahById(int id) =>
      (_db.select(_db.surahs)..where((s) => s.id.equals(id))).getSingle();

  Future<Ayah> ayahById(int id) =>
      (_db.select(_db.ayahs)..where((a) => a.id.equals(id))).getSingle();

  /// تفسير آية واحدة بإصدار معيّن. **كل الإصدارات الأربعة تنزيل حسب
  /// الحاجة الآن** (`kEmbeddedTafsirEditions` فارغة، لا شيء مضمَّن
  /// بـ`quran.db` — راجع `tafsir_edition_catalog.dart`): `null` لو
  /// الإصدار غير منزَّل بعد **أو** لا تفسير لهذه الآية بهذا الإصدار (لا
  /// تمييز بين الحالتين هون عمداً — الواجهة تميّز عبر
  /// `TafsirDownloadController.statusFor` قبل الاستدعاء أصلاً، راجع
  /// `ayah_text_view_screen.dart`).
  Future<Tafsir?> tafsirForAyah(int ayahId, {String edition = 'jalalayn'}) async {
    if (kEmbeddedTafsirEditions.contains(edition)) {
      return (_db.select(_db.tafsirs)
            ..where((t) => t.ayahId.equals(ayahId) & t.edition.equals(edition)))
          .getSingleOrNull();
    }
    final editionDb = await _tafsirRegistry.dbForEdition(edition);
    if (editionDb == null) return null;
    final row = await (editionDb.select(editionDb.tafsirTexts)..where((t) => t.ayahId.equals(ayahId)))
        .getSingleOrNull();
    if (row == null) return null;
    return Tafsir(id: row.ayahId, ayahId: row.ayahId, edition: edition, content: row.body);
  }

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

  /// نطاق آيات متتالٍ بمعرّفات صفوف من fromId إلى toId شاملَين — يُستخدَم
  /// لميزة "من — إلى" باستوديو بطاقات الآيات (`AyahStoryMakerScreen`).
  Future<List<Ayah>> ayahsInIdRange(int fromId, int toId) => (_db.select(_db.ayahs)
        ..where((a) =>
            a.id.isBiggerOrEqualValue(fromId) & a.id.isSmallerOrEqualValue(toId))
        ..orderBy([(a) => OrderingTerm.asc(a.id)]))
      .get();

  /// غليف علامة نهاية الآية لخط صفحتها بالمصحف (QCF V2)
  Future<String?> ayahMarkerGlyph(int ayahId) async {
    final row = await (_db.select(_db.words)
          ..where((w) => w.ayahId.equals(ayahId) & w.charType.equals('ayah_marker'))
          ..limit(1))
        .getSingleOrNull();
    return row?.glyph;
  }

  /// أول صفحة لكل جزء (١-٣٠) — للتنقّل بالجزء من فهرس المصحف. تقريب على
  /// مستوى الصفحة لا الآية الدقيقة، كافٍ لفتح الصفحة الأولى للجزء.
  Future<Map<int, int>> juzStartPages() async {
    final rows = await _db
        .customSelect(
          'SELECT juz, MIN(page) AS start_page FROM ayahs GROUP BY juz ORDER BY juz',
          readsFrom: {_db.ayahs},
        )
        .get();
    return {for (final r in rows) r.read<int>('juz'): r.read<int>('start_page')};
  }

  /// رقم الحزب لأول آية بصفحة معيّنة — لعرضه بشريط تنقّل الصفحات (نفس
  /// تقريب [juzStartPages]: مستوى الصفحة لا الآية الدقيقة). `Ayahs.hizb`
  /// مُعبَّأ بالكامل فعلياً (٦٢٣٦/٦٢٣٦ آية، ٦٠ حزباً — راجع
  /// `tools/build_quran_db.py`)، لا حاجة تنزيل/إعادة بناء `quran.db`.
  Future<int> hizbForPage(int page) async {
    final row = await (_db.select(_db.ayahs)
          ..where((a) => a.page.equals(page))
          ..orderBy([(a) => OrderingTerm.asc(a.ayah)])
          ..limit(1))
        .getSingleOrNull();
    return row?.hizb ?? 1;
  }

  /// ربع-الحزب (`Ayahs.rub`، ١..٢٤٠) لأول آية بصفحة — نفس نمط [hizbForPage].
  /// **تحقّق مباشر بالبيانات:** الترقيم متسلسل ومحاذٍ لحدود الأحزاب فعلياً
  /// (حزب ١ = ربع ١..٤، حزب ٢ = ربع ٥..٨...، ٤ أرباع لكل حزب بالضبط
  /// ٦٠×٤=٢٤٠)، فحساب "أي ربع ضمن هذا الحزب" = `((rub - 1) % 4) + 1`
  /// صحيح دوماً بلا استثناء — راجع `_PageIdentityBar` بـ`mushaf_screen.dart`
  /// لاستخدامه (تسمية "ربع/نصف/ثلاثة أرباع الحزب" بدل رقم حزب مجرَّد).
  Future<int> rubForPage(int page) async {
    final row = await (_db.select(_db.ayahs)
          ..where((a) => a.page.equals(page))
          ..orderBy([(a) => OrderingTerm.asc(a.ayah)])
          ..limit(1))
        .getSingleOrNull();
    return row?.rub ?? 1;
  }

  /// تفصيل الأرباع الأربعة لجزء معيّن (١-٣٠): رقم الربع ضمن الجزء (١-٤)،
  /// أول آية له (سورة+رقم آية)، وصفحة بدايته. `Ayahs.rub` مُعبَّأ بالكامل
  /// فعلياً (٢٤٠ ربعاً بكل المصحف = ٤ لكل جزء)، راجع توثيق [hizbForPage].
  Future<List<RubDetail>> rubDetailsForJuz(int juz) async {
    final rows = await _db
        .customSelect(
          'SELECT rub, MIN(id) AS start_ayah_id, MIN(page) AS start_page '
          'FROM ayahs WHERE juz = ? GROUP BY rub ORDER BY rub',
          variables: [Variable.withInt(juz)],
          readsFrom: {_db.ayahs},
        )
        .get();
    final result = <RubDetail>[];
    for (final r in rows) {
      final startAyah = await ayahById(r.read<int>('start_ayah_id'));
      result.add(RubDetail(
        rubInJuz: result.length + 1,
        startAyah: startAyah,
        startPage: r.read<int>('start_page'),
      ));
    }
    return result;
  }

  /// تخطيط صفحة كاملة (طبعتَي V1/V2 — يتشاركان نفس ترقيم `page_lines`/
  /// `words`، راجع توثيق [Words.glyphV1]): سطورها وكلماتها، جاهزة للرسم
  /// بخط `p{page}.ttf`. [preferV1] يختار عمود `glyph_v1` لكل كلمة (بدل
  /// `glyph` الافتراضي لـV2) إن كان مُعبّأً، وإلا يسقط تلقائياً لـV2 لتلك
  /// الكلمة تحديداً (V1 لسا غير مكتمل التعبئة — راجع `tools/quran_layout.py`).
  Future<MushafPage> pageLayout(int page, {bool preferV1 = false}) async {
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

    final wordsByLine = <int, List<MushafWord>>{};
    for (final w in words) {
      final glyph = (preferV1 && w.glyphV1 != null) ? w.glyphV1! : w.glyph;
      wordsByLine.putIfAbsent(w.lineNo, () => []).add(
            MushafWord(id: w.id, ayahId: w.ayahId, lineNo: w.lineNo, charType: w.charType, glyph: glyph),
          );
    }

    return MushafPage(
      page: page,
      lines: [
        for (final l in lines)
          MushafPageLineInfo(
            page: l.page,
            lineNo: l.lineNo,
            lineType: l.lineType,
            isCentered: l.isCentered,
            surahRef: l.surahRef,
          ),
      ],
      wordsByLine: wordsByLine,
    );
  }

  /// تخطيط صفحة كاملة بطبعة **V4 Tajweed** (١٤٤١هـ، ألوان تجويد مدمجة
  /// بالglyph) — جدول مستقل تماماً (`page_lines_v4`/`words_v4`)، لا علاقة
  /// له بترقيم [pageLayout] (V1/V2). راجع توثيق [PageLinesV4]/[WordsV4].
  Future<MushafPage> pageLayoutV4(int page) async {
    final lines = await (_db.select(_db.pageLinesV4)
          ..where((l) => l.page.equals(page))
          ..orderBy([(l) => OrderingTerm.asc(l.lineNo)]))
        .get();

    final words = await (_db.select(_db.wordsV4)
          ..where((w) => w.page.equals(page))
          ..orderBy([(w) => OrderingTerm.asc(w.id)]))
        .get();

    final wordsByLine = <int, List<MushafWord>>{};
    for (final w in words) {
      wordsByLine.putIfAbsent(w.lineNo, () => []).add(
            MushafWord(id: w.id, ayahId: w.ayahId, lineNo: w.lineNo, charType: w.charType, glyph: w.glyph),
          );
    }

    return MushafPage(
      page: page,
      lines: [
        for (final l in lines)
          MushafPageLineInfo(
            page: l.page,
            lineNo: l.lineNo,
            lineType: l.lineType,
            isCentered: l.isCentered,
            surahRef: l.surahRef,
          ),
      ],
      wordsByLine: wordsByLine,
    );
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

  /// كل الآيات المتشابهة لفظاً بهذه الآية (قد تكون بسور مختلفة تماماً) —
  /// راجع `tools/raw/README.md` "المتشابهات". كل صف بجدول `mutashabihat`
  /// اتجاه واحد فقط (`ayah_id → similar_ayah_id`)، والمصدر يخزّن الاتجاهين
  /// كصفّين مستقلّين بالفعل — فاستعلام `WHERE ayah_id = ?` وحده كافٍ، بلا
  /// حاجة لـ`OR` أو تطبيع طرف.
  Future<List<SimilarAyahResult>> similarAyahsFor(int ayahId) async {
    final rows = await _db
        .customSelect(
          '''
          SELECT ayahs.*, surahs.name_ar AS surah_name_ar
          FROM mutashabihat
          JOIN ayahs ON ayahs.id = mutashabihat.similar_ayah_id
          JOIN surahs ON surahs.id = ayahs.surah
          WHERE mutashabihat.ayah_id = ?
          ORDER BY ayahs.id
          ''',
          variables: [Variable.withInt(ayahId)],
          readsFrom: {_db.mutashabihat, _db.ayahs, _db.surahs},
        )
        .get();

    return rows.map((row) {
      final ayah = _db.ayahs.map(row.data);
      return SimilarAyahResult(ayah: ayah, surahNameAr: row.read<String>('surah_name_ar'));
    }).toList();
  }
}
