// بيانات ثابتة تخص المسبحة الإلكترونية (`tasbih_screen.dart`): مكتبة
// السبحات الجاهزة، قائمة الأذكار السريعة الافتراضية، وصياغة نص "آخر مرة"
// — أُخرجت من الشاشة أثناء تفكيكها بلا أي تغيير سلوكي.

/// أذكار سريعة جاهزة بلا هدف محدَّد ولا تسجيل إتمام — بخلاف
/// [kTasbihLibrary] (راجع توثيقها).
const List<String> kDefaultTasbihPhrases = [
  'سُبْحَانَ اللَّهِ',
  'الْحَمْدُ لِلَّهِ',
  'لَا إِلَهَ إِلَّا اللَّهُ',
  'اللَّهُ أَكْبَرُ',
  'أَسْتَغْفِرُ اللَّهَ',
  'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
  'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
  'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
];

/// مكتبة سبحات/أذكار جاهزة بعدد مستهدف ثابت (راجع `TasbihLog` بـ
/// `user_tables.dart`) — اختيار إحداها يضبط النص/الهدف تلقائياً ويُسجَّل
/// إتمامها بسجل مستقل لعرض "آخر مرة" لاحقاً، بخلاف العدّ الحر/المخصَّص
/// (لا `azkarKey` ثابتاً له فلا يُسجَّل).
class TasbihLibraryItem {
  const TasbihLibraryItem({
    required this.key,
    required this.label,
    required this.phrase,
    required this.target,
  });
  final String key;
  final String label;
  final String phrase;
  final int target;
}

const List<TasbihLibraryItem> kTasbihLibrary = [
  TasbihLibraryItem(
    key: 'morning_tasbih',
    label: 'تسبيحة الصباح',
    phrase: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    target: 100,
  ),
  TasbihLibraryItem(
    key: 'after_prayer_subhan',
    label: 'بعد الصلاة (٣٣ تسبيحة)',
    phrase: 'سُبْحَانَ اللَّهِ',
    target: 33,
  ),
  TasbihLibraryItem(
    key: 'after_prayer_hamd',
    label: 'بعد الصلاة (٣٣ تحميدة)',
    phrase: 'الْحَمْدُ لِلَّهِ',
    target: 33,
  ),
  TasbihLibraryItem(
    key: 'after_prayer_takbir',
    label: 'بعد الصلاة (٣٤ تكبيرة)',
    phrase: 'اللَّهُ أَكْبَرُ',
    target: 34,
  ),
  TasbihLibraryItem(
    key: 'istighfar_100',
    label: 'الاستغفار (١٠٠)',
    phrase: 'أَسْتَغْفِرُ اللَّهَ',
    target: 100,
  ),
  TasbihLibraryItem(
    key: 'salawat_100',
    label: 'الصلاة على النبي ﷺ (١٠٠)',
    phrase: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    target: 100,
  ),
  TasbihLibraryItem(
    key: 'tahlil_100',
    label: 'التهليل (١٠٠)',
    phrase: 'لَا إِلَهَ إِلَّا اللَّهُ',
    target: 100,
  ),
];

/// نص "آخر مرة" (اليوم/البارحة/تاريخ) لعرضه ببطاقة سبحة بالمكتبة —
/// `null` يعني لم تكتمل هذه السبحة قط بعد.
String lastCompletedLabel(DateTime? completedAt) {
  if (completedAt == null) return 'لم تكتمل بعد';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(completedAt.year, completedAt.month, completedAt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'آخر مرة: اليوم';
  if (diff == 1) return 'آخر مرة: البارحة';
  if (diff > 1 && diff < 30) return 'آخر مرة: قبل $diff يوم';
  return 'آخر مرة: ${completedAt.year}/${completedAt.month}/${completedAt.day}';
}
