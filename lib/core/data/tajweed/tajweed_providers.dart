import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../quran/quran_providers.dart';
import 'tajweed_text_parser.dart';

class WordTajweedInfo {
  final Color color;
  final String ruleName;

  const WordTajweedInfo({required this.color, required this.ruleName});
}

/// خريطة الكلمات العثمانية للآية (1-based position -> String wordText)
final ayahUthmaniWordsProvider = FutureProvider.family<Map<int, String>, int>((ref, ayahId) async {
  final ayah = await ref.watch(quranRepositoryProvider).ayahById(ayahId);
  final words = ayah.textUthmani.trim().split(RegExp(r'\s+'));
  final map = <int, String>{};
  for (var i = 0; i < words.length; i++) {
    map[i + 1] = words[i];
  }
  return map;
});

/// خريطة المقاطع التجويدية الدقيقة لكل كلمة في الآية (1-based position -> `List<TajweedSpanSegment>`)
final ayahWordTajweedSegmentsProvider = FutureProvider.family<Map<int, List<TajweedSpanSegment>>, int>((ref, ayahId) async {
  final ayah = await ref.watch(quranRepositoryProvider).ayahById(ayahId);
  final words = ayah.textUthmani.trim().split(RegExp(r'\s+'));
  final map = <int, List<TajweedSpanSegment>>{};

  for (var i = 0; i < words.length; i++) {
    final wordText = words[i];
    final segments = TajweedTextParser.parse(wordText);
    map[i + 1] = segments;
  }

  return map;
});

/// خريطة أحكام التجويد المجمعة لكل كلمة في آية معينة
final ayahTajweedWordsProvider = FutureProvider.family<Map<int, WordTajweedInfo>, int>((ref, ayahId) async {
  final ayah = await ref.watch(quranRepositoryProvider).ayahById(ayahId);
  final words = ayah.textUthmani.trim().split(RegExp(r'\s+'));
  final map = <int, WordTajweedInfo>{};

  for (var i = 0; i < words.length; i++) {
    final wordText = words[i];
    final segments = TajweedTextParser.parse(wordText);

    // نبحث عن أول مقطع يحتوي على حكم تجويدي ملون
    for (final seg in segments) {
      if (seg.color != null && seg.ruleName != null) {
        map[i + 1] = WordTajweedInfo(color: seg.color!, ruleName: seg.ruleName!);
        break;
      }
    }
  }

  return map;
});
