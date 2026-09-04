import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/audio_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import 'audio_download_service.dart'
    show localAyahAudioFile, localSurahAudioFile;
import 'ayah_audio_service.dart';
import 'reciters.dart';

/// خيارات تكرار التشغيل الحالي. تُطبَّق عند بدء تشغيل جديد (`playAyah`/
/// `playSurahFull`) لا أثناء تشغيل جارٍ — تجنّباً لتعقيد إعادة بناء طابور
/// مُشغَّل جزئياً بمضاعف مختلف منتصف الطريق.
enum RepeatOption {
  off,
  times2,
  times3,
  times5,
  infinite;

  /// عدد مرّات تكرار الطابور الأساسي كاملاً (`null` = تكرار مستمر عبر
  /// `LoopMode.all` بدل بناء طابور ضخم مسبقاً).
  int? get multiplier => switch (this) {
    RepeatOption.off => 1,
    RepeatOption.times2 => 2,
    RepeatOption.times3 => 3,
    RepeatOption.times5 => 5,
    RepeatOption.infinite => null,
  };

  String get labelAr => switch (this) {
    RepeatOption.off => 'بلا تكرار',
    RepeatOption.times2 => 'تكرار ×٢',
    RepeatOption.times3 => 'تكرار ×٣',
    RepeatOption.times5 => 'تكرار ×٥',
    RepeatOption.infinite => 'تكرار مستمر',
  };

  RepeatOption get nextOption =>
      RepeatOption.values[(index + 1) % RepeatOption.values.length];
}

const _sentinel = Object();

class QuranAudioState {
  const QuranAudioState({
    this.isActive = false,
    required this.reciterId,
    this.currentSurah,
    this.fromAyah,
    this.toAyah,
    this.currentAyahId,
    this.isPlaying = false,
    this.isLoading = false,
    required this.speed,
    this.repeat = RepeatOption.off,
    this.supportsHighlight = true,
    this.errorMessage,
    this.liveListenEnabled = false,
    this.sleepTimerEndsAt,
  });

  /// يوجد تشغيل/طابور محمَّل حالياً (حتى لو موقوفاً مؤقتاً بـ pause).
  final bool isActive;
  final String reciterId;
  final int? currentSurah;
  final int? fromAyah;
  final int? toAyah;

  /// معرّف الآية المشغَّلة الآن بالضبط — `null` لو خامل، أو لو القارئ
  /// `perSurahOnly` (لا بيانات تقسيم بالآية فتُعطَّل تظليل الآية).
  final int? currentAyahId;
  final bool isPlaying;
  final bool isLoading;
  final double speed;
  final RepeatOption repeat;
  final bool supportsHighlight;
  final String? errorMessage;

  /// وضع "سماع مباشر" — راجع توثيق `AudioSettings.liveListenEnabled`.
  final bool liveListenEnabled;

  /// وقت انتهاء مؤقّت النوم الحالي (`null` = لا مؤقّت نشط) — راجع
  /// [QuranAudioController.setSleepTimer].
  final DateTime? sleepTimerEndsAt;

  QuranAudioState copyWith({
    bool? isActive,
    String? reciterId,
    Object? currentSurah = _sentinel,
    Object? fromAyah = _sentinel,
    Object? toAyah = _sentinel,
    Object? currentAyahId = _sentinel,
    bool? isPlaying,
    bool? isLoading,
    double? speed,
    RepeatOption? repeat,
    bool? supportsHighlight,
    Object? errorMessage = _sentinel,
    bool? liveListenEnabled,
    Object? sleepTimerEndsAt = _sentinel,
  }) {
    return QuranAudioState(
      isActive: isActive ?? this.isActive,
      reciterId: reciterId ?? this.reciterId,
      currentSurah: identical(currentSurah, _sentinel)
          ? this.currentSurah
          : currentSurah as int?,
      fromAyah: identical(fromAyah, _sentinel)
          ? this.fromAyah
          : fromAyah as int?,
      toAyah: identical(toAyah, _sentinel) ? this.toAyah : toAyah as int?,
      currentAyahId: identical(currentAyahId, _sentinel)
          ? this.currentAyahId
          : currentAyahId as int?,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      speed: speed ?? this.speed,
      repeat: repeat ?? this.repeat,
      supportsHighlight: supportsHighlight ?? this.supportsHighlight,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      liveListenEnabled: liveListenEnabled ?? this.liveListenEnabled,
      sleepTimerEndsAt: identical(sleepTimerEndsAt, _sentinel)
          ? this.sleepTimerEndsAt
          : sleepTimerEndsAt as DateTime?,
    );
  }
}

class QuranAudioController extends Notifier<QuranAudioState> {
  List<int?> _queueAyahIds = const [];
  int _playRequestId = 0;

  // --- تعقّب دقائق الاستماع الفعلية (راجع UserRepository.logAudioSeconds)
  // — نافذة زمنية متدحرجة: `_playingSince` يُضبط لحظة بدء التشغيل الفعلي
  // (لا تحميل/تخزين مؤقت)، وتُسجَّل الثواني المنقضية كل ٣٠ ثانية (Timer
  // دوري) أو فوراً عند التوقّف (إيقاف مؤقت/كامل/انتهاء المقطع) — أيّهما أسبق.
  DateTime? _playingSince;
  Timer? _audioLogTimer;

  // --- مؤقّت النوم (راجع [setSleepTimer]) — وضع "سماع مباشر" يُقرأ من
  // `state.liveListenEnabled` مباشرة عند كل تشغيل، لا حاجة حقل منفصل هون.
  Timer? _sleepTimer;

  AudioPlayer get _player => ref.read(ayahAudioPlayerProvider);

  /// يسجّل الثواني المنقضية منذ آخر تسجيل ويُصفّر نقطة البداية لنافذة
  /// تالية (لا يمسحها كلياً) — يُستدعى من المؤقّت الدوري (تشغيل مستمر) ومن
  /// أي انتقال من "يشغّل" إلى "متوقّف".
  void _flushPlayedSeconds() {
    final since = _playingSince;
    if (since == null) return;
    final elapsed = DateTime.now().difference(since).inSeconds;
    _playingSince = DateTime.now();
    if (elapsed > 0) {
      try {
        ref.read(userPrefsProvider).logAudioSeconds(elapsed);
      } catch (e) {
        debugPrint('تعذّر تسجيل ثواني الاستماع: $e');
      }
    }
  }

  @override
  QuranAudioState build() {
    final prefs = ref.watch(audioPrefsProvider);
    final player = ref.watch(ayahAudioPlayerProvider);

    final indexSub = player.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _queueAyahIds.length) return;
      state = state.copyWith(currentAyahId: _queueAyahIds[index]);
    });

    final stateSub = player.playerStateStream.listen((s) {
      final completed = s.processingState == ProcessingState.completed;
      final wasPlaying = state.isPlaying;
      final nowPlaying = s.playing && !completed;
      state = state.copyWith(
        isPlaying: nowPlaying,
        isLoading:
            s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering,
        isActive: completed ? false : null,
        currentAyahId: completed ? null : _sentinelKeep(),
      );
      if (nowPlaying && !wasPlaying) {
        _playingSince = DateTime.now();
        _audioLogTimer ??= Timer.periodic(
          const Duration(seconds: 30),
          (_) => _flushPlayedSeconds(),
        );
      } else if (!nowPlaying && wasPlaying) {
        _flushPlayedSeconds();
        _audioLogTimer?.cancel();
        _audioLogTimer = null;
      }
    });

    ref.onDispose(() {
      indexSub.cancel();
      stateSub.cancel();
      _audioLogTimer?.cancel();
      _sleepTimer?.cancel();
      _flushPlayedSeconds();
    });

    return QuranAudioState(
      reciterId: prefs.reciterId,
      speed: prefs.speed,
      liveListenEnabled: prefs.liveListenEnabled,
    );
  }

  // مساعد صغير: يبقي القيمة الحالية بلا تغيير (يمرَّر لـ copyWith فقط
  // بحالة "لم يكتمل بعد" ليتفادى استبدال currentAyahId بلا داعٍ).
  Object? _sentinelKeep() => _sentinel;

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _player.setSpeed(speed);
    await ref.read(audioPrefsProvider).setSpeed(speed);
  }

  /// وضع "سماع مباشر" — راجع توثيق `AudioSettings.liveListenEnabled`. لا
  /// يعيد تشغيل المقطع الحالي تلقائياً عند التبديل (يُطبَّق على أي تشغيل
  /// **تالٍ** فقط) تفادياً لمقاطعة استماع جارٍ بلا داعٍ.
  Future<void> setLiveListenEnabled(bool value) async {
    state = state.copyWith(liveListenEnabled: value);
    await ref.read(audioPrefsProvider).setLiveListenEnabled(value);
  }

  /// يبدأ مؤقّت نوم يوقف التلاوة تلقائياً بعد [duration] — يستبدل أي مؤقّت
  /// سابق (اختيار مدّة جديدة = إعادة ضبط، لا تراكم). يعمل مع وضع "سماع
  /// مباشر" بلا فرق (يوقف `_player` بغضّ النظر عن مصدر الصوت).
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    state = state.copyWith(sleepTimerEndsAt: DateTime.now().add(duration));
    _sleepTimer = Timer(duration, () {
      _sleepTimer = null;
      stop();
    });
  }

  /// يلغي مؤقّت النوم الحالي بلا إيقاف التلاوة الجارية.
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (state.sleepTimerEndsAt != null) {
      state = state.copyWith(sleepTimerEndsAt: null);
    }
  }

  Future<void> setRepeat(RepeatOption repeat) async {
    state = state.copyWith(repeat: repeat);
    if (state.isActive && state.currentSurah != null) {
      await _playSelection(
        surahId: state.currentSurah!,
        fromAyah: state.fromAyah,
        toAyah: state.toAyah,
      );
    }
  }

  Future<void> setReciter(String reciterId) async {
    final reciter = reciterById(reciterId);
    state = state.copyWith(
      reciterId: reciterId,
      supportsHighlight: reciter.mode == ReciterAudioMode.perAyah,
    );
    await ref.read(audioPrefsProvider).setReciterId(reciterId);
    if (state.isActive && state.currentSurah != null) {
      await _playSelection(
        surahId: state.currentSurah!,
        fromAyah: state.fromAyah,
        toAyah: state.toAyah,
      );
    }
  }

  Future<void> playSurah(int surahId) async {
    await _playSelection(surahId: surahId);
  }

  Future<void> playSurahFull(int surahId) async {
    await _playSelection(surahId: surahId);
  }

  Future<void> playAyah(int surahId, int ayahNumber) async {
    await _playSelection(
      surahId: surahId,
      fromAyah: ayahNumber,
      toAyah: ayahNumber,
    );
  }

  Future<void> playFromAyah(int surahId, int fromAyah) async {
    await _playSelection(surahId: surahId, fromAyah: fromAyah);
  }

  Future<void> playRange({
    required int surahId,
    required int fromAyah,
    required int toAyah,
  }) async {
    await _playSelection(
      surahId: surahId,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    _playRequestId++;
    // إيقاف يدوي (أو مؤقّت النوم نفسه) يمسح مؤقّت النوم أيضاً — لا يبقى
    // معلَّقاً ليطلق `stop()` ثانية لاحقاً على تشغيل جديد لا علاقة له به.
    _sleepTimer?.cancel();
    _sleepTimer = null;
    await _player.stop();
    _queueAyahIds = const [];
    state = state.copyWith(
      isActive: false,
      isPlaying: false,
      isLoading: false,
      currentAyahId: null,
      errorMessage: null,
      sleepTimerEndsAt: null,
    );
  }

  Future<void> seekToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> next() => seekToNext();

  Future<void> seekToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  Future<void> previous() => seekToPrevious();

  Future<void> _playSelection({
    required int surahId,
    int? fromAyah,
    int? toAyah,
  }) async {
    final requestId = ++_playRequestId;
    final reciter = reciterById(state.reciterId);
    state = state.copyWith(
      errorMessage: null,
      isLoading: true,
      currentSurah: surahId,
      fromAyah: fromAyah,
      toAyah: toAyah,
      supportsHighlight: reciter.mode == ReciterAudioMode.perAyah,
    );

    try {
      List<Uri> baseUris;
      List<int?> baseAyahIds;

      // وضع "سماع مباشر": يتجاهل أي ملف محلي منزَّل عمداً حتى لو موجوداً،
      // يبثّ رابط الشبكة دائماً — راجع توثيق `AudioSettings.liveListenEnabled`.
      final liveListen = state.liveListenEnabled;

      if (reciter.mode == ReciterAudioMode.perSurahOnly) {
        final local = liveListen
            ? null
            : await localSurahAudioFile(reciter.id, surahId);
        if (requestId != _playRequestId) return;
        baseUris = [
          local?.uri ?? Uri.parse(surahAudioUrl(reciter.id, surahId)),
        ];
        baseAyahIds = [null];
      } else {
        final ayahs = await ref
            .read(quranRepositoryProvider)
            .ayahsForSurah(surahId);
        if (requestId != _playRequestId) return;
        final selected = (fromAyah == null && toAyah == null)
            ? ayahs
            : ayahs
                  .where(
                    (a) =>
                        a.ayah >= (fromAyah ?? 1) &&
                        a.ayah <= (toAyah ?? ayahs.length),
                  )
                  .toList();
        if (selected.isEmpty) throw StateError('لا آيات بهذا النطاق');
        baseUris = [];
        for (final a in selected) {
          final local = liveListen
              ? null
              : await localAyahAudioFile(reciter.id, a.surah, a.ayah);
          if (requestId != _playRequestId) return;
          baseUris.add(local?.uri ?? Uri.parse(ayahAudioUrl(reciter.id, a.surah, a.ayah)));
        }
        baseAyahIds = [for (final a in selected) a.id];
      }

      final multiplier = state.repeat.multiplier;
      final loopAll = state.repeat == RepeatOption.infinite;
      final finalUris = multiplier == null
          ? baseUris
          : [for (var i = 0; i < multiplier; i++) ...baseUris];
      final finalAyahIds = multiplier == null
          ? baseAyahIds
          : [for (var i = 0; i < multiplier; i++) ...baseAyahIds];
      _queueAyahIds = finalAyahIds;

      await _player.setAudioSources([
        for (final u in finalUris) AudioSource.uri(u),
      ], preload: true);
      await _player.setLoopMode(loopAll ? LoopMode.all : LoopMode.off);
      await _player.setSpeed(state.speed);
      state = state.copyWith(isActive: true, currentAyahId: finalAyahIds.first);
      await _player.play();
    } catch (e) {
      _queueAyahIds = const [];
      debugPrint('تعذّر تشغيل الصوت (سورة $surahId): $e');
      state = state.copyWith(
        isActive: false,
        isLoading: false,
        currentAyahId: null,
        // وضع "سماع مباشر" بلا أي نسخة محلية بديلة — الفشل هون شبه دائماً
        // انقطاع شبكة، فرسالة مباشرة "نزّل السورة أولاً" أوضح للمستخدم من
        // الرسالة العامة.
        errorMessage: state.liveListenEnabled
            ? 'لا إنترنت — نزّل السورة أولاً'
            : 'تعذّر تشغيل الصوت — تحقّق من الاتصال بالإنترنت',
      );
    }
  }
}

final quranAudioControllerProvider =
    NotifierProvider<QuranAudioController, QuranAudioState>(
      QuranAudioController.new,
    );
