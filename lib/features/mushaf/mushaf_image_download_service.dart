import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config/remote_assets_config.dart';
import '../../core/data/download_helper.dart';
import 'mushaf_settings.dart' show RasterMushafEdition;

const int kMushafImageTotalPages = 604;

/// حالة تنزيل نسخة مصورة واحدة (`normal`/`jawamie`/`premium`) — راجع
/// [MushafImageDownloadState] لتجميع الثلاث نسخ معاً.
class MushafImageEditionState {
  const MushafImageEditionState({
    this.downloadedPages = const {},
    this.isBulkRunning = false,
    this.bulkCompleted = 0,
    this.bulkTotal = kMushafImageTotalPages,
    this.currentPage,
    this.errorMessage,
  });

  /// صفحات (١-٦٠٤) محمَّلة محلياً فعلاً — مصدر الحقيقة ملفات فعلية بمجلد
  /// التطبيق، لا علامة SharedPreferences منفصلة قد تكذب لو حُذف الملف يدوياً.
  final Set<int> downloadedPages;
  final bool isBulkRunning;
  final int bulkCompleted;
  final int bulkTotal;
  final int? currentPage;
  final String? errorMessage;

  MushafImageEditionState copyWith({
    Set<int>? downloadedPages,
    bool? isBulkRunning,
    int? bulkCompleted,
    int? bulkTotal,
    Object? currentPage = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return MushafImageEditionState(
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

/// حالة الثلاث نسخ المصورة معاً، مفهرَسة بـ[RasterMushafEdition.id].
class MushafImageDownloadState {
  const MushafImageDownloadState({this.editions = const {}});

  final Map<String, MushafImageEditionState> editions;

  MushafImageEditionState forEdition(String editionId) =>
      editions[editionId] ?? const MushafImageEditionState();

  MushafImageDownloadState copyWithEdition(String editionId, MushafImageEditionState editionState) {
    return MushafImageDownloadState(editions: {...editions, editionId: editionState});
  }
}

/// مدير تنزيل صور صفحات الطبعات المصورة (سكان مجمع الملك فهد) — نفس بنية
/// `FontDownloadController` بالضبط لكن مفهرَسة بثلاث نسخ مستقلة (`normal`/
/// `jawamie`/`premium`) بدل نسختَي خط واحدتين. راجع `remote_assets_config.dart`
/// (`mushafImagePageUrl`) و`tools/mushaf/README.md` لخطوات الاستضافة.
///
/// الاستئناف هون على مستوى الطابور لا البايت: كل صفحة صغيرة بما يكفي إنه
/// إعادة تنزيلها من الصفر عند فشلها رخيصة، لكن **تنزيل النسخة الكاملة**
/// (٦٠٤ صفحة) يستأنف من حيث توقّف فعلياً — يتخطّى أي صفحة ملفها موجود
/// محلياً أصلاً.
class MushafImageDownloadController extends Notifier<MushafImageDownloadState> {
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  MushafImageDownloadState build() {
    for (final edition in RasterMushafEdition.values) {
      unawaited(_scanExisting(edition.id));
    }
    ref.onDispose(() {
      for (final token in _cancelTokens.values) {
        token.cancel();
      }
    });
    return const MushafImageDownloadState();
  }

  Future<Directory> _editionDir(String editionId) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'downloaded_mushaf_images', editionId));
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
    return imagesDir;
  }

  Future<File> localImageFile(String editionId, int page) async {
    final dir = await _editionDir(editionId);
    final filename = '${page.toString().padLeft(3, '0')}.webp';
    return File(p.join(dir.path, filename));
  }

  Future<void> _scanExisting(String editionId) async {
    final dir = await _editionDir(editionId);
    final found = <int>{};
    await for (final entity in dir.list()) {
      if (entity is File) {
        final match = RegExp(r'^(\d{3})\.webp$').firstMatch(p.basename(entity.path));
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
    final current = state.forEdition(editionId);
    state = state.copyWithEdition(editionId, current.copyWith(downloadedPages: found));
  }

  Future<void> downloadPage(String editionId, int page) async {
    final file = await localImageFile(editionId, page);
    final current = state.forEdition(editionId);
    if (await file.exists() && (await file.length()) > 0) {
      state = state.copyWithEdition(
        editionId,
        current.copyWith(downloadedPages: {...current.downloadedPages, page}),
      );
      return;
    }
    final result = await downloadResumable(
      dio: Dio(),
      url: mushafImagePageUrl(editionId, page),
      destination: file,
    );
    final latest = state.forEdition(editionId);
    if (result.success) {
      state = state.copyWithEdition(
        editionId,
        latest.copyWith(downloadedPages: {...latest.downloadedPages, page}, errorMessage: null),
      );
    } else if (!result.cancelled) {
      state = state.copyWithEdition(
        editionId,
        latest.copyWith(errorMessage: 'تعذّر تنزيل صفحة $page — تحقّق من الاتصال بالإنترنت'),
      );
    }
  }

  Future<void> downloadRemaining(String editionId) async {
    final current = state.forEdition(editionId);
    if (current.isBulkRunning) return;

    final missing = [
      for (var page = 1; page <= kMushafImageTotalPages; page++) page,
    ].where((page) => !current.downloadedPages.contains(page)).toList();

    final cancelToken = CancelToken();
    _cancelTokens[editionId] = cancelToken;
    state = state.copyWithEdition(
      editionId,
      current.copyWith(
        isBulkRunning: true,
        bulkTotal: kMushafImageTotalPages,
        bulkCompleted: current.downloadedPages.length,
        errorMessage: null,
      ),
    );

    final dio = Dio();
    try {
      for (final page in missing) {
        if (cancelToken.isCancelled) break;
        final file = await localImageFile(editionId, page);
        final result = await downloadResumable(
          dio: dio,
          url: mushafImagePageUrl(editionId, page),
          destination: file,
          cancelToken: cancelToken,
        );
        final latest = state.forEdition(editionId);
        if (result.success) {
          state = state.copyWithEdition(
            editionId,
            latest.copyWith(
              downloadedPages: {...latest.downloadedPages, page},
              bulkCompleted: latest.bulkCompleted + 1,
              currentPage: page,
            ),
          );
        } else if (result.cancelled) {
          break;
        } else {
          // فشل هذه الصفحة تحديداً لا يوقف النسخة كاملة — نتابع البقية،
          // والجزء المُنزَّل جزئياً (لو وُجد) يبقى صالحاً للاستئناف بمحاولة
          // "تنزيل الباقي" تالية.
          state = state.copyWithEdition(
            editionId,
            latest.copyWith(errorMessage: 'تعذّر تنزيل بعض الصفحات (مثلاً $page) — أعد المحاولة لاحقاً'),
          );
        }
      }
    } catch (e) {
      final latest = state.forEdition(editionId);
      state = state.copyWithEdition(editionId, latest.copyWith(errorMessage: 'حدث خطأ أثناء التنزيل الجماعي: $e'));
    } finally {
      final latest = state.forEdition(editionId);
      state = state.copyWithEdition(editionId, latest.copyWith(isBulkRunning: false, currentPage: null));
    }
  }

  void cancelBulk(String editionId) => _cancelTokens[editionId]?.cancel();

  /// يحذف كل صفحات نسخة مصورة منزَّلة محلياً ويحرّر المساحة — لا رجوع.
  Future<void> deleteEdition(String editionId) async {
    cancelBulk(editionId);
    final dir = await _editionDir(editionId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    state = state.copyWithEdition(editionId, const MushafImageEditionState());
  }
}

final mushafImageDownloadControllerProvider =
    NotifierProvider<MushafImageDownloadController, MushafImageDownloadState>(
  MushafImageDownloadController.new,
);
