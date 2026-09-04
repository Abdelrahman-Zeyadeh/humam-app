import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/remote_assets_config.dart';
import '../../core/data/download_helper.dart';
import '../../core/data/quran/tafsir_edition_catalog.dart';
import '../../core/data/quran/tafsir_edition_files.dart';

enum TafsirEditionDownloadStatus { notDownloaded, downloading, downloaded, error }

class TafsirDownloadState {
  const TafsirDownloadState({
    this.downloadedKeys = const {},
    this.downloadingKey,
    this.downloadProgress = 0,
    this.errorMessage,
  });

  /// إصدارات منزَّلة فعلياً — مصدر الحقيقة فحص ملفات حقيقي، لا علم
  /// SharedPreferences قد يكذب لو حُذف الملف يدوياً. راجع
  /// `HadithDownloadState.downloadedKeys` لنفس المبدأ حرفياً.
  final Set<String> downloadedKeys;
  final String? downloadingKey;
  final double downloadProgress;
  final String? errorMessage;

  TafsirEditionDownloadStatus statusFor(String editionKey) {
    if (kEmbeddedTafsirEditions.contains(editionKey) || downloadedKeys.contains(editionKey)) {
      return TafsirEditionDownloadStatus.downloaded;
    }
    if (downloadingKey == editionKey) return TafsirEditionDownloadStatus.downloading;
    return TafsirEditionDownloadStatus.notDownloaded;
  }

  TafsirDownloadState copyWith({
    Set<String>? downloadedKeys,
    Object? downloadingKey = _sentinel,
    double? downloadProgress,
    Object? errorMessage = _sentinel,
  }) {
    return TafsirDownloadState(
      downloadedKeys: downloadedKeys ?? this.downloadedKeys,
      downloadingKey: identical(downloadingKey, _sentinel) ? this.downloadingKey : downloadingKey as String?,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

/// مدير تنزيل إصدارات التفسير غير المضمَّنة — نفس نمط `HadithDownloadController`
/// بالضبط (ملف واحد لكل إصدار، تقدّم بالبايت، استئناف عبر `.part`).
class TafsirDownloadController extends Notifier<TafsirDownloadState> {
  CancelToken? _cancelToken;

  @override
  TafsirDownloadState build() {
    unawaited(_scanExisting());
    ref.onDispose(() => _cancelToken?.cancel());
    return const TafsirDownloadState();
  }

  Future<void> _scanExisting() async {
    state = state.copyWith(downloadedKeys: await scanDownloadedTafsirEditionKeys());
  }

  Future<void> downloadEdition(String editionKey) async {
    if (kEmbeddedTafsirEditions.contains(editionKey) || state.downloadedKeys.contains(editionKey)) return;
    if (state.downloadingKey != null) return;

    final file = await tafsirEditionLocalFile(editionKey);
    _cancelToken = CancelToken();
    state = state.copyWith(downloadingKey: editionKey, downloadProgress: 0, errorMessage: null);

    final result = await downloadResumable(
      dio: Dio(),
      url: tafsirEditionDownloadUrl(editionKey),
      destination: file,
      cancelToken: _cancelToken,
      onProgress: (received, total) {
        if (total <= 0) return;
        state = state.copyWith(downloadProgress: received / total);
      },
    );

    if (result.success) {
      state = state.copyWith(
        downloadedKeys: {...state.downloadedKeys, editionKey},
        downloadingKey: null,
        downloadProgress: 0,
      );
    } else if (result.cancelled) {
      state = state.copyWith(downloadingKey: null, downloadProgress: 0);
    } else {
      state = state.copyWith(
        downloadingKey: null,
        downloadProgress: 0,
        errorMessage: 'تعذّر تنزيل تفسير ${tafsirEditionCatalogByKey(editionKey).nameAr} — تحقّق من الاتصال بالإنترنت',
      );
    }
  }

  void cancelDownload() => _cancelToken?.cancel();

  Future<void> deleteEdition(String editionKey) async {
    if (kEmbeddedTafsirEditions.contains(editionKey)) return;
    final file = await tafsirEditionLocalFile(editionKey);
    if (await file.exists()) await file.delete();
    state = state.copyWith(downloadedKeys: {...state.downloadedKeys}..remove(editionKey));
  }
}

final tafsirDownloadControllerProvider = NotifierProvider<TafsirDownloadController, TafsirDownloadState>(
  TafsirDownloadController.new,
);
