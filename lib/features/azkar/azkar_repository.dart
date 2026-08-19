import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// تصنيف الذكر حسب `type` بمصدر البيانات: `0` = صباح ومساء معاً، `1` =
/// صباح فقط، `2` = مساء فقط. راجع `tools/raw/README.md` لمصدر البيانات.
enum AzkarPeriod { morning, evening }

class Dhikr {
  const Dhikr({
    required this.order,
    required this.content,
    required this.count,
    this.countDescription,
    this.fadl,
    this.source,
    required this.rawType,
    this.audioUrl,
    this.hadithText,
    this.explanation,
  });

  factory Dhikr.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(dynamic v) {
      final s = v as String?;
      return (s == null || s.isEmpty) ? null : s;
    }

    return Dhikr(
      order: json['order'] as int,
      content: json['content'] as String,
      count: json['count'] as int,
      countDescription: nonEmpty(json['count_description']),
      fadl: nonEmpty(json['fadl']),
      source: nonEmpty(json['source']),
      rawType: json['type'] as int,
      audioUrl: nonEmpty(json['audio']),
      hadithText: nonEmpty(json['hadith_text']),
      explanation: nonEmpty(json['explanation_of_hadith_vocabulary']),
    );
  }

  final int order;
  final String content;
  final int count;
  final String? countDescription;
  final String? fadl;
  final String? source;
  final int rawType; // 0 | 1 | 2
  final String? audioUrl;
  final String? hadithText;
  final String? explanation;

  bool appliesTo(AzkarPeriod period) {
    if (rawType == 0) return true;
    if (period == AzkarPeriod.morning) return rawType == 1;
    return rawType == 2;
  }
}

/// أذكار الصباح والمساء (تسبيح حصن المسلم) — مصدر مرخّص MIT، راجع
/// `tools/raw/README.md`. **لا يشمل** أذكار النوم/بعد الصلاة/المتفرقة من
/// الكتاب كاملاً — هذا قسم فرعي محدَّد فقط (نفس مصدر البيانات لا يغطي الباقي).
final azkarListProvider = FutureProvider<List<Dhikr>>((ref) async {
  final raw = await rootBundle.loadString('assets/azkar/azkar.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list.map((e) => Dhikr.fromJson(e as Map<String, dynamic>)).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
});
