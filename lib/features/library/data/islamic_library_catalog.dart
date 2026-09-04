import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum LibraryCategory {
  dorarHadith,
  hadithBooks,
  tafsirQuran,
  fiqhRules,
  seerahHistory,
  tazkiyah,
}

class LibraryBookItem {
  const LibraryBookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.chaptersCount,
    required this.hadithsOrVersesCount,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String author;
  final LibraryCategory category;
  final String description;
  final IconData icon;
  final Color accentColor;
  final int chaptersCount;
  final String hadithsOrVersesCount;
  final bool isFeatured;
}

class FiqhTopicItem {
  const FiqhTopicItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.subtopics,
  });

  final String id;
  final String title;
  final String summary;
  final IconData icon;
  final List<String> subtopics;
}

final List<LibraryBookItem> kIslamicLibraryBooks = [
  // 1. موسوعة الدرر السنية
  const LibraryBookItem(
    id: 'dorar_engine',
    title: 'محرك تخريج وتحقيق الأحاديث (الدرر السنية)',
    author: 'موسوعة الدرر السنية المعتمدة',
    category: LibraryCategory.dorarHadith,
    description:
        'ابحث عن صحة أي حديث نبوي فوراً مع استعراض أحكام كبار المحدثين، الراوي، المحدث، المصدر، والتخريج الكامل والشرح.',
    icon: Icons.verified_user_rounded,
    accentColor: Color(0xFF1B8A72),
    chaptersCount: 1,
    hadithsOrVersesCount: 'موسوعة شاملة',
    isFeatured: true,
  ),

  // 2. كتب الحديث
  const LibraryBookItem(
    id: 'bukhari',
    title: 'صحيح البخاري',
    author: 'الإمام محمد بن إسماعيل البخاري',
    category: LibraryCategory.hadithBooks,
    description: 'أصح كتاب بعد كتاب الله عز وجل، جامع لأحاديث الأحكام والفضائل والآداب.',
    icon: Icons.menu_book_rounded,
    accentColor: Color(0xFF1F4E79),
    chaptersCount: 97,
    hadithsOrVersesCount: '٧,٥٦٣ حديثاً',
    isFeatured: true,
  ),
  const LibraryBookItem(
    id: 'muslim',
    title: 'صحيح مسلم',
    author: 'الإمام مسلم بن الحجاج النيسابوري',
    category: LibraryCategory.hadithBooks,
    description: 'المصنف الثاني في الصحة بجمال الترتيب وحسن سياق الروايات والأسانيد.',
    icon: Icons.menu_book_rounded,
    accentColor: Color(0xFF2E75B6),
    chaptersCount: 56,
    hadithsOrVersesCount: '٣,٠٣٣ حديثاً',
    isFeatured: true,
  ),
  const LibraryBookItem(
    id: 'riyad',
    title: 'رياض الصالحين',
    author: 'الإمام يحيى بن شرف النووي',
    category: LibraryCategory.hadithBooks,
    description: 'كتاب الأخلاق والآداب والرقائق النبوية الأشهر في العالم الإسلامي.',
    icon: Icons.spa_rounded,
    accentColor: Color(0xFF2E8071),
    chaptersCount: 372,
    hadithsOrVersesCount: '١,٨٩٦ حديثاً',
    isFeatured: true,
  ),
  const LibraryBookItem(
    id: 'forty_nawawi',
    title: 'الأربعون النووية',
    author: 'الإمام يحيى بن شرف النووي',
    category: LibraryCategory.hadithBooks,
    description: 'أصول الإسلام وقواعد الدين الكبرى في أحاديث جوامع الكلم.',
    icon: Icons.auto_awesome_rounded,
    accentColor: AppColors.goldDeep,
    chaptersCount: 42,
    hadithsOrVersesCount: '٤٢ حديثاً',
    isFeatured: true,
  ),
  const LibraryBookItem(
    id: 'tirmidhi',
    title: 'جامع الترمذي (سنن الترمذي)',
    author: 'الإمام أبو عيسى محمد بن عيسى الترمذي',
    category: LibraryCategory.hadithBooks,
    description: 'موسوعة فقه الحديث وعلل الأحاديث وبيان درجاتها الفقهية.',
    icon: Icons.library_books_rounded,
    accentColor: Color(0xFF8E44AD),
    chaptersCount: 50,
    hadithsOrVersesCount: '٣,٩٥٦ حديثاً',
  ),
  const LibraryBookItem(
    id: 'abudawud',
    title: 'سنن أبي داود',
    author: 'الإمام أبو داود السجستاني',
    category: LibraryCategory.hadithBooks,
    description: 'عمدة كتب أحاديث الأحكام والسنن المعتمدة لدى الفقهاء.',
    icon: Icons.library_books_rounded,
    accentColor: Color(0xFF5B2C6F),
    chaptersCount: 43,
    hadithsOrVersesCount: '٥,٢٧٤ حديثاً',
  ),
  const LibraryBookItem(
    id: 'bulugh',
    title: 'بلوغ المرام من أدلة الأحكام',
    author: 'الحافظ ابن حجر العسقلاني',
    category: LibraryCategory.hadithBooks,
    description: 'خلاصة أدلة الأحكام الفقهية مع بيان درجتها وتخريجها الدقيق.',
    icon: Icons.gavel_rounded,
    accentColor: Color(0xFF34495E),
    chaptersCount: 16,
    hadithsOrVersesCount: '١,٥٩٦ حديثاً',
  ),

  // 3. كتب التفسير
  const LibraryBookItem(
    id: 'saadi',
    title: 'تيسير الكريم الرحمن (تفسير السعدي)',
    author: 'الشيخ عبد الرحمن بن ناصر السعدي',
    category: LibraryCategory.tafsirQuran,
    description: 'تفسير ميسر واضح وسلس يركز على هدايات الآيات ومقاصدها العقدية والتربوية.',
    icon: Icons.menu_book_rounded,
    accentColor: Color(0xFF16A085),
    chaptersCount: 114,
    hadithsOrVersesCount: '٦,٢٣٦ آية',
    isFeatured: true,
  ),
  const LibraryBookItem(
    id: 'ibn_kathir',
    title: 'تفسير القرآن العظيم (ابن كثير)',
    author: 'الحافظ عماد الدين إسماعيل بن كثير',
    category: LibraryCategory.tafsirQuran,
    description: 'عمدة التفسير بالمأثور، يفسر القرآن بالقرآن ثم بالسنة النبوية وآثار السلف.',
    icon: Icons.menu_book_rounded,
    accentColor: Color(0xFF2C3E50),
    chaptersCount: 114,
    hadithsOrVersesCount: '٤ مجلدات',
    isFeatured: true,
  ),
  const LibraryBookItem(
    id: 'muyassar',
    title: 'التفسير الميسر',
    author: 'نخبة من علماء مجمع الملك فهد لطباعة المصحف',
    category: LibraryCategory.tafsirQuran,
    description: 'تفسير موجز ودقيق على هامش المصحف الشريف يوضح المعنى الإجمالي لكل آية.',
    icon: Icons.book_rounded,
    accentColor: Color(0xFFD35400),
    chaptersCount: 114,
    hadithsOrVersesCount: '٦,٢٣٦ آية',
  ),
  const LibraryBookItem(
    id: 'baghawi',
    title: 'معالم التنزيل (تفسير البغوي)',
    author: 'الإمام أبو محمد الحسين بن مسعود البغوي',
    category: LibraryCategory.tafsirQuran,
    description: 'تفسير جامع بين الرواية والدراية، متوسط الحجم، سالم من البدع والإسرائيليات.',
    icon: Icons.book_rounded,
    accentColor: Color(0xFF7D6608),
    chaptersCount: 114,
    hadithsOrVersesCount: 'كامل المصحف',
  ),

  // 4. كتب الفقه والأحكام
  const LibraryBookItem(
    id: 'fiqh_muyassar',
    title: 'الفقه الميسر في ضوء الكتاب والسنة',
    author: 'نخبة من كبار العلماء والفقهاء',
    category: LibraryCategory.fiqhRules,
    description: 'أحكام العبادات والمعاملات الفقهية بدليلها الصحيح وبأسلوب عصري ميسر.',
    icon: Icons.balance_rounded,
    accentColor: Color(0xFF27AE60),
    chaptersCount: 12,
    hadithsOrVersesCount: 'موسوعة فقهية',
    isFeatured: true,
  ),

  // 5. السيرة النبوية والتاريخ
  const LibraryBookItem(
    id: 'raheeq',
    title: 'الرحيق المختوم',
    author: 'الشيخ صفي الرحمن المباركفوري',
    category: LibraryCategory.seerahHistory,
    description: 'الكتاب الحائز على المركز الأول في مسابقة السيرة النبوية العالمية لرابطة العالم الإسلامي.',
    icon: Icons.explore_rounded,
    accentColor: Color(0xFFE67E22),
    chaptersCount: 30,
    hadithsOrVersesCount: 'سيرة كاملة',
    isFeatured: true,
  ),
  const LibraryBookItem(
    id: 'shamail',
    title: 'الشمائل المحمدية',
    author: 'الإمام أبو عيسى الترمذي',
    category: LibraryCategory.seerahHistory,
    description: 'أوصاف النبي ﷺ الخَلقية والخُلقية، ملبسه، طعامه، نومه، وعبادته.',
    icon: Icons.person_pin_rounded,
    accentColor: Color(0xFF9C640C),
    chaptersCount: 56,
    hadithsOrVersesCount: '٣٩٧ حديثاً',
  ),

  // 6. التزكية والآداب
  const LibraryBookItem(
    id: 'azkar_nawawi',
    title: 'كتاب الأذكار المنتخبة',
    author: 'الإمام يحيى بن شرف النووي',
    category: LibraryCategory.tazkiyah,
    description: 'جامع الأذكار والأدعية الصحيحة في جميع أحوال اليوم والليلة والمناسبات.',
    icon: Icons.favorite_rounded,
    accentColor: Color(0xFFC0392B),
    chaptersCount: 20,
    hadithsOrVersesCount: '١,٣٢٤ ذكراً',
  ),
  const LibraryBookItem(
    id: 'madarij',
    title: 'تهذيب مدارج السالكين',
    author: 'الإمام ابن قيم الجوزية',
    category: LibraryCategory.tazkiyah,
    description: 'مراتب إياك نعبد وإياك نستعين، ومنازل السائرين إلى الله عز وجل.',
    icon: Icons.psychology_alt_rounded,
    accentColor: Color(0xFF6C3483),
    chaptersCount: 25,
    hadithsOrVersesCount: 'منازل إيمانية',
  ),
];

final List<FiqhTopicItem> kFiqhTopics = [
  const FiqhTopicItem(
    id: 'tahara',
    title: 'كتاب الطهارة',
    summary: 'أحكام المياه، النجاسات، الوضوء، المسح على الخفين، الغسل، والتيمم.',
    icon: Icons.water_drop_outlined,
    subtopics: [
      'أقسام المياه وأحكامها',
      'سنن الفطرة وآداب قضاء الحاجة',
      'صفة الوضوء الكامل وفروضه ونواقضه',
      'المسح على الخفين والجبائر',
      'موجبات الغسل وصفته',
      'التيمم وشروطه ومبطلاته',
    ],
  ),
  const FiqhTopicItem(
    id: 'salah',
    title: 'كتاب الصلاة',
    summary: 'شروط الصلاة، أركانها، واجباتها، سننها، صلاة الجماعة، وسجود السهو.',
    icon: Icons.mosque_outlined,
    subtopics: [
      'مواقيت الصلاة وشروط صحتها',
      'أركان الصلاة وواجباتها وسننها',
      'سجود السهو وسجود التلاوة والشكر',
      'صلاة الجماعة وأحكام الإمامة',
      'صلاة أهل الأعذار (المريض والمسافر)',
      'صلاة الجمعة والعيدين والاستسقاء والكسوف',
    ],
  ),
  const FiqhTopicItem(
    id: 'zakah',
    title: 'كتاب الزكاة والصدقة',
    summary: 'شروط وجوب الزكاة، مصارفها الثمانية، زكاة الفطر، وصدقة التطوع.',
    icon: Icons.volunteer_activism_outlined,
    subtopics: [
      'الأموال التي تجب فيها الزكاة ونصابها',
      'زكاة الذهب والفضة والأوراق النقدية المعاصرة',
      'زكاة عروض التجارة والأسهم',
      'مصارف الزكاة الثمانية ومن لا يجوز دفعها لهم',
      'أحكام زكاة الفطر ومقدارها ووقت إخراجها',
    ],
  ),
  const FiqhTopicItem(
    id: 'sawm',
    title: 'كتاب الصيام',
    summary: 'شروط الصوم، مفسداته، الأعذار المبيحة للفطر، صيام التطوع، والاعتكاف.',
    icon: Icons.nightlight_round,
    subtopics: [
      'شروط وجوب صيام رمضان وثبوت دخوله',
      'مفطرات الصيام المعاصرة والتقليدية',
      'أهل الأعذار والفدية والقضاء',
      'سنن الصيام ومستحباته ومكروهاته',
      'أيام صيام التطوع والأيام المنهي عن صيامها',
      'أحكام الاعتكاف في العشر الأواخر من رمضان',
    ],
  ),
  const FiqhTopicItem(
    id: 'hajj',
    title: 'كتاب الحج والعمرة',
    summary: 'شروط الاستطاعة، المواقيت، الإحرام، أركان الحج والعمرة، والهدي والأضاحي.',
    icon: Icons.card_travel_rounded,
    subtopics: [
      'شروط وجوب الحج والعمرة على المستطيع',
      'المواقيت الزمانية والمكانية وأنواع النسك',
      'محظورات الإحرام وفديتها',
      'صفة العمرة خطوة بخطوة',
      'صفة الحج وأعمال أيام التشريق',
      'أحكام الأضحية والعقيقة والهدي',
    ],
  ),
];
