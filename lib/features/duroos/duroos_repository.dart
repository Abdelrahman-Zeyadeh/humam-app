import 'package:dio/dio.dart';

import 'duroos_models.dart';

/// خطأ تحليل/جلب صريح — الواجهة تميّزه عن أخطاء الشبكة لتُظهر رسالة
/// صحيحة + زر إعادة محاولة بدل "لا يوجد محتوى" المضلِّلة (التي كانت
/// تظهر لو تغيّرت بنية HTML من جهة المصدر فلا يُطابِق ايُّا تعبير).
class DuroosParseException implements Exception {
  const DuroosParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// يجلب ويحلِّل محتوى الدروس من مصدرين حقيقيين (لا واجهة JS تحتاج
/// متصفحاً كاملاً بأيٍّ منهما، فتحليل نص HTML/XML مباشر بتعبير نمطي
/// كافٍ وموثوق):
///
/// - **islamweb**: صفحة `audio.islamweb.net/audio/index.php?page=lecview`
///   عبارة PHP قديم يُخرج HTML ثابتاً — كل محاضرة رابط mp3 مباشر (CDN
///   Azure) ضمن سمة `url='...'` بجوار `title_data="..."`، وكل تصنيف
///   فرعي رابط `lg=N` بجوار `<label class="tree_label">العنوان</label>`.
/// - **rss**: موجز بودكاست حقيقي (مثال: Anchor.fm) — كل حلقة `<item>`
///   بعنوان `<title>` (قد يكون بـCDATA) ورابط مباشر بسمة `<enclosure url="...">`.
///
/// **مقاومة تغيّر بنية المصدر**: تُطابَق وسوم `<a>` كاملة بلا افتراض ترتيب
/// السمات (`url`/`title_data`/`lg` بأيّ ترتيب وبأي اقتباس)، ومع فككيانات
/// HTML رقمية (&#…;) — وأيّ صفحة تُجلب بنجاح لكن بلا محتوى مطابق تُرفَع
/// كـ[DuroosParseException] صريحة بدل صمت "لا يوجد محتوى". لا حاجة لحزمة
/// تحليل HTML/XML كاملة (`html`/`xml`).
///
/// ⚠️ **ملاحظة محتوى**: هذه الميزة تعيد بثّ ملفات mp3 من أرشيف إسلام ويب/
/// موجزات رسمية داخل التطبيق — الإسناد للمصدر يظهر في واجهة المشغّل
/// (راجع `duroos_lectures_screen.dart`) رفق قبول التطبيق لقواعد استخدام
/// المصدر. لو غيّر المصدر سياساته، تتأثر الميزة لا غير.
class DuroosRepository {
  DuroosRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {'User-Agent': 'Mozilla/5.0'},
            ));

  final Dio _dio;

  /// وسوم `<a ...>` كاملة — نطابق الوسم ثم نستخرج سماته بأي ترتيب،
  /// لا تعبيراً مفترضاً تسلسلاً ثابتاً هشّاً.
  static final _aTagRe = RegExp(r'<a\b[^>]*>', caseSensitive: false, dotAll: true);
  static final _urlAttrRe = RegExp("\\burl\\s*=\\s*'([^']*)'");
  static final _titleAttrRe = RegExp(r'\btitle_data\s*=\s*"([^"]*)"');
  static final _lgAttrRe = RegExp(r'\blg\s*=\s*(\d+)');
  static final _labelRe = RegExp(r'<label[^>]*>(.*?)</label>', caseSensitive: false, dotAll: true);

  Future<DuroosPage> fetchIslamweb(int sid, int lg) async {
    final url =
        'https://audio.islamweb.net/audio/index.php?page=lecview&sid=$sid&read=0&lg=$lg&kh=0';
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data ?? '';
    if (html.trim().isEmpty) {
      throw const DuroosParseException(
        'استجابة فارغة من المصدر — تحقق من الاتصال وأعد المحاولة.',
      );
    }

    final categories = <DuroosCategory>[];
    if (lg == 0) {
      final seen = <int>{};
      for (final tag in _aTagRe.allMatches(html)) {
        final tagHtml = tag.group(0)!;
        // نفس شروط التصنيف السابقة (`lg=N&kh=0`) بلا افتراض ترتيب
        // المعاملات داخل الرابط.
        if (!tagHtml.contains('lg=') || !tagHtml.contains('kh=0')) continue;
        final lgMatch = _lgAttrRe.firstMatch(tagHtml);
        final id = lgMatch == null ? 0 : int.parse(lgMatch.group(1)!);
        if (id == 0 || !seen.add(id)) continue;
        // اسم التصنيف: سمة `title_data` أولاً، وإلا النص داخل `<label>`.
        var title = _titleAttrRe.firstMatch(tagHtml)?.group(1)?.trim() ?? '';
        if (title.isEmpty) {
          final label = _labelRe.firstMatch(html.substring(tag.end));
          title = label?.group(1)?.trim() ?? '';
        }
        if (title.isNotEmpty) {
          categories.add(DuroosCategory(lg: id, title: _decodeEntities(title)));
        }
      }
    }

    final lectures = <DuroosLecture>[];
    for (final tag in _aTagRe.allMatches(html)) {
      final tagHtml = tag.group(0)!;
      final urlMatch = _urlAttrRe.firstMatch(tagHtml);
      if (urlMatch == null) continue;
      final title = _decodeEntities(_titleAttrRe.firstMatch(tagHtml)?.group(1)?.trim() ?? '');
      if (title.isEmpty) continue;
      lectures.add(DuroosLecture(title: title, audioUrl: urlMatch.group(1)!));
    }

    // صفحة جُلبت بنجاح لكن لا تصنيفات فيها ولا محاضرات = البنية تغيّرت
    // أو القسم غير مطابق بصياغتنا — رسالة صريحة مع زر إعادة محاولة
    // أوضح للمستخدم من "لا يوجد محتوى بهذا القسم حالياً" الصامتة.
    if (categories.isEmpty && lectures.isEmpty) {
      throw const DuroosParseException(
        'تعذّر التعرف على محتوى هذه الصفحة (ربما تغيّرت بنية المصدر أو القسم فارغ) — أعد المحاولة.',
      );
    }

    return DuroosPage(categories: categories, lectures: lectures);
  }

  static final _rssItemRe = RegExp(r'<item>(.*?)</item>', dotAll: true);
  static final _rssTitleRe = RegExp(
    r'<title>(?:<!\[CDATA\[(.*?)\]\]>|(.*?))</title>',
    dotAll: true,
  );
  static final _rssEnclosureRe = RegExp(r'<enclosure[^>]*\burl="([^"]+)"');

  Future<List<DuroosLecture>> fetchRss(String feedUrl) async {
    final response = await _dio.get<String>(
      feedUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final xml = response.data ?? '';
    if (xml.trim().isEmpty) {
      throw const DuroosParseException(
        'استجابة فارغة من المصدر — تحقق من الاتصال وأعد المحاولة.',
      );
    }

    final lectures = <DuroosLecture>[];
    for (final m in _rssItemRe.allMatches(xml)) {
      final item = m.group(1)!;
      final t = _rssTitleRe.firstMatch(item);
      final rawTitle = t == null ? '' : (t.group(1) ?? t.group(2) ?? '');
      final title = _decodeEntities(rawTitle.trim());
      final enclosure = _rssEnclosureRe.firstMatch(item);
      if (enclosure == null || title.isEmpty) continue;
      lectures.add(DuroosLecture(title: title, audioUrl: enclosure.group(1)!));
    }
    if (lectures.isEmpty) {
      throw const DuroosParseException(
        'تعذّر التعرف على حلقات هذا الموجز (ربما تغيّرت بنيته) — أعد المحاولة.',
      );
    }
    return lectures;
  }

  /// فكّ تشفير كيانات HTML الشائعة **و** الكيانات الرقمية (`&#39;`,
  /// `&#x27;`) — عناوين إسلام ويب كثيراً ما ترد بكيانات رقمية لعربية.
  String _decodeEntities(String s) {
    var out = s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
    final hexRe = RegExp(r'&#x([0-9a-fA-F]+);');
    out = out.replaceAllMapped(
      hexRe,
      (m) => _codePointToString(int.parse(m.group(1)!, radix: 16)),
    );
    final numRe = RegExp(r'&#(\d+);');
    out = out.replaceAllMapped(
      numRe,
      (m) => _codePointToString(int.parse(m.group(1)!)),
    );
    return out;
  }

  static String _codePointToString(int codePoint) =>
      codePoint > 0 && codePoint <= 0x10FFFF ? String.fromCharCode(codePoint) : '';
}