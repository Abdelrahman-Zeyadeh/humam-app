import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart';

/// تخطيط صفحة واحدة (سطورها وكلماتها) — يُطلب عند الحاجة فقط لكل صفحة
/// يزورها المستخدم، لا الـ604 دفعة واحدة.
final mushafPageProvider = FutureProvider.family<MushafPage, int>((ref, page) {
  return ref.watch(quranRepositoryProvider).pageLayout(page);
});
