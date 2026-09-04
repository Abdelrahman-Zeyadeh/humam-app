// اختبار وحدة لـ`MushafImageDownloadController` — نفس نهج
// `download_resume_test.dart` (خادم HTTP محلي حقيقي، لا محاكاة لطبقة
// الشبكة) بس عبر الـController كاملاً (لا `downloadResumable` مباشرة)،
// بمجلد وثائق تطبيق مزيَّف (`PathProviderPlatform.instance`) بدل مجلد
// حقيقي بالجهاز.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/config/remote_assets_config.dart';
import 'package:humam_app/features/mushaf/mushaf_image_download_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

final _kPageContent = utf8.encode('WEBP' * 1000); // ٤٠٠٠ بايت لكل صفحة وهمية

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.docsPath);
  final String docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

void main() {
  late Directory tempDir;
  late HttpServer server;
  late ProviderContainer container;
  final servedPages = <int>[]; // صفحات فعلاً طُلبت من الخادم
  final originalBaseUrl = kMushafImagesBaseUrlOverride;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mushaf_image_download_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);

    servedPages.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      // الرابط: /<editionId>/<page:03d>.webp
      final match = RegExp(r'/(\d{3})\.webp$').firstMatch(req.uri.path);
      if (match != null) servedPages.add(int.parse(match.group(1)!));
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.set(HttpHeaders.contentLengthHeader, _kPageContent.length)
        ..add(_kPageContent);
      req.response.close();
    });
    kMushafImagesBaseUrlOverride = 'http://${server.address.address}:${server.port}';

    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await server.close(force: true);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    kMushafImagesBaseUrlOverride = originalBaseUrl;
  });

  test('downloadPage يحفظ الصفحة محلياً بالمسار الصحيح ويحدّث downloadedPages', () async {
    final controller = container.read(mushafImageDownloadControllerProvider.notifier);

    await controller.downloadPage('normal', 1);

    final file = await controller.localImageFile('normal', 1);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), _kPageContent);
    expect(file.path, endsWith('downloaded_mushaf_images${Platform.pathSeparator}normal${Platform.pathSeparator}001.webp'));

    final state = container.read(mushafImageDownloadControllerProvider).forEdition('normal');
    expect(state.downloadedPages, contains(1));
  });

  test('downloadPage لا يعيد التنزيل لو الملف موجود أصلاً محلياً', () async {
    final controller = container.read(mushafImageDownloadControllerProvider.notifier);
    final file = await controller.localImageFile('normal', 5);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(_kPageContent);

    await controller.downloadPage('normal', 5);

    expect(servedPages, isEmpty); // ما طلب من الخادم إطلاقاً
    final state = container.read(mushafImageDownloadControllerProvider).forEdition('normal');
    expect(state.downloadedPages, contains(5));
  });

  test('deleteEdition يحذف كل الملفات ويصفّر الحالة', () async {
    final controller = container.read(mushafImageDownloadControllerProvider.notifier);
    await controller.downloadPage('jawamie', 1);
    await controller.downloadPage('jawamie', 2);
    expect(
      container.read(mushafImageDownloadControllerProvider).forEdition('jawamie').downloadedPages,
      {1, 2},
    );

    await controller.deleteEdition('jawamie');

    final state = container.read(mushafImageDownloadControllerProvider).forEdition('jawamie');
    expect(state.downloadedPages, isEmpty);
    final file = await controller.localImageFile('jawamie', 1);
    expect(await file.exists(), isFalse);
  });

  test('النسختين مستقلتان — تنزيل واحدة لا يؤثر على حالة الأخرى', () async {
    final controller = container.read(mushafImageDownloadControllerProvider.notifier);
    await controller.downloadPage('normal', 1);

    final normalState = container.read(mushafImageDownloadControllerProvider).forEdition('normal');
    final premiumState = container.read(mushafImageDownloadControllerProvider).forEdition('premium');
    expect(normalState.downloadedPages, {1});
    expect(premiumState.downloadedPages, isEmpty);
  });
}
