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

/// أول/آخر صفحة **تحتاج تنزيلاً** لطبعة معيّنة — V2 وحدها أول ٥٠ صفحة
/// مضمّنة أصلاً بالتطبيق ([kFirstDownloadablePage]=٥١)، بينما V1 وV4
/// Tajweed بلا أي صفحة مضمَّنة إطلاقاً (تبدأ من ١).
(int first, int last) downloadableRangeFor(MushafFontEdition edition) => switch (edition) {
      MushafFontEdition.v2 => (kFirstDownloadablePage, kLastDownloadablePage),
      MushafFontEdition.v1 || MushafFontEdition.v4Tajweed => (1, kLastDownloadablePage),
    };

class FontDownloadState {
  const FontDownloadState({
    this.activeEdition = MushafFontEdition.v2,
    this.downloadedPages = const {},
    this.inFlightPages = const {},
    this.isBulkRunning = false,
    this.bulkCompleted = 0,
    this.bulkTotal = kLastDownloadablePage - kFirstDownloadablePage + 1,
    this.currentPage,
    this.errorMessage,
  });

  /// الطبعة يلي [downloadedPages]/[bulkTotal]/[isBulkRunning] بتوصّفها
  /// حالياً — تتحدَّث بـ[FontDownloadController.switchEdition] أو
  /// [FontDownloadController.downloadRemaining]. حالة واحدة مشتركة (لا
  /// خريطة لكل طبعة) بما إنه شاشة تنزيل واحدة تُعرض بمرّة — أبسط بما يكفي.
  final MushafFontEdition activeEdition;

  /// صفحات [activeEdition] محمَّلة محلياً فعلاً — مصدر الحقيقة ملفات
  /// فعلية بمجلد التطبيق، لا علامة SharedPreferences منفصلة قد تكذب لو
  /// حُذف الملف يدوياً.
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
    MushafFontEdition? activeEdition,
    Set<int>? downloadedPages,
    Set<int>? inFlightPages,
    bool? isBulkRunning,
    int? bulkCompleted,
    int? bulkTotal,
    Object? currentPage = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return FontDownloadState(
      activeEdition: activeEdition ?? this.activeEdition,
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

/// مدير تنزيل خطوط صفحات المصحف غير المضمَّنة — **الطبعات الثلاث** (V1/V2/
/// V4 Tajweed، راجع [downloadableRangeFor]). كل صفحة ملف TTF صغير مستقل
/// يُنزَّل حسب رابط الطبعة (`remote_assets_config.dart`).
///
/// الاستئناف على **مستويين معاً**: كل ملف صفحة نفسه بمستوى البايت
/// (`downloadResumable` بـ`download_helper.dart` — استئناف HTTP Range
/// حقيقي، يبقى الجزء المُنزَّل صالحاً حتى لو أُغلق التطبيق أو ضُغط "إيقاف"
/// منتصف صفحة وحدة)، **و**تنزيل الحزمة الكاملة بمستوى الطابور (يتخطّى أي
/// صفحة ملفها موجود محلياً أصلاً بالكامل). يعني ضغط "إيقاف" ثم "بدء
/// التنزيل" لاحقاً **يكمل من حيث توقّف بالضبط** — لا إعادة من الصفر بأي
/// من المستويين.
class FontDownloadController extends Notifier<FontDownloadState> {
  CancelToken? _cancelToken;

  @override
  FontDownloadState build() {
    unawaited(_scanExisting(MushafFontEdition.v2));
    ref.onDispose(() {
      _cancelToken?.cancel();
    });
    return const FontDownloadState();
  }

  Future<Directory> _fontsDir([MushafFontEdition edition = MushafFontEdition.v2]) async {
    final dir = await getApplicationDocumentsDirectory();
    final sub = switch (edition) {
      MushafFontEdition.v1 => 'downloaded_fonts_v1',
      MushafFontEdition.v4Tajweed => 'downloaded_fonts_v4_tajweed',
      MushafFontEdition.v2 => 'downloaded_fonts',
    };
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

  /// مسح ملفات طبعة معيّنة محلياً — **للقراءة فقط، بلا لمس [state]**
  /// (خلافاً لـ[_scanExisting]/[switchEdition] يلي بيغيّران `activeEdition`
  /// المشترك). يسمح لأي مستهلك (شريط تنبيه "باقي X صفحة" بـ`mushaf_screen.dart`
  /// مثلاً) يستعلم عن تقدّم أي طبعة **بغضّ النظر عن الطبعة النشطة حالياً**
  /// بشاشة تنزيل الحزمة — راجع [fontDownloadedCountProvider].
  Future<Set<int>> scanDownloadedPages(MushafFontEdition edition) async {
    final dir = await _fontsDir(edition);
    final pattern = edition == MushafFontEdition.v1
        ? RegExp(r'^QCF_P(\d+)\.TTF$', caseSensitive: false)
        : RegExp(r'^p(\d+)\.ttf$');
    final found = <int>{};
    await for (final entity in dir.list()) {
      if (entity is File) {
        final match = pattern.firstMatch(p.basename(entity.path));
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
    return found;
  }

  Future<void> _scanExisting(MushafFontEdition edition) async {
    final found = await scanDownloadedPages(edition);
    final (first, last) = downloadableRangeFor(edition);
    state = state.copyWith(
      activeEdition: edition,
      downloadedPages: found,
      bulkTotal: last - first + 1,
    );
  }

  /// يُستدعى عند فتح شاشة تنزيل طبعة معيّنة (`FontDownloadScreen`) —
  /// يُحدِّث [FontDownloadState.activeEdition] ويعيد مسح الملفات المحلية
  /// لتلك الطبعة تحديداً (لا شي إن كانت أصلاً الطبعة النشطة).
  Future<void> switchEdition(MushafFontEdition edition) async {
    if (state.activeEdition == edition && !state.isBulkRunning) {
      await _scanExisting(edition);
      return;
    }
    if (state.isBulkRunning) return; // لا تبديل أثناء تنزيل جماعي جارٍ
    await _scanExisting(edition);
  }

  Future<void> downloadPage(int page, [MushafFontEdition edition = MushafFontEdition.v2]) async {
    final file = await localFontFile(page, edition);
    if (await file.exists() && (await file.length()) > 0) {
      if (edition == state.activeEdition) {
        state = state.copyWith(downloadedPages: {...state.downloadedPages, page});
      }
      return;
    }
    final url = switch (edition) {
      MushafFontEdition.v1 => fontV1DownloadUrl(page),
      MushafFontEdition.v4Tajweed => fontV4TajweedDownloadUrl(page),
      MushafFontEdition.v2 => fontDownloadUrl(page),
    };
    final result = await downloadResumable(
      dio: Dio(),
      url: url,
      destination: file,
    );
    if (result.success) {
      if (edition == state.activeEdition) {
        state = state.copyWith(downloadedPages: {...state.downloadedPages, page}, errorMessage: null);
      }
    } else if (!result.cancelled) {
      state = state.copyWith(errorMessage: 'تعذّر تنزيل خط الصفحة $page — تحقّق من الاتصال بالإنترنت');
    }
  }

  Future<void> downloadRemaining([MushafFontEdition edition = MushafFontEdition.v2]) async {
    if (state.isBulkRunning) return;

    await _scanExisting(edition); // يضمن downloadedPages مطابقة لهذه الطبعة تحديداً قبل حساب الناقص
    final (first, last) = downloadableRangeFor(edition);
    final missing = [
      for (var page = first; page <= last; page++) page,
    ].where((page) => !state.downloadedPages.contains(page)).toList();

    _cancelToken = CancelToken();
    state = state.copyWith(
      isBulkRunning: true,
      bulkTotal: last - first + 1,
      bulkCompleted: state.downloadedPages.length,
      errorMessage: null,
    );

    final dio = Dio();
    try {
      for (final page in missing) {
        if (_cancelToken?.isCancelled ?? false) break;
        final file = await localFontFile(page, edition);
        final url = switch (edition) {
          MushafFontEdition.v1 => fontV1DownloadUrl(page),
          MushafFontEdition.v4Tajweed => fontV4TajweedDownloadUrl(page),
          MushafFontEdition.v2 => fontDownloadUrl(page),
        };
        final result = await downloadResumable(
          dio: dio,
          url: url,
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

  /// **إيقاف مؤقت** لا إلغاء حقيقي — الجزء المُنزَّل (كامل الصفحات
  /// المكتملة + جزء البايتات من صفحة قيد التنزيل حالياً) يبقى محفوظاً
  /// بالكامل، و[downloadRemaining] القادم يكمل من حيث توقّف بالضبط
  /// (راجع توثيق الصنف أعلاه).
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

/// عدد صفحات طبعة معيّنة محمَّلة محلياً فعلاً — **مستقل تماماً عن الطبعة
/// النشطة بشاشة التنزيل** (`FontDownloadState.activeEdition`)، فيسمح
/// لشريط تنبيه "باقي X صفحة" (`mushaf_screen.dart`) يعرض تقدّم **طبعة
/// المصحف المختارة فعلياً حالياً** دايماً — يتبدّل تلقائياً لعدّاد الطبعة
/// الجديدة فور تغييرها بالإعدادات، بلا حاجة لفتح شاشة تنزيل تلك الطبعة
/// أولاً. لا يُعيد الاستعلام (`autoDispose` الافتراضي لـ`FutureProvider`
/// كافٍ) إلا عند تغيّر [edition] أو حدث آخر يُعيد بناء المستهلك.
final fontDownloadedCountProvider = FutureProvider.family<int, MushafFontEdition>((ref, edition) async {
  final controller = ref.watch(fontDownloadControllerProvider.notifier);
  final found = await controller.scanDownloadedPages(edition);
  return found.length;
});
