import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/dorar_hadith_result.dart';

final dorarSearchServiceProvider = Provider<DorarSearchService>((ref) {
  return DorarSearchService();
});

/// رابط صفحة نتائج بحث دُرر السنية — دالة موحّدة يستخدمها كل من الجالب
/// الفعلي (`DorarWebViewFetcher`) وهذا الملف، لضمان تطابقهما دائماً.
String dorarSearchUrl(String query, {int page = 1}) {
  final q = Uri.encodeComponent(query.trim());
  return page <= 1
      ? 'https://dorar.net/hadith/search?q=$q'
      : 'https://dorar.net/hadith/search?q=$q&page=$page';
}

/// تحليل HTML صفحة نتائج بحث دُرر السنية (dorar.net) وتحويله لكائنات
/// Dart — لا يجلب أي شيء بنفسه، فقط يحلّل نصّاً وصله جاهزاً (راجع
/// `DorarWebViewFetcher` لكيفية الجلب الفعلي وسبب استخدام WebView حقيقي
/// لا Dio). الموقع لا يوفّر أي API رسمي، فهذا تحليل HTML مباشر لبنية
/// صفحة النتائج (بنية ثابتة تحقّقنا منها مباشرة: كل نتيجة
/// `div.border-bottom.py-4` يحوي `h5.h5-responsive` للمتن و
/// `div.d-block.mb-2` لبيانات الراوي/المحدث/الحكم، بالإضافة لرابط
/// `a.shareLink[tag]` يحمل معرّف الحديث). لو غيّر الموقع بنيته مستقبلاً،
/// النتيجة تكون قائمة فارغة لا خطأ صريح — تعامل مع هذا الاحتمال بمراجعة
/// `_parseResultBlock` من جديد.
class DorarSearchService {
  /// بحث بنص الحديث أو أي جزء منه — يحتاج HTML صفحة النتائج جاهزاً
  /// (`html`)، عادة من `DorarWebViewFetcher.fetchHtml`.
  List<DorarHadithResult> parseSearchResults(String html) {
    if (html.isEmpty) return [];

    final document = html_parser.parse(html);
    final blocks = document.querySelectorAll('div.border-bottom.py-4');

    final results = <DorarHadithResult>[];
    for (final block in blocks) {
      final parsed = _parseResultBlock(block);
      if (parsed != null) results.add(parsed);
    }
    return results;
  }

  DorarHadithResult? _parseResultBlock(Element block) {
    final h5 = block.querySelector('article h5.h5-responsive');
    if (h5 == null) return null;

    var matn = h5.text.trim();
    // إزالة رقم ترتيب النتيجة بأول النص (مثلاً "2  -  ") إن وُجد.
    matn = matn.replaceFirst(RegExp(r'^\d+\s*-\s*'), '').trim();
    if (matn.isEmpty) return null;

    // المعرّف: من رابط المشاركة (a.shareLink[tag]) أساساً، أو من رابط
    // "عرض الحديث" (/h/<id>) احتياطياً لو تغيّرت خاصية tag.
    String? id = block.querySelector('a.shareLink')?.attributes['tag'];
    if (id == null || id.isEmpty) {
      for (final a in block.querySelectorAll('a[href]')) {
        final href = a.attributes['href'] ?? '';
        final match = RegExp(r'^/h/([A-Za-z0-9]+)').firstMatch(href);
        if (match != null) {
          id = match.group(1);
          break;
        }
      }
    }
    if (id == null || id.isEmpty) return null;

    String? grade;
    String? narrator;
    String? muhaddith;
    String? source;
    String? pageOrNumber;
    String? takhrij;

    final details = block.querySelector('div.d-block.mb-2');
    if (details != null) {
      for (final strong in details.querySelectorAll('strong.px-2')) {
        final label = strong.text;
        final value = strong.querySelector('span')?.text.trim();
        if (value == null || value.isEmpty) continue;

        if (label.contains('خلاصة حكم المحدث')) {
          grade = value;
        } else if (label.contains('المحدث')) {
          muhaddith = value;
        } else if (label.contains('المصدر')) {
          source = value;
        } else if (label.contains('الصفحة أو الرقم')) {
          pageOrNumber = value;
        } else if (label.contains('التخريج')) {
          takhrij = value;
        } else if (label.contains('الراوي')) {
          narrator = value;
        }
      }

      final categories = details
          .querySelectorAll('a.badge-dorar')
          .map((a) => a.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      return DorarHadithResult(
        id: id,
        matn: matn,
        grade: grade,
        narrator: narrator,
        muhaddith: muhaddith,
        source: source,
        pageOrNumber: pageOrNumber,
        takhrij: takhrij,
        categories: categories,
      );
    }

    return DorarHadithResult(id: id, matn: matn);
  }
}
