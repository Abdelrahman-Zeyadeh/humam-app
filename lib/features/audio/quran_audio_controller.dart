import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/audio_prefs.dart';
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

  RepeatOption get nextOption => RepeatOption.values[(index + 1) % RepeatOption.values.length];
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
  }) {
    return QuranAudioState(
      isActive: isActive ?? this.isActive,
      reciterId: reciterId ?? this.reciterId,
      currentSurah: identical(currentSurah, _sentinel) ? this.currentSurah : currentSurah as int?,
      fromAyah: identical(fromAyah, _sentinel) ? this.fromAyah : fromAyah as int?,
      toAyah: identical(toAyah, _sentinel) ? this.toAyah : toAyah as int?,
      currentAyahId: identical(currentAyahId, _sentinel) ? this.currentAyahId : currentAyahId as int?,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      speed: speed ?? this.speed,
      repeat: repeat ?? this.repeat,
      supportsHighlight: supportsHighlight ?? this.supportsHighlight,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
    );
  }
}

/// محرّك تشغيل المصحف الصوتي كله: آية واحدة، سورة كاملة، تكرار، سرعة،
/// وتظليل الآية الحالية (`currentAyahId`) لعرضها على صفحة المصحف.
/// يبني طابوراً واحداً بمشغّل `just_audio` مشترك (`ayahAudioPlayerProvider`)
/// سواء كانت التلاوة مقسّمة بالآية أو ملف سورة واحد — راجع `reciters.dart`.
class QuranAudioController extends Notifier<QuranAudioState> {
  List<int?> _queueAyahIds = const [];

  AudioPlayer get _player => ref.read(ayahAudioPlayerProvider);

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
      state = state.copyWith(
        isPlaying: s.playing && !completed,
        isLoading: s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering,
        isActive: completed ? false : null,
        currentAyahId: completed ? null : _sentinelKeep(),
      );
    });

    ref.onDispose(() {
      indexSub.cancel();
      stateSub.cancel();
    });

    return QuranAudioState(reciterId: prefs.reciterId, speed: prefs.speed);
  }

  // مساعد صغير: يبقي القيمة الحالية بلا تغيير (يمرَّر لـ copyWith فقط
  // بحالة "لم يكتمل بعد" ليتفادى استبدال currentAyahId بلا داعٍ).
  Object? _sentinelKeep() => _sentinel;

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await ref.read(audioPrefsProvider).setSpeed(speed);
    if (state.isActive) await _player.setSpeed(speed);
  }

  void setRepeat(RepeatOption option) {
    state = state.copyWith(repeat: option);
  }

  /// يبدّل القارئ. لو تشغيل جارٍ، يعيد تحميل نفس الاختيار (سورة/نطاق) بصوت
  /// القارئ الجديد بدل قطع التشغيل بلا تفسير.
  Future<void> setReciter(String id) async {
    final wasActive = state.isActive;
    final surah = state.currentSurah;
    final from = state.fromAyah;
    final to = state.toAyah;
    state = state.copyWith(reciterId: id);
    await ref.read(audioPrefsProvider).setReciterId(id);
    if (wasActive && surah != null) {
      await _playSelection(surahId: surah, fromAyah: from, toAyah: to);
    }
  }

  /// تشغيل آية واحدة فورية (زر "استماع" بشيت إجراءات الآية).
  Future<void> playAyah(int surah, int ayah) =>
      _playSelection(surahId: surah, fromAyah: ayah, toAyah: ayah);

  /// تشغيل سورة كاملة من أوّلها.
  Future<void> playSurahFull(int surahId) => _playSelection(surahId: surahId);

  Future<void> togglePlayPause() async {
    if (!state.isActive) return;
    if (state.isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _queueAyahIds = const [];
    state = state.copyWith(
      isActive: false,
      isPlaying: false,
      currentAyahId: null,
      currentSurah: null,
      fromAyah: null,
      toAyah: null,
      errorMessage: null,
    );
  }

  Future<void> next() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  Future<void> _playSelection({required int surahId, int? fromAyah, int? toAyah}) async {
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
      List<String> baseUrls;
      List<int?> baseAyahIds;

      if (reciter.mode == ReciterAudioMode.perSurahOnly) {
        baseUrls = [surahAudioUrl(reciter.id, surahId)];
        baseAyahIds = [null];
      } else {
        final ayahs = await ref.read(quranRepositoryProvider).ayahsForSurah(surahId);
        final selected = (fromAyah == null && toAyah == null)
            ? ayahs
            : ayahs.where((a) => a.ayah >= (fromAyah ?? 1) && a.ayah <= (toAyah ?? ayahs.length)).toList();
        if (selected.isEmpty) throw StateError('لا آيات بهذا النطاق');
        baseUrls = [for (final a in selected) ayahAudioUrl(reciter.id, a.surah, a.ayah)];
        baseAyahIds = [for (final a in selected) a.id];
      }

      final multiplier = state.repeat.multiplier;
      final loopAll = state.repeat == RepeatOption.infinite;
      final finalUrls = multiplier == null ? baseUrls : [for (var i = 0; i < multiplier; i++) ...baseUrls];
      final finalAyahIds =
          multiplier == null ? baseAyahIds : [for (var i = 0; i < multiplier; i++) ...baseAyahIds];
      _queueAyahIds = finalAyahIds;

      await _player.setAudioSources(
        [for (final u in finalUrls) AudioSource.uri(Uri.parse(u))],
        preload: true,
      );
      await _player.setLoopMode(loopAll ? LoopMode.all : LoopMode.off);
      await _player.setSpeed(state.speed);
      state = state.copyWith(isActive: true, currentAyahId: finalAyahIds.first);
      await _player.play();
    } catch (_) {
      _queueAyahIds = const [];
      state = state.copyWith(
        isActive: false,
        isLoading: false,
        currentAyahId: null,
        errorMessage: 'تعذّر تشغيل الصوت — تحقّق من الاتصال بالإنترنت',
      );
    }
  }
}

final quranAudioControllerProvider = NotifierProvider<QuranAudioController, QuranAudioState>(
  QuranAudioController.new,
);
