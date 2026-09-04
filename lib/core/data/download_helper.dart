import 'dart:io';

import 'package:dio/dio.dart';

/// نتيجة استدعاء واحد لـ[downloadResumable].
class DownloadResult {
  const DownloadResult({required this.success, this.errorMessage, this.cancelled = false});

  final bool success;
  final String? errorMessage;

  /// `true` لو أُلغي التنزيل عمداً (`CancelToken`) — ليس فشلاً حقيقياً،
  /// المستدعي عادة لا يعرض رسالة خطأ لهذه الحالة.
  final bool cancelled;
}

/// تنزيل ملف واحد بدعم **استئناف حقيقي على مستوى البايت** — يُستخدَم من
/// `font_download_service.dart`/`audio_download_service.dart`/
/// `tafsir_download_service.dart` بدل كل واحد يعيد كتابة نفس منطق
/// `Dio().download()` بمفرده (كان `.part` يُستبدَل بالكامل من الصفر بكل
/// محاولة، رغم تعليق `pubspec.yaml` القديم الذي يدّعي "استئناف بـ HTTP
/// Range" زوراً — لا رابط فعلي كان يُرسِل ترويسة `Range` قط).
///
/// الآلية: لو وُجد ملف `.part` سابق بجانب [destination] بحجم أكبر من صفر،
/// يُرسَل `Range: bytes=<length>-` ويُكتَب الجزء الجديد بوضع "إلحاق"
/// (`FileAccessMode.append`) بدل الكتابة من الصفر. لو تجاهل السيرفر ترويسة
/// `Range` (رجع ٢٠٠ بدل ٢٠٦ الجزئي المتوقَّع) — حالة مواقع لا تدعم
/// الاستئناف الجزئي — يُحذَف `.part` الفاسد ويُعاد التنزيل بالكامل من
/// الصفر مرّة واحدة تلقائياً بدل تعطّب الملف بدمج محتويين مختلفين. عند
/// الاكتمال يتحقّق أن الحجم النهائي يطابق `Content-Length` (لو معروفاً)
/// قبل إعادة تسمية `.part` ذرّياً لمسار [destination] النهائي — لا يُحذَف
/// `.part` **إلا** عند النجاح الكامل؛ عند أي فشل يبقى الجزء المُنزَّل فعلياً
/// بمكانه ليُستأنف بالمحاولة التالية بدل إعادة التنزيل من الصفر.
Future<DownloadResult> downloadResumable({
  required Dio dio,
  required String url,
  required File destination,
  CancelToken? cancelToken,
  void Function(int received, int total)? onProgress,
}) async {
  final partFile = File('${destination.path}.part');
  try {
    final existingLength = await partFile.exists() ? await partFile.length() : 0;
    final useRange = existingLength > 0;

    final Response response;
    try {
      response = await dio.download(
        url,
        partFile.path,
        cancelToken: cancelToken,
        deleteOnError: false,
        fileAccessMode: useRange ? FileAccessMode.append : FileAccessMode.write,
        options: useRange
            ? Options(headers: {HttpHeaders.rangeHeader: 'bytes=$existingLength-'})
            : null,
        onReceiveProgress: onProgress == null
            ? null
            : (received, total) {
                final totalKnown = total > 0 ? total + existingLength : total;
                onProgress(received + existingLength, totalKnown);
              },
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return const DownloadResult(success: false, cancelled: true);
      }
      rethrow;
    }

    if (useRange && response.statusCode != 206) {
      // السيرفر تجاهل `Range` وأرسل الملف كاملاً من جديد — لو أكملنا
      // بوضع الإلحاق لصار الملف النهائي = الجزء القديم + نسخة كاملة ثانية
      // ملتصقة به. الحل: امسح الجزء القديم وأعد المحاولة كاملة من الصفر.
      if (await partFile.exists()) await partFile.delete();
      return await downloadResumable(
        dio: dio,
        url: url,
        destination: destination,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
    }

    final length = await partFile.length();
    if (length == 0) {
      if (await partFile.exists()) await partFile.delete();
      return const DownloadResult(success: false, errorMessage: 'الملف الناتج فارغ');
    }

    final contentLengthHeader = response.headers.value(Headers.contentLengthHeader);
    final receivedThisRequest = contentLengthHeader != null ? int.tryParse(contentLengthHeader) : null;
    if (receivedThisRequest != null && receivedThisRequest > 0) {
      final expectedFinalLength = useRange ? existingLength + receivedThisRequest : receivedThisRequest;
      if (length != expectedFinalLength) {
        // لا حذف — الجزء المكتوب فعلياً صالح للاستئناف بمحاولة لاحقة.
        return const DownloadResult(
          success: false,
          errorMessage: 'حجم الملف غير مكتمل — سيُستأنف بالمحاولة القادمة',
        );
      }
    }

    await partFile.rename(destination.path);
    return const DownloadResult(success: true);
  } catch (e) {
    return DownloadResult(success: false, errorMessage: 'تعذّر التنزيل: $e');
  }
}
