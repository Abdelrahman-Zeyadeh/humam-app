/// كتالوج ثابت لإصدارات التفسير والإعراب ومعاني الكلمات — **كلها تنزيل حسب الحاجة عبر GitHub Releases**
class TafsirEditionCatalogEntry {
  const TafsirEditionCatalogEntry({
    required this.key,
    required this.nameAr,
    required this.embedded,
    this.approxDownloadBytes = 0,
    this.category = 'tafsir',
    this.coverageNote,
  });

  final String key;
  final String nameAr;
  final bool embedded;
  final int approxDownloadBytes;
  final String category; // 'tafsir' | 'irab' | 'words'

  /// ملاحظة تنبّه المستخدم **قبل** التنزيل أن هذا الإصدار لا يغطي القرآن
  /// كاملاً — null يعني تغطية كاملة (٦٢٣٦ آية). بلا هذا التنويه يفاجأ
  /// المستخدم بآية "بلا تفسير" ويظنّها عطلاً بالتطبيق بدل نقص أصلي بمصدر
  /// التفسير نفسه (المؤلف توفي قبل إكماله).
  final String? coverageNote;
}

const Set<String> kEmbeddedTafsirEditions = {};

const List<TafsirEditionCatalogEntry> kTafsirEditionCatalog = [
  // المختصرات والمعاصرة — تحقّق فعلي من متوسط طول الشرح لكل آية بمحتوى
  // الملفات المبنية محلياً (لا حجم الملف، مضلِّل هون: تشفير/فهرسة مختلفة
  // بين الملفات تغيّر الحجم بلا علاقة بطول النص الفعلي) — الثلاثة هون
  // فعلاً بين ٣٠-٤٣ كلمة/آية بالمتوسط، فجوة واضحة عن "المتوسطات" التالية.
  TafsirEditionCatalogEntry(
    key: 'mukhtasar',
    nameAr: 'المختصر في التفسير',
    embedded: false,
    approxDownloadBytes: 2105344,
  ),
  TafsirEditionCatalogEntry(
    key: 'jalalayn',
    nameAr: 'الجلالين',
    embedded: false,
    approxDownloadBytes: 2105344,
  ),
  TafsirEditionCatalogEntry(
    key: 'muyassar',
    nameAr: 'الميسر',
    embedded: false,
    approxDownloadBytes: 3174400,
  ),

  // المتوسطات والإيمانية — ٤٠٣-٥٦٠ كلمة/آية بالمتوسط (تحقّق فعلي، لا تقدير)
  TafsirEditionCatalogEntry(
    key: 'saadi',
    nameAr: 'السعدي',
    embedded: false,
    approxDownloadBytes: 42885120,
  ),
  TafsirEditionCatalogEntry(
    key: 'adwaa',
    nameAr: 'أضواء البيان (الشنقيطي)',
    embedded: false,
    approxDownloadBytes: 18526208,
    coverageNote: 'توفي الشنقيطي رحمه الله قبل إكماله — يغطي نحو ٣٧٪ من '
        'القرآن فقط (حتى قرابة سورة المجادلة)، فبعض الآيات بلا تفسير هون.',
  ),
  TafsirEditionCatalogEntry(
    key: 'baghawi',
    nameAr: 'البغوي (معالم التنزيل)',
    embedded: false,
    approxDownloadBytes: 42295296,
  ),

  // أمهات التفاسير المطولة — ٨٠٠-٩٥٨ كلمة/آية بالمتوسط. **تفسير ابن
  // عثيمين هون لا بالمختصرات** — تحقّق فعلي (لا افتراض) من محتوى الملف:
  // متوسط ٣٨٩٤ كلمة شرح لكل آية مغطاة، أي أطول من الطبري وابن كثير
  // أنفسهما بأكثر من ٤ أضعاف، وأضخم ملف تفسير بالكتالوج كله (١٤٠ ميجا) —
  // كان مصنَّفاً خطأً مع الجلالين/الميسر (٣٠-٤٣ كلمة/آية فقط) قبل هذا
  // التصحيح، لأن تصنيفه الأولي اعتمد خطأً على توقّع لا فحص فعلي للنص.
  TafsirEditionCatalogEntry(
    key: 'uthaymeen',
    nameAr: 'تفسير ابن عثيمين',
    embedded: false,
    approxDownloadBytes: 147181568,
    coverageNote: 'مُفرَّغ من دروسه رحمه الله، ولم يكمل تفسير القرآن كاملاً '
        '— يغطي نحو ٥٥٪ منه فقط (٣٤٥٦ من ٦٢٣٦ آية)، فبعض الآيات بلا تفسير هون.',
  ),
  TafsirEditionCatalogEntry(
    key: 'ibnkathir',
    nameAr: 'ابن كثير (تفسير القرآن العظيم)',
    embedded: false,
    approxDownloadBytes: 93315072,
  ),
  TafsirEditionCatalogEntry(
    key: 'tabari',
    nameAr: 'الطبري (جامع البيان)',
    embedded: false,
    approxDownloadBytes: 65060864,
  ),
  TafsirEditionCatalogEntry(
    key: 'qurtubi',
    nameAr: 'القرطبي (الجامع لأحكام القرآن)',
    embedded: false,
    approxDownloadBytes: 81698816,
  ),

  // إعراب القرآن الكريم
  TafsirEditionCatalogEntry(
    key: 'irab_jadwal',
    nameAr: 'الجدول في إعراب القرآن (محمود صافي)',
    embedded: false,
    approxDownloadBytes: 30859264,
    category: 'irab',
  ),
  TafsirEditionCatalogEntry(
    key: 'irab_darwish',
    nameAr: 'إعراب القرآن وبيانه (محيي الدين درويش)',
    embedded: false,
    approxDownloadBytes: 72220672,
    category: 'irab',
  ),
  TafsirEditionCatalogEntry(
    key: 'irab_muyassar',
    nameAr: 'الإعراب الميسر للقرآن الكريم',
    embedded: false,
    approxDownloadBytes: 7692288,
    category: 'irab',
  ),

  // معاني الكلمات وغريب القرآن
  TafsirEditionCatalogEntry(
    key: 'words_meanings',
    nameAr: 'معاني الكلمات وغريب القرآن',
    embedded: false,
    approxDownloadBytes: 1187840,
    category: 'words',
  ),
];

TafsirEditionCatalogEntry tafsirEditionCatalogByKey(String key) =>
    kTafsirEditionCatalog.firstWhere(
      (e) => e.key == key,
      orElse: () => throw StateError('إصدار تفسير غير معروف: $key'),
    );
