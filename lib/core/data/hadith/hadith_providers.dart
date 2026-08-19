import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hadith_database.dart';
import 'hadith_repository.dart';

final hadithDatabaseProvider = Provider<HadithDatabase>((ref) {
  final db = HadithDatabase();
  ref.onDispose(db.close);
  return db;
});

final hadithRepositoryProvider = Provider<HadithRepository>((ref) {
  return HadithRepository(ref.watch(hadithDatabaseProvider));
});
