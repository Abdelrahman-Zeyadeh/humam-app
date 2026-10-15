import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/features/audio/reciters.dart';
import 'package:humam_app/features/duroos/duroos_models.dart';

void main() {
  group('Reciters Update Tests', () {
    test('Waleed Al-Saeedan is in kReciters with perSurahOnly mode', () {
      final reciter = reciterById('saeedan');
      expect(reciter.id, 'saeedan');
      expect(reciter.nameAr, contains('وليد بن راشد السعيدان'));
      expect(reciter.mode, ReciterAudioMode.perSurahOnly);
    });

    test('Waleed Al-Saeedan surah audio URL generates valid Archive.org URLs for 114 surahs', () {
      final urlFatiha = surahAudioUrl('saeedan', 1);
      expect(urlFatiha, 'https://archive.org/download/Walid-Alsaeedan-1438/001.mp3');

      final urlNas = surahAudioUrl('saeedan', 114);
      expect(urlNas, 'https://archive.org/download/Walid-Alsaeedan-1438/114.mp3');
    });

    test('Reciter avatar image exists on disk for saeedan', () {
      final reciter = reciterById('saeedan');
      final file = File(reciter.imageAsset);
      expect(file.existsSync(), isTrue, reason: 'Image file ${reciter.imageAsset} should exist');
    });
  });

  group('Duroos Sources and Scholars Images Tests', () {
    test('Waleed Al-Saeedan recitation entry is removed from kDuroosSources', () {
      final hasRecitation = kDuroosSources.any((s) => s.id == 'waleed_saeedan_recitation');
      expect(hasRecitation, isFalse);
    });

    test('Waleed Al-Saeedan lessons entry is still present in kDuroosSources', () {
      final hasLessons = kDuroosSources.any((s) => s.id == 'waleed_saeedan');
      expect(hasLessons, isTrue);
    });

    test('All Duroos sources have imageAsset defined and files exist on disk', () {
      for (final source in kDuroosSources) {
        expect(source.imageAsset, isNotNull, reason: 'Source ${source.id} (${source.title}) should have imageAsset');
        final file = File(source.imageAsset!);
        expect(file.existsSync(), isTrue, reason: 'Image asset for ${source.id} (${source.imageAsset}) must exist on disk');
      }
    });
  });
}
