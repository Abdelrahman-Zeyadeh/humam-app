// اختبار وحدة لمنطق روابط تنزيل الخطوط — بلا شبكة فعلية.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/config/remote_assets_config.dart';
import 'package:humam_app/features/mushaf/font_download_service.dart';

void main() {
  test('الاستضافة غير مهيّأة افتراضياً (placeholder) — يجب تحديثه يدوياً قبل النشر', () {
    expect(isFontsBaseUrlConfigured, isFalse);
  });

  test('رابط تنزيل صفحة يطابق نمط p{page}.ttf', () {
    expect(fontDownloadUrl(51), '$kFontsBaseUrl/p51.ttf');
    expect(fontDownloadUrl(604), '$kFontsBaseUrl/p604.ttf');
  });

  test('نطاق الصفحات القابلة للتنزيل ٥١-٦٠٤ (٥٥٤ صفحة)', () {
    expect(kFirstDownloadablePage, 51);
    expect(kLastDownloadablePage, 604);
    expect(kLastDownloadablePage - kFirstDownloadablePage + 1, 554);
  });
}
