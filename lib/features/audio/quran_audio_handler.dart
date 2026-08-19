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
/// ⚠️ **لم يُختبر بجهاز أندرويد/iOS فعلي بعد** — مبني حرفياً حسب توثيق
/// حزمة `audio_service` الرسمي (النمط القياسي `BaseAudioHandler` + تحويل
/// `playbackEventStream`)، لكن بلا تحقّق ميداني من ظهور/عمل الإشعار فعلياً.
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranAudioHandler(this._ref) {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _ref.listen<QuranAudioState>(quranAudioControllerProvider, (prev, next) {
      if (prev?.currentAyahId != next.currentAyahId || prev?.currentSurah != next.currentSurah) {
        _updateMediaItem(next);
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  AudioPlayer get _player => _ref.read(ayahAudioPlayerProvider);

  Future<void> _updateMediaItem(QuranAudioState audio) async {
    final surahId = audio.currentSurah;
    if (surahId == null) return;
    String title = 'المصحف';
    try {
      final surah = await _ref.read(quranRepositoryProvider).surahById(surahId);
      title = 'سورة ${surah.nameArPlain}';
    } catch (_) {
      // تجاهل — يبقى العنوان الافتراضي لو تعذّر الاستعلام، ما يوقف التشغيل.
    }
    mediaItem.add(MediaItem(
      id: 'quran-audio-$surahId-${audio.currentAyahId ?? 0}',
      title: title,
      artist: reciterById(audio.reciterId).nameAr,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _ref.read(quranAudioControllerProvider.notifier).stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
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
      queueIndex: _player.currentIndex,
    );
  }
}

final quranAudioHandlerProvider = Provider<QuranAudioHandler>((ref) => QuranAudioHandler(ref));
