import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// يجلب HTML صفحة عبر محرك متصفح حقيقي (WebView) بدل `Dio`.
///
/// **سبب وجود هذا الملف (تحقّقتُ منه مباشرة، لا تخمين)**: موقع دُرر
/// السنية خلف حماية Cloudflare ترفض أي طلب لا يحمل بصمة TLS/HTTP فعلية
/// لمتصفح حقيقي — بـ٤٠٣ Forbidden، **حتى لو كانت كل الترويسات (User-
/// Agent، Accept، Referer، كوكيز جلسة صالحة) مطابقة تماماً لمتصفح
/// حقيقي**. جرّبتُ: (أ) ترويسات كاملة بلا كوكيز — ٤٠٣. (ب) نفس الشيء مع
/// `CookieManager`/جلسة Laravel حقيقية مأخوذة من طلب "إحماء" للصفحة
/// الرئيسية — ٤٠٣ أيضاً، حتى طلب الإحماء نفسه رُفض. السبب: مكتبة `Dio`
/// (عبر `dart:io HttpClient`) تستخدم مكدّس TLS مختلفاً فعلياً عن
/// Chrome/WebKit (بصمة JA3/JA4 مختلفة)، وCloudflare يميّز هذا الفرق بغض
/// النظر عن الترويسات الظاهرة. الحل الوحيد الموثوق من Dart خالص: تحميل
/// الصفحة فعلياً عبر محرك المتصفح الحقيقي بالجهاز (WebView نظام
/// أندرويد/iOS)، الذي يحمل بصمة متصفح حقيقية فعلاً.
///
/// يعمل بلا عرض مرئي: `WebView` مضمّن بحجم صفر (`SizedBox.shrink`) داخل
/// شجرة الواجهة (لازم يكون ضمن الشجرة فعلياً ليبدأ التحميل على أندرويد،
/// حتى لو بلا مساحة ظاهرة)، يحمّل الرابط، وينتظر انتهاء التحميل
/// (`onPageFinished`) قبل استخراج `document.documentElement.outerHTML`
/// عبر JavaScript.
class DorarWebViewFetcher extends StatefulWidget {
  const DorarWebViewFetcher({super.key, required this.controller});

  /// يُمرَّر من الشاشة الأم — `fetchHtml` يُستدعى عليه مباشرة (راجع
  /// `DorarWebViewFetcherController`).
  final DorarWebViewFetcherController controller;

  @override
  State<DorarWebViewFetcher> createState() => _DorarWebViewFetcherState();
}

class _DorarWebViewFetcherState extends State<DorarWebViewFetcher> {
  late final WebViewController _webViewController;
  Completer<void>? _pageLoadCompleter;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // `onPageFinished` قد يُستدعى أكثر من مرة لنفس التحميل (تنقّلات
            // فرعية/تحديثات داخل الصفحة) — إكمال `Completer` مُكتمِل أصلاً
            // يرمي `StateError` غير مُمسَك يُسقِط الجلب بصمت. نكمل أول مرة
            // فقط.
            if (_pageLoadCompleter?.isCompleted == false) {
              _pageLoadCompleter!.complete();
            }
          },
          onWebResourceError: (error) {
            // **باج حقيقي**: أخطاء موارد فرعية (خط/صورة/سكربت تحليلات
            // فشل تحميله) كانت تُسقِط الجلب بالكامل رغم أن الصفحة الرئيسية
            // نفسها حمّلت بنجاح فعلياً — لأن `onWebResourceError` يُستدعى
            // لأي مورد بالصفحة لا فقط الإطار الرئيسي. نتجاهل أي خطأ ليس
            // للإطار الرئيسي، ونترك `onPageFinished` يكمل الإكمال بدلها.
            if (error.isForMainFrame != true) return;
            if (_pageLoadCompleter?.isCompleted == false) {
              _pageLoadCompleter!.completeError(error.description);
            }
          },
        ),
      );
    widget.controller._bind(_fetchHtml);
  }

  Future<String> _fetchHtml(
    String url, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final completer = Completer<void>();
    _pageLoadCompleter = completer;
    await _webViewController.loadRequest(Uri.parse(url));
    await completer.future.timeout(timeout);

    final raw = await _webViewController.runJavaScriptReturningResult(
      'document.documentElement.outerHTML',
    );
    // `runJavaScriptReturningResult` يرجع النص مُرمَّزاً كـJSON string
    // (بمحاذر إضافية) على أندرويد — نفكّه لنص HTML خام فعلي.
    final text = raw is String ? raw : raw.toString();
    try {
      return jsonDecode(text) as String;
    } catch (_) {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    // **باج حقيقي مُصلَح هون**: كان `build()` يرجّع `SizedBox` فارغاً بلا
    // أي `WebViewWidget` بداخله إطلاقاً — أي إن `_webViewController` لم
    // يكن مربوطاً بأي عرض فعلي بشجرة الواجهة، فـ`loadRequest` لا ينفّذ أي
    // تنقّل حقيقي على أندرويد (يحتاج `WebViewWidget` مركَّباً فعلياً)،
    // فيبقى الجلب معلَّقاً لحد المهلة (٢٠ ثانية) ثم يفشل دائماً — هذا كان
    // السبب الحقيقي وراء "التحقق من صحة الحديث لا يعمل إطلاقاً" حتى بعد
    // إضافة WebView. بحجم ١×١ (لا صفر) لضمان تركيب العرض الأصلي فعلياً.
    return SizedBox(
      width: 1,
      height: 1,
      child: WebViewWidget(controller: _webViewController),
    );
  }
}

/// مقبض يربط الشاشة الأم بحالة [DorarWebViewFetcher] الداخلية — يسمح
/// باستدعاء `fetchHtml` من خارج الودجت (الودجت نفسه بلا عرض/تفاعل، فقط
/// آلية جلب).
class DorarWebViewFetcherController {
  Future<String> Function(String url, {Duration timeout})? _fetch;

  void _bind(Future<String> Function(String url, {Duration timeout}) fetch) {
    _fetch = fetch;
  }

  bool get isReady => _fetch != null;

  Future<String> fetchHtml(
    String url, {
    Duration timeout = const Duration(seconds: 20),
  }) {
    final fetch = _fetch;
    if (fetch == null) {
      throw StateError('DorarWebViewFetcher لم يُركَّب بعد بشجرة الواجهة');
    }
    return fetch(url, timeout: timeout);
  }
}
