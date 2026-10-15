import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dorar_hadith_result.dart';
import 'dorar_search_cache.dart';
import 'dorar_search_service.dart';

/// سبب فشل عملية التحقق من الحديث
enum VerificationFailureReason {
  networkTimeout,
  noInternet,
  webViewFailure,
  htmlParsingFailure,
  unexpectedPageStructure,
  dorarUnavailable,
  requestCancelled,
  unknown,
}

/// نتيجة عملية التحقق من الحديث الموحّدة
class VerificationResult {
  const VerificationResult.success(
    this.results, {
    this.hasMorePages = true,
  })  : isSuccess = true,
        userMessage = null,
        failureReason = null;

  const VerificationResult.failure({
    required this.userMessage,
    required this.failureReason,
    this.results = const [],
    this.hasMorePages = false,
  }) : isSuccess = false;

  final List<DorarHadithResult> results;
  final bool isSuccess;
  final String? userMessage;
  final VerificationFailureReason? failureReason;
  final bool hasMorePages;
}

/// تجريد خدمة التحقق من الحديث لعزل طبقة جلب وتحليل HTML عن الواجهة
abstract class HadithVerificationService {
  Future<VerificationResult> verify(
    String hadith, {
    int page = 1,
    required Future<String> Function(String url, {Duration timeout}) fetchHtml,
  });
}

/// تطبيق خدمة التحقق عبر موسوعة الدرر السنية مع حماية من الأخطاء وإعادة المحاولة
class DorarHadithVerificationService implements HadithVerificationService {
  DorarHadithVerificationService({DorarSearchService? parser})
      : _parser = parser ?? DorarSearchService();

  final DorarSearchService _parser;

  static const Duration _kTimeout = Duration(seconds: 15);
  static const int _kMaxRetries = 1;

  @override
  Future<VerificationResult> verify(
    String hadith, {
    int page = 1,
    required Future<String> Function(String url, {Duration timeout}) fetchHtml,
  }) async {
    final query = hadith.trim();
    if (query.isEmpty) {
      return const VerificationResult.success([]);
    }

    final url = dorarSearchUrl(query, page: page);
    int attempts = 0;
    String? lastError;

    while (attempts <= _kMaxRetries) {
      attempts++;
      try {
        final html = await fetchHtml(url, timeout: _kTimeout);

        if (html.isEmpty) {
          _logTechnical('Received empty HTML from fetcher on attempt $attempts');
          if (attempts <= _kMaxRetries) continue;
          return const VerificationResult.failure(
            userMessage: 'تعذر التحقق من الحديث حاليًا، حاول مرة أخرى لاحقًا.',
            failureReason: VerificationFailureReason.dorarUnavailable,
          );
        }

        try {
          final results = _parser.parseSearchResults(html);
          return VerificationResult.success(
            results,
            hasMorePages: results.isNotEmpty,
          );
        } on DorarBlockedException {
          _logTechnical('Dorar protection/challenge detected on attempt $attempts');
          return const VerificationResult.failure(
            userMessage:
                'موسوعة الدرر السنية فرضت حماية مؤقتة على الطلبات الآن. انتظر قليلاً ثم أعد المحاولة.',
            failureReason: VerificationFailureReason.dorarUnavailable,
          );
        } catch (parseError, stack) {
          _logTechnical('HTML parsing error on attempt $attempts: $parseError', stack);
          return const VerificationResult.failure(
            userMessage: 'تعذر التحقق من الحديث حاليًا، حاول مرة أخرى لاحقًا.',
            failureReason: VerificationFailureReason.htmlParsingFailure,
          );
        }
      } on TimeoutException catch (e, stack) {
        _logTechnical('Network timeout on attempt $attempts ($url): $e', stack);
        lastError = 'timeout';
        if (attempts <= _kMaxRetries) {
          await Future.delayed(const Duration(milliseconds: 600));
          continue;
        }
        return const VerificationResult.failure(
          userMessage:
              'استغرق الاتصال وقتاً طويلاً. تأكد من جودة الإنترنت وحاول مجدداً.',
          failureReason: VerificationFailureReason.networkTimeout,
        );
      } on SocketException catch (e, stack) {
        _logTechnical('No internet / SocketException on attempt $attempts: $e', stack);
        return const VerificationResult.failure(
          userMessage:
              'تعذر الاتصال بموسوعة الدرر السنية. تأكد من اتصال الإنترنت وحاول مجدداً.',
          failureReason: VerificationFailureReason.noInternet,
        );
      } catch (generalError, stack) {
        _logTechnical('General fetch error on attempt $attempts: $generalError', stack);
        if (attempts <= _kMaxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        return const VerificationResult.failure(
          userMessage: 'تعذر التحقق من الحديث حاليًا، حاول مرة أخرى لاحقًا.',
          failureReason: VerificationFailureReason.unknown,
        );
      }
    }

    _logTechnical('All retry attempts failed. Last status: $lastError');
    return const VerificationResult.failure(
      userMessage: 'تعذر التحقق من الحديث حاليًا، حاول مرة أخرى لاحقًا.',
      failureReason: VerificationFailureReason.dorarUnavailable,
    );
  }

  void _logTechnical(String message, [StackTrace? stack]) {
    // تسجيل داخلي للأخطاء التقنية لتتبع الأعطال دون تسجيل مدخلات المستخدم الحساسة
    debugPrint('[HadithVerificationService] $message');
    if (stack != null && kDebugMode) {
      debugPrint('$stack');
    }
  }
}

/// مستودع التحقق من الحديث مع دعم الكاش المحلي
class HadithVerificationRepository {
  HadithVerificationRepository({
    required this.service,
    required this.cache,
  });

  final HadithVerificationService service;
  final DorarSearchCache cache;

  Future<VerificationResult> verify(
    String hadith, {
    int page = 1,
    required Future<String> Function(String url, {Duration timeout}) fetchHtml,
    bool forceRefresh = false,
  }) async {
    final query = hadith.trim();
    if (query.isEmpty) {
      return const VerificationResult.success([]);
    }

    if (!forceRefresh) {
      final cached = cache.get(query, page: page);
      if (cached != null) {
        return VerificationResult.success(cached, hasMorePages: cached.isNotEmpty);
      }
    }

    final result = await service.verify(query, page: page, fetchHtml: fetchHtml);
    if (result.isSuccess && result.results.isNotEmpty) {
      unawaited(cache.set(query, result.results, page: page));
    }
    return result;
  }
}

final hadithVerificationServiceProvider =
    Provider<HadithVerificationService>((ref) {
  return DorarHadithVerificationService(
    parser: ref.read(dorarSearchServiceProvider),
  );
});

final hadithVerificationRepositoryProvider =
    Provider<HadithVerificationRepository>((ref) {
  return HadithVerificationRepository(
    service: ref.watch(hadithVerificationServiceProvider),
    cache: ref.watch(dorarSearchCacheProvider),
  );
});
