// اختبار وحدة لمنطق روابط تنزيل الخطوط — بلا شبكة فعلية.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/config/remote_assets_config.dart';
import 'package:humam_app/features/mushaf/font_download_service.dart';

void main() {
  test('الاستضافة مهيّأة برابط GitHub Releases حقيقي (تحقّق يدوي ٢٠٢٦-٠٨-١٩)', () {
    expect(kFontsBaseUrl, startsWith('https://github.com/'));
  });

  test('رابط تنزيل صفحة يطابق نمط p{page}.ttf لخط V2', () {
    expect(fontDownloadUrl(51), '$kFontsBaseUrl/p51.ttf');
    expect(fontDownloadUrl(604), '$kFontsBaseUrl/p604.ttf');
  });

  test('رابط تنزيل خطوط V1 يطابق مستودع fadihittih/quran-center-mushaf-assets', () {
    expect(kFontsV1BaseUrl, contains('fadihittih/quran-center-mushaf-assets'));
    expect(fontV1DownloadUrl(1), '$kFontsV1BaseUrl/QCF_P001.TTF');
    expect(fontV1DownloadUrl(604), '$kFontsV1BaseUrl/QCF_P604.TTF');
  });

  test('نطاق الصفحات القابلة للتنزيل ٥١-٦٠٤ (٥٥٤ صفحة)', () {
    expect(kFirstDownloadablePage, 51);
    expect(kLastDownloadablePage, 604);
    expect(kLastDownloadablePage - kFirstDownloadablePage + 1, 554);
  });
}
