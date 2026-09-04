import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config/remote_assets_config.dart';
import '../../core/data/download_helper.dart';
import 'mushaf_settings.dart' show MushafFontEdition;

const int kFirstDownloadablePage = 51;
const int kLastDownloadablePage = 604;

class FontDownloadState {
  const FontDownloadState({
    this.downloadedPages = const {},
    this.inFlightPages = const {},
    this.isBulkRunning = false,
    this.bulkCompleted = 0,
    this.bulkTotal = kLastDownloadablePage - kFirstDownloadablePage + 1,
    this.currentPage,
    this.errorMessage,
  });

  /// صفحات (٥١-٦٠٤) محمَّلة محلياً فعلاً — مصدر الحقيقة ملفات فعلية
  /// بمجلد التطبيق، لا علامة SharedPreferences منفصلة قد تكذب لو حُذف
  /// الملف يدوياً.
  final Set<int> downloadedPages;

  /// صفحات قيد تنزيل تلقائي (أولوية) الآن — تغذّي مؤشر التقدّم الخافت
  /// بزاوية `_PageDownloadPrompt` بدل شاشة "يحتاج تنزيلاً" الكاملة، راجع
  /// `mushaf_page_widget.dart`.
  final Set<int> inFlightPages;
  final bool isBulkRunning;
  final int bulkCompleted;
  final int bulkTotal;
  final int? currentPage;
  final String? errorMessage;

  FontDownloadState copyWith({
    Set<int>? downloadedPages,
    Set<int>? inFlightPages,
    bool? isBulkRunning,
    int? bulkCompleted,
    int? bulkTotal,
    Object? currentPage = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return FontDownloadState(
      downloadedPages: downloadedPages ?? this.downloadedPages,
      inFlightPages: inFlightPages ?? this.inFlightPages,
      isBulkRunning: isBulkRunning ?? this.isBulkRunning,
      bulkCompleted: bulkCompleted ?? this.bulkCompleted,
      bulkTotal: bulkTotal ?? this.bulkTotal,
      currentPage: identical(currentPage, _sentinel) ? this.currentPage : currentPage as int?,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

/// مدير تنزيل خطوط صفحات المصحف غير المضمَّنة (٥١-٦٠٤، راجع pubspec.yaml).
/// كل صفحة ملف TTF صغير مستقل (~٢٧٠ كيلوبايت بالمتوسط) يُنزَّل من
/// `kFontsBaseUrl/p{page}.ttf` — راجع `remote_assets_config.dart`
/// و`tools/raw/README.md` لخطوات الاستضافة (**لم تُهيَّأ بعد**).
///
/// الاستئناف هون على مستوى الطابور لا البايت: كل صفحة صغيرة بما يكفي إنه
/// إعادة تنزيلها من الصفر عند فشلها رخيصة، لكن **تنزيل الحزمة الكاملة**
/// (٥٥٤ صفحة) يستأنف من حيث توقّف فعلياً — يتخطّى أي صفحة ملفها موجود
/// محلياً أصلاً، فإغلاق التطبيق منتصف التنزيل الجماعي لا يعيد من الصفر.
class FontDownloadController extends Notifier<FontDownloadState> {
  CancelToken? _cancelToken;

  @override
  FontDownloadState build() {
    unawaited(_scanExisting());
    ref.onDispose(() {
      _cancelToken?.cancel();
    });
    return const FontDownloadState();
  }

  Future<Directory> _fontsDir([MushafFontEdition edition = MushafFontEdition.v2]) async {
    final dir = await getApplicationDocumentsDirectory();
    final sub = edition == MushafFontEdition.v1 ? 'downloaded_fonts_v1' : 'downloaded_fonts';
    final fontsDir = Directory(p.join(dir.path, sub));
    if (!await fontsDir.exists()) await fontsDir.create(recursive: true);
    return fontsDir;
  }

  Future<File> localFontFile(int page, [MushafFontEdition edition = MushafFontEdition.v2]) async {
    final dir = await _fontsDir(edition);
    final filename = edition == MushafFontEdition.v1
        ? 'QCF_P${page.toString().padLeft(3, '0')}.TTF'
        : 'p$page.ttf';
    return File(p.join(dir.path, filename));
  }

  Future<void> _scanExisting() async {
    final dir = await _fontsDir(MushafFontEdition.v2);
    final found = <int>{};
    await for (final entity in dir.list()) {
      if (entity is File) {
        final match = RegExp(r'^p(\d+)\.ttf$').firstMatch(p.basename(entity.path));
        if (match != null) {
          final page = int.parse(match.group(1)!);
          if (await entity.length() > 0) {
            found.add(page);
          } else {
            // حذف أي ملف تالف متبقٍّ بحجم ٠
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    }
    state = state.copyWith(downloadedPages: found);
  }

  Future<void> downloadPage(int page, [MushafFontEdition edition = MushafFontEdition.v2]) async {
    final file = await localFontFile(page, edition);
    if (await file.exists() && (await file.length()) > 0) {
      if (edition == MushafFontEdition.v2) {
        state = state.copyWith(downloadedPages: {...state.downloadedPages, page});
      }
      return;
    }
    final url = edition == MushafFontEdition.v1
        ? fontV1DownloadUrl(page)
        : fontDownloadUrl(page);
    final result = await downloadResumable(
      dio: Dio(),
      url: url,
      destination: file,
    );
    if (result.success) {
      if (edition == MushafFontEdition.v2) {
        state = state.copyWith(downloadedPages: {...state.downloadedPages, page}, errorMessage: null);
      }
    } else if (!result.cancelled) {
      state = state.copyWith(errorMessage: 'تعذّر تنزيل خط الصفحة $page — تحقّق من الاتصال بالإنترنت');
    }
  }

  Future<void> downloadRemaining() async {
    if (state.isBulkRunning) return;

    final missing = [
      for (var page = kFirstDownloadablePage; page <= kLastDownloadablePage; page++) page,
    ].where((page) => !state.downloadedPages.contains(page)).toList();

    _cancelToken = CancelToken();
    state = state.copyWith(
      isBulkRunning: true,
      bulkTotal: kLastDownloadablePage - kFirstDownloadablePage + 1,
      bulkCompleted: state.downloadedPages.length,
      errorMessage: null,
    );

    final dio = Dio();
    try {
      for (final page in missing) {
        if (_cancelToken?.isCancelled ?? false) break;
        final file = await localFontFile(page);
        final result = await downloadResumable(
          dio: dio,
          url: fontDownloadUrl(page),
          destination: file,
          cancelToken: _cancelToken,
        );
        if (result.success) {
          state = state.copyWith(
            downloadedPages: {...state.downloadedPages, page},
            bulkCompleted: state.bulkCompleted + 1,
            currentPage: page,
          );
        } else if (result.cancelled) {
          break;
        } else {
          // فشل هذه الصفحة تحديداً لا يوقف الحزمة كاملة — نتابع البقية،
          // والجزء المُنزَّل جزئياً (لو وُجد) يبقى صالحاً للاستئناف بمحاولة
          // "تنزيل الباقي" تالية.
          state = state.copyWith(errorMessage: 'تعذّر تنزيل بعض الصفحات (مثلاً $page) — أعد المحاولة لاحقاً');
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'حدث خطأ أثناء التنزيل الجماعي: $e');
    } finally {
      state = state.copyWith(isBulkRunning: false, currentPage: null);
    }
  }

  void cancelBulk() => _cancelToken?.cancel();

  /// يُستدعى عند فتح/تصفّح صفحة `currentPage` بالمصحف — يُنزِّل هذه
  /// الصفحة أولاً ثم جيرانها (`±١` فـ`±٢`) بالخلفية بلا زر يدوي، ويُلغي أي
  /// طلبات أولوية سابقة صار بعدها عن الصفحة الحالية أكبر من
  /// [_kPriorityCancelDistance] (تصفّح سريع تجاوزها فلا فائدة إكمالها).
  /// ينظّف أيضاً صفحات مُنزَّلة بعيدة جداً الآن (LRU، راجع [_cleanupFarPages]).
  /// تم إلغاء التنزيل الكسول بناءً على الطلب — التصفح لن يقوم بتنزيل تلقائي خلفي للمجاورين أو تنظيف LRU تلقائي.
  void requestPageWithPriority(int currentPage) {
    // التنزيل الكسول ملغى
  }
}

final fontDownloadControllerProvider = NotifierProvider<FontDownloadController, FontDownloadState>(
  FontDownloadController.new,
);
