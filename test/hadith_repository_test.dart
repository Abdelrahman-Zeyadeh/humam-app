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

  test('ثلاثة كتب: البخاري ومسلم والأربعون النووية', () async {
    final books = await repo.allBooks();
    expect(books.length, 3);
    expect(books.map((b) => b.key).toSet(), {'bukhari', 'muslim', 'nawawi'});
  });

  test('حديث الأربعين النووية الأول هو حديث "إنما الأعمال بالنيات"', () async {
    final books = await repo.allBooks();
    final nawawi = books.firstWhere((b) => b.key == 'nawawi');
    final first = (await repo.hadithsForBook(nawawi.id, limit: 1)).single;
    expect(first.hadithNumber, 1);
    expect(first.content, contains('إنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ'));
  });

  test('عدد أحاديث البخاري ومسلم بالحدود المتوقَّعة (فوق الحد الأدنى بسكربت البناء)', () async {
    final books = await repo.allBooks();
    final bukhari = books.firstWhere((b) => b.key == 'bukhari');
    final muslim = books.firstWhere((b) => b.key == 'muslim');
    expect(await repo.countForBook(bukhari.id), greaterThanOrEqualTo(7500));
    expect(await repo.countForBook(muslim.id), greaterThanOrEqualTo(7300));
  });

  test('البحث عن "الأعمال" يطابق حديث الأربعين الأول (كلمة مستقلة، لا "بالنيات" الملتصقة بحرف جر)', () async {
    final results = await repo.search('الأعمال');
    expect(results, isNotEmpty);
    expect(results.any((r) => r.hadith.content.contains('بِالنِّيَّاتِ')), isTrue);
  });
}
