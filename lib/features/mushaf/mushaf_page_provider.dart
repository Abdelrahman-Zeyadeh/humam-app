import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart';
import 'mushaf_settings.dart';

/// تخطيط صفحة واحدة (سطورها وكلماتها) — يُطلب عند الحاجة فقط لكل صفحة
/// يزورها المستخدم، لا الـ604 دفعة واحدة. يتبع طبعة الخط المختارة
/// (`mushafFontEditionProvider`): V4 Tajweed لها جدول تخطيط مستقل تماماً
/// (`pageLayoutV4`)، بينما V1/V2 يتشاركان جدولاً واحداً (`pageLayout`).
final mushafPageProvider = FutureProvider.family<MushafPage, int>((ref, page) {
  final edition = ref.watch(mushafFontEditionProvider);
  final repo = ref.watch(quranRepositoryProvider);
  return switch (edition) {
    MushafFontEdition.v4Tajweed => repo.pageLayoutV4(page),
    MushafFontEdition.v1 => repo.pageLayout(page, preferV1: true),
    MushafFontEdition.v2 => repo.pageLayout(page),
  };
});
