import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_database.dart';
import 'user_repository.dart';

/// نسخة واحدة من `user.db` تعيش طوال عمر التطبيق — نفس نمط `quranDatabaseProvider`.
/// **غير مستخدَمة وقت التشغيل الفعلي** — `main()` يبني `UserDatabase`/`UserRepository`
/// يدوياً قبل `runApp` (لأن الهجرة و[UserRepository.preload] لازم يكتملا قبل أول
/// بناء واجهة، تماماً متل `SharedPreferences.getInstance()`)، ثم يُمرَّر عبر
/// `userRepositoryProvider.overrideWithValue(...)`. هذا الـ provider موجود
/// كقيمة افتراضية للاختبارات التي لا تحتاج تلك الخطوات.
final userDatabaseProvider = Provider<UserDatabase>((ref) {
  final db = UserDatabase();
  ref.onDispose(db.close);
  return db;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(userDatabaseProvider));
});
