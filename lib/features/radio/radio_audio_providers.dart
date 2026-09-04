import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'quran_radio_screen.dart';

/// مشغّل صوت **واحد مشترك** لشاشة الإذاعات — نفس نمط
/// `duroosAudioPlayerProvider` بالضبط. الفائدة الأساسية هون ليست منع
/// تقاطع صوت (شاشة واحدة فقط لا شاشات متداخلة كالدروس) بل **فصل عمر
/// المشغّل عن عمر الشاشة**: قبل هذا كان `AudioPlayer()` حقل عادي بحالة
/// `_QuranRadioScreenState` يُتخلَّص منه بـ`dispose()`، فلما يخرج المستخدم
/// من الشاشة (زر الرجوع، أو تصغير التطبيق يودي أحياناً لإعادة بناء
/// الشجرة) ينقطع البث فوراً رغم أن المستخدم بس يبي يسمع بالخلفية. بمشغّل
/// مشترك بعمر التطبيق (`ref.onDispose` فقط)، إغلاق الشاشة ما يوقف البث —
/// يوقفه فقط زر الإغلاق الصريح بالشريط السفلي. راجع [activeRadioStationProvider]
/// لحالة "أي محطة نشطة الآن" المتزامنة بنفس المنطق.
final radioAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// المحطة النشطة حالياً على [radioAudioPlayerProvider] — null لو لا شيء
/// يُشغَّل. راجع `duroos_audio_providers.dart` لنفس الفكرة بالضبط.
class ActiveRadioStationNotifier extends Notifier<QuranRadioStation?> {
  @override
  QuranRadioStation? build() => null;

  void set(QuranRadioStation? station) => state = station;
}

final activeRadioStationProvider =
    NotifierProvider<ActiveRadioStationNotifier, QuranRadioStation?>(
      ActiveRadioStationNotifier.new,
    );
