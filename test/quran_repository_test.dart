// اختبار تكامل لطبقة الوصول: يفتح قاعدة quran.db الحقيقية المضمّنة
// كـ asset ويتأكد من صحة بيانات أساسية معروفة (الفاتحة، صفحة ١، والبحث).

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/quran/quran_database.dart';
import 'package:humam_app/core/data/quran/quran_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranDatabase db;
  late QuranRepository repo;

  setUpAll(() {
    // نفتح الملف المبنى مباشرة (بدل نسخه من الأصول) لأن اختبارات الوحدة
    // لا تشغّل محرك Flutter الكامل ولا تصل rootBundle بسهولة.
    final dbFile = File(p.join(p.current, 'assets', 'quran', 'quran.db'));
    db = QuranDatabase.forTesting(NativeDatabase(dbFile));
    repo = QuranRepository(db);
  });

  tearDownAll(() => db.close());

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
}
