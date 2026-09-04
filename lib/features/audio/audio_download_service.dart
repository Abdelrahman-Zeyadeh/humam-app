import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/data/download_helper.dart';
import '../../core/data/user/audio_prefs.dart';
import 'reciters.dart';

/// مدير تنزيل تلاوات القرّاء للاستماع بلا إنترنت — بطلب صاحب المشروع
/// "قسم... القراء... يصير التنزيل حسب حاجة المستخدم"، بدل بث كل آية من
/// الشبكة في كل مرّة. **لا يستبدل** البث المباشر الحالي (`quran_audio_
/// controller.dart` ما زال يبثّ من `everyayah.com`/`mp3quran.net` مباشرة
/// حين لا يوجد ملف محلي) — هذا فقط يضيف خيار "نزّل هذه السورة" اختيارياً،
/// ويقرأ منه المشغّل تلقائياً حين يكون موجوداً (`localAyahAudioFile`/
/// `localSurahAudioFile` أدناه).
///
/// التجزئة على مستوى **السورة** لا الآية (114 مهمة تنزيل جماعي كحد أقصى،
/// لا 6236) — نفس مبدأ `font_download_service.dart` وموصى به صراحة بوثيقة
/// التصميم (قسم "مدير التنزيلات"). القارئ `perSurahOnly` أصلاً ملف واحد
/// للسورة فتُنزَّل كوحدة.
///
/// **بلا Family Notifier عمداً** — Riverpod 3 بلا codegen لا يوفّر
/// `NotifierProvider.family` جاهزاً بهذا المشروع (لا توجد سابقة له بالكود
/// أصلاً). القرّاء أربعة فقط، فحالة واحدة تحمل `reciterId` النشط وتُعاد
/// مسحها عند [switchReciter] أبسط وكافية تماماً.
class AudioDownloadState {
  const AudioDownloadState({
    required this.reciterId,
    this.downloadedSurahs = const {},
    this.isBulkRunning = false,
    this.bulkCompleted = 0,
    this.bulkTotal = 114,
    this.currentSurah,
    this.errorMessage,
  });

  final String reciterId;

  /// سور (١-١١٤) محمَّلة محلياً بالكامل لـ[reciterId] — مصدر الحقيقة فحص
  /// ملفات فعلي، لا علم SharedPreferences قد يكذب.
  final Set<int> downloadedSurahs;
  final bool isBulkRunning;
  final int bulkCompleted;
  final int bulkTotal;
  final int? currentSurah;
  final String? errorMessage;

  AudioDownloadState copyWith({
    String? reciterId,
    Set<int>? downloadedSurahs,
    bool? isBulkRunning,
    int? bulkCompleted,
    int? bulkTotal,
    Object? currentSurah = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return AudioDownloadState(
      reciterId: reciterId ?? this.reciterId,
      downloadedSurahs: downloadedSurahs ?? this.downloadedSurahs,
      isBulkRunning: isBulkRunning ?? this.isBulkRunning,
      bulkCompleted: bulkCompleted ?? this.bulkCompleted,
      bulkTotal: bulkTotal ?? this.bulkTotal,
      currentSurah: identical(currentSurah, _sentinel)
          ? this.currentSurah
          : currentSurah as int?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

/// مسار الملف المحلي لآية لو نُزِّلت، أو `null` لو لا — يُستدعى من
/// `quran_audio_controller.dart` قبل البثّ لتفضيل الملف المحلي.
Future<File?> localAyahAudioFile(String reciterId, int surah, int ayah) async {
  final dir = await _reciterDir(reciterId);
  final f = File(p.join(dir.path, '${surah}_$ayah.mp3'));
  return await f.exists() ? f : null;
}

/// مساوٍ لكن للقارئ ذي ملف السورة الواحد (`perSurahOnly`).
Future<File?> localSurahAudioFile(String reciterId, int surah) async {
  final dir = await _reciterDir(reciterId);
  final f = File(p.join(dir.path, '$surah.mp3'));
  return await f.exists() ? f : null;
}

Future<Directory> _reciterDir(String reciterId) async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, 'downloaded_audio', reciterId));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

class AudioDownloadController extends Notifier<AudioDownloadState> {
  CancelToken? _cancelToken;

  @override
  AudioDownloadState build() {
    final reciterId = ref.watch(audioPrefsProvider).reciterId;
    ref.onDispose(() => _cancelToken?.cancel());
    unawaited(_scanExisting(reciterId));
    return AudioDownloadState(reciterId: reciterId);
  }

  /// يبدّل القارئ المعروض بشاشة التنزيلات ويعيد مسح ملفاته — لا علاقة له
  /// بقارئ التشغيل الفعلي (`audioPrefsProvider`)، شاشة التنزيلات تسمح
  /// بإدارة أي قارئ بلا تبديل تشغيل.
  Future<void> switchReciter(String reciterId) async {
    state = AudioDownloadState(reciterId: reciterId);
    await _scanExisting(reciterId);
  }

  Future<void> _scanExisting(String reciterId) async {
    final reciter = reciterById(reciterId);
    final dir = await _reciterDir(reciterId);
    if (reciter.mode == ReciterAudioMode.perSurahOnly) {
      final found = <int>{};
      await for (final entity in dir.list()) {
        if (entity is File) {
          final m = RegExp(r'^(\d+)\.mp3$').firstMatch(p.basename(entity.path));
          if (m != null) {
            final surah = int.parse(m.group(1)!);
            if (await entity.length() > 0) {
              found.add(surah);
            } else {
              try {
                await entity.delete();
              } catch (_) {}
            }
          }
        }
      }
      if (state.reciterId == reciterId) {
        state = state.copyWith(downloadedSurahs: found);
      }
      return;
    }
    // سورة "مكتملة" = كل ملفاتها الفردية موجودة وبحجم أكبر من ٠
    final bySurah = <int, int>{};
    await for (final entity in dir.list()) {
      if (entity is File) {
        final m = RegExp(
          r'^(\d+)_(\d+)\.mp3$',
        ).firstMatch(p.basename(entity.path));
        if (m != null) {
          final s = int.parse(m.group(1)!);
          if (await entity.length() > 0) {
            bySurah[s] = (bySurah[s] ?? 0) + 1;
          } else {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    }
    final ok = <int>{
      for (final entry in bySurah.entries)
        if (entry.value >= (kSurahAyahCounts[entry.key] ?? 999999)) entry.key,
    };
    if (state.reciterId == reciterId) {
      state = state.copyWith(downloadedSurahs: ok);
    }
  }

  Future<void> downloadSurah(int surahId, {CancelToken? cancelToken}) async {
    final reciterId = state.reciterId;
    final reciter = reciterById(reciterId);
    final dir = await _reciterDir(reciterId);
    final dio = Dio();
    try {
      if (reciter.mode == ReciterAudioMode.perSurahOnly) {
        final f = File(p.join(dir.path, '$surahId.mp3'));
        if (!await f.exists() || (await f.length()) == 0) {
          final result = await downloadResumable(
            dio: dio,
            url: surahAudioUrl(reciterId, surahId),
            destination: f,
            cancelToken: cancelToken,
          );
          if (!result.success && !result.cancelled) {
            throw StateError(result.errorMessage ?? 'ملف الصوت فارغ');
          }
        }
      } else {
        final count = kSurahAyahCounts[surahId]!;
        for (var ayah = 1; ayah <= count; ayah++) {
          if (cancelToken?.isCancelled ?? false) break;
          final f = File(p.join(dir.path, '${surahId}_$ayah.mp3'));
          if (await f.exists() && (await f.length()) > 0) continue;
          final result = await downloadResumable(
            dio: dio,
            url: ayahAudioUrl(reciterId, surahId, ayah),
            destination: f,
            cancelToken: cancelToken,
          );
          if (!result.success) {
            if (result.cancelled) break;
            throw StateError(result.errorMessage ?? 'ملف الآية فارغ');
          }
        }
      }
      if (state.reciterId == reciterId) {
        state = state.copyWith(
          downloadedSurahs: {...state.downloadedSurahs, surahId},
          errorMessage: null,
        );
      }
    } catch (e) {
      debugPrint('تعذّر تنزيل سورة $surahId: $e');
      if (state.reciterId == reciterId) {
        state = state.copyWith(
          errorMessage: 'تعذّر تنزيل السورة — تحقّق من الاتصال بالإنترنت',
        );
      }
    }
  }

  Future<void> deleteSurah(int surahId) async {
    final reciterId = state.reciterId;
    final dir = await _reciterDir(reciterId);
    await for (final entity in dir.list()) {
      final name = p.basename(entity.path);
      if (name == '$surahId.mp3' || name.startsWith('${surahId}_')) {
        await entity.delete();
      }
    }
    state = state.copyWith(
      downloadedSurahs: {...state.downloadedSurahs}..remove(surahId),
    );
  }

  Future<void> downloadAll() async {
    if (state.isBulkRunning) return;
    final reciterId = state.reciterId;
    final missing = [
      for (var s = 1; s <= 114; s++) s,
    ].where((s) => !state.downloadedSurahs.contains(s)).toList();
    _cancelToken = CancelToken();
    state = state.copyWith(
      isBulkRunning: true,
      bulkCompleted: state.downloadedSurahs.length,
      errorMessage: null,
    );
    try {
      for (final s in missing) {
        if (_cancelToken?.isCancelled ?? false) break;
        if (state.reciterId != reciterId) {
          break; // بدّل المستخدم القارئ أثناء التنزيل الجماعي
        }
        state = state.copyWith(currentSurah: s);
        await downloadSurah(s, cancelToken: _cancelToken);
        if (state.downloadedSurahs.contains(s)) {
          state = state.copyWith(bulkCompleted: state.bulkCompleted + 1);
        }
      }
    } catch (e) {
      debugPrint('خطأ في التنزيل الصوتي الجماعي: $e');
    } finally {
      state = state.copyWith(isBulkRunning: false, currentSurah: null);
    }
  }

  void cancelBulk() => _cancelToken?.cancel();

  Future<void> deleteAll() async {
    final reciterId = state.reciterId;
    final dir = await _reciterDir(reciterId);
    if (await dir.exists()) await dir.delete(recursive: true);
    state = state.copyWith(downloadedSurahs: {});
  }
}

final audioDownloadControllerProvider =
    NotifierProvider<AudioDownloadController, AudioDownloadState>(
      AudioDownloadController.new,
    );

/// عدد آيات كل سورة (١-١١٤) — ثابت معروف بلا حاجة استعلام قاعدة بيانات،
/// يُستخدَم فقط لبناء روابط التنزيل والتحقّق من الاكتمال. المصدر: عدّ
/// آيات المصحف القياسي (نفس ترقيم `Ayahs.ayah` بقاعدة بيانات المشروع).
const Map<int, int> kSurahAyahCounts = {
  1: 7,
  2: 286,
  3: 200,
  4: 176,
  5: 120,
  6: 165,
  7: 206,
  8: 75,
  9: 129,
  10: 109,
  11: 123,
  12: 111,
  13: 43,
  14: 52,
  15: 99,
  16: 128,
  17: 111,
  18: 110,
  19: 98,
  20: 135,
  21: 112,
  22: 78,
  23: 118,
  24: 64,
  25: 77,
  26: 227,
  27: 93,
  28: 88,
  29: 69,
  30: 60,
  31: 34,
  32: 30,
  33: 73,
  34: 54,
  35: 45,
  36: 83,
  37: 182,
  38: 88,
  39: 75,
  40: 85,
  41: 54,
  42: 53,
  43: 89,
  44: 59,
  45: 37,
  46: 35,
  47: 38,
  48: 29,
  49: 18,
  50: 45,
  51: 60,
  52: 49,
  53: 62,
  54: 55,
  55: 78,
  56: 96,
  57: 29,
  58: 22,
  59: 24,
  60: 13,
  61: 14,
  62: 11,
  63: 11,
  64: 18,
  65: 12,
  66: 12,
  67: 30,
  68: 52,
  69: 52,
  70: 44,
  71: 28,
  72: 28,
  73: 20,
  74: 56,
  75: 40,
  76: 31,
  77: 50,
  78: 40,
  79: 46,
  80: 42,
  81: 29,
  82: 19,
  83: 36,
  84: 25,
  85: 22,
  86: 17,
  87: 19,
  88: 26,
  89: 30,
  90: 20,
  91: 15,
  92: 21,
  93: 11,
  94: 8,
  95: 8,
  96: 19,
  97: 5,
  98: 8,
  99: 8,
  100: 11,
  101: 11,
  102: 8,
  103: 3,
  104: 9,
  105: 5,
  106: 4,
  107: 7,
  108: 3,
  109: 6,
  110: 3,
  111: 5,
  112: 4,
  113: 5,
  114: 6,
};
