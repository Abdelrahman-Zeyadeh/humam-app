import 'package:flutter/material.dart';

/// نوع مصدر محتوى الدروس — يحدّد كيف يُجلب ويُحلَّل المحتوى بـ
/// `DuroosRepository`. راجع `duroos_repository.dart` لتفاصيل التحليل.
enum DuroosSourceKind {
  /// صفحة عالِم على `audio.islamweb.net` (`sid` + تصنيفات فرعية اختيارية
  /// عبر `lg`) — أرشيف صوتي حقيقي بروابط mp3 مباشرة، لا JS.
  islamweb,

  /// موجز RSS لبودكاست حقيقي (مثلاً Anchor.fm) — حلقات بعناوين وروابط
  /// mp3 مباشرة أيضاً، بلا تصنيفات فرعية.
  rss,

  /// نتائج بحث بموقع `midad.com` (تطبيق Inertia.js يُخرج بيانات JSON
  /// مضمّنة بوسم `<script id="app">` — لا حاجة لمتصفح كامل). بعكس
  /// islamweb وrss، رابط الصوت هنا **موقّع ومؤقت** (صلاحية أسبوع تقريباً
  /// عبر AWS S3 signed URL) فلا يُجلب مع نتائج البحث، بل عند فتح كل
  /// محاضرة بعينها (`DuroosRepository.fetchMidadLessonAudio`) — يضمن هذا
  /// رابطاً صالحاً دوماً بلا تحديث يدوي مستقبلاً. راجع `duroos_repository.dart`.
  midad,
}

/// مصدر دروس/محاضرات لعالِم أو موضوع شرعي — **محتوى فعلي داخل التطبيق**
/// (عناوين محاضرات حقيقية + تشغيل مباشر بـ`just_audio`)، لا رابط خارجي
/// واحد يفتح متصفحاً. استُبدلت به شاشة سابقة كانت تكتفي بفتح موقع
/// الشيخ خارجياً — بطلب صريح من صاحب المشروع: "المواضيع والعناوين
/// والمحاضرات موجودة بصفحة الشيخ نفسه" (يعني يجب عرضها داخل التطبيق).
class DuroosSource {
  const DuroosSource({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
    required this.category,
    this.sid,
    this.initialLg = 0,
    this.feedUrl,
    this.midadQuery,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final DuroosSourceKind kind;

  /// تصنيف القسم (`DuroosCategoryIds`) — **حقل صريح** بدل مطابقة يدوية
  /// بمعرّفات ثابتة (`source.id == 'binbaz' || ...`) كانت بـ`duroos_screen.
  /// dart` سابقاً: أي مصدر جديد يُضاف كان يبقى بلا تصنيف بصمت (يظهر فقط
  /// بتبويب "الكل") لو نُسي إدراج معرّفه بتلك القوائم اليدوية — بالفعل ٦
  /// من ١٨ مصدراً كانت هيك (waleed_saeedan, saleh_fawzan, tarifi,
  /// hasan_bukhari, mishari_kharraz, saad_atiq)، بطلب صريح "تاكد من
  /// التصانيف". الحقل هون إلزامي (`required`) عمداً — يمنع تكرار هذا
  /// الخطأ بنيوياً، لا يعتمد على تذكّر المطوّر لاحقاً.
  final String category;

  /// صورة شخصية حقيقية للشيخ/العالِم (مصدرها ويكيبيديا العربية) — `null`
  /// يعني ما في صورة موثوقة بعد لهذا المصدر تحديداً، فتُستخدَم الأيقونة
  /// الاحتياطية [icon] بدلها (راجع `duroos_screen.dart`).
  final String? imageAsset;

  /// معرّف صفحة العالِم بـislamweb (مطلوب لـ`kind == islamweb`).
  final int? sid;

  /// تصنيف البداية (`lg`) — عادة صفر (الجذر)، أو معرّف تصنيف محدَّد لو
  /// أردنا الدخول مباشرة لسلسلة بعينها (مثال: نور على الدرب).
  final int initialLg;

  /// رابط موجز RSS (مطلوب لـ`kind == rss`).
  final String? feedUrl;

  /// اسم الشيخ/عبارة البحث بموقع midad.com (مطلوب لـ`kind == midad`) —
  /// نفس النص يُمرَّر لبحث الموقع (`/search?q=...`).
  final String? midadQuery;
}

/// تصنيف فرعي (سلسلة دروس) ضمن صفحة عالِم بـislamweb — يُفتح بتصنيف
/// جديد (`lg`) يعرض إما محاضرات مباشرة أو تصنيفات أعمق.
class DuroosCategory {
  const DuroosCategory({required this.lg, required this.title, this.count});
  final int lg;
  final String title;
  final int? count;
}

/// محاضرة واحدة قابلة للتشغيل — عادة رابط mp3 حقيقي جاهز مسبقاً
/// (`audioUrl`)، إلا لمصدر `midad` حيث الرابط موقّع ومؤقت فلا يُجلب إلا
/// عند فتح المحاضرة فعلياً (`audioUrl == null` و`midadLessonId` محدَّد
/// بدله؛ راجع `DuroosSourceKind.midad`).
class DuroosLecture {
  const DuroosLecture({required this.title, this.audioUrl, this.midadLessonId})
      : assert(audioUrl != null || midadLessonId != null);
  final String title;
  final String? audioUrl;
  final int? midadLessonId;

  /// معرِّف تشغيل مستقر يميّز بين المحاضرات حتى لو كانت `audioUrl` بعدها
  /// `null` (كل محاضرات midad قبل فتحها) — لا نقارن بـ`audioUrl` مباشرة
  /// بمنطق "هل هذه المحاضرة النشطة؟" لأن عدة محاضرات midad قد تشترك
  /// بـ`null` قبل التشغيل فتبدو متطابقة خطأً.
  String get playbackKey => audioUrl ?? 'midad:$midadLessonId';
}

/// نتيجة جلب صفحة واحدة: إما قائمة تصنيفات (يُختار منها) أو قائمة
/// محاضرات (تُشغَّل مباشرة) — islamweb قد يعطي كليهما بصفحة الجذر
/// (تصنيفات) أو الورقة الفرعية (محاضرات)، وrss يعطي محاضرات فقط دائماً.
class DuroosPage {
  const DuroosPage({required this.categories, required this.lectures});
  final List<DuroosCategory> categories;
  final List<DuroosLecture> lectures;
}

/// قيم [DuroosSource.category] — نفس الثلاثة المعروضة كشرائح تصفية
/// بـ`duroos_screen.dart` أصلاً.
class DuroosCategoryIds {
  DuroosCategoryIds._();
  static const scholars = 'scholars'; // كبار العلماء والأئمة
  static const mutoon = 'mutoon'; // شروح المتون والفقه
  static const seerahGeneral = 'seerah_general'; // السيرة والفتاوى العامة
}

const List<DuroosSource> kDuroosSources = [
  DuroosSource(
    id: 'binbaz',
    title: 'الشيخ عبد العزيز بن باز رحمه الله',
    subtitle: 'محاضرات وفتاوى صوتية — أرشيف إسلام ويب',
    icon: Icons.school_outlined,
    category: DuroosCategoryIds.scholars,
    kind: DuroosSourceKind.islamweb,
    sid: 159,
    imageAsset: 'assets/images/scholars/binbaz.png',
  ),
  DuroosSource(
    id: 'nour_aladdarb',
    title: 'نور على الدرب',
    subtitle: 'سلسلة فتاوى نور على الدرب لسماحة الشيخ ابن باز',
    icon: Icons.lightbulb_outline,
    category: DuroosCategoryIds.seerahGeneral,
    kind: DuroosSourceKind.islamweb,
    sid: 159,
    initialLg: 451,
    // نفس شخص "binbaz" أعلاه (سلسلته هو) — لا صورة منفصلة مطلوبة.
    imageAsset: 'assets/images/scholars/binbaz.png',
  ),
  DuroosSource(
    id: 'albadr',
    title: 'الشيخ عبد الرزاق بن عبد المحسن البدر',
    subtitle: 'شروح ودروس صوتية — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.mutoon,
    kind: DuroosSourceKind.islamweb,
    sid: 2735,
    imageAsset: 'assets/images/scholars/albadr.jpg',
  ),
  DuroosSource(
    id: 'osaimi',
    title: 'الشيخ صالح بن عبد الله العصيمي',
    subtitle: 'دروس ومتون علمية — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.mutoon,
    kind: DuroosSourceKind.islamweb,
    sid: 1812,
    imageAsset: 'assets/images/scholars/osaimi.jpg',
  ),
  DuroosSource(
    id: 'qasim',
    title: 'الشيخ عبد المحسن بن محمد القاسم',
    subtitle: 'إمام وخطيب المسجد النبوي — دروس صوتية بأرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.mutoon,
    kind: DuroosSourceKind.islamweb,
    sid: 1326,
    imageAsset: 'assets/images/scholars/qasim.jpg',
  ),
  DuroosSource(
    id: 'shuwaier',
    title: 'الشيخ عبد السلام بن محمد الشويعر',
    subtitle: 'شرح الإقناع (فقه حنبلي) — بودكاست رسمي',
    icon: Icons.gavel_outlined,
    category: DuroosCategoryIds.mutoon,
    kind: DuroosSourceKind.rss,
    feedUrl: 'https://anchor.fm/s/f5e47d48/podcast/rss',
    imageAsset: 'assets/images/scholars/shuwaier.jpg',
  ),
  DuroosSource(
    id: 'fiqh',
    title: 'الفقه الإسلامي وأحكام العبادات',
    subtitle: 'الشيخ محمد بن صالح العثيمين — أرشيف إسلام ويب',
    icon: Icons.account_balance_outlined,
    category: DuroosCategoryIds.scholars,
    kind: DuroosSourceKind.islamweb,
    sid: 162,
    imageAsset: 'assets/images/scholars/othaymeen.png',
  ),
  DuroosSource(
    id: 'seerah',
    title: 'السيرة النبوية',
    subtitle: 'الدكتور راغب السرجاني — أرشيف إسلام ويب',
    icon: Icons.history_edu_outlined,
    category: DuroosCategoryIds.seerahGeneral,
    kind: DuroosSourceKind.islamweb,
    sid: 985,
    // لسا بلا صورة موثوقة — بانتظار صورة يزوّدها صاحب المشروع لاحقاً
    // (راجع توثيق `imageAsset` بالأعلى)، تُعرض الأيقونة الاحتياطية حالياً.
  ),
  DuroosSource(
    id: 'huwaini',
    title: 'الشيخ أبو إسحاق الحويني',
    subtitle: 'محدّث — دروس وسلاسل حديثية — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.scholars,
    kind: DuroosSourceKind.islamweb,
    sid: 452,
    imageAsset: 'assets/images/scholars/huwaini.jpg',
  ),
  DuroosSource(
    // كان مصدره islamweb (sid=2376) — بدّلناه لـmidad بعد مقارنة فعلية:
    // islamweb عنده ٩ محاضرات فقط بلا تصنيفات فرعية، بينما بحث midad عن
    // نفس الشيخ رجّع ١٩١ نتيجة عبر ١٠ صفحات (دروس/محاضرات/كتب متنوعة) —
    // فرق ضخم لصالح midad.
    id: 'amer_bahjat',
    title: 'الشيخ عامر محمد فداء بهجت',
    subtitle: 'دروس ومحاضرات متنوعة من موقع مِداد',
    icon: Icons.school_outlined,
    category: DuroosCategoryIds.seerahGeneral,
    kind: DuroosSourceKind.midad,
    midadQuery: 'عامر بهجت',
    imageAsset: 'assets/images/scholars/amer_bahjat.jpg',
  ),
  DuroosSource(
    // كان مصدره midad (بحث "صالح بن عبد العزيز آل الشيخ") — بدّلناه
    // لـislamweb (sid=41) بعد مقارنة فعلية: islamweb عنده ٢٥ تصنيفاً
    // فرعياً و٣٠ محاضرة مباشرة بالجذر، بينما نتائج بحث midad لنفس الشيخ
    // ٢٠ نتيجة مسطّحة فقط (دروس مفردة + مجموعات قليلة) — أرشيف islamweb
    // أشمل بوضوح لنفس الشخص، فلا داعي لمصدرين لنفس الشيخ.
    id: 'saleh_al_alsheikh',
    title: 'الشيخ صالح بن عبد العزيز آل الشيخ',
    subtitle: 'وزير الشؤون الإسلامية السعودي — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.seerahGeneral,
    kind: DuroosSourceKind.islamweb,
    sid: 41,
    // لسا بلا صورة موثوقة — راجع توثيق imageAsset بالأعلى.
  ),
  DuroosSource(
    // كان مصدره بودكاست RSS وحيد (شرح العقيدة الطحاوية فقط) — بدّلناه
    // لـmidad بعد مقارنة فعلية: بحث midad عن نفس الشيخ (بالتهجئة
    // "السندي") رجّع ١٠ مجموعات دروس مستقلة (شرح كتاب التوحيد، الأسماء
    // الحسنى، شروط الصلاة...)، أشمل بوضوح من حلقات بودكاست واحد.
    id: 'saleh_sindi',
    title: 'الدكتور صالح بن عبد العزيز السندي',
    subtitle: 'دروس ومحاضرات متنوعة من موقع مِداد',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.mutoon,
    kind: DuroosSourceKind.midad,
    midadQuery: 'صالح بن عبدالعزيز السندي',
    imageAsset: 'assets/images/scholars/saleh_sindi.jpg',
  ),
  DuroosSource(
    id: 'waleed_saeedan',
    title: 'الشيخ وليد بن راشد السعيدان',
    subtitle: 'عقيدة وأصول فقه — دروس ومحاضرات من موقع مِداد',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.mutoon,
    kind: DuroosSourceKind.midad,
    midadQuery: 'وليد بن راشد السعيدان',
  ),
  DuroosSource(
    id: 'saleh_fawzan',
    title: 'الشيخ صالح بن فوزان الفوزان',
    subtitle: 'عضو هيئة كبار العلماء — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.scholars,
    kind: DuroosSourceKind.islamweb,
    sid: 235,
  ),
  DuroosSource(
    id: 'tarifi',
    title: 'الشيخ عبد العزيز بن مرزوق الطريفي',
    subtitle: 'دروس حديثية وفقهية — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.mutoon,
    kind: DuroosSourceKind.islamweb,
    sid: 2102,
  ),
  DuroosSource(
    id: 'hasan_bukhari',
    title: 'الشيخ حسن عبد الحميد بخاري',
    subtitle: 'دروس صوتية — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.seerahGeneral,
    kind: DuroosSourceKind.islamweb,
    sid: 2066,
  ),
  DuroosSource(
    id: 'mishari_kharraz',
    title: 'الشيخ مشاري الخراز',
    subtitle: 'دروس صوتية — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.seerahGeneral,
    kind: DuroosSourceKind.islamweb,
    sid: 1489,
  ),
  DuroosSource(
    id: 'saad_atiq',
    title: 'الشيخ سعد بن عتيق العتيق',
    subtitle: 'دروس صوتية — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    category: DuroosCategoryIds.seerahGeneral,
    kind: DuroosSourceKind.islamweb,
    sid: 1535,
  ),
];
