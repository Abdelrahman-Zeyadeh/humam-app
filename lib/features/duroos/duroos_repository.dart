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
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
                'Accept':
                    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'ar,en-US;q=0.9,en;q=0.8',
              },
            ));

  final Dio _dio;
  static final Map<String, DuroosPage> _cache = {};

  /// وسوم `<a ...>` كاملة — نطابق الوسم ثم نستخرج سماته بأي ترتيب،
  /// لا تعبيراً مفترضاً تسلسلاً ثابتاً هشّاً.
  static final _aTagRe = RegExp(r'<a\b[^>]*>', caseSensitive: false, dotAll: true);
  static final _urlAttrRe = RegExp("\\burl\\s*=\\s*'([^']*)'");
  static final _titleAttrRe = RegExp(r'\btitle_data\s*=\s*"([^"]*)"');
  static final _lgAttrRe = RegExp(r'\blg\s*=\s*(\d+)');
  static final _labelRe = RegExp(r'<label[^>]*>(.*?)</label>', caseSensitive: false, dotAll: true);

  Future<DuroosPage> fetchIslamweb(int sid, int lg) async {
    final cacheKey = 'iw-$sid-$lg';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

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

    // جلب الصفحات التالية للمحاضرات لو كان القسم يحتوي على أكثر من ٣٠ محاضرة
    // نطلب الصفحتين بالتوازي لتوفير الوقت وسرعة الاستجابة الخاطفة مع مهلة سريعة
    if (categories.isEmpty && lectures.length >= 30) {
      try {
        final pagesResponses = await Future.wait([
          _dio.get<String>(
            'https://audio.islamweb.net/audio/index.php?page=lecview&sid=$sid&read=0&lg=$lg&kh=0&pageno=2',
            options: Options(responseType: ResponseType.plain),
          ),
          _dio.get<String>(
            'https://audio.islamweb.net/audio/index.php?page=lecview&sid=$sid&read=0&lg=$lg&kh=0&pageno=3',
            options: Options(responseType: ResponseType.plain),
          ),
        ]).timeout(const Duration(seconds: 4), onTimeout: () => []);
        for (final pResp in pagesResponses) {
          final pHtml = pResp.data ?? '';
          for (final tag in _aTagRe.allMatches(pHtml)) {
            final tagHtml = tag.group(0)!;
            final urlMatch = _urlAttrRe.firstMatch(tagHtml);
            if (urlMatch == null) continue;
            final title = _decodeEntities(_titleAttrRe.firstMatch(tagHtml)?.group(1)?.trim() ?? '');
            if (title.isEmpty) continue;
            lectures.add(DuroosLecture(title: title, audioUrl: urlMatch.group(1)!));
          }
        }
      } catch (_) {}
    }

    if (categories.isEmpty && lectures.isEmpty) {
      throw const DuroosParseException(
        'تعذّر التعرف على محتوى هذه الصفحة (ربما تغيّرت بنية المصدر أو القسم فارغ) — أعد المحاولة.',
      );
    }

    final result = DuroosPage(categories: categories, lectures: lectures);
    _cache[cacheKey] = result;
    return result;
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

  /// جلب سلاسل ومحاضرات الشيخ مباشرة من صفحته على موقع مداد عبر worksIndex
  Future<DuroosPage> fetchMidadScholar(
    int scholarId, {
    bool isRecitation = false,
  }) async {
    final cacheKey = 'midad-scholar-$scholarId-$isRecitation';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final path = isRecitation ? 'recitations' : 'lessons';
    final response = await _dio.get<String>(
      'https://midad.com/scholar/$scholarId/$path',
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data ?? '';
    final json = _extractInertiaJson(html);
    final data = json?['props']?['data'] as Map<String, dynamic>?;
    final worksIndex = data?['worksIndex'] as List? ?? const [];

    final categories = <DuroosCategory>[];
    final lectures = <DuroosLecture>[];
    final seenCat = <int>{};
    final seenLec = <int>{};

    for (final section in worksIndex) {
      if (section is! Map) continue;
      final key = section['key'] as String? ?? '';
      final entries = section['entries'] as List? ?? const [];

      // 1. سلاسل ومجموعات الدروس أو التلاوات
      if (key == 'lesson_collection' ||
          key == 'recitation_collection' ||
          key.contains('collection')) {
        for (final item in entries) {
          if (item is! Map) continue;
          final id = item['id'] is int ? item['id'] as int : null;
          final title = _decodeEntities(
              (item['title'] as String? ?? '').replaceAll(_emTagRe, '').trim());
          if (id != null && title.isNotEmpty && seenCat.add(id)) {
            final count = item['items_count'] ??
                item['entries_count'] ??
                item['count'] ??
                item['total'];
            categories.add(DuroosCategory(
              lg: id,
              title: title,
              count: count is int ? count : null,
            ));
          }
        }
      } else if (key == 'lesson' || key == 'recitation' || key == 'video') {
        // 2. محاضرات ومقاطع فردية
        final segment =
            key == 'video' ? 'video' : (isRecitation ? 'recitation' : 'lesson');
        for (final item in entries) {
          if (item is! Map) continue;
          final id = item['id'] is int ? item['id'] as int : null;
          final title = _decodeEntities(
              (item['title'] as String? ?? '').replaceAll(_emTagRe, '').trim());
          if (id != null && title.isNotEmpty && seenLec.add(id)) {
            lectures.add(DuroosLecture(
              title: title,
              midadLessonId: id,
              midadEntryType: segment,
              midadIsRecitation: isRecitation,
            ));
          }
        }
      }
    }

    if (categories.isEmpty && lectures.isEmpty) {
      throw DuroosParseException(
        isRecitation
            ? 'تعذّر العثور على تلاوات لهذا الشيخ حالياً — أعد المحاولة.'
            : 'تعذّر العثور على محاضرات لهذا الشيخ حالياً — أعد المحاولة.',
      );
    }

    final result = DuroosPage(categories: categories, lectures: lectures);
    _cache[cacheKey] = result;
    return result;
  }

  /// جلب نتائج البحث لشخصية معينة على midad.com بسرعة خاطفة ودعم السلاسل والمحاضرات والفيديوهات
  Future<DuroosPage> fetchMidadSearch(
    String query, {
    bool isRecitation = false,
  }) async {
    final cacheKey = 'midad-$query-$isRecitation';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final entryType = isRecitation ? 'recitation' : 'lesson-article-audiobook-video';
    final categories = <DuroosCategory>[];
    final lectures = <DuroosLecture>[];
    final seen = <int>{};
    final seenColl = <int>{};

    // جلب الصفحات بالتوازي للحصول على استجابة فورية دون أي تأخير
    Future<List<dynamic>> fetchPageHits(int page) async {
      try {
        final url = 'https://midad.com/search'
            '?q=${Uri.encodeQueryComponent(query)}'
            '&entry_type=$entryType'
            '&type=collection-entry'
            '&page=$page';
        final response = await _dio.get<String>(
          url,
          options: Options(responseType: ResponseType.plain),
        );
        final html = response.data ?? '';
        final json = _extractInertiaJson(html);
        return (json?['props']?['data']?['data']?['data']?['hits'] as List?) ?? const [];
      } catch (_) {
        return const [];
      }
    }

    final pagesHits = await Future.wait([fetchPageHits(1), fetchPageHits(2)]);
    final allHits = [...pagesHits[0], ...pagesHits[1]];

    final entryIdRe = RegExp(r'/(?:lesson|video|audiobook|recitation|entry)/(\d+)');
    final collIdRe = RegExp(r'/collection/(\d+)');

    for (final hit in allHits) {
      if (hit is! Map) continue;
      final rawTitle = (hit['title'] as String? ?? '').replaceAll(_emTagRe, '');
      final title = _decodeEntities(rawTitle.trim());
      if (title.isEmpty) continue;

      final hitType = hit['type'] as String? ?? '';
      final url = hit['url'] as String? ?? '';

      // 1. إذا كان العنصر سلسلة أو مجموعة (collection)
      if (hitType == 'collection') {
        final idMatch = collIdRe.firstMatch(url);
        final id = idMatch != null
            ? int.tryParse(idMatch.group(1)!)
            : (hit['id'] is int ? hit['id'] as int : null);
        if (id != null && seenColl.add(id)) {
          final count = hit['items_count'] ?? hit['entries_count'] ?? hit['count'];
          categories.add(DuroosCategory(
            lg: id,
            title: title,
            count: count is int ? count : null,
          ));
        }
        continue;
      }

      // 2. إذا كان العنصر محاضرة أو مقطع صوتي/مرئي
      final idMatch = entryIdRe.firstMatch(url);
      if (idMatch == null) continue;
      final id = int.parse(idMatch.group(1)!);
      if (!seen.add(id)) continue;

      final segment = url.contains('/video/') ? 'video' : (isRecitation ? 'recitation' : 'lesson');
      lectures.add(
        DuroosLecture(
          title: title,
          midadLessonId: id,
          midadEntryType: segment,
          midadIsRecitation: isRecitation,
        ),
      );
    }

    if (categories.isEmpty && lectures.isEmpty) {
      throw DuroosParseException(
        isRecitation
            ? 'تعذّر العثور على تلاوات لهذا الشيخ — أعد المحاولة.'
            : 'تعذّر العثور على محاضرات لهذا الشيخ — أعد المحاولة.',
      );
    }
    final result = DuroosPage(categories: categories, lectures: lectures);
    _cache[cacheKey] = result;
    return result;
  }

  /// جلب محتويات سلسلة/مجموعة دروس كاملة من موقع مداد
  Future<DuroosPage> fetchMidadCollection(int collectionId) async {
    final cacheKey = 'coll-$collectionId';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final response = await _dio.get<String>(
      'https://midad.com/collection/$collectionId',
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data ?? '';
    final json = _extractInertiaJson(html);
    final data = json?['props']?['data'] as Map<String, dynamic>?;

    final dynamic entriesRaw = data?['entries']?['data'] ??
        data?['collection']?['entries'] ??
        data?['entries'];

    final entries = entriesRaw is List ? entriesRaw : const [];
    final lectures = <DuroosLecture>[];
    final seen = <int>{};
    final entryIdRe = RegExp(r'/(?:lesson|video|audiobook|recitation|entry)/(\d+)');

    for (final e in entries) {
      if (e is! Map) continue;
      final id = e['id'] is int ? e['id'] as int : null;
      final rawTitle = (e['title'] as String? ?? '').replaceAll(_emTagRe, '');
      final title = _decodeEntities(rawTitle.trim());
      final url = e['url'] as String? ?? '';
      final matchedId = id ?? (entryIdRe.firstMatch(url) != null ? int.parse(entryIdRe.firstMatch(url)!.group(1)!) : null);
      if (matchedId == null || !seen.add(matchedId) || title.isEmpty) continue;

      final typeStr = (e['type'] as String? ?? url);
      final segment = typeStr.contains('video') ? 'video' : 'lesson';
      lectures.add(DuroosLecture(
        title: title,
        midadLessonId: matchedId,
        midadEntryType: segment,
      ));
    }

    final result = DuroosPage(categories: const [], lectures: lectures);
    _cache[cacheKey] = result;
    return result;
  }

  /// رابط الصوت الفعلي لمحاضرة/تلاوة midad محدَّدة
  Future<String> fetchMidadEntryAudio(
    int entryId, {
    String entryType = 'lesson',
    bool isRecitation = false,
  }) async {
    final pathSegment = isRecitation ? 'recitation' : entryType;
    final response = await _dio.get<String>(
      'https://midad.com/$pathSegment/$entryId',
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data ?? '';
    final json = _extractInertiaJson(html);
    final data = json?['props']?['data'] as Map<String, dynamic>?;

    List? resources = (data?[pathSegment]?['resources'] as List?);
    if (resources == null || resources.isEmpty) {
      if (data != null) {
        for (final k in data.keys) {
          if (data[k] is Map && (data[k] as Map).containsKey('resources')) {
            resources = data[k]['resources'] as List?;
            if (resources != null && resources.isNotEmpty) break;
          }
        }
      }
    }
    resources ??= const [];

    String? mp3Url;
    String? anyAudioUrl;
    for (final r in resources) {
      if (r is! Map) continue;
      final path = r['path'] as String?;
      if (path == null || path.isEmpty) continue;
      final type = r['type'] as String? ?? '';
      if (type == 'audio' || type == 'video') {
        anyAudioUrl ??= path;
        final cleanPath = Uri.tryParse(path)?.path.toLowerCase() ?? '';
        if (cleanPath.endsWith('.mp3')) {
          mp3Url = path;
          break;
        }
      }
    }
    final resolved = mp3Url ?? anyAudioUrl;
    if (resolved == null) {
      throw const DuroosParseException(
        'تعذّر العثور على رابط صوتي لهذه المحاضرة — أعد المحاولة.',
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