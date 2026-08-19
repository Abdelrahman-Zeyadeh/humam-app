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
