import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quran_database.dart';
import 'quran_repository.dart';
import 'tafsir_edition_registry.dart';

/// نسخة واحدة من قاعدة المصحف تعيش طوال عمر التطبيق — تُغلَق تلقائياً
/// عند التخلّص من الـ provider (لا يحدث عملياً إلا بإعادة تشغيل الاختبارات).
final quranDatabaseProvider = Provider<QuranDatabase>((ref) {
  final db = QuranDatabase();
  ref.onDispose(db.close);
  return db;
});

final tafsirEditionRegistryProvider = Provider<TafsirEditionRegistry>((ref) {
  final registry = TafsirEditionRegistry();
  ref.onDispose(registry.closeAll);
  return registry;
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository(ref.watch(quranDatabaseProvider), ref.watch(tafsirEditionRegistryProvider));
});

final allSurahsProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).allSurahs();
});

final pageAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, page) {
  return ref.watch(quranRepositoryProvider).ayahsForPage(page);
});
