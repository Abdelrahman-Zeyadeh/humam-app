/// تحويل عدد إلى أرقام عربية (هندية) — يُستخدم في عرض أرقام الآيات وأرقام
/// السور بالخط العربي التقليدي بدل الأرقام اللاتينية.
String toArabicDigits(int num) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
}

/// الاسم المعروض لكتاب التفسير المختار (أو "بدون تفسير" حين لا يوجد اختيار).
String tafsirDisplayName(String key) {
  switch (key) {
    case 'mukhtasar':
      return 'تفسير المختصر';
    case 'saadi':
      return 'تفسير السعدي';
    case 'muyassar':
      return 'التفسير الميسر';
    case 'jalalayn':
      return 'تفسير الجلالين';
    case 'asbab':
      return 'أسباب النزول';
    case 'en_sahih':
      return 'English (Sahih)';
    default:
      return 'بدون تفسير';
  }
}
