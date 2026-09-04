/// تطبيع نص البحث العربي. **يجب** أن يُطبَّق بالضبط بنفس منطق
/// `tools/build_quran_db.py` (الدالة `normalize_search_text`) — أي اختلاف
/// بينهما يكسر البحث لأن الفهرس `fts_ayahs` مبنيّ بمنطق بايثون.
library;

// النطاقات الأربعة أدناه (بالترتيب): إشارات الوصل القرآنية، علامات التشكيل
// الأساسية، علامات إضافية، علامات الضبط القرآنية + الألف الخنجرية — مطابقة
// حرفياً لنطاقات `_DIACRITICS` في tools/build_quran_db.py.
final RegExp _diacritics = RegExp(
  '[ؐ-ًؚ-ْٖ-ٟۖ-ٰۭ]',
);

/// يحذف التشكيل وعلامات الضبط القرآنية، ويوحّد الحروف المتشابهة رسماً
/// (أإآٱ → ا، ة → ه، ى → ي) — لمطابقة نص البحث `text_search` بقاعدة البيانات.
String normalizeArabicSearch(String input) {
  var text = input.replaceAll(_diacritics, '');
  text = text.replaceAll('ـ', ''); // تطويل
  text = text.replaceAll(RegExp('[آأإٱ]'), 'ا');
  text = text.replaceAll('ة', 'ه');
  text = text.replaceAll('ى', 'ي');
  return text;
}

/// نطاق علامات الضبط القرآنية الخاصة فقط (ۖ-ۭ، أي U+06D6–U+06ED: علامات وقف/سكتة/رأس آية...)
final RegExp _quranicAnnotationMarksOnly = RegExp('[ۖ-ۭ]');

/// يحذف **علامات الضبط القرآنية الخاصة فقط** ([_quranicAnnotationMarksOnly])
/// ويحوّل التنوين والسكون القرآني التتابعي إلى تشكيل قياسي متوافق مع كافة الخطوط،
/// ويزيل أي مسافات خاطئة بين التنوين وحرف الألف/الياء التابع له، بلا لمس أي حرف
/// من حروف الكلمة القرآنية.
String stripQuranicMarksForDisplay(String input) {
  var text = input.replaceAll(_quranicAnnotationMarksOnly, '');
  // إزالة أي مدات عثمانية طافية (U+0653) قد تكسر تشبيك الهمزات في الخطوط القياسية
  text = text.replaceAll('\u0653', '');
  // إزالة أي مسافات عارضة بين تنوين الفتح حصراً (\u064B/\u08F0) وحرف الألف/الياء التابع لنفس الكلمة
  text = text.replaceAllMapped(
    RegExp(r'([\u064B\u08F0])\s+([اى][ۖ-ۭ]?)(?=\s|$|[\u2000-\u200F])'),
    (m) => '${m[1]}${m[2]}',
  );
  // تحويل التنوين التتابعي القرآني والسكون لرسم قياسي تدعمه كل الخطوط
  text = text.replaceAll('\u08F0', '\u064B'); // فتحتان
  text = text.replaceAll('\u08F1', '\u064C'); // ضمتان
  text = text.replaceAll('\u08F2', '\u064D'); // كسرتان
  text = text.replaceAll('\u06E1', '\u0652'); // رأس خاء صغيرة -> سكون قياسي
  return text.trim();
}

/// تنظيف وتنسيق النص القرآني للعرض بالنصوص القياسية (بطاقات التطبيق والودجت):
/// 1. عدم تغيير أو إضافة أي حرف إطلاقاً (منع تحويل به إلى بهي أو له إلى لهو).
/// 2. تحويل التنوين والسكون القرآني العثماني إلى تشكيل قياسي 100%.
/// 3. إزالة رموز الوقف والسكت والصلة العثمانية الطافية التي تسبب دوائر منقطة.
String formatAyahForWidgetDisplay(String input) {
  var text = input.trim();

  // تحويل التنوين القرآني التتابعي والسكون لرسم قياسي تدعمه كافة الخطوط
  text = text.replaceAll('\u08F0', '\u064B'); // فتحتان
  text = text.replaceAll('\u08F1', '\u064C'); // ضمتان
  text = text.replaceAll('\u08F2', '\u064D'); // كسرتان
  text = text.replaceAll('\u06E1', '\u0652'); // سكون

  // 6. إزالة أي علامات وقف وسكت ورموز طافية عثمانية تسبب دوائر منقطة
  text = text.replaceAll(RegExp(r'[\u06DF\u06E0\u06E2\u06D6-\u06ED\u0653\u0615-\u061A]'), '');
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  // 7. التقليم الذكي عند آخر كلمة كاملة لحساب الحروف الحقيقية (بدون التشكيل)
  final plainText = text.replaceAll(RegExp(r'[\u064B-\u0652\u0670]'), '');

  if (plainText.length > 140) {
    final words = text.split(' ');
    var currentPlainLength = 0;
    final resultWords = <String>[];

    for (final w in words) {
      final wPlain = w.replaceAll(RegExp(r'[\u064B-\u0652\u0670]'), '');
      if (currentPlainLength + wPlain.length > 140) {
        break;
      }
      resultWords.add(w);
      currentPlainLength += wPlain.length + 1;
    }

    if (resultWords.length < words.length) {
      text = '${resultWords.join(' ')}...';
    } else {
      text = resultWords.join(' ');
    }
  }

  if (!text.startsWith('﴿') && !text.startsWith('«')) {
    text = '﴿ $text ﴾';
  }

  return text;
}

/// ينظّف اسم السورة للعرض، ويزيل أي مدات أو تطويل أو علامات ضبط قد تفصل الهمزة عن النبرة في خطوط النسخ.
String sanitizeSurahNameForDisplay(String name) {
  var text = name.replaceAll('\u0653', '');
  text = text.replaceAll('ـ', '');
  text = text.replaceAll('المَـاۤئِدَةِ', 'المَائِدَةِ');
  text = text.replaceAll('المَـائِدَةِ', 'المَائِدَةِ');
  text = text.replaceAll('المـائدة', 'المائدة');
  text = text.replaceAll('الماۤئدة', 'المائدة');
  text = stripQuranicMarksForDisplay(text);
  return text;
}

/// اسم السورة المختصر بدون بادئة "سورة" لشريط الهوية العلوي (مثل "الأَنْعَام"، "المَائِدَة")
String surahShortName(String full) {
  var s = sanitizeSurahNameForDisplay(full);
  return s.replaceFirst(RegExp(r'^سُ?و?ْ?رَ?ةُ?\s*'), '').trim();
}


