// اختبار وحدة لمنطق الصوت الصرف: بناء الروابط وخيارات التكرار — بلا شبكة
// ولا مشغّل فعلي.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/features/audio/quran_audio_controller.dart';
import 'package:humam_app/features/audio/reciters.dart';

void main() {
  test('القرّاء الأربعة المعتمدون بأنماطهم الصحيحة', () {
    expect(kReciters.map((r) => r.id).toSet(), {'husary', 'minshawy', 'qasim', 'baleela'});
    expect(reciterById('baleela').mode, ReciterAudioMode.perSurahOnly);
    expect(reciterById('husary').mode, ReciterAudioMode.perAyah);
    expect(reciterById('minshawy').mode, ReciterAudioMode.perAyah);
    expect(reciterById('qasim').mode, ReciterAudioMode.perAyah);
  });

  test('رابط آية everyayah.com بصيغة SSSAAA.mp3 صحيحة', () {
    expect(ayahAudioUrl('husary', 1, 1), 'https://everyayah.com/data/Husary_128kbps/001001.mp3');
    expect(ayahAudioUrl('minshawy', 2, 286), 'https://everyayah.com/data/Minshawy_Murattal_128kbps/002286.mp3');
    expect(ayahAudioUrl('qasim', 114, 6), 'https://everyayah.com/data/Muhsin_Al_Qasim_192kbps/114006.mp3');
  });

  test('رابط سورة بندر بليلة كاملة بصيغة SSS.mp3', () {
    expect(surahAudioUrl('baleela', 1), 'https://server6.mp3quran.net/balilah/001.mp3');
    expect(surahAudioUrl('baleela', 114), 'https://server6.mp3quran.net/balilah/114.mp3');
  });

  test('لا رابط سورة كاملة للقرّاء المقسَّمين بالآية (يستخدمون طابور آيات بدله)', () {
    expect(() => surahAudioUrl('husary', 1), throwsArgumentError);
  });

  test('لا رابط آية للقارئ غير المقسَّم بالآية', () {
    expect(() => ayahAudioUrl('baleela', 1, 1), throwsArgumentError);
  });

  test('مضاعفات خيارات التكرار', () {
    expect(RepeatOption.off.multiplier, 1);
    expect(RepeatOption.times2.multiplier, 2);
    expect(RepeatOption.times3.multiplier, 3);
    expect(RepeatOption.times5.multiplier, 5);
    expect(RepeatOption.infinite.multiplier, isNull);
  });

  test('دورة خيارات التكرار ترجع للبداية بعد الأخير', () {
    expect(RepeatOption.off.nextOption, RepeatOption.times2);
    expect(RepeatOption.infinite.nextOption, RepeatOption.off);
  });
}
