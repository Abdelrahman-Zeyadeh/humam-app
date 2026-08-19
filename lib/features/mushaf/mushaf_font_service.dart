import 'dart:typed_data' show ByteData;

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'font_download_service.dart';

/// يُرمى عند طلب خط صفحة غير مُضمَّنة **ولا محمَّلة محلياً بعد** (الصفحات
/// ١-٥٠ مضمَّنة أصلاً، ٥١-٦٠٤ تحتاج تنزيلاً — راجع `FontDownloadController`).
class PageFontNotBundledException implements Exception {
  PageFontNotBundledException(this.page);
  final int page;

  @override
  String toString() => 'خط الصفحة $page غير متوفّر بعد — يحتاج تنزيلاً';
}

/// تحميل خطوط QCF V2 الديناميكية (خط منفصل لكل صفحة، glyph-per-page)
/// وتسجيلها كعائلة خط بمعرّف فريد لكل صفحة. يُخزَّن ما حُمِّل فعلاً بذاكرة
/// الجلسة لتفادي إعادة القراءة والتسجيل — لا حدّ أقصى بعد لأن أول ٥٠ صفحة
/// فقط مضمَّنة أصلاً؛ نافذة LRU الفعلية (تفريغ الأبعد) مرحلة أداء لاحقة.
///
/// يجرّب أولاً الـ asset المضمَّن (١-٥٠)، ثم ملف مُنزَّل محلياً (٥١-٦٠٤ لو
/// المستخدم نزّله عبر `FontDownloadController`)، وإلا يرمي الاستثناء أعلاه.
class MushafFontService {
  MushafFontService(this._downloads);
  final FontDownloadController _downloads;

  final Set<int> _loaded = {};

  String familyFor(int page) => 'QCF_P$page';

  Future<String> ensureLoaded(int page) async {
    final family = familyFor(page);
    if (_loaded.contains(page)) return family;

    try {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/quran/fonts/pages/p$page.ttf'));
      await loader.load();
      _loaded.add(page);
      return family;
    } catch (_) {
      // rootBundle.load ترمي عند غياب الـ asset — طبيعي لصفحات ٥١+.
    }

    final downloadedFile = await _downloads.localFontFile(page);
    if (await downloadedFile.exists()) {
      final loader = FontLoader(family)..addFont(downloadedFile.readAsBytes().then(ByteData.sublistView));
      await loader.load();
      _loaded.add(page);
      return family;
    }

    throw PageFontNotBundledException(page);
  }
}

final mushafFontServiceProvider = Provider<MushafFontService>((ref) {
  return MushafFontService(ref.watch(fontDownloadControllerProvider.notifier));
});

final pageFontFamilyProvider = FutureProvider.family<String, int>((ref, page) {
  return ref.watch(mushafFontServiceProvider).ensureLoaded(page);
});
