import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart';
import 'mushaf_font_service.dart';
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

/// عائلة الخط + غليفات آية الفاتحة الأولى (كلماتها الأربع + رمز نهاية
/// الآية — نفس النطاق `id` 1-5 بكل الطبعات الثلاث حرفياً) لمعاينة شكل
/// طبعة معيّنة **بلا تأثير على الطبعة المختارة فعلياً بالمصحف** (خلافاً
/// لـ[mushafPageProvider] الذي يتبع `mushafFontEditionProvider`) — تستخدمها
/// `_MushafFontEditionSection` بشاشة الإعدادات لعرض معاينة حيّة لكل خيار
/// بالـ`SegmentedButton` قبل اختياره. لـV1/V4 (غير مضمَّنتين) هذا يُنزِّل
/// خط صفحة ١ فقط (~٨٠-١٠٠ كيلوبايت) مرّة واحدة، يُخزَّن محلياً بعدها.
typedef MushafEditionPreview = ({String fontFamily, String text});

final mushafEditionPreviewProvider =
    FutureProvider.family<MushafEditionPreview, MushafFontEdition>((ref, edition) async {
  final repo = ref.watch(quranRepositoryProvider);
  final fontService = ref.watch(mushafFontServiceProvider);

  final page = edition == MushafFontEdition.v4Tajweed
      ? await repo.pageLayoutV4(1)
      : await repo.pageLayout(1, preferV1: edition == MushafFontEdition.v1);

  final firstAyahLine = page.lines.firstWhere((l) => l.lineType == 'ayah');
  final words = page.wordsByLine[firstAyahLine.lineNo] ?? const [];
  final text = words.map((w) => w.glyph).join();

  final fontFamily = await fontService.ensureLoaded(1, edition);
  return (fontFamily: fontFamily, text: text);
});
