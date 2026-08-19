import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ذكر مفرد ضمن قسم من مكتبة حصن المسلم الكاملة — راجع
/// `tools/build_azkar_full.py` ومصدره (`asellam/HisnElMuslim`، رخصة MIT).
class AzkarLibraryItem {
  const AzkarLibraryItem({required this.text, required this.count, this.reference});

  factory AzkarLibraryItem.fromJson(Map<String, dynamic> json) {
    return AzkarLibraryItem(
      text: json['text'] as String,
      count: json['count'] as int,
      reference: json['reference'] as String?,
    );
  }

  final String text;
  final int count;
  final String? reference;
}

/// قسم من مكتبة حصن المسلم (١٣١ قسماً — يستبعد الصباح/المساء المغطّيين
/// بشاشة `AzkarScreen` المخصّصة أصلاً). `id` مستقر عبر إعادة البناء
/// (فهرس القسم بالملف الخام الأصلي)، يُستخدم مفتاحاً لتتبّع تقدّم العدّ.
class AzkarLibraryCategory {
  const AzkarLibraryCategory({required this.id, required this.title, required this.items});

  factory AzkarLibraryCategory.fromJson(Map<String, dynamic> json) {
    return AzkarLibraryCategory(
      id: json['id'] as int,
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => AzkarLibraryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String title;
  final List<AzkarLibraryItem> items;
}

/// مكتبة أذكار حصن المسلم الكاملة (١٣١ قسماً غير أذكار الصباح/المساء) —
/// راجع `tools/raw/README.md` لمصدرها ورخصتها.
final azkarLibraryProvider = FutureProvider<List<AzkarLibraryCategory>>((ref) async {
  final raw = await rootBundle.loadString('assets/azkar/azkar_categories.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list.map((e) => AzkarLibraryCategory.fromJson(e as Map<String, dynamic>)).toList();
});

/// أذكار النوم تحديداً (القسم `id == 28` — "أَذْكَارُ النَّوْمِ"، ١٥ ذكراً —
/// تحقّقتُ من `assets/azkar/azkar_categories.json` مباشرة) معروضة كـ"خانة"
/// ثالثة بشاشة الأذكار الرئيسية (`AzkarScreen`) على نفس مستوى الصباح/
/// المساء، بدل الاكتفاء بدفنها وسط ١٣١ قسم مكتبة حصن المسلم الكاملة.
final sleepAzkarProvider = FutureProvider<AzkarLibraryCategory>((ref) async {
  final categories = await ref.watch(azkarLibraryProvider.future);
  return categories.firstWhere((c) => c.id == 28);
});
