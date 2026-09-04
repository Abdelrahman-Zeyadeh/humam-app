// اختبار تكامل لطبقة وصول الأحاديث: يفتح hadith.db الحقيقية المضمّنة
// (الأربعون النووية/القدسية فقط الآن — راجع hadith_book_catalog.dart)
// **و**شظايا tools/hadith_shards/*.db للكتب السبعة الأخرى (تنزيل اختياري
// بالتطبيق الفعلي، لكن هنا نفتحها مباشرة عبر
// HadithDatabase.forDownloadedBook — نفس الآلية بالضبط، فقط بلا تنزيل HTTP
// فعلي) — يتأكد من بيانات أساسية معروفة عبر HadithDbRegistry.forTesting.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/hadith/essential_hadith_fallback.dart';
import 'package:humam_app/core/data/hadith/hadith_book_catalog.dart';
import 'package:humam_app/core/data/hadith/hadith_database.dart';
import 'package:humam_app/core/data/hadith/hadith_db_registry.dart';
import 'package:humam_app/core/data/hadith/hadith_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HadithDatabase embeddedDb;
  late Map<String, HadithDatabase> shardDbs;
  late HadithRepository repo;

  setUpAll(() {
    final embeddedFile = File(p.join(p.current, 'assets', 'hadith', 'hadith.db'));
    embeddedDb = HadithDatabase.forTesting(NativeDatabase(embeddedFile));

    shardDbs = {
      for (final key in kHadithBookCatalog.map((b) => b.key).where((k) => !kEmbeddedHadithBookKeys.contains(k)))
        key: HadithDatabase.forDownloadedBook(File(p.join(p.current, 'tools', 'hadith_shards', '$key.db'))),
    };

    final registry = HadithDbRegistry.forTesting(embeddedDb, shardDbs);
    repo = HadithRepository(registry);
  });

  tearDownAll(() async {
    await embeddedDb.close();
    for (final db in shardDbs.values) {
      await db.close();
    }
  });

  test('تسعة كتب بالكتالوج: البخاري ومسلم والأربعون النووية وستّة أخرى', () {
    final books = repo.allBooks();
    expect(books.length, 9);
    expect(books.map((b) => b.key).toSet(), {
      'bukhari', 'muslim', 'nawawi', 'abudawud', 'tirmidhi', 'nasai', 'ibnmajah', 'malik', 'qudsi',
    });
  });

  test('حديث الأربعين النووية الأول هو حديث "إنما الأعمال بالنيات"', () async {
    final nawawi = repo.bookById(3);
    final first = (await repo.hadithsForBook(nawawi.id, limit: 1)).single;
    expect(first.hadithNumber, 1);
    expect(first.content, contains('إنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ'));
  });

  test('عدد أحاديث كل كتاب بالحدود المتوقَّعة (فوق الحد الأدنى بسكربت البناء)', () async {
    Future<void> expectAtLeast(String key, int minCount) async {
      final book = kHadithBookCatalog.firstWhere((b) => b.key == key);
      expect(await repo.countForBook(book.id), greaterThanOrEqualTo(minCount), reason: key);
    }

    await expectAtLeast('bukhari', 7500);
    await expectAtLeast('muslim', 7300);
    await expectAtLeast('abudawud', 5200);
    await expectAtLeast('tirmidhi', 3850);
    await expectAtLeast('nasai', 5600);
    await expectAtLeast('ibnmajah', 4250);
    await expectAtLeast('malik', 1750);
    await expectAtLeast('qudsi', 40);
  });

  test('البحث عن "الأعمال" يطابق حديث الأربعين الأول (كلمة مستقلة، لا "بالنيات" الملتصقة بحرف جر)', () async {
    final results = await repo.search('الأعمال');
    expect(results, isNotEmpty);
    expect(results.any((r) => r.hadith.content.contains('بِالنِّيَّاتِ')), isTrue);
  });

  test('أبواب كل كتاب تُقرأ فعلياً بلا استثناء (عطل حقيقي رُصد بجهاز فعلي وأُصلح)', () async {
    for (final book in kHadithBookCatalog) {
      final chapters = await repo.chaptersForBook(book.id);
      expect(chapters, isNotEmpty, reason: book.key);
      // مجموع الأحاديث بكل الأبواب، لا الباب الأول تحديداً — بعض الأبواب
      // فعلياً بلا أحاديث (قسم "بلا عنوان" بمصدر البيانات نفسه، راجع
      // build_hadith_db.py)، فليس كل باب مفرد يُتوقَّع منه عدد > صفر.
      final total = chapters.fold<int>(0, (sum, c) => sum + c.hadithCount);
      expect(total, greaterThan(0), reason: book.key);
    }
  });

  test(
    'استشهادات التذكيرات الثابتة (essential_hadith_fallback) مطابقة حرفياً لمصدرها الحقيقي بالكتاب',
    () async {
      // hadithByBookAndNumber يفضّل قاعدة البيانات الفعلية دائماً حين تكون
      // متاحة — الـfallback حالة استثنائية فقط (كتاب غير منزَّل). هنا الكتب
      // كلها "منزَّلة" فعلياً (شظايا الاختبار)، فيجب أن يُقرأ من المصدر
      // الحقيقي، **ويطابق** النسخة الثابتة المنسوخة يدوياً بالكود حرفياً —
      // هذا يتحقّق من صحة النسخ نفسه، لا فقط من "شيء ما رجع".
      for (final entry in kEssentialHadithFallback.entries) {
        final fallback = entry.value;
        final fromDb = await repo.hadithByBookAndNumber(fallback.bookId, fallback.hadithNumber);
        expect(fromDb, isNotNull, reason: entry.key);
        expect(fromDb!.content, fallback.content, reason: entry.key);
      }
    },
  );
}
