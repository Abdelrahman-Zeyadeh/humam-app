import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quran_database.dart';
import 'quran_repository.dart';

/// نسخة واحدة من قاعدة المصحف تعيش طوال عمر التطبيق — تُغلَق تلقائياً
/// عند التخلّص من الـ provider (لا يحدث عملياً إلا بإعادة تشغيل الاختبارات).
final quranDatabaseProvider = Provider<QuranDatabase>((ref) {
  final db = QuranDatabase();
  ref.onDispose(db.close);
  return db;
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository(ref.watch(quranDatabaseProvider));
});
