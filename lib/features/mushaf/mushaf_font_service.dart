import 'dart:typed_data' show ByteData;

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'font_download_service.dart';
import 'mushaf_settings.dart' show MushafFontEdition, mushafFontEditionProvider;

/// يُرمى عند طلب خط صفحة غير مُضمَّنة **ولا محمَّلة محلياً بعد**
class PageFontNotBundledException implements Exception {
  PageFontNotBundledException(this.page, [this.edition = MushafFontEdition.v2]);
  final int page;
  final MushafFontEdition edition;

  @override
  String toString() => 'خط الصفحة $page (${edition.name}) غير متوفّر بعد — يحتاج تنزيلاً';
}

/// تحميل خطوط QCF (خط منفصل لكل صفحة، glyph-per-page) لطبعتي V1 و V2
/// وتسجيلها كعائلة خط بمعرّف فريد لكل صفحة وطبعة.
class MushafFontService {
  MushafFontService(this._downloads);
  final FontDownloadController _downloads;

  final Set<String> _loaded = {};

  String familyFor(int page, [MushafFontEdition edition = MushafFontEdition.v2]) =>
      edition == MushafFontEdition.v1 ? 'QCF_V1_P$page' : 'QCF_P$page';

  Future<String> ensureLoaded(int page, [MushafFontEdition edition = MushafFontEdition.v2]) async {
    final family = familyFor(page, edition);
    if (_loaded.contains(family)) return family;

    // لـ V2: تجربة الـ asset المضمّن (صفحات 1-50) أولاً
    if (edition == MushafFontEdition.v2) {
      try {
        final loader = FontLoader(family)
          ..addFont(rootBundle.load('assets/quran/fonts/pages/p$page.ttf'));
        await loader.load();
        _loaded.add(family);
        return family;
      } catch (_) {
        // غياب الـ asset طبيعي لصفحات 51+
      }
    }

    final downloadedFile = await _downloads.localFontFile(page, edition);
    if (await downloadedFile.exists() && (await downloadedFile.length()) > 0) {
      final loader = FontLoader(family)..addFont(downloadedFile.readAsBytes().then(ByteData.sublistView));
      await loader.load();
      _loaded.add(family);
      return family;
    }

    // تنزيل فوري إذا كان خط V1 أو خط صفحة مطلوب
    try {
      await _downloads.downloadPage(page, edition);
      if (await downloadedFile.exists() && (await downloadedFile.length()) > 0) {
        final loader = FontLoader(family)..addFont(downloadedFile.readAsBytes().then(ByteData.sublistView));
        await loader.load();
        _loaded.add(family);
        return family;
      }
    } catch (_) {}

    throw PageFontNotBundledException(page, edition);
  }
}

final mushafFontServiceProvider = Provider<MushafFontService>((ref) {
  return MushafFontService(ref.watch(fontDownloadControllerProvider.notifier));
});

final pageFontFamilyProvider = FutureProvider.family<String, int>((ref, page) {
  final edition = ref.watch(mushafFontEditionProvider);
  return ref.watch(mushafFontServiceProvider).ensureLoaded(page, edition);
});
