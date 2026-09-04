import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hadith_database.dart';
import 'hadith_db_registry.dart';
import 'hadith_repository.dart';

/// الاتصال المضمَّن الوحيد (asset، يحوي الأربعين النووية/القدسية فقط بعد
/// تحويل بقية الكتب لتنزيل حسب الحاجة — راجع `hadith_book_catalog.dart`).
final hadithEmbeddedDatabaseProvider = Provider<HadithDatabase>((ref) {
  final db = HadithDatabase();
  ref.onDispose(db.close);
  return db;
});

final hadithDbRegistryProvider = Provider<HadithDbRegistry>((ref) {
  final registry = HadithDbRegistry(ref.watch(hadithEmbeddedDatabaseProvider));
  // يُغلق اتصالات الكتب المنزَّلة فقط — الاتصال المضمَّن يُغلَق منفصلاً
  // بواسطة `hadithEmbeddedDatabaseProvider.onDispose` أعلاه (تجنّباً لإغلاقه مرّتين).
  ref.onDispose(registry.closeDownloadedConnections);
  return registry;
});

final hadithRepositoryProvider = Provider<HadithRepository>((ref) {
  return HadithRepository(ref.watch(hadithDbRegistryProvider));
});
