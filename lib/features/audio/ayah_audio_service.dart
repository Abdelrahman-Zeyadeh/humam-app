import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// مشغّل صوتي واحد يعيش طوال عمر التطبيق — نفس نمط `quranDatabaseProvider`.
/// **لا تحكّم من الإشعار/شاشة القفل مباشرة عبره** — ذاك عبر `audio_service`
/// بمقبض منفصل (`quran_audio_handler.dart`) يستخدم نفس هذا المشغّل، لا
/// يستبدله. منطق التشغيل الفعلي (طوابير، تكرار، سرعة) بـ
/// `quran_audio_controller.dart` — هذا الملف يوفّر المشغّل الخام فقط.
final ayahAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});
