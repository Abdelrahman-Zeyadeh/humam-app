import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config/remote_assets_config.dart';

const int kFirstDownloadablePage = 51;
const int kLastDownloadablePage = 604;

class FontDownloadState {
  const FontDownloadState({
    this.downloadedPages = const {},
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
  final bool isBulkRunning;
  final int bulkCompleted;
  final int bulkTotal;
  final int? currentPage;
  final String? errorMessage;

  FontDownloadState copyWith({
    Set<int>? downloadedPages,
    bool? isBulkRunning,
    int? bulkCompleted,
    int? bulkTotal,
    Object? currentPage = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return FontDownloadState(
      downloadedPages: downloadedPages ?? this.downloadedPages,
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
    ref.onDispose(() => _cancelToken?.cancel());
    return const FontDownloadState();
  }

  Future<Directory> _fontsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory(p.join(dir.path, 'downloaded_fonts'));
    if (!await fontsDir.exists()) await fontsDir.create(recursive: true);
    return fontsDir;
  }

  Future<File> localFontFile(int page) async {
    final dir = await _fontsDir();
    return File(p.join(dir.path, 'p$page.ttf'));
  }

  Future<void> _scanExisting() async {
    final dir = await _fontsDir();
    final found = <int>{};
    await for (final entity in dir.list()) {
      final match = RegExp(r'^p(\d+)\.ttf$').firstMatch(p.basename(entity.path));
      if (match != null) found.add(int.parse(match.group(1)!));
    }
    state = state.copyWith(downloadedPages: found);
  }

  Future<void> downloadPage(int page) async {
    if (!isFontsBaseUrlConfigured) {
      state = state.copyWith(errorMessage: 'استضافة الخطوط غير مهيّأة بعد بهذا الإصدار');
      return;
    }
    final file = await localFontFile(page);
    if (await file.exists()) {
      state = state.copyWith(downloadedPages: {...state.downloadedPages, page});
      return;
    }
    try {
      await Dio().download(fontDownloadUrl(page), file.path);
      state = state.copyWith(downloadedPages: {...state.downloadedPages, page}, errorMessage: null);
    } catch (_) {
      state = state.copyWith(errorMessage: 'تعذّر تنزيل خط الصفحة $page — تحقّق من الاتصال بالإنترنت');
    }
  }

  Future<void> downloadRemaining() async {
    if (!isFontsBaseUrlConfigured) {
      state = state.copyWith(errorMessage: 'استضافة الخطوط غير مهيّأة بعد بهذا الإصدار');
      return;
    }
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
    for (final page in missing) {
      if (_cancelToken?.isCancelled ?? false) break;
      final file = await localFontFile(page);
      try {
        await dio.download(fontDownloadUrl(page), file.path, cancelToken: _cancelToken);
        state = state.copyWith(
          downloadedPages: {...state.downloadedPages, page},
          bulkCompleted: state.bulkCompleted + 1,
          currentPage: page,
        );
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) break;
        // صفحة وحدة فشلت — نكمل الباقي بدل إيقاف الطابور كله، ونعرض
        // تحذيراً بدل خطأ قاطع.
        state = state.copyWith(errorMessage: 'تعذّر تنزيل بعض الصفحات (مثلاً $page) — أعد المحاولة لاحقاً');
      }
    }

    state = state.copyWith(isBulkRunning: false, currentPage: null);
  }

  void cancelBulk() => _cancelToken?.cancel();
}

final fontDownloadControllerProvider = NotifierProvider<FontDownloadController, FontDownloadState>(
  FontDownloadController.new,
);
