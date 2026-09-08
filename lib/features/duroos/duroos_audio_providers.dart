import 'dart:async';

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

/// **مؤقّت نوم للدروس** — بطلب صريح ("مؤقّت نوم للأقسام والتصانيف
/// ناقص")، بنفس فكرة `QuranRadioScreen._startSleepTimer` تماماً لكن على
/// مستوى الـprovider المشترك (لا حالة شاشة محلية) — ضروري هون تحديداً
/// لأن [duroosAudioPlayerProvider] مشترك بين عدة نسخ شاشة مفتوحة فوق
/// بعضها (عالِم → تصنيف فرعي)، فمؤقّت بحالة شاشة محلية كان سيُفقَد فوراً
/// عند التنقّل بينها. يوقف [duroosAudioPlayerProvider] فقط (لا يغلق
/// الشاشة ولا يصفّر المحاضرة النشطة) — نفس سلوك مؤقّت الراديو تماماً.
class DuroosSleepTimerNotifier extends Notifier<DateTime?> {
  Timer? _fireTimer;
  Timer? _tickTimer;

  @override
  DateTime? build() {
    ref.onDispose(() {
      _fireTimer?.cancel();
      _tickTimer?.cancel();
    });
    return null;
  }

  void start(Duration duration) {
    _fireTimer?.cancel();
    _tickTimer?.cancel();
    state = DateTime.now().add(duration);

    _fireTimer = Timer(duration, () {
      ref.read(duroosAudioPlayerProvider).pause();
      _tickTimer?.cancel();
      state = null;
    });
    // يُبقي "الدقائق المتبقّية" المعروضة بالواجهة (شارة الأيقونة) محدَّثة
    // كل دقيقة عبر [duroosSleepTimerTickProvider] — `state` هون (وقت
    // الانتهاء الثابت) لا يتغيّر بين البداية والانتهاء فمراقبته وحدها لا
    // تُعيد بناء الواجهة كل دقيقة.
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.read(duroosSleepTimerTickProvider.notifier).bump();
    });
  }

  void cancel() {
    _fireTimer?.cancel();
    _tickTimer?.cancel();
    state = null;
  }
}

final duroosSleepTimerProvider = NotifierProvider<DuroosSleepTimerNotifier, DateTime?>(
  DuroosSleepTimerNotifier.new,
);

/// عدّاد يُزاد كل دقيقة أثناء عمل [duroosSleepTimerProvider] فقط — راقبه
/// بالواجهة بجانب `duroosSleepTimerProvider` لإجبار إعادة حساب "الدقائق
/// المتبقّية" (`sleepEndsAt.difference(DateTime.now())`) كل دقيقة، بلا
/// حاجة لأي حالة إضافية بالشاشة نفسها — نفس نمط
/// `CategoryStreakVersionNotifier` بـ`user_prefs.dart`.
class DuroosSleepTimerTickNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final duroosSleepTimerTickProvider = NotifierProvider<DuroosSleepTimerTickNotifier, int>(
  DuroosSleepTimerTickNotifier.new,
);
