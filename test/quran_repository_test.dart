// اختبار تكامل لطبقة الوصول: يفتح قاعدة quran.db الحقيقية المضمّنة
// كـ asset ويتأكد من صحة بيانات أساسية معروفة (الفاتحة، صفحة ١، والبحث).

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/quran/quran_database.dart';
import 'package:humam_app/core/data/quran/quran_repository.dart';
import 'package:humam_app/core/data/quran/tafsir_edition_database.dart';
import 'package:humam_app/core/data/quran/tafsir_edition_registry.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranDatabase db;
  late Map<String, TafsirEditionDatabase> tafsirEditionDbs;
  late QuranRepository repo;

  setUpAll(() {
    // نفتح الملف المبنى مباشرة (بدل نسخه من الأصول) لأن اختبارات الوحدة
    // لا تشغّل محرك Flutter الكامل ولا تصل rootBundle بسهولة.
    final dbFile = File(p.join(p.current, 'assets', 'quran', 'quran.db'));
    db = QuranDatabase.forTesting(NativeDatabase(dbFile));

    // الأربعة (بما فيهم الجلالين — لم يعد مضمَّناً، راجع
    // tafsir_edition_catalog.dart) صاروا تنزيلاً اختيارياً — بيئة الاختبار
    // "تنزّلهم" بفتح اتصال مباشر على الملفات المولَّدة محلياً بـ
    // tools/tafsir_editions/ (نفس نمط test/hadith_repository_test.dart تماماً).
    tafsirEditionDbs = {
      for (final key in ['jalalayn', 'muyassar', 'saadi', 'ibnkathir'])
        key: TafsirEditionDatabase(File(p.join(p.current, 'tools', 'tafsir_editions', 'tafsir_$key.db'))),
    };
    final tafsirRegistry = TafsirEditionRegistry.forTesting(tafsirEditionDbs);

    repo = QuranRepository(db, tafsirRegistry);
  });

  tearDownAll(() async {
    await db.close();
    for (final editionDb in tafsirEditionDbs.values) {
      await editionDb.close();
    }
  });

  test('سورة الفاتحة: ٧ آيات تبدأ من الصفحة ١', () async {
    final fatiha = await repo.surahById(1);
    expect(fatiha.ayahCount, 7);
    expect(fatiha.startPage, 1);

    final ayahs = await repo.ayahsForSurah(1);
    expect(ayahs.length, 7);
    expect(ayahs.first.textUthmani, contains('بِسۡمِ'));
  });

  test('صفحة ١ تحتوي آيات الفاتحة السبع فقط', () async {
    final page1 = await repo.ayahsForPage(1);
    expect(page1.length, 7);
    expect(page1.every((a) => a.surah == 1), isTrue);
  });

  test('البحث عن "الرحمن" يطابق ولو مع اختلاف التشكيل', () async {
    final results = await repo.search('الرحمن');
    expect(results, isNotEmpty);
    expect(results.first.ayah.surah, 1);
  });

  test('تخطيط الصفحة ١: ٨ أسطر، وآخر كلمة بكل آية علامة نهاية الآية', () async {
    final page1 = await repo.pageLayout(1);
    expect(page1.lines.length, 8);
    expect(page1.lines.first.lineType, 'surah_name');

    // السطر الثاني هو آية الفاتحة الأولى: كلماتها الأربع + علامة نهاية الآية.
    final firstAyahWords = page1.wordsByLine[2]!;
    expect(firstAyahWords.length, 5);
    expect(firstAyahWords.last.charType, 'ayah_marker');
    expect(firstAyahWords.sublist(0, 4).every((w) => w.charType == 'word'), isTrue);
    expect(firstAyahWords.every((w) => w.glyph.isNotEmpty), isTrue);
  });

  test('تفسير الجلالين وترجمة صحيح إنترناشونال متوفّران لآية الفاتحة الأولى', () async {
    final fatiha1 = (await repo.ayahsForSurah(1)).first;

    final tafsir = await repo.tafsirForAyah(fatiha1.id);
    expect(tafsir, isNotNull);
    expect(tafsir!.content, contains('بسم الله'));

    final translation = await repo.translationForAyah(fatiha1.id);
    expect(translation, isNotNull);
    expect(translation!.content.toLowerCase(), contains('allah'));
  });

  test('التفاسير الثلاثة الإضافية (الميسر/السعدي/ابن كثير) متوفّرة — عيّنة من ٣ آيات متفرّقة', () async {
    // عيّنة لا كل ٦٢٣٦ آية (بطء غير ضروري باختبار وحدة) — التحقّق الشامل
    // فعلياً بـ`tools/quran_texts.py` وقت البناء (يفشل البناء نفسه لو نقص
    // صف واحد لأي إصدار).
    final samples = [
      (await repo.ayahsForSurah(1)).first, // الفاتحة ١
      (await repo.ayahsForSurah(2)).last, // البقرة (آخر آية، طويلة)
      (await repo.ayahsForSurah(114)).first, // الناس ١ (آخر سورة)
    ];
    for (final ayah in samples) {
      for (final edition in ['muyassar', 'saadi', 'ibnkathir']) {
        final tafsir = await repo.tafsirForAyah(ayah.id, edition: edition);
        expect(tafsir, isNotNull, reason: 'تفسير $edition للآية ${ayah.id}');
        expect(tafsir!.content, isNotEmpty);
      }
    }
  });

  test('متشابهات: آية ١:١ تحوي تطابقاً مع ٢٧:٣٠ (مؤكَّد يدوياً من raw/matching-ayah.db)', () async {
    final fatiha1 = (await repo.ayahsForSurah(1)).first;
    final results = await repo.similarAyahsFor(fatiha1.id);
    expect(results, isNotEmpty);

    final naml30 = await repo.surahById(27);
    expect(results.any((r) => r.ayah.surah == 27 && r.ayah.ayah == 30), isTrue);
    expect(results.firstWhere((r) => r.ayah.surah == 27).surahNameAr, naml30.nameAr);
  });

  test('متشابهات: آية بلا تطابق موثّق (الناس ٢) ترجع قائمة فارغة لا خطأً', () async {
    // عيّنة من الغالبية غير المغطاة (١١٦٢ آية فقط من ٦٢٣٦ لها تطابق موثّق)
    // — مؤكَّدة يدوياً بلا صف بجدول mutashabihat.
    final nas2 = (await repo.ayahsForSurah(114))[1];
    expect(nas2.ayah, 2);
    final results = await repo.similarAyahsFor(nas2.id);
    expect(results, isEmpty);
  });

  test('ترتيب كلمات السطر بمعرّفها العام (id) لا برقمها داخل الآية (position)', () async {
    // صفحة ٧: أسطرها تحوي نهايات وبدايات آيات متتالية بنفس السطر — لو
    // رُتِّبت الكلمات بـ position (يرجع لـ١ كل آية) بدل id، تختلط كلمات
    // الآية التالية قبل تمام السابقة. راجع quran_repository.pageLayout.
    final page7 = await repo.pageLayout(7);
    for (final entry in page7.wordsByLine.entries) {
      final ids = entry.value.map((w) => w.id).toList();
      final sorted = [...ids]..sort();
      expect(ids, sorted, reason: 'سطر ${entry.key} بصفحة ٧ غير مرتب بمعرّف الكلمة العام');
    }
  });

  test('تدقيق أسماء سور القرآن الـ ١١٤ ومطابقتها لمصحف المدينة النبوية والهمزات الصحيحة', () async {
    final surahs = await repo.allSurahs();
    expect(surahs.length, 114);

    final surahMap = {for (final s in surahs) s.id: s};

    // عيّنات للسور التي كانت بها أخطاء إملائية أو همزات ساقطة سابقاً
    expect(surahMap[3]!.nameAr, 'سُورَةُ آلِ عِمْرَانَ');
    expect(surahMap[3]!.nameArPlain, 'سورة آل عمران');

    expect(surahMap[6]!.nameAr, 'سُورَةُ الأَنْعَامِ');
    expect(surahMap[6]!.nameArPlain, 'سورة الأنعام');

    expect(surahMap[7]!.nameAr, 'سُورَةُ الأَعْرَافِ');
    expect(surahMap[7]!.nameArPlain, 'سورة الأعراف');

    expect(surahMap[8]!.nameAr, 'سُورَةُ الأَنْفَالِ');
    expect(surahMap[8]!.nameArPlain, 'سورة الأنفال');

    expect(surahMap[14]!.nameAr, 'سُورَةُ إِبْرَاهِيمَ');
    expect(surahMap[14]!.nameArPlain, 'سورة إبراهيم');

    expect(surahMap[17]!.nameAr, 'سُورَةُ الإِسْرَاءِ');
    expect(surahMap[17]!.nameArPlain, 'سورة الإسراء');

    expect(surahMap[20]!.nameAr, 'سُورَةُ طه');
    expect(surahMap[20]!.nameArPlain, 'سورة طه');

    expect(surahMap[21]!.nameAr, 'سُورَةُ الأَنْبِيَاءِ');
    expect(surahMap[21]!.nameArPlain, 'سورة الأنبياء');

    expect(surahMap[33]!.nameAr, 'سُورَةُ الأَحْزَابِ');
    expect(surahMap[33]!.nameArPlain, 'سورة الأحزاب');

    expect(surahMap[34]!.nameAr, 'سُورَةُ سَبَأٍ');
    expect(surahMap[34]!.nameArPlain, 'سورة سبأ');

    expect(surahMap[36]!.nameAr, 'سُورَةُ يس');
    expect(surahMap[36]!.nameArPlain, 'سورة يس');

    expect(surahMap[40]!.nameAr, 'سُورَةُ غَافِرٍ');
    expect(surahMap[40]!.nameArPlain, 'سورة غافر');

    expect(surahMap[42]!.nameAr, 'سُورَةُ الشُّورَى');
    expect(surahMap[42]!.nameArPlain, 'سورة الشورى');

    expect(surahMap[46]!.nameAr, 'سُورَةُ الأَحْقَافِ');
    expect(surahMap[46]!.nameArPlain, 'سورة الأحقاف');

    expect(surahMap[55]!.nameAr, 'سُورَةُ الرَّحْمَٰنِ');
    expect(surahMap[55]!.nameArPlain, 'سورة الرحمن');

    expect(surahMap[76]!.nameAr, 'سُورَةُ الإِنْسَانِ');
    expect(surahMap[76]!.nameArPlain, 'سورة الإنسان');

    expect(surahMap[78]!.nameAr, 'سُورَةُ النَّبَإِ');
    expect(surahMap[78]!.nameArPlain, 'سورة النبأ');

    expect(surahMap[82]!.nameAr, 'سُورَةُ الانْفِطَارِ');
    expect(surahMap[82]!.nameArPlain, 'سورة الانفطار');

    expect(surahMap[84]!.nameAr, 'سُورَةُ الانْشِقَاقِ');
    expect(surahMap[84]!.nameArPlain, 'سورة الانشقاق');

    expect(surahMap[87]!.nameAr, 'سُورَةُ الأَعْلَى');
    expect(surahMap[87]!.nameArPlain, 'سورة الأعلى');

    expect(surahMap[92]!.nameAr, 'سُورَةُ اللَّيْلِ');
    expect(surahMap[92]!.nameArPlain, 'سورة الليل');

    expect(surahMap[93]!.nameAr, 'سُورَةُ الضُّحَى');
    expect(surahMap[93]!.nameArPlain, 'سورة الضحى');

    expect(surahMap[99]!.nameAr, 'سُورَةُ الزَّلْزَلَةِ');
    expect(surahMap[99]!.nameArPlain, 'سورة الزلزلة');

    expect(surahMap[112]!.nameAr, 'سُورَةُ الإِخْلَاصِ');
    expect(surahMap[112]!.nameArPlain, 'سورة الإخلاص');

    for (final s in surahs) {
      expect(s.nameAr.startsWith('سُورَةُ '), isTrue, reason: 'السورة ${s.id} nameAr يجب أن تبدأ بـ سُورَةُ');
      expect(s.nameArPlain.startsWith('سورة '), isTrue, reason: 'السورة ${s.id} nameArPlain يجب أن تبدأ بـ سورة');
    }
  });
}
