import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/data/quran/quran_providers.dart';
import 'ayah_audio_service.dart';
import 'quran_audio_controller.dart';
import 'reciters.dart';

/// يعكس حالة المشغّل المشترك (`ayahAudioPlayerProvider`) بإشعار نظام حقيقي
/// (أندرويد/iOS فقط — راجع `main.dart`) فيقدر المستخدم يتحكّم بالتلاوة من
/// الإشعار وشاشة القفل بلا فتح التطبيق. **لا يملك مشغّلاً خاصاً به** ولا
/// يكرّر منطق الطابور/التكرار — فقط يترجم أوامر النظام (تشغيل/إيقاف/تالي)
/// لنفس استدعاءات `QuranAudioController`/المشغّل المستخدَمة داخل التطبيق،
/// فيبقى كل شيء متزامناً بمصدر واحد.
///
/// `AudioService.init` يُستدعى **مرة واحدة فقط** لكامل التطبيق (راجع
/// `main.dart`)، لذا هذا المقبض أصبح أيضاً القناة الوحيدة لأي ميزة صوت
/// أخرى تريد إشعار نظام حقيقي — دروس العلماء أول من استخدمها (راجع
/// `duroos_lectures_screen.dart`)، والراديو مرشّح لاحقاً بنفس الطريقة.
/// آلية ذلك: [attachExternalSession] يحوّل كل أوامر النظام (تشغيل/إيقاف/
/// تقديم وترجيع بالثواني) لمشغّل `just_audio` تسلّمه الشاشة نفسها بدل
/// تلاوة القرآن مؤقتاً، و[detachExternalSession] يعيد السيطرة تلقائياً
/// لتلاوة القرآن عند إغلاق تلك الشاشة. تلاوة القرآن تدعم "تالي/سابق"
/// (سورة تالية/سابقة)؛ المصدر الخارجي لا (لا معنى لـ"تالي" بمحاضرة أو بث
/// مباشر) فيعرض بدلها أزرار تقديم/ترجيع ١٠ ثوانٍ (`SeekHandler` أدناه
/// ينفّذهما تلقائياً فوق [seek]، بلا حاجة لتطبيقهما يدوياً).
///
/// ⚠️ **الجزء الخاص بتلاوة القرآن لم يُختبر بجهاز فعلي بعد** (راجع مذكّرة
/// المشروع). الجزء الخاص بدروس العلماء (المصدر الخارجي) بانتظار أول
/// اختبار فعلي أيضاً — بُني حديثاً بنفس نمط `BaseAudioHandler` القياسي.
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranAudioHandler(this._ref) {
    _ref.listen<QuranAudioState>(quranAudioControllerProvider, (prev, next) {
      if (_hasExternal) return; // مصدر خارجي (دروس/راديو) نشط حالياً — تجاهل تحديثات القرآن بالخلفية
      if (prev?.currentAyahId != next.currentAyahId || prev?.currentSurah != next.currentSurah) {
        _updateQuranMediaItem(next);
      }
    }, fireImmediately: true);

    _bindQuranPlayer();

    _ref.onDispose(() {
      _eventSub?.cancel();
      _durationSub?.cancel();
    });
  }

  final Ref _ref;
  StreamSubscription<PlaybackEvent>? _eventSub;
  StreamSubscription<Duration?>? _durationSub;

  /// null = المتحكَّم به حالياً هو تلاوة القرآن (الوضع الافتراضي)، غير
  /// null = مشغّل مصدر خارجي (راجع [attachExternalSession]).
  AudioPlayer? _externalPlayer;
  bool get _hasExternal => _externalPlayer != null;

  AudioPlayer get _player => _externalPlayer ?? _ref.read(ayahAudioPlayerProvider);

  void _bindQuranPlayer() {
    _eventSub?.cancel();
    _durationSub?.cancel();
    final player = _ref.read(ayahAudioPlayerProvider);
    _eventSub = player.playbackEventStream.listen((event) {
      if (_hasExternal) return; // تبدّل المصدر بالأثناء — تجاهل حدث قديم من مشغّل القرآن
      playbackState.add(_transformEvent(event, skippable: true));
    });
    _durationSub = player.durationStream.listen((duration) {
      if (_hasExternal) return;
      final current = mediaItem.valueOrNull;
      if (current == null || duration == null) return;
      mediaItem.add(current.copyWith(duration: duration));
    });
  }

  Future<void> _updateQuranMediaItem(QuranAudioState audio) async {
    final surahId = audio.currentSurah;
    final ayahId = audio.currentAyahId;
    if (surahId == null) return;
    String title = 'المصحف';
    try {
      final surah = await _ref.read(quranRepositoryProvider).surahById(surahId);
      // `nameArPlain` يشمل كلمة "سورة" أصلاً
      title = surah.nameArPlain;
    } catch (_) {
      // تجاهل — يبقى العنوان الافتراضي لو تعذّر الاستعلام، ما يوقف التشغيل.
    }

    final latest = _ref.read(quranAudioControllerProvider);
    if (latest.currentSurah != surahId || latest.currentAyahId != ayahId) {
      return; // حماية من سباق الاستجابات المتأخرة
    }
    if (_hasExternal) return; // مصدر خارجي انتقل بالأثناء

    mediaItem.add(MediaItem(
      id: 'quran-audio-$surahId-${ayahId ?? 0}',
      title: title,
      artist: reciterById(audio.reciterId).nameAr,
      duration: _ref.read(ayahAudioPlayerProvider).duration,
    ));
  }

  /// يحوّل إشعار النظام للتحكّم بمشغّل خارج تلاوة القرآن — دروس العلماء
  /// حالياً (راجع `duroos_lectures_screen.dart`)، والراديو مرشّح لاحقاً.
  /// تستدعيه الشاشة عند بدء التشغيل، وتستدعي [updateExternalMediaItem]
  /// عند تبدّل العنوان (محاضرة تالية بلا مغادرة الشاشة)، و
  /// [detachExternalSession] عند إغلاق الشاشة لتعود السيطرة تلقائياً
  /// لتلاوة القرآن.
  void attachExternalSession(AudioPlayer player, MediaItem initialItem) {
    _eventSub?.cancel();
    _durationSub?.cancel();
    _externalPlayer = player;
    mediaItem.add(initialItem);
    playbackState.add(_transformEvent(player.playbackEvent, skippable: false));
    _eventSub = player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event, skippable: false));
    });
    _durationSub = player.durationStream.listen((duration) {
      final current = mediaItem.valueOrNull;
      if (current == null || duration == null) return;
      mediaItem.add(current.copyWith(duration: duration));
    });
  }

  /// يحدّث عنوان/فنان الإشعار الخارجي الحالي (مثلاً عند تبديل المحاضرة
  /// المُشغَّلة) — بلا أثر لو لا توجد جلسة خارجية نشطة حالياً.
  void updateExternalMediaItem(MediaItem item) {
    if (!_hasExternal) return;
    mediaItem.add(item);
  }

  /// يفصل المصدر الخارجي ويعيد الإشعار لعرض/التحكّم بتلاوة القرآن.
  void detachExternalSession() {
    if (!_hasExternal) return;
    _externalPlayer = null;
    _bindQuranPlayer();
    unawaited(_updateQuranMediaItem(_ref.read(quranAudioControllerProvider)));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    if (_hasExternal) {
      await _player.stop();
      return;
    }
    await _ref.read(quranAudioControllerProvider.notifier).stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_hasExternal) return; // لا معنى لـ"تالي" بمحاضرة/بث — يُستبدل بالتقديم بالثواني (SeekHandler)
    await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_hasExternal) return;
    await _player.seekToPrevious();
  }

  PlaybackState _transformEvent(PlaybackEvent event, {required bool skippable}) {
    return PlaybackState(
      controls: [
        if (skippable) MediaControl.skipToPrevious else MediaControl.rewind,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        if (skippable) MediaControl.skipToNext else MediaControl.fastForward,
      ],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [0, 1, 3],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: _player.playing,
      updatePosition: _player.position,
      speed: _player.speed,
      queueIndex: skippable ? _player.currentIndex : null,
    );
  }
}

final quranAudioHandlerProvider = Provider<QuranAudioHandler>((ref) => QuranAudioHandler(ref));
