/// نموذج اسم من أسماء الله الحسنى مع المعنى والتدبر والشواهد
class NameOfAllah {
  const NameOfAllah({
    required this.id,
    required this.name,
    required this.meaning,
    required this.tadabbur,
    required this.category,
    required this.quranReferences,
    required this.dua,
    this.hadithProof,
  });

  /// الرقم المتسلسل (1 - 99)
  final int id;

  /// الاسم الشريف مضبوطاً بالشكل
  final String name;

  /// المعنى اللغوي والشرعي للاسم
  final String meaning;

  /// كيف تعيش بهذا الاسم وتتدبره في حياتك اليومية
  final String tadabbur;

  /// التصنيف الموضوعي (الرحمة، العظمة والجلال، القدرة والتدبير، الرزق والكرم...)
  final String category;

  /// شواهد من القرآن الكريم مع السورة والآية
  final List<String> quranReferences;

  /// دعاء مأثور للتعبد بالاسم والدعاء به
  final String dua;

  /// شاهد من السنة النبوية الشريفة إن وُجد
  final String? hadithProof;
}
