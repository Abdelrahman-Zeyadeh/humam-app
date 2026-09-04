import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/remote_assets_config.dart';
import '../../core/data/hadith/hadith_book_catalog.dart';
import '../../core/data/hadith/hadith_book_files.dart';

export '../../core/data/hadith/hadith_book_files.dart' show hadithBookLocalFile;

enum HadithBookDownloadStatus { notDownloaded, downloading, downloaded, error }

class HadithDownloadState {
  const HadithDownloadState({
    this.downloadedKeys = const {},
    this.downloadingKey,
    this.downloadProgress = 0,
    this.errorMessage,
  });

  /// مفاتيح الكتب المنزَّلة فعلياً — مصدر الحقيقة فحص ملفات حقيقي
  /// (`_scanExisting`)، لا علم SharedPreferences قد يكذب لو حُذف الملف يدوياً.
  final Set<String> downloadedKeys;
  final String? downloadingKey;

  /// نسبة إنجاز الكتاب الجاري تنزيله حالياً (٠.٠-١.٠).
  final double downloadProgress;
  final String? errorMessage;

  HadithBookDownloadStatus statusFor(String bookKey) {
    if (kEmbeddedHadithBookKeys.contains(bookKey) || downloadedKeys.contains(bookKey)) {
      return HadithBookDownloadStatus.downloaded;
    }
    if (downloadingKey == bookKey) return HadithBookDownloadStatus.downloading;
    return HadithBookDownloadStatus.notDownloaded;
  }

  HadithDownloadState copyWith({
    Set<String>? downloadedKeys,
    Object? downloadingKey = _sentinel,
    double? downloadProgress,
    Object? errorMessage = _sentinel,
  }) {
    return HadithDownloadState(
      downloadedKeys: downloadedKeys ?? this.downloadedKeys,
      downloadingKey: identical(downloadingKey, _sentinel) ? this.downloadingKey : downloadingKey as String?,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

/// مدير تنزيل كتب الأحاديث غير المضمَّنة — نفس نمط `FontDownloadController`
/// (`font_download_service.dart`) لكن ملف واحد لكل كتاب بدل ٥٥٤ ملفاً صغيراً،
/// فالتقدّم هنا بالبايت (`onReceiveProgress`) لا بعدّ الملفات.
class HadithDownloadController extends Notifier<HadithDownloadState> {
  CancelToken? _cancelToken;

  @override
  HadithDownloadState build() {
    unawaited(_scanExisting());
    ref.onDispose(() => _cancelToken?.cancel());
    return const HadithDownloadState();
  }

  Future<void> _scanExisting() async {
    state = state.copyWith(downloadedKeys: await scanDownloadedHadithBookKeys());
  }

  Future<void> downloadBook(String bookKey) async {
    if (kEmbeddedHadithBookKeys.contains(bookKey) || state.downloadedKeys.contains(bookKey)) return;
    if (state.downloadingKey != null) return; // كتاب آخر قيد التنزيل أصلاً

    final file = await hadithBookLocalFile(bookKey);
    final partFile = File('${file.path}.part');
    _cancelToken = CancelToken();
    state = state.copyWith(downloadingKey: bookKey, downloadProgress: 0, errorMessage: null);

    try {
      await Dio().download(
        hadithBookDownloadUrl(bookKey),
        partFile.path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          state = state.copyWith(downloadProgress: received / total);
        },
      );
      await partFile.rename(file.path);
      state = state.copyWith(
        downloadedKeys: {...state.downloadedKeys, bookKey},
        downloadingKey: null,
        downloadProgress: 0,
      );
    } catch (e) {
      if (await partFile.exists()) await partFile.delete();
      if (e is DioException && CancelToken.isCancel(e)) {
        state = state.copyWith(downloadingKey: null, downloadProgress: 0);
        return;
      }
      state = state.copyWith(
        downloadingKey: null,
        downloadProgress: 0,
        errorMessage: 'تعذّر تنزيل ${hadithBookCatalogByKey(bookKey).nameAr} — تحقّق من الاتصال بالإنترنت',
      );
    }
  }

  void cancelDownload() => _cancelToken?.cancel();

  Future<void> deleteBook(String bookKey) async {
    if (kEmbeddedHadithBookKeys.contains(bookKey)) return;
    final file = await hadithBookLocalFile(bookKey);
    if (await file.exists()) await file.delete();
    state = state.copyWith(downloadedKeys: {...state.downloadedKeys}..remove(bookKey));
  }
}

final hadithDownloadControllerProvider = NotifierProvider<HadithDownloadController, HadithDownloadState>(
  HadithDownloadController.new,
);
