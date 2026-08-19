// اختبار تكامل لطبقة وصول الأحاديث: يفتح hadith.db الحقيقية المضمّنة
// كـ asset ويتأكد من بيانات أساسية معروفة.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/hadith/hadith_database.dart';
import 'package:humam_app/core/data/hadith/hadith_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HadithDatabase db;
  late HadithRepository repo;

  setUpAll(() {
    final dbFile = File(p.join(p.current, 'assets', 'hadith', 'hadith.db'));
    db = HadithDatabase.forTesting(NativeDatabase(dbFile));
    repo = HadithRepository(db);
  });

  tearDownAll(() => db.close());

  test('تسعة كتب: البخاري ومسلم والأربعون النووية وستّة أخرى', () async {
    final books = await repo.allBooks();
    expect(books.length, 9);
    expect(books.map((b) => b.key).toSet(), {
      'bukhari', 'muslim', 'nawawi', 'abudawud', 'tirmidhi', 'nasai', 'ibnmajah', 'malik', 'qudsi',
    });
  });

  test('حديث الأربعين النووية الأول هو حديث "إنما الأعمال بالنيات"', () async {
    final books = await repo.allBooks();
    final nawawi = books.firstWhere((b) => b.key == 'nawawi');
    final first = (await repo.hadithsForBook(nawawi.id, limit: 1)).single;
    expect(first.hadithNumber, 1);
    expect(first.content, contains('إنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ'));
  });

  test('عدد أحاديث كل كتاب بالحدود المتوقَّعة (فوق الحد الأدنى بسكربت البناء)', () async {
    final books = await repo.allBooks();
    Future<void> expectAtLeast(String key, int minCount) async {
      final book = books.firstWhere((b) => b.key == key);
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
    final books = await repo.allBooks();
    for (final book in books) {
      final chapters = await repo.chaptersForBook(book.id);
      expect(chapters, isNotEmpty, reason: book.key);
      // مجموع الأحاديث بكل الأبواب، لا الباب الأول تحديداً — بعض الأبواب
      // فعلياً بلا أحاديث (قسم "بلا عنوان" بمصدر البيانات نفسه، راجع
      // build_hadith_db.py)، فليس كل باب مفرد يُتوقَّع منه عدد > صفر.
      final total = chapters.fold<int>(0, (sum, c) => sum + c.hadithCount);
      expect(total, greaterThan(0), reason: book.key);
    }
  });
}
