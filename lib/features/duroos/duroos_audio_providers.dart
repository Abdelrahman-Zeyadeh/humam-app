import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'duroos_models.dart';

/// مشغّل صوت **واحد مشترك** لكل شاشات الدروس المفتوحة (شاشة عالِم +
/// تصنيفاته الفرعية المفتوحة فوقها بالتنقّل) — قبل هذا كان كل نسخة شاشة
/// (`DuroosLecturesScreen`) تنشئ `AudioPlayer()` خاصاً بها، فلو شغّلت
/// محاضرة بشاشة الأصل ثم دخلت تصنيفاً فرعياً وشغّلت محاضرة ثانية هناك،
/// يشتغل الاثنان معاً (تقاطع صوت). بمشغّل واحد مشترك، تشغيل محاضرة
/// جديدة يستبدل تلقائياً أي محاضرة سابقة على نفس المشغّل — تقاطع الصوت
/// أصبح مستحيلاً بنيوياً. راجع [activeDuroosLectureProvider] لحالة "أي
/// محاضرة نشطة الآن" المتزامنة بنفس المنطق بين كل الشاشات.
final duroosAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// المحاضرة النشطة حالياً على [duroosAudioPlayerProvider] — null لو لا
/// شيء يُشغَّل. كل شاشات الدروس المفتوحة تراقب هذه القيمة نفسها (بدل كل
/// شاشة تحتفظ بحالتها الخاصة) فيبقى الشريط السفلي/تمييز المحاضرة النشطة
/// متزامناً بلا فرق بين الشاشة التي بدأت التشغيل وأي شاشة أخرى مفتوحة
/// فوقها أو تحتها.
class ActiveDuroosLectureNotifier extends Notifier<DuroosLecture?> {
  @override
  DuroosLecture? build() => null;

  void set(DuroosLecture? lecture) => state = lecture;
}

final activeDuroosLectureProvider = NotifierProvider<ActiveDuroosLectureNotifier, DuroosLecture?>(
  ActiveDuroosLectureNotifier.new,
);
