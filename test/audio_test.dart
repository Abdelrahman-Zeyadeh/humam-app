// اختبار وحدة لمنطق الصوت الصرف: بناء الروابط وخيارات التكرار — بلا شبكة
// ولا مشغّل فعلي.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/features/audio/quran_audio_controller.dart';
import 'package:humam_app/features/audio/reciters.dart';

void main() {
  test('القرّاء المعتمدون بأنماطهم الصحيحة', () {
    expect(kReciters.map((r) => r.id).toSet(), {
      'husary', 'husary_mujawwad', 'husary_muallim',
      'minshawy', 'minshawy_mujawwad', 'minshawy_teacher',
      'abdulbasit_murattal', 'abdulbasit_mujawwad',
      'tablawi', 'mustafa_ismail', 'banna',
      'alafasy', 'dossari', 'muaiqly', 'qatami', 'ajamy', 'ghamadi', 'fares_abbad',
      'shuraym', 'sudais', 'juhaynee', 'hudhaify', 'qasim', 'jaber', 'ayyoub', 'basfar',
      'shatri', 'rifai', 'budair', 'tunaiji', 'matroud', 'akhdar',
      'baleela', 'barhaji', 'talib_hamid', 'qarafi', 'badr_turki', 'buaijan', 'abkar', 'hazza',
    });
    // القرّاء بنمط سورة كاملة
    for (final id in [
      'baleela', 'barhaji', 'talib_hamid', 'qarafi', 'badr_turki', 'buaijan', 'abkar', 'hazza',
    ]) {
      expect(reciterById(id).mode, ReciterAudioMode.perSurahOnly, reason: id);
    }
    // القرّاء بنمط آية بآية
    for (final id in [
      'husary', 'husary_mujawwad', 'husary_muallim',
      'minshawy', 'minshawy_mujawwad', 'minshawy_teacher',
      'abdulbasit_murattal', 'abdulbasit_mujawwad',
      'tablawi', 'mustafa_ismail', 'banna',
      'alafasy', 'dossari', 'muaiqly', 'qatami', 'ajamy', 'ghamadi', 'fares_abbad',
      'shuraym', 'sudais', 'juhaynee', 'hudhaify', 'qasim', 'jaber', 'ayyoub', 'basfar',
      'shatri', 'rifai', 'budair', 'tunaiji', 'matroud', 'akhdar',
    ]) {
      expect(reciterById(id).mode, ReciterAudioMode.perAyah, reason: id);
    }
  });

  test('رابط آية everyayah.com بصيغة SSSAAA.mp3 صحيحة', () {
    expect(ayahAudioUrl('husary', 1, 1), 'https://everyayah.com/data/Husary_128kbps/001001.mp3');
    expect(ayahAudioUrl('minshawy', 2, 286), 'https://everyayah.com/data/Minshawy_Murattal_128kbps/002286.mp3');
    expect(ayahAudioUrl('qasim', 114, 6), 'https://everyayah.com/data/Muhsin_Al_Qasim_192kbps/114006.mp3');
  });

  test('رابط سورة بندر بليلة كاملة بصيغة SSS.mp3', () {
    expect(surahAudioUrl('baleela', 1), 'https://media.way2quran.com/bandar-balila/hafs-an-asim/001.mp3');
    expect(surahAudioUrl('baleela', 114), 'https://media.way2quran.com/bandar-balila/hafs-an-asim/114.mp3');
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
