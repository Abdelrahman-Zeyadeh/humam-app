// اختبار استئناف التنزيل الحقيقي على مستوى البايت (downloadResumable —
// core/data/download_helper.dart) عبر خادم HTTP محلي حقيقي (`HttpServer`
// على 127.0.0.1) يدعم `Range` فعلياً — لا محاكاة/Mock لطبقة الشبكة، بل
// خادم صغير حقيقي يتحقّق من ترويسة Range الواردة فعلياً ويرد جزئياً (٢٠٦)
// أو كاملاً (٢٠٠) حسب السيناريو، بلا حاجة أي حزمة اختبار HTTP جديدة.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/download_helper.dart';

/// محتوى ثابت معروف (لا عشوائي) للتحقّق الحرفي من تطابق الناتج النهائي.
final _kFullContent = utf8.encode('AAAA' * 5000 + 'BBBB' * 5000); // ٤٠٠٠٠ بايت

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('download_resume_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('استئناف حقيقي: .part موجود جزئياً — يكمل بـRange بدل إعادة التنزيل كاملاً', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var receivedRangeHeader = '';
    server.listen((req) {
      receivedRangeHeader = req.headers.value(HttpHeaders.rangeHeader) ?? '';
      final rangeMatch = RegExp(r'bytes=(\d+)-').firstMatch(receivedRangeHeader);
      if (rangeMatch != null) {
        final start = int.parse(rangeMatch.group(1)!);
        final remaining = _kFullContent.sublist(start);
        req.response
          ..statusCode = HttpStatus.partialContent
          ..headers.set(HttpHeaders.contentLengthHeader, remaining.length)
          ..headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $start-${_kFullContent.length - 1}/${_kFullContent.length}',
          )
          ..add(remaining);
      } else {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.set(HttpHeaders.contentLengthHeader, _kFullContent.length)
          ..add(_kFullContent);
      }
      req.response.close();
    });
    addTearDown(server.close);

    final destination = File('${tempDir.path}/file.bin');
    final partFile = File('${destination.path}.part');
    // نصف الملف الأول مكتوب مسبقاً — يحاكي تنزيلاً سابقاً انقطع منتصف الطريق.
    final existingLength = _kFullContent.length ~/ 2;
    await partFile.writeAsBytes(_kFullContent.sublist(0, existingLength));

    final result = await downloadResumable(
      dio: Dio(),
      url: 'http://${server.address.address}:${server.port}/file.bin',
      destination: destination,
    );

    expect(result.success, isTrue);
    expect(receivedRangeHeader, 'bytes=$existingLength-');
    expect(await destination.exists(), isTrue);
    expect(await destination.readAsBytes(), _kFullContent);
    expect(await partFile.exists(), isFalse); // .part يُحذَف بعد النجاح
  });

  test('لا .part سابق — تنزيل عادي كامل من الصفر بلا ترويسة Range', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var sawRangeHeader = false;
    server.listen((req) {
      sawRangeHeader = req.headers.value(HttpHeaders.rangeHeader) != null;
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.set(HttpHeaders.contentLengthHeader, _kFullContent.length)
        ..add(_kFullContent);
      req.response.close();
    });
    addTearDown(server.close);

    final destination = File('${tempDir.path}/fresh.bin');
    final result = await downloadResumable(
      dio: Dio(),
      url: 'http://${server.address.address}:${server.port}/fresh.bin',
      destination: destination,
    );

    expect(result.success, isTrue);
    expect(sawRangeHeader, isFalse);
    expect(await destination.readAsBytes(), _kFullContent);
  });

  test('السيرفر يتجاهل Range ويرجع ٢٠٠ كاملاً — يُعاد التنزيل من الصفر بلا تعطّب (لا دمج محتويين)', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      // يتجاهل ترويسة Range عمداً — يحاكي مضيفاً لا يدعم الاستئناف الجزئي.
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.set(HttpHeaders.contentLengthHeader, _kFullContent.length)
        ..add(_kFullContent);
      req.response.close();
    });
    addTearDown(server.close);

    final destination = File('${tempDir.path}/ignores_range.bin');
    final partFile = File('${destination.path}.part');
    await partFile.writeAsBytes(_kFullContent.sublist(0, 1000));

    final result = await downloadResumable(
      dio: Dio(),
      url: 'http://${server.address.address}:${server.port}/ignores_range.bin',
      destination: destination,
    );

    expect(result.success, isTrue);
    // الملف النهائي يطابق المحتوى الكامل الصحيح تماماً — لا "١٠٠٠ بايت قديمة
    // + ٤٠٠٠٠ بايت كاملة ملتصقة بها" (كان سيحصل بوضع الإلحاق الأعمى).
    expect(await destination.readAsBytes(), _kFullContent);
  });

  test('فشل شبكة (لا خادم يستجيب) — نتيجة فشل واضحة بلا استثناء غير مُمسَك', () async {
    // نحصل على منفذ حر فعلياً (نظام التشغيل يختاره) ثم نغلق الخادم فوراً —
    // "رفض اتصال" حقيقي على منفذ مضمون عدم تعارضه مع أي شيء آخر، أبسط
    // وأصدق محاكاة لانقطاع شبكة من محاولة إجبار خادم Dart نفسه (يتحقّق
    // داخلياً من تطابق Content-Length فيرفض بناء استجابة مبتورة أصلاً).
    final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final freePort = probe.port;
    await probe.close(force: true);

    final destination = File('${tempDir.path}/unreachable.bin');
    final result = await downloadResumable(
      dio: Dio(),
      url: 'http://127.0.0.1:$freePort/unreachable.bin',
      destination: destination,
    );

    expect(result.success, isFalse);
    expect(result.errorMessage, isNotNull);
    expect(await destination.exists(), isFalse);
  });

  test('جزء .part صغير موجود مسبقاً، لكن الخادم لا يردّ — الجزء القديم يبقى محفوظاً بلا حذف', () async {
    final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final freePort = probe.port;
    await probe.close(force: true);

    final destination = File('${tempDir.path}/unreachable_with_part.bin');
    final partFile = File('${destination.path}.part');
    await partFile.writeAsBytes([1, 2, 3, 4, 5]);

    final result = await downloadResumable(
      dio: Dio(),
      url: 'http://127.0.0.1:$freePort/unreachable_with_part.bin',
      destination: destination,
    );

    expect(result.success, isFalse);
    // فشل الاتصال قبل حتى إرسال الطلب — لا سبب لحذف جزء قديم صالح.
    expect(await partFile.exists(), isTrue);
    expect(await partFile.readAsBytes(), [1, 2, 3, 4, 5]);
  });
}
