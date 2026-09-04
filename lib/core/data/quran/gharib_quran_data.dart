/// معجم غريب القرآن الكريم ومعاني المفردات الشريفة
/// بيانات موثقة ومضبوطة لبيان معاني الكلمات الدقيقة في القرآن الكريم
library;

class GharibWord {
  const GharibWord({
    required this.word,
    required this.meaning,
    this.root,
    this.benefit,
  });

  /// الكلمة القرآنية كما وردت في الآية
  final String word;

  /// البيان والمعنى اللغوي
  final String meaning;

  /// الجذر اللغوي إن وُجد
  final String? root;

  /// لطيفة لغوية أو فائدة تدبرية
  final String? benefit;
}

class GharibQuranData {
  const GharibQuranData._();

  /// قاموس معاني الكلمات والغريب مفهرساً برقم الآية العام (1..6236)
  static final Map<int, List<GharibWord>> _curatedWords = {
    // الفاتحة
    1: [
      GharibWord(word: 'بِسْمِ اللَّهِ', meaning: 'أبدأ قراءتي مستعيناً باسم الله ومستحضراً بركته', root: 'سما'),
      GharibWord(word: 'الرَّحْمَنِ', meaning: 'ذو الرحمة الواسعة الشاملة لجميع الخلائق في الدنيا', root: 'رحم'),
      GharibWord(word: 'الرَّحِيمِ', meaning: 'ذو الرحمة الخاصة بالمؤمنين في الآخرة', root: 'رحم'),
    ],
    2: [
      GharibWord(word: 'الْحَمْدُ لِلَّهِ', meaning: 'الثناء الكامل المطلق على الله بصفات كماله ونعمه', root: 'حمد'),
      GharibWord(word: 'رَبِّ', meaning: 'المالك المصلح المدبر لشؤون خلقه والمربي لهم بنعمه', root: 'ربب'),
      GharibWord(word: 'الْعَالَمِينَ', meaning: 'جميع المخلوقات والأكوان وسائر من سوى الله', root: 'علم'),
    ],
    4: [
      GharibWord(word: 'يَوْمِ الدِّينِ', meaning: 'يوم القيامة والجزاء والحساب على الأعمال', root: 'دين'),
    ],
    5: [
      GharibWord(word: 'إِيَّاكَ نَعْبُدُ', meaning: 'نخصك وحدك بالعبادة والخضوع والتذلل', root: 'عبد'),
      GharibWord(word: 'نَسْتَعِينُ', meaning: 'نطلب العون منك وحدك في كل أمور ديننا ودنيانا', root: 'عون'),
    ],
    6: [
      GharibWord(word: 'اهْدِنَا', meaning: 'وفقنا وثبتنا وبصرنا وزدنا هداية', root: 'هدي'),
      GharibWord(word: 'الصِّرَاطَ الْمُسْتَقِيمَ', meaning: 'الطريق الواضح الذي لا اعوجاج فيه، وهو دين الإسلام', root: 'صرط'),
    ],
    7: [
      GharibWord(word: 'أَنْعَمْتَ عَلَيْهِمْ', meaning: 'النبيين والصديقين والشهداء والصالحين', root: 'نعم'),
      GharibWord(word: 'الْمَغْضُوبِ عَلَيْهِمْ', meaning: 'الذين عرفوا الحق ولم يعملوا به كاليهود', root: 'غضب'),
      GharibWord(word: 'الضَّالِّينَ', meaning: 'الذين تركوا الحق عن جهل وضلال كالنصارى', root: 'ضلل'),
    ],

    // البقرة
    8: [
      GharibWord(word: 'الم', meaning: 'حروف مقطعة للتحدي والإعجاز، استأثر الله بعلم مرادها', root: 'حرف'),
    ],
    9: [
      GharibWord(word: 'لا رَيْبَ فِيهِ', meaning: 'لا شك ولا ارتياب في كونه حقاً من عند الله', root: 'ريب'),
      GharibWord(word: 'هُدًى', meaning: 'دلالة ورشاد وتوفيق', root: 'هدي'),
      GharibWord(word: 'لِّلْمُتَّقِينَ', meaning: 'الذين جعلوا بينهم وبين عذاب الله وقاية بامتثال أوامره واجتناب نواهيه', root: 'وقي'),
    ],
    10: [
      GharibWord(word: 'بِالْغَيْبِ', meaning: 'كل ما غاب عن حواسنا مما أخبر الله به ورسوله كالجنة والنار والملائكة', root: 'غيب'),
      GharibWord(word: 'يُقِيمُونَ الصَّلاةَ', meaning: 'يؤدونها بأركانها وشروطها وخشوعها في أوقاتها', root: 'قوم'),
    ],
    14: [
      GharibWord(word: 'خَتَمَ اللَّهُ', meaning: 'طبع الله وأغلق على قلوبهم فلا يدخلها إيمان ولا يخرج منها كفر', root: 'ختم'),
      GharibWord(word: 'غِشَاوَةٌ', meaning: 'غطاء وستر يمنعهم من رؤية الحق والانتفاع به', root: 'غشو'),
    ],
    16: [
      GharibWord(word: 'يُخَادِعُونَ', meaning: 'يظهرون الإيمان ويبطنون الكفر ظناً أنهم يروج عليهم', root: 'خدع'),
    ],
    17: [
      GharibWord(word: 'مَّرَضٌ', meaning: 'شك ونفاق وضعف يقين في قلوبهم', root: 'مرض'),
    ],
    24: [
      GharibWord(word: 'اسْتَوْقَدَ نَارًا', meaning: 'أوقد ناراً واستضاء بضوئها', root: 'وقد'),
      GharibWord(word: 'حَوْلَهُ', meaning: 'ما حوله من المكان', root: 'حول'),
    ],
    25: [
      GharibWord(word: 'صُمٌّ', meaning: 'عن سماع الحق سماع قبول وانتفاع', root: 'صمم'),
      GharibWord(word: 'بُكْمٌ', meaning: 'خرس عن النطق بالحق والإقرار به', root: 'بكم'),
      GharibWord(word: 'عُمْيٌ', meaning: 'عن رؤية آيات الله ودلائل توحيده', root: 'عمي'),
    ],
    26: [
      GharibWord(word: 'صَيِّبٍ', meaning: 'مطر شديد ينصب من السماء', root: 'صوب'),
      GharibWord(word: 'رَعْدٌ', meaning: 'صوت الملك الموكل بالسحاب أو صوت السحاب', root: 'رعد'),
      GharibWord(word: 'بَرْقٌ', meaning: 'الضوء اللامع الذي يخرج من بين السحاب', root: 'برق'),
      GharibWord(word: 'الصَّوَاعِقِ', meaning: 'النيران المهلكة التي تنزل من السماء مع شدة الرعد', root: 'صعق'),
    ],
    27: [
      GharibWord(word: 'يَخْطَفُ', meaning: 'يسلب ويأخذ بسرعة خاطفة', root: 'خطف'),
      GharibWord(word: 'قَامُوا', meaning: 'وقفوا وثبتوا في مكانهم حائرين مظلمين', root: 'قوم'),
    ],
    29: [
      GharibWord(word: 'فِرَاشًا', meaning: 'بساطاً ممهداً صالحاً للاستقرار والانتفاع', root: 'فرش'),
      GharibWord(word: 'بِنَاءً', meaning: 'سقفاً مرفوعاً ومحكماً كالقبة', root: 'بني'),
      GharibWord(word: 'أَندَادًا', meaning: 'أشباهاً وأمثالاً وشركاء تعبدونهم مع الله', root: 'ندد'),
    ],
    33: [
      GharibWord(word: 'بَعُوضَةً', meaning: 'الحشرة الصغيرة الضعيفة، ضرب الله بها المثل إعجازاً وتذكيراً', root: 'بعض'),
      GharibWord(word: 'فَمَا فَوْقَهَا', meaning: 'أي فما هو أكبر منها كالذباب أو أصغر منها في الصغر واللطافة', root: 'فوق'),
    ],

    // آية الكرسي
    262: [ // آية 255 من سورة البقرة (رقمها الإجمالي 262)
      GharibWord(word: 'الْحَيُّ', meaning: 'كامل الحياة الدائمة بلا بداية ولا نهاية، الذي لا يموت', root: 'حيي'),
      GharibWord(word: 'الْقَيُّومُ', meaning: 'القائم بنفسه، المقيم لكل ما سواه والمدبر لجميع شؤون خلقه', root: 'قوم'),
      GharibWord(word: 'سِنَةٌ', meaning: 'نعاس وابتداء النوم وفترة الحواس', root: 'وسن', benefit: 'تنزه الرب جل وعلا عن أدنى غفلة أو فتور'),
      GharibWord(word: 'كُرْسِيُّهُ', meaning: 'موضع قدمي الرب جل جلاله، وهو أعظم من السماوات والأرض', root: 'كرس'),
      GharibWord(word: 'يَئُودُهُ', meaning: 'يثقله أو يشق عليه أو يتعبه حفظهما', root: 'أود'),
    ],

    // سورة الكهف
    2141: [ // الكهف 1
      GharibWord(word: 'عِوَجًا', meaning: 'ميلاً أو انحرافاً أو تناقضاً أو لبساً', root: 'عوج'),
    ],
    2142: [ // الكهف 2
      GharibWord(word: 'قَيِّمًا', meaning: 'مستقيماً معتدلاً قيماً على سائر الكتب السابقة', root: 'قوم'),
      GharibWord(word: 'بَأْسًا شَدِيدًا', meaning: 'عذاباً وعقاباً أليماً من عنده', root: 'بأس'),
    ],
    2148: [ // الكهف 8
      GharibWord(word: 'صَعِيدًا جُرُزًا', meaning: 'أرضاً ملساء يابسة لا نبت فيها ولا شجر', root: 'صعد'),
    ],
    2149: [ // الكهف 9
      GharibWord(word: 'الرَّقِيمِ', meaning: 'اللوح المكتوب فيه أسماء أهل الكهف وقصتهم ونسبهم', root: 'رقم'),
    ],
    2158: [ // الكهف 18
      GharibWord(word: 'أَيْقَاظًا', meaning: 'تظنهم منتبهين مفتوحي الأعين', root: 'يقظ'),
      GharibWord(word: 'رُقُودٌ', meaning: 'نيام لا يتحركون', root: 'رقد'),
      GharibWord(word: 'بِالْوَصِيدِ', meaning: 'بفناء الكهف أو بابه وعتبته', root: 'وصد'),
    ],

    // سورة الإخلاص
    6221: [
      GharibWord(word: 'قُلْ هُوَ اللَّهُ أَحَدٌ', meaning: 'الواحد الأحد الفرد الذي لا نظير له ولا مثيل ولا شريك', root: 'أحد'),
    ],
    6222: [
      GharibWord(word: 'اللَّهُ الصَّمَدُ', meaning: 'السيد الذي تصمد وتقصد إليه الخلائق في حوائجها، المستغني عن كل شيء', root: 'صمد'),
    ],
    6223: [
      GharibWord(word: 'لَمْ يَلِدْ', meaning: 'ليس له ولد ولا ذرية ولا صاحبة، لكمال غناه وأحديته', root: 'ولد'),
      GharibWord(word: 'وَلَمْ يُولَدْ', meaning: 'ليس له والد ولا أصل ولا ابتداء، لكمال أوليته وأزليته', root: 'ولد'),
    ],
    6224: [
      GharibWord(word: 'كُفُوًا أَحَدٌ', meaning: 'مكافئاً ومماثلاً وشبيهاً له أحد في ذاته أو أسمائه أو صفاته أو أفعاله', root: 'كفأ'),
    ],

    // سورة الفلق
    6225: [
      GharibWord(word: 'الْفَلَقِ', meaning: 'الصبح إذا انشق، أو الخلق كله إذا انفلق عن العدم', root: 'فلق'),
    ],
    6227: [
      GharibWord(word: 'غَاسِقٍ إِذَا وَقَبَ', meaning: 'الليل المظلم إذا دخل واشتدت ظلمته وانتشر شره', root: 'غسق'),
    ],
    6228: [
      GharibWord(word: 'النَّفَّاثَاتِ فِي الْعُقَدِ', meaning: 'الساحرات اللاتي يعقدن الخيوط وينفخن فيها بالرقى الشيطانية', root: 'نفث'),
    ],
    6229: [
      GharibWord(word: 'حَاسِدٍ إِذَا حَسَدَ', meaning: 'الذي يتمنى زوال النعمة عن غيره ويظهر حسده بالعمل أو العين', root: 'حسد'),
    ],

    // سورة الناس
    6233: [
      GharibWord(word: 'الْوَسْوَاسِ', meaning: 'الشيطان الذي يلقي الخواطر الرديئة في النفس', root: 'وسوس'),
      GharibWord(word: 'الْخَنَّاسِ', meaning: 'الذي يتراجع ويختفي وينخنس إذا ذُكر الله تعالى', root: 'خنس'),
    ],
  };

  /// هل تتوفر كلمات معجمية مسجلة لهذه الآية؟
  static bool hasGharib(int ayahId) => _curatedWords.containsKey(ayahId);

  /// جلب الكلمات المعجمية لآية محددة
  static List<GharibWord> getWordsForAyah(int ayahId) {
    if (_curatedWords.containsKey(ayahId)) {
      return _curatedWords[ayahId]!;
    }
    return const [];
  }

  /// استخراج كلمات مفتاحية ذكية من الآية في حال عدم وجود مدخل مخصص
  static List<GharibWord> generateQuickVocabulary({
    required String ayahText,
    String? tafsirSummary,
  }) {
    final words = ayahText.split(RegExp(r'\s+')).where((w) => w.length >= 3).toList();
    if (words.isEmpty) return const [];

    final result = <GharibWord>[];
    for (final w in words.take(4)) {
      final clean = w.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
      result.add(GharibWord(
        word: w,
        meaning: 'انظر سياق اللفظ في التفسير المعتمد للآية',
        root: clean.length >= 3 ? clean.substring(0, 3) : clean,
      ));
    }
    return result;
  }
}
