import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/tajweed/tajweed_text_parser.dart';

void main() {
  test('تلوين المدود والقلقلة والغنة والإقلاب', () {
    // 1. القلقلة (قطب جد عند السكون)
    const quranText = 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ';
    final segments = TajweedTextParser.parse(quranText);
    expect(segments.isNotEmpty, true);

    // 2. فحص استخراج Spans
    final spans = TajweedTextParser.buildSpans(
      quranText,
      defaultColor: const Color(0xFF000000),
      enableTajweed: true,
    );
    expect(spans.isNotEmpty, true);
  });
}
