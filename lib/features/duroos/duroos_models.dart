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
    this.sid,
    this.initialLg = 0,
    this.feedUrl,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final DuroosSourceKind kind;

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
}

/// تصنيف فرعي (سلسلة دروس) ضمن صفحة عالِم بـislamweb — يُفتح بتصنيف
/// جديد (`lg`) يعرض إما محاضرات مباشرة أو تصنيفات أعمق.
class DuroosCategory {
  const DuroosCategory({required this.lg, required this.title, this.count});
  final int lg;
  final String title;
  final int? count;
}

/// محاضرة واحدة قابلة للتشغيل مباشرة (رابط mp3 حقيقي).
class DuroosLecture {
  const DuroosLecture({required this.title, required this.audioUrl});
  final String title;
  final String audioUrl;
}

/// نتيجة جلب صفحة واحدة: إما قائمة تصنيفات (يُختار منها) أو قائمة
/// محاضرات (تُشغَّل مباشرة) — islamweb قد يعطي كليهما بصفحة الجذر
/// (تصنيفات) أو الورقة الفرعية (محاضرات)، وrss يعطي محاضرات فقط دائماً.
class DuroosPage {
  const DuroosPage({required this.categories, required this.lectures});
  final List<DuroosCategory> categories;
  final List<DuroosLecture> lectures;
}

const List<DuroosSource> kDuroosSources = [
  DuroosSource(
    id: 'binbaz',
    title: 'الشيخ عبد العزيز بن باز رحمه الله',
    subtitle: 'محاضرات وفتاوى صوتية — أرشيف إسلام ويب',
    icon: Icons.school_outlined,
    kind: DuroosSourceKind.islamweb,
    sid: 159,
    imageAsset: 'assets/images/scholars/binbaz.png',
  ),
  DuroosSource(
    id: 'nour_aladdarb',
    title: 'نور على الدرب',
    subtitle: 'سلسلة فتاوى نور على الدرب لسماحة الشيخ ابن باز',
    icon: Icons.lightbulb_outline,
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
    kind: DuroosSourceKind.islamweb,
    sid: 2735,
    imageAsset: 'assets/images/scholars/albadr.jpg',
  ),
  DuroosSource(
    id: 'osaimi',
    title: 'الشيخ صالح بن عبد الله العصيمي',
    subtitle: 'دروس ومتون علمية — أرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    kind: DuroosSourceKind.islamweb,
    sid: 1812,
    imageAsset: 'assets/images/scholars/osaimi.jpg',
  ),
  DuroosSource(
    id: 'qasim',
    title: 'الشيخ عبد المحسن بن محمد القاسم',
    subtitle: 'إمام وخطيب المسجد النبوي — دروس صوتية بأرشيف إسلام ويب',
    icon: Icons.menu_book_outlined,
    kind: DuroosSourceKind.islamweb,
    sid: 1326,
    imageAsset: 'assets/images/scholars/qasim.jpg',
  ),
  DuroosSource(
    id: 'shuwaier',
    title: 'الشيخ عبد السلام بن محمد الشويعر',
    subtitle: 'شرح الإقناع (فقه حنبلي) — بودكاست رسمي',
    icon: Icons.gavel_outlined,
    kind: DuroosSourceKind.rss,
    feedUrl: 'https://anchor.fm/s/f5e47d48/podcast/rss',
    imageAsset: 'assets/images/scholars/shuwaier.jpg',
  ),
  DuroosSource(
    id: 'fiqh',
    title: 'الفقه الإسلامي وأحكام العبادات',
    subtitle: 'الشيخ محمد بن صالح العثيمين — أرشيف إسلام ويب',
    icon: Icons.account_balance_outlined,
    kind: DuroosSourceKind.islamweb,
    sid: 162,
    imageAsset: 'assets/images/scholars/othaymeen.png',
  ),
  DuroosSource(
    id: 'seerah',
    title: 'السيرة النبوية',
    subtitle: 'الدكتور راغب السرجاني — أرشيف إسلام ويب',
    icon: Icons.history_edu_outlined,
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
    kind: DuroosSourceKind.islamweb,
    sid: 452,
    imageAsset: 'assets/images/scholars/huwaini.jpg',
  ),
  DuroosSource(
    id: 'amer_bahjat',
    title: 'الشيخ عامر محمد فداء بهجت',
    subtitle: 'دروس صوتية — أرشيف إسلام ويب',
    icon: Icons.school_outlined,
    kind: DuroosSourceKind.islamweb,
    sid: 2376,
    imageAsset: 'assets/images/scholars/amer_bahjat.jpg',
  ),
  DuroosSource(
    id: 'saleh_sindi',
    title: 'الدكتور صالح بن عبد العزيز سندي',
    subtitle: 'شرح العقيدة الطحاوية — بودكاست رسمي',
    icon: Icons.menu_book_outlined,
    kind: DuroosSourceKind.rss,
    feedUrl: 'https://anchor.fm/s/f6681cfc/podcast/rss',
    imageAsset: 'assets/images/scholars/saleh_sindi.jpg',
  ),
];
