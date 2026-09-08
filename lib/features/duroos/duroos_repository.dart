import 'dart:convert';

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

  /// موقع midad.com تطبيق Inertia.js — كل الاستجابة HTML عادي، لكن
  /// البيانات الفعلية (نتائج البحث، تفاصيل الدرس) مضمّنة كـJSON كامل
  /// داخل `<script id="app" type="application/json">...</script>`، لا
  /// تحتاج تشغيل JS لقراءتها. راجع توثيق `DuroosSourceKind.midad`.
  static const _midadInertiaMarker = 'data-page="app" type="application/json">';

  Map<String, dynamic>? _extractInertiaJson(String html) {
    final start = html.indexOf(_midadInertiaMarker);
    if (start == -1) return null;
    final jsonStart = start + _midadInertiaMarker.length;
    final jsonEnd = html.indexOf('</script>', jsonStart);
    if (jsonEnd == -1) return null;
    try {
      return jsonDecode(html.substring(jsonStart, jsonEnd)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static final _emTagRe = RegExp(r'</?em>');

  /// بحث midad.com عن اسم الشيخ — يرجع محاضرات مفردة فقط (نتجاهل نوع
  /// "collection" لأنها تحتاج جلباً إضافياً لعناصرها الفرعية، وخارج نطاق
  /// هذه الميزة حالياً). لا `audioUrl` هنا عمداً — يُجلب لاحقاً لحظة فتح
  /// المحاضرة تحديداً عبر [fetchMidadEntryAudio] (راجع سبب ذلك بتوثيق
  /// `DuroosSourceKind.midad`).
  /// [isRecitation] يبحث عن **تلاوات قرآن** (`/recitation/<id>`، بطلب
  /// صريح "التلاوات ممكن تضيفها لقسم الاستماع") بدل محاضرات علمية عادية
  /// (`/lesson/<id>`، الافتراضي). راجع `DuroosSource.midadIsRecitation`.
  Future<DuroosPage> fetchMidadSearch(
    String query, {
    bool isRecitation = false,
  }) async {
    // `entry_type` **بلا** `recitation` للمحاضرات العادية عمداً — بطلب
    // صريح ("رابط السعيدان وعامر بهجت مش شغال، اتاكد منهم"): تحقّقت فعلياً
    // بمتصفح حقيقي على midad.com، والسبب مزدوج:
    // ١. إدراج `recitation` بالقائمة كان يُغرق نتائج الشيوخ الذين سجّلوا
    //    ختمة قرآن أيضاً (كالسعيدان) بمئات نتائج "سورة كذا" (تلاوة، لا
    //    محاضرة أصلاً)، تتصدّر ترتيب النتائج فتزيح المحاضرات الفعلية خارج
    //    أول ٢٠ نتيجة المضمَّنة بالصفحة. [isRecitation] يعكس هذا: يطلب
    //    "recitation" فقط بدل استبعادها — لسور المصحف المرتَّل نفسه.
    // ٢. `_extractInertiaJson` كان يقرأ `props.data.data.hits` (مستويان
    //    `data`) — الصحيح فعلياً `props.data.data.data.hits` (**ثلاثة**
    //    مستويات)، تحقّقت منه مباشرة بمحتوى الصفحة الحقيقي. لو تغيّر بنية
    //    الموقع لاحقاً (ربما كان صحيحاً سابقاً وتغيّر)، هذا أول موضع يُراجَع.
    final entryType = isRecitation ? 'recitation' : 'lesson-article-audiobook-video';
    final url = 'https://midad.com/search'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&entry_type=$entryType'
        '&type=collection-entry';
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data ?? '';
    final json = _extractInertiaJson(html);
    final hits =
        (json?['props']?['data']?['data']?['data']?['hits'] as List?) ??
        const [];

    final entryPathSegment = isRecitation ? 'recitation' : 'lesson';
    final idRe = RegExp('/$entryPathSegment/(\\d+)');
    final lectures = <DuroosLecture>[];
    final seen = <int>{};
    for (final hit in hits) {
      if (hit is! Map) continue;
      if (hit['type'] != 'entry') continue; // نتجاهل "collection" — راجع التوثيق أعلاه
      final entryUrl = hit['url'] as String? ?? '';
      final idMatch = idRe.firstMatch(entryUrl);
      if (idMatch == null) continue;
      final id = int.parse(idMatch.group(1)!);
      if (!seen.add(id)) continue;
      final rawTitle = (hit['title'] as String? ?? '').replaceAll(_emTagRe, '');
      final title = _decodeEntities(rawTitle.trim());
      if (title.isEmpty) continue;
      lectures.add(
        DuroosLecture(title: title, midadLessonId: id, midadIsRecitation: isRecitation),
      );
    }

    if (lectures.isEmpty) {
      throw DuroosParseException(
        isRecitation
            ? 'تعذّر العثور على تلاوات لهذا الشيخ (ربما تغيّرت بنية الموقع أو لا نتائج) — أعد المحاولة.'
            : 'تعذّر العثور على محاضرات لهذا الشيخ (ربما تغيّرت بنية الموقع أو لا نتائج) — أعد المحاولة.',
      );
    }
    return DuroosPage(categories: const [], lectures: lectures);
  }

  /// رابط الصوت الفعلي لمحاضرة/تلاوة midad محدَّدة — **موقّع ومؤقت** (AWS
  /// S3 signed URL، صلاحيته أسبوع تقريباً وقت الجلب)، لذا يُطلَب هنا لحظياً
  /// عند فتح العنصر لا وقت البحث — يضمن رابطاً صالحاً دوماً بلا تخزين
  /// أو تحديث يدوي (راجع توثيق `DuroosSourceKind.midad`). [isRecitation]
  /// يبدّل مسار الصفحة (`/recitation/` بدل `/lesson/`) **و** مفتاح JSON
  /// المقروء (`recitation` بدل `lesson`) — تحقّقت من الاختلافين معاً
  /// مباشرة بمتصفح حقيقي (بنيتا الاستجابة متشابهتان لكن غير متطابقتين).
  Future<String> fetchMidadEntryAudio(int entryId, {bool isRecitation = false}) async {
    final pathSegment = isRecitation ? 'recitation' : 'lesson';
    final jsonKey = isRecitation ? 'recitation' : 'lesson';
    final response = await _dio.get<String>(
      'https://midad.com/$pathSegment/$entryId',
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data ?? '';
    final json = _extractInertiaJson(html);
    final resources = (json?['props']?['data']?[jsonKey]?['resources'] as List?) ?? const [];

    String? mp3Url;
    String? anyAudioUrl;
    for (final r in resources) {
      if (r is! Map) continue;
      if (r['type'] != 'audio') continue;
      final path = r['path'] as String?;
      if (path == null || path.isEmpty) continue;
      anyAudioUrl ??= path;
      // قد يتوفّر نفس الدرس بصيغة `rm` قديمة إضافة لـmp3 — نفضّل mp3
      // دوماً حين متاحاً (راجع مثال حقيقي بالتعليق أعلى الملف).
      if (Uri.parse(path).path.toLowerCase().endsWith('.mp3')) {
        mp3Url = path;
        break;
      }
    }
    final resolved = mp3Url ?? anyAudioUrl;
    if (resolved == null) {
      throw const DuroosParseException(
        'تعذّر العثور على رابط صوتي لهذه المحاضرة (ربما تغيّرت بنية الموقع) — أعد المحاولة.',
      );
    }
    return resolved;
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