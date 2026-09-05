import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart'
    show BookmarkTypes, UserCategories, UserRepository;
import '../../core/text/arabic_normalizer.dart' show surahShortName;
import '../../core/theme/app_colors.dart';
import '../../core/theme/mushaf_palettes.dart';
import '../audio/quran_audio_controller.dart';
import '../notifications/smart_reminder_sync.dart';
import '../onboarding/onboarding_target_keys.dart';
import '../settings/settings_screen.dart';
import 'font_download_screen.dart';
import 'font_download_service.dart';
import 'mushaf_page_widget.dart';
import 'mushaf_search_screen.dart';
import 'mushaf_settings.dart';
import 'mushaf_surah_index_sheet.dart';
import 'quran_audio_bar.dart';
import 'tafsir_reading_screen.dart';

const int kMushafPageCount = 604;

/// مفتاح "تجاهل" شريط تنبيه تنزيل الخطوط الباقية — **محفوظ بين الجلسات**
/// (كان قبلاً `bool` محلي بالودجت فقط، يرجع يظهر كل فتح تطبيق جديد رغم
/// ضغط "لاحقاً" — بلاغ صاحب المشروع "مزعج وماخذ مساحة"). **مستقل لكل طبعة**
/// (`.name` مضافاً لاحقة) — الشريط هلق يتبع طبعة المصحف المختارة فعلياً
/// (`fontDownloadedCountProvider`، لا V2 حصراً كالسابق)، فتجاهله لطبعة لا
/// يخفيه تلقائياً عن طبعة أخرى بعد تبديل الخط.
String _fontDownloadBannerDismissedKey(MushafFontEdition edition) =>
    'mushaf_font_download_banner_dismissed_${edition.name}';

const Duration _kChromeAnim = Duration(milliseconds: 200);

/// جزء الصفحة الحالية — أول آية بالصفحة تكفي (الجزء لا يتغيّر داخل نفس
/// الصفحة عملياً إلا نادراً عند حد جزء بمنتصف صفحة، تقريب مقبول لشريط
/// تنقّل لا لحساب دقيق).
final _pageJuzProvider = FutureProvider.family<int, int>((ref, page) async {
  final ayahs = await ref.watch(quranRepositoryProvider).ayahsForPage(page);
  return ayahs.isEmpty ? 1 : ayahs.first.juz;
});

/// حزب الصفحة الحالية — نفس تقريب [_pageJuzProvider] (أول آية بالصفحة).
/// `Ayahs.hizb` مُعبَّأ بالكامل فعلياً (راجع `QuranRepository.hizbForPage`).
final _pageHizbProvider = FutureProvider.family<int, int>((ref, page) {
  return ref.watch(quranRepositoryProvider).hizbForPage(page);
});

/// ربع-حزب الصفحة الحالية (`Ayahs.rub`) — راجع توثيق `QuranRepository.
/// rubForPage` وتوثيق [_hizbFractionLabel] لاستخدامه.
final _pageRubProvider = FutureProvider.family<int, int>((ref, page) {
  return ref.watch(quranRepositoryProvider).rubForPage(page);
});

/// تسمية الربع التقليدية بالمصحف — "ربع/نصف/ثلاثة أرباع الحزب"، أو بلا
/// بادئة (الحزب كاملاً) للربع الرابع. بطلب صاحب المشروع "تفاصيل الحزب:
/// الربع، النصف، ثلاثة أرباع الحزب" بدل رقم حزب مجرَّد بشريط هوية الصفحة.
const _hizbFractionLabel = {1: 'ربع', 2: 'نصف', 3: 'ثلاثة أرباع'};

/// نص "[ربع/نصف/ثلاثة أرباع] الحزب N" لصفحة معيّنة، من [rub] (`Ayahs.rub`
/// العام ١..٢٤٠) و[hizb] (`Ayahs.hizb` ١..٦٠) — `((rub - 1) % 4) + 1` يعطي
/// موقع الربع ضمن حزبه (راجع توثيق `QuranRepository.rubForPage`).
String _hizbFractionText(int rub, int hizb) {
  final quarterInHizb = ((rub - 1) % 4) + 1;
  final prefix = _hizbFractionLabel[quarterInHizb];
  return prefix == null ? 'الحزب $hizb' : '$prefix الحزب $hizb';
}

/// اسم سورة الصفحة الحالية (أول آية بالصفحة) — لشريط تنقّل الصفحات وشريط
/// هوية الصفحة (`_PageIdentityBar` أسفل). مستقل عن `_surahNameProvider`
/// الخاص بـ`mushaf_page_widget.dart` (ذاك بمفتاح `surahId` مباشر من سطر
/// `surah_name`، هذا بمفتاح `page` — كلاهما يصلان لنفس `surahById` بالنهاية).
final _pageSurahNameProvider = FutureProvider.family<String, int>((
  ref,
  page,
) async {
  final quran = ref.watch(quranRepositoryProvider);
  final ayahs = await quran.ayahsForPage(page);
  if (ayahs.isEmpty) return '';
  final surah = await quran.surahById(ayahs.first.surah);
  if (surah.id == 5) return 'المائدة';
  return surahShortName(surah.nameAr);
});

/// رقم سورة الصفحة الحالية — لغليف `surah{NNN}` بشريط هوية الصفحة
/// (`_PageIdentityBar`)، بدل الاكتفاء بالاسم النصي أعلاه.
final _pageSurahIdProvider = FutureProvider.family<int, int>((ref, page) async {
  final ayahs = await ref.watch(quranRepositoryProvider).ayahsForPage(page);
  return ayahs.isEmpty ? 1 : ayahs.first.surah;
});

/// شاشة عرض المصحف: تقليب أفقي بين الصفحات (٦٠٤ صفحة)، كل صفحة تُبنى
/// وتُحمَّل خطها عند زيارتها فقط. الاتجاه العام RTL (مضبوط بجذر التطبيق)
/// فيخلي السحب الطبيعي يقدّم للصفحة التالية بترتيب المصحف.
///
/// **قراءة غامرة:** لا `AppBar` تقليدياً — عناصر التحكّم (فهرس السور،
/// رقم الصفحة، وضع الحفظ، بحث، حجم الخط، الوضع الليلي، وشريط الصوت)
/// شريطان عائمان (`_TopChromeBar`/`_BottomChromeBar`) فوق الصفحة مباشرة،
/// تتبدّل رؤيتهما بلمسة في أي مكان بالصفحة (`_chromeVisible`) — راجع
/// `GestureDetector` المغلِّف لـ`PageView` أسفل.
///
/// حالياً: أول ٥٠ صفحة فقط لها خط مُضمَّن (راجع MushafFontService)، الباقي
/// يعرض رسالة "غير متوفر بعد" ريثما يُبنى مدير التنزيلات.
class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({
    super.key,
    this.initialPage,
    this.pickingHifzRange = false,
    this.hifzPracticeMode = false,
    this.hifzPlanId,
    this.qiyamSessionMode = false,
    this.khatmaPracticeMode = false,
    this.khatmaPlanId,
    this.wirdTargetPage,
  });

  /// null = ابدأ من آخر صفحة مقروءة محفوظة (أو ١ إن لم توجد). مرّر رقماً
  /// صريحاً فقط لفتح صفحة محدَّدة عمداً (قفز من فهرس/بحث مثلاً).
  final int? initialPage;

  /// `true` = وضع "اختيار نطاق حفظ من المصحف" (`HifzScreen`): الضغط على
  /// كلمة يختار طرف نطاق بدل فتح شيت الآية، وعند اكتمال الاختيار
  /// (طرفَين) تُغلَق الشاشة بـ`Navigator.pop((from: ..., to: ...))` —
  /// راجع `hifzPickerProvider` بـ`mushaf_settings.dart`.
  final bool pickingHifzRange;

  /// `true` = "تابع الحفظ" من `HifzScreen`: يفعِّل وضع تخفية/كشف الكلمات
  /// تلقائياً، و**تقدّم تصفّح الصفحات هون يُحدِّث خطة الحفظ [hifzPlanId]
  /// فقط** (`UserRepository.updateHifzCurrentAyah`) — لا يلمس `lastReadPage`/
  /// سلسلة القراءة اليومية العاديين إطلاقاً (`_onPageChanged` أسفل).
  final bool hifzPracticeMode;

  /// أي خطة (من عدّة خطط حفظ ممكنة الآن) يخصّها هذا التقدّم — **إلزامي
  /// فعلياً** حين [hifzPracticeMode]، `HifzScreen` تمرّره دوماً عند فتح
  /// "تابع الحفظ" (راجع تعليق `_updateHifzProgressForPage` أسفل لو غاب).
  final int? hifzPlanId;

  /// `true` = "ابدأ قيام" من `QiyamScreen`: تصفّح عادي بلا تخصيص (يبقى
  /// `lastReadPage`/سلسلة القراءة يُحدَّثان كالمعتاد، بخلاف [hifzPracticeMode])،
  /// لكن كل آية تُمرّ عليها بأي صفحة تُسجَّل بجلسة `qiyamSessionProvider`
  /// (`mushaf_settings.dart`) لعدّها عند إنهاء الجلسة — راجع شريط "إنهاء
  /// الجلسة" أسفل و`QiyamAyahLog` بـ`user_tables.dart`.
  final bool qiyamSessionMode;

  /// `true` = "تابع القراءة" من `KhatmaScreen` لخطة ختمة محدَّدة: نفس مبدأ
  /// [hifzPracticeMode] بالضبط — **تقدّم تصفّح الصفحات هون يُحدِّث خطة
  /// الختمة [khatmaPlanId] فقط** (`UserRepository.updateKhatmaCurrentPage`)،
  /// لا يلمس `lastReadPage`/سلسلة القراءة اليومية العاديين إطلاقاً. بطلب
  /// صاحب المشروع صراحة: تقدّم كل خطة ختمة "مختلف عن التقدّم الحالي"
  /// (القراءة العامة)، خصوصاً أن خطة الختمة قد تبدأ من نقطة غير الصفحة ١.
  final bool khatmaPracticeMode;

  /// أي خطة (من عدّة خطط ختمة ممكنة الآن) يخصّها هذا التقدّم — **إلزامي
  /// فعلياً** حين [khatmaPracticeMode]، `KhatmaScreen` تمرّره دوماً عند فتح
  /// "تابع القراءة" — راجع تعليق `_updateKhatmaProgressForPage` أسفل لو غاب.
  final int? khatmaPlanId;

  /// صفحة هدف "ورد اليوم" — بلوغها أثناء [khatmaPracticeMode] (فتح عبر زر
  /// "ابدأ وردي" بالرئيسية) يُظهر إشعار تهنئة داخلي مرّة واحدة بهذه
  /// الجلسة. `null` = لا احتفال (فتح الختمة من `KhatmaScreen` مباشرة مثلاً،
  /// بلا هدف يومي محدَّد لهذه الجلسة تحديداً).
  final int? wirdTargetPage;

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  late final PageController _controller;
  late int _currentPage;
  /// أسماء طبعات (`MushafFontEdition.name`) تجاهَل المستخدم شريط تنزيلها
  /// — راجع توثيق [_fontDownloadBannerDismissedKey].
  final Set<String> _dismissedFontDownloadBanners = {};
  Timer? _highlightClearTimer;
  // --- تعقّب "جلسة قراءة" لـ`reading_log` (راجع UserRepository.logReadingSession)
  // — لا نكتب صفاً بكل تصفّح صفحة (بحث/قفز فهرس يقلّب عدة صفحات بسرعة)، بل
  // نجمع فرق الصفحات الموجب (تقدّم فعلي للأمام فقط) وننتظر خمولاً ٣٠ ثانية
  // (Timer يُعاد ضبطه بكل تصفّح جديد) قبل تفريغها كجلسة واحدة — أو نفرّغها
  // فوراً عند إغلاق الشاشة (`dispose`) لو ما وصل الخمول بعد.
  int _pendingReadingPages = 0;
  Timer? _readingLogIdleTimer;
  // تظهر إشعار "أتممت ورد اليوم" مرّة واحدة فقط لكل جلسة (راجع
  // [MushafScreen.wirdTargetPage]) — لا تتكرّر لو رجع المستخدم للصفحة
  // نفسها بتصفّح إضافي بعد بلوغها أول مرة.
  bool _wirdCelebrationShown = false;
  // `true` لتصفّح واحد قادم فقط: يمنع `_onPageChanged` من مسح التظليل
  // المؤقت الذي *سيُضبط* حالاً بعد `_jumpTo` هون تحديداً — راجع
  // [_handleJumpRequest]. بقية استدعاءات `_jumpTo` (فهرس/بحث/صوت) تترك
  // القيمة `false` عمداً فيُمسَح أي تظليل مؤقت سابق طبيعياً بقفزها.
  bool _skipNextHighlightClear = false;

  @override
  void initState() {
    super.initState();
    _currentPage =
        widget.initialPage ?? ref.read(userPrefsProvider).lastReadPage ?? 1;
    _controller = PageController(initialPage: _currentPage - 1);
    final prefs = ref.read(sharedPreferencesProvider);
    for (final edition in MushafFontEdition.values) {
      if (prefs.getBool(_fontDownloadBannerDismissedKey(edition)) ?? false) {
        _dismissedFontDownloadBanners.add(edition.name);
      }
    }
    // **لا** تعديل حالة أي Notifier هون (`hifzPickerProvider.notifier.activate()`
    // كان هون سابقاً) — Riverpod يمنع صراحة تعديل حالة provider أثناء
    // `initState` (يرمي "Tried to modify a provider while the widget tree
    // was building"، راجع نفس الخطأ الفعلي الذي ظهر لـ`qiyamSessionProvider`
    // أسفل). التفعيل صار مسؤولية المستدعي: `HifzScreen._startNewPlan` تستدعي
    // `activate()` قبل `Navigator.push` مباشرة (معالِج زر عادي، لا قيد عليه).
    if (widget.hifzPracticeMode) {
      // **لا** نُفعِّل وضع تخفية الكلمات تلقائياً هون — كان يُظهر كل كلمات
      // الصفحة كمربّعات ■ فوراً بلا نص حقيقي ظاهر أصلاً (باج حقيقي: بدا
      // للمستخدم أن الصفحة "بلا نص"). تابع الحفظ يفتح النص الحقيقي أولاً؛
      // وضع التخفية يبقى اختيارياً بضغطة زر "وضع الحفظ" بالشريط العلوي
      // كالمعتاد.
      //
      // دخول ممارسة الحفظ يُحسَب "تدرّب اليوم" — نفس منطق تفعيل وضع الحفظ
      // يدوياً من الشريط العلوي (`_TopChromeBar.onToggleMemorization`)، لكن
      // ذاك المسار لا يُستدعى هون لأن الدخول نفسه (لا الضغط) هو الإشارة هون.
      ref
          .read(userPrefsProvider)
          .bumpCategoryStreakIfNewDay(UserCategories.hifz);
    }
    if (widget.qiyamSessionMode) {
      // `qiyamSessionProvider.notifier.start()` **لا** يُستدعى هون — نفس
      // القيد أعلاه بالضبط. المستدعي (`QiyamScreen` أزرار "ابدأ قيام"/خطط
      // القيام بعدد آيات) يستدعيها قبل `Navigator.push`. `_recordQiyamAyahs`
      // أسفل آمنة كما هي: `unawaited` + تمرّ بـ`await` قبل أي تعديل حالة،
      // فتهرب من نافذة البناء المتزامنة تلقائياً (لا تُستدعى مباشرة من
      // `initState` بل مجدولة بعده).
      unawaited(_recordQiyamAyahs(_currentPage));
    }
    // تنزيل كسول بالأولوية لخط الصفحة الحالية وجيرانها — راجع
    // `font_download_service.dart.requestPageWithPriority`. لا ضرر لو
    // الصفحة مضمَّنة أصلاً (١-٥٠) أو مُنزَّلة سابقاً، الدالة تتجاهلها.
    ref
        .read(fontDownloadControllerProvider.notifier)
        .requestPageWithPriority(_currentPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    _highlightClearTimer?.cancel();
    _readingLogIdleTimer?.cancel();
    _flushReadingLog();
    if (widget.pickingHifzRange) {
      // نفس قيد Riverpod يشمل `dispose` أيضاً (مذكور صراحة برسالة الخطأ) —
      // لا يمكن نقل هذا لمعالِج زر (التخلّص يحصل أيضاً بزر رجوع النظام/سحبة
      // الرجوع، لا مسار واحد محدَّد). الحل الرسمي الثاني من نفس رسالة
      // الخطأ: اقرأ الـnotifier نفسه بشكل متزامن (قراءة، لا كتابة — مسموحة
      // دائماً) ثم أجِّل الكتابة الفعلية (`deactivate`) لِـ`Future` يعمل
      // بعد الخروج من نافذة البناء المحظورة.
      final hifzPicker = ref.read(hifzPickerProvider.notifier);
      Future(() => hifzPicker.deactivate());
    }
    super.dispose();
  }

  /// لمسة أي مكان بالصفحة تبدّل رؤية القوائم العائمة — **إلا** لو وقعت على
  /// كلمة (فتحت شيت آية/كشفت حفظاً/اختارت طرف نطاق حفظ)، حينها نتجاهلها هون
  /// بدل تبديل القوائم بنفس اللمسة. راجع توثيق [wordTapConsumedThisGesture]
  /// بـ`mushaf_page_widget.dart` لضمان ترتيب الاستدعاء (الكلمة أولاً دوماً).
  void _handlePageTap() {
    if (wordTapConsumedThisGesture) {
      wordTapConsumedThisGesture = false;
      return;
    }
    ref.read(mushafChromeVisibleProvider.notifier).toggle();
  }

  void _jumpTo(int page) {
    _controller.jumpToPage(page - 1);
    setState(() => _currentPage = page);
  }

  /// استجابة لطلب قفز خارجي (متشابهات مثلاً — راجع توثيق
  /// [mushafJumpRequestProvider]): يقفز للصفحة، ويضبط تظليلاً مؤقتاً
  /// يُمسح تلقائياً بعد ٤ ثوانٍ أو عند أي تغيير صفحة يدوي لاحق
  /// (`_onPageChanged`)، أيّهما أسبق.
  void _handleJumpRequest(MushafJumpRequest req) {
    if (req.page != _currentPage) {
      _skipNextHighlightClear = true;
      _jumpTo(req.page);
    }
    _highlightClearTimer?.cancel();
    ref.read(highlightedAyahProvider.notifier).set(req.ayahId);
    _highlightClearTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) ref.read(highlightedAyahProvider.notifier).set(null);
    });
  }

  Future<void> _openSurahIndex() async {
    final startPage = await MushafSurahIndexSheet.show(
      context,
      currentPage: _currentPage,
    );
    if (startPage != null) _jumpTo(startPage);
  }

  /// نفس الفهرس بس مفتوح على تبويب الأجزاء مباشرة، مع تمرير تلقائي للجزء
  /// الحالي وربعه — راجع توثيق [_PageIdentityBar] لسبب فصل هذا عن
  /// [_openSurahIndex] (لمسة اسم السورة تفتح تبويب السور، لمسة الجزء/الحزب
  /// تفتح تبويب الأجزاء).
  Future<void> _openJuzIndex() async {
    final startPage = await MushafSurahIndexSheet.show(
      context,
      currentPage: _currentPage,
      openJuzTab: true,
    );
    if (startPage != null) _jumpTo(startPage);
  }

  /// يحفظ الصفحة الحالية كفاصلة "تلاوة" (`BookmarkTypes.reading`) — نفس
  /// فعل زر 🔖 ببطاقة "فاصل الصفحة" داخل الفهرس، لكن مباشرة من شريط هوية
  /// الصفحة بلا حاجة لفتح الفهرس أولاً (بطلب صاحب المشروع "شريط الحفظ
  /// ممكن تضيفه للشريط العلوي").
  ///
  /// **باج حقيقي مُصلَح هون:** `BookmarkTypes.reading` فتحة أحادية واحدة
  /// فقط (تُستبدَل بفاصلة جديدة عند كل ضغط، لا تبقى قابلة للعثور عليها لاحقاً
  /// بأي شاشة أخرى غير بطاقة "فاصل الصفحة" بأعلى الفهرس نفسه) — بطلب صاحب
  /// المشروع "فاصل الحفظ... ما بتخزن خزنه مثلاً بالعلامات المرجعية"، تُضاف
  /// الآن أيضاً للعلامات المرجعية العامة غير المحدودة (`toggleBookmark`،
  /// ظاهرة بشاشة `bookmarks_screen.dart`) فتبقى موجودة حتى لو حُفظت صفحة
  /// تالية كفاصلة "تلاوة" جديدة — وهذا أيضاً يحل "الفواصل... مسموح لآية
  /// وحدة خليه أكثر من آية": كل ضغطة تضيف آية جديدة للقائمة العامة، لا تستبدل
  /// سابقتها. لا إضافة مكرَّرة لو الآية محفوظة أصلاً (`isBookmarked`).
  Future<void> _saveCurrentPageBookmark() async {
    final ayahs = await ref
        .read(quranRepositoryProvider)
        .ayahsForPage(_currentPage);
    if (ayahs.isEmpty || !mounted) return;
    final ayahId = ayahs.first.id;
    final prefs = ref.read(userPrefsProvider);
    await prefs.setActivityBookmark(BookmarkTypes.reading, ayahId);
    ref.read(activityBookmarkVersionProvider.notifier).bump();
    if (!prefs.isBookmarked(ayahId)) {
      await prefs.toggleBookmark(ayahId);
      ref.read(bookmarkVersionProvider.notifier).bump();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اتحفظت هذه الصفحة بالعلامات المرجعية')),
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  /// يفتح شاشة "قراءة مع التفسير" على نفس صفحة المصحف المفتوحة حالياً —
  /// الشاشة الجديدة صفحة-بصفحة (`PageView`) بنفس ترقيم المصحف، فتمرير
  /// الصفحة الحالية مباشرة كافٍ بلا حاجة لحل سورة/آية أولاً.
  Future<void> _openTafsirReading() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TafsirReadingScreen(initialPage: _currentPage),
      ),
    );
  }

  Future<void> _openSearch() async {
    final page = await Navigator.of(
      context,
    ).push<int>(MaterialPageRoute(builder: (_) => const MushafSearchScreen()));
    if (page != null) _jumpTo(page);
  }

  /// يفرّغ الصفحات المتراكمة منذ آخر تسجيل كجلسة قراءة واحدة بـ`reading_log`
  /// (راجع تعليق `_pendingReadingPages` أعلى) — لا شيء لو لا تراكم بعد.
  void _flushReadingLog() {
    if (_pendingReadingPages <= 0) return;
    final pages = _pendingReadingPages;
    _pendingReadingPages = 0;
    final userPrefs = ref.read(userPrefsProvider);
    userPrefs.logReadingSession(pagesRead: pages).then((_) {
      // إلغاء فوري لتذكير "الورد اليومي" لو صار اليوم مقروءاً فعلاً — بدل
      // انتظار إعادة التقييم بالإقلاع التالي فقط (راجع توثيق
      // `syncDailyWirdReminder`).
      syncDailyWirdReminder(userPrefs);
    });
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    final oldPage = _currentPage;
    setState(() => _currentPage = page);
    // تنزيل كسول بالأولوية للصفحة الجديدة وجيرانها — راجع توثيق الاستدعاء
    // المماثل بـ`initState` أعلى.
    ref
        .read(fontDownloadControllerProvider.notifier)
        .requestPageWithPriority(page);
    // أي تصفّح آخر (يدوي أو قفز فهرس/بحث/صوت) يُلغي التظليل المؤقت الموروث
    // من قفز متشابهات سابق — لا يبقى معلَّقاً بصفحة صار المستخدم غادرها
    // فعلياً. الاستثناء الوحيد: القفز الذي *سبَّب* هذا التظليل نفسه للتو
    // (راجع [_handleJumpRequest]/[_skipNextHighlightClear]).
    if (_skipNextHighlightClear) {
      _skipNextHighlightClear = false;
    } else {
      _highlightClearTimer?.cancel();
      ref.read(highlightedAyahProvider.notifier).set(null);
    }
    // تراكم "ورد اليوم" لـ`reading_log` — تقدّم فعلي للأمام فقط (لا فهرس/
    // بحث يرجع للخلف)، يُفرَّغ بخمول ٣٠ ثانية أو عند إغلاق الشاشة. يشمل وضع
    // "ابدأ وردي" (khatmaPracticeMode) عمداً — قراءة فعلية حقيقية أيضاً،
    // بطلب صاحب المشروع صراحة لهذه الميزة تحديداً. **يستثني** وضع الحفظ
    // (hifzPracticeMode) — مراجعة/تكرار آيات محدود لا "قراءة" بنفس المعنى.
    final diff = page - oldPage;
    if (diff > 0 && !widget.hifzPracticeMode) {
      _pendingReadingPages += diff;
      _readingLogIdleTimer?.cancel();
      _readingLogIdleTimer = Timer(
        const Duration(seconds: 30),
        _flushReadingLog,
      );
    }

    if (widget.qiyamSessionMode) {
      unawaited(_recordQiyamAyahs(page));
    }
    if (widget.hifzPracticeMode) {
      // تقدّم ممارسة الحفظ يُحدَّث بخطة الحفظ النشطة فقط — **بلا لمس**
      // `lastReadPage`/سلسلة القراءة اليومية العاديين، هذا صلب فصل تقدّم
      // الحفظ عن تقدّم القراءة (راجع توثيق `hifzPracticeMode` أعلى الودجت).
      unawaited(_updateHifzProgressForPage(page));
      return;
    }
    if (widget.khatmaPracticeMode) {
      // نفس مبدأ hifzPracticeMode أعلاه بالضبط — راجع توثيق
      // [MushafScreen.khatmaPracticeMode].
      unawaited(_updateKhatmaProgressForPage(page));
      return;
    }
    final prefs = ref.read(userPrefsProvider);
    prefs.setLastReadPage(page);
    prefs.bumpStreakIfNewDay();
  }

  /// يسجّل آيات صفحة بجلسة القيام الحالية — راجع توثيق [MushafScreen.qiyamSessionMode].
  Future<void> _recordQiyamAyahs(int page) async {
    final ayahs = await ref.read(quranRepositoryProvider).ayahsForPage(page);
    if (!mounted || ayahs.isEmpty) return;
    ref.read(qiyamSessionProvider.notifier).recordAyahs(ayahs.map((a) => a.id));
  }

  /// يخفي شريط "تنزيل الخطوط الباقية" **نهائياً لهذه الطبعة تحديداً** (لا
  /// لهالجلسة فقط، ولا لبقية الطبعات) — راجع توثيق
  /// [_fontDownloadBannerDismissedKey] أعلى الملف.
  void _dismissDownloadBannerPermanently(MushafFontEdition edition) {
    setState(() => _dismissedFontDownloadBanners.add(edition.name));
    ref.read(sharedPreferencesProvider).setBool(_fontDownloadBannerDismissedKey(edition), true);
  }

  /// ينهي جلسة القيام: يحفظ عدد آياتها بـ`QiyamAyahLog` (تراكمي لليوم)،
  /// يسجّل "تمّ قيام الليل اليوم" (نفس زر "سجّل قيامك الليلة" اليدوي
  /// بـ`qiyam_screen.dart`)، ثم يعرض ملخّصاً ويعيد المستخدم للشاشة السابقة.
  Future<void> _endQiyamSession() async {
    final count = ref.read(qiyamSessionProvider.notifier).end();
    final prefs = ref.read(userPrefsProvider);
    final dateKey = UserRepository.dateKeyFor(DateTime.now());
    await prefs.addQiyamAyahCount(dateKey, count);
    await prefs.bumpCategoryStreakIfNewDay(UserCategories.qiyam);
    ref.read(qiyamSessionProvider.notifier).reset();
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('انتهت جلسة القيام'),
        content: Text(
          count > 0
              ? 'قرأت $count آية هذه الليلة — تقبّل الله.'
              : 'أُنهيت الجلسة بلا آيات مسجَّلة.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  /// **متابعة تلقائية أثناء الاستماع** — بطلب صاحب المشروع (كان لا يوجد
  /// أي تتبّع لموضع القارئ إطلاقاً: "عند انتقال القارئ لصفحة أخرى يبقى
  /// المؤشر في صفحة بداية القراءة"). تُستدعى من `ref.listen` بـ`build()`
  /// كل ما تغيّرت `currentAyahId` أثناء تشغيل فعلي — لو صفحة الآية الجديدة
  /// غير الصفحة المعروضة حالياً، نقفز إليها (نفس `_jumpTo` المستخدَم
  /// بفهرس السور/قفز الصفحة، فيُحدِّث `lastReadPage`/السلسلة كالمعتاد).
  Future<void> _followAudioToAyah(int ayahId) async {
    final ayah = await ref.read(quranRepositoryProvider).ayahById(ayahId);
    if (!mounted) return;
    if (ayah.page != _currentPage) _jumpTo(ayah.page);
  }

  Future<void> _updateHifzProgressForPage(int page) async {
    final planId = widget.hifzPlanId;
    // دفاعي فقط: `HifzScreen` تمرّر `hifzPlanId` دوماً مع `hifzPracticeMode`
    // (راجع `_HifzScreenState._continue`) — لا يجب أن يحصل هذا فعلياً.
    if (planId == null) return;
    final ayahs = await ref.read(quranRepositoryProvider).ayahsForPage(page);
    if (ayahs.isEmpty || !mounted) return;
    await ref.read(hifzPrefsProvider).updateCurrentAyah(planId, ayahs.first.id);
    ref.read(hifzVersionProvider.notifier).bump();
  }

  Future<void> _updateKhatmaProgressForPage(int page) async {
    final planId = widget.khatmaPlanId;
    // دفاعي فقط: `KhatmaScreen` تمرّر `khatmaPlanId` دوماً مع
    // `khatmaPracticeMode` — لا يجب أن يحصل هذا فعلياً.
    if (planId == null) return;
    if (!mounted) return;
    await ref.read(khatmaPrefsProvider).updateCurrentPage(planId, page);
    ref.read(khatmaVersionProvider.notifier).bump();

    final target = widget.wirdTargetPage;
    if (target != null && !_wirdCelebrationShown && page >= target) {
      _wirdCelebrationShown = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أحسنت! أتممت ورد اليوم 🎉'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(mushafPaletteVersionProvider);
    ref.watch(accentColorVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final palette = mushafPaletteById(
      userPrefs.mushafPaletteId,
      accentId: userPrefs.accentColorId,
    );
    final bg = palette.bg(isDark);
    final fg = palette.fg(isDark);
    final textSize = ref.watch(mushafTextSizeProvider);
    final downloadState = ref.watch(fontDownloadControllerProvider);
    final chromeVisible = ref.watch(mushafChromeVisibleProvider);

    // متابعة تلقائية لصفحة الصوت الجاري — راجع توثيق [_followAudioToAyah].
    ref.listen<QuranAudioState>(quranAudioControllerProvider, (prev, next) {
      if (!next.isActive || !next.isPlaying) return;
      final ayahId = next.currentAyahId;
      if (ayahId == null || ayahId == prev?.currentAyahId) return;
      unawaited(_followAudioToAyah(ayahId));
    });

    // طلب قفز خارجي (متشابهات مثلاً) — راجع توثيق [mushafJumpRequestProvider].
    ref.listen<MushafJumpRequest?>(mushafJumpRequestProvider, (prev, next) {
      if (next != null && next.nonce != prev?.nonce) _handleJumpRequest(next);
    });

    int? pickerPendingFrom;
    if (widget.pickingHifzRange) {
      // بمجرّد اكتمال طرفَي النطاق (`completedFrom`/`completedTo`) نُغلِق
      // الشاشة بالنتيجة — `HifzScreen` هي من تستدعي `startHifzPlan` بعدها.
      ref.listen<HifzPickerState>(hifzPickerProvider, (prev, next) {
        if (next.completedFrom != null && next.completedTo != null) {
          Navigator.of(
            context,
          ).pop((from: next.completedFrom!, to: next.completedTo!));
        }
      });
      pickerPendingFrom = ref.watch(
        hifzPickerProvider.select((s) => s.pendingFrom),
      );
    }
    // شريط "باقي X صفحة" **مستقل عن طبعة التنزيل النشطة بشاشة التنزيل**
    // (`FontDownloadState.activeEdition`) — يتبع طبعة المصحف المختارة
    // فعلياً حالياً (`mushafFontEditionProvider`) دايماً، ويتبدّل تلقائياً
    // لعدّاد الطبعة الجديدة فور تبديلها بالإعدادات (بطلب صاحب المشروع).
    final currentFontEdition = ref.watch(mushafFontEditionProvider);
    final (downloadableFirst, downloadableLast) = downloadableRangeFor(currentFontEdition);
    final totalDownloadable = downloadableLast - downloadableFirst + 1;
    final downloadedCountAsync = ref.watch(fontDownloadedCountProvider(currentFontEdition));
    final missingPages = totalDownloadable - (downloadedCountAsync.value ?? 0);
    final bulkRunningForCurrentEdition =
        downloadState.isBulkRunning && downloadState.activeEdition == currentFontEdition;
    final showDownloadBanner =
        !_dismissedFontDownloadBanners.contains(currentFontEdition.name) &&
        !bulkRunningForCurrentEdition &&
        downloadedCountAsync.hasValue &&
        missingPages > 0;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          if (widget.pickingHifzRange)
            Container(
              width: double.infinity,
              color: AppColors.teal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickerPendingFrom == null
                            ? 'اختر آية البداية للحفظ'
                            : 'اختر آية النهاية',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.qiyamSessionMode)
            Container(
              width: double.infinity,
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.bedtime_outlined,
                      color: themeAccent(context),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'جلسة قيام جارية — ${ref.watch(qiyamSessionProvider.select((s) => s.ayahCount))} آية',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _endQiyamSession,
                      child: Text(
                        'إنهاء الجلسة',
                        style: TextStyle(color: themeAccent(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // شريط رفيع سطر واحد (بدل `MaterialBanner` القديم الكبير بحشوة
          // ٨+صف أزرار كاملة) — بلاغ صاحب المشروع "مزعج وماخذ مساحة".
          // "تجاهل" **دائم لكل طبعة على حدة** (`_fontDownloadBannerDismissedKey`)
          // لا جلسة واحدة فقط — يظهر مرّة لكل طبعة، يختفي نهائياً بعد
          // "لاحقاً" أو × **لتلك الطبعة تحديداً**، والعدّاد نفسه يتبع طبعة
          // المصحف الحالية دايماً (`fontDownloadedCountProvider`).
          if (showDownloadBanner)
            SafeArea(
              bottom: false,
              child: Container(
                height: 34,
                color: themeAccent(context).withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.cloud_download_outlined, size: 15, color: themeAccent(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'باقي $missingPages صفحة تحتاج تنزيلاً للعمل بلا إنترنت',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontSize: 11.5),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        _dismissDownloadBannerPermanently(currentFontEdition);
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => FontDownloadScreen(edition: currentFontEdition)),
                        );
                      },
                      child: Text(
                        'تنزيل',
                        style: TextStyle(
                          color: themeAccent(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 15),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      color: fg.withValues(alpha: 0.6),
                      onPressed: () => _dismissDownloadBannerPermanently(currentFontEdition),
                    ),
                  ],
                ),
              ),
            ),
          _PageIdentityBar(
            bg: bg,
            fg: fg,
            page: _currentPage,
            onSurahTap: _openSurahIndex,
            onJuzTap: _openJuzIndex,
          ),
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _handlePageTap,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: kMushafPageCount,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final page = index + 1;
                      return RepaintBoundary(
                        key: ValueKey('mushaf_page_${page}_${textSize.name}'),
                        child: MushafPageWidget(page: page),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: _ChromeSlide(
                    visible: chromeVisible,
                    fromTop: true,
                    child: _TopChromeBar(
                      bg: bg,
                      fg: fg,
                      currentPage: _currentPage,
                      onSurahIndex: _openSurahIndex,
                      onSearch: _openSearch,
                      onSave: _saveCurrentPageBookmark,
                      onReadWithTafsir: _openTafsirReading,
                      onSettings: _openSettings,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 74,
                  right: 0,
                  left: 0,
                  child: _ChromeSlide(
                    visible: chromeVisible,
                    fromTop: false,
                    child: _BottomChromeBar(
                      bg: bg,
                      fg: fg,
                      currentPage: _currentPage,
                      onJump: _jumpTo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// يغلّف شريطاً عائماً بحركة ظهور/اختفاء (انزلاق + شفافية)، ويمنع لمسه
/// (`IgnorePointer`) حين مخفيّاً حتى لا يحجب اللمس عن الصفحة تحته رغم بقائه
/// بالشجرة لأجل الحركة السلسة.
class _ChromeSlide extends StatelessWidget {
  const _ChromeSlide({
    required this.visible,
    required this.fromTop,
    required this.child,
  });
  final bool visible;
  final bool fromTop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hiddenOffset = Offset(0, fromTop ? -1.1 : 1.1);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: _kChromeAnim,
        curve: Curves.easeInOut,
        offset: visible ? Offset.zero : hiddenOffset,
        child: AnimatedOpacity(
          duration: _kChromeAnim,
          opacity: visible ? 1 : 0,
          child: child,
        ),
      ),
    );
  }
}

/// الشريط العلوي العائم: فهرس السور، رقم الصفحة، بحث، قراءة مع التفسير، الإعدادات.
class _TopChromeBar extends StatelessWidget {
  const _TopChromeBar({
    required this.bg,
    required this.fg,
    required this.currentPage,
    required this.onSurahIndex,
    required this.onSearch,
    required this.onSave,
    required this.onReadWithTafsir,
    required this.onSettings,
  });

  final Color bg;
  final Color fg;
  final int currentPage;
  final VoidCallback onSurahIndex;
  final VoidCallback onSearch;
  final VoidCallback onSave;
  final VoidCallback onReadWithTafsir;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Material(
        color: bg.withValues(alpha: 0.96),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              // فهرس السور
              IconButton(
                key: mushafSurahIndexButtonKey,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                iconSize: 20,
                icon: Icon(Icons.list_alt_outlined, color: fg),
                tooltip: 'فهرس السور',
                onPressed: onSurahIndex,
              ),
              // رقم الصفحة (عرض فقط — القفز لصفحة محدَّدة عبر الشريط السفلي `onJump`)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'صفحة $currentPage',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
              // بحث
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                iconSize: 20,
                icon: Icon(Icons.search, color: fg),
                tooltip: 'بحث',
                onPressed: onSearch,
              ),
              // قراءة مع التفسير — تمرير طولي متواصل، كل آية وتحتها تفسيرها
              IconButton(
                key: mushafTafsirReadingButtonKey,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                iconSize: 20,
                icon: Icon(Icons.menu_book_outlined, color: fg),
                tooltip: 'قراءة مع التفسير',
                onPressed: onReadWithTafsir,
              ),
              // الإعدادات
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                iconSize: 20,
                icon: Icon(Icons.settings_outlined, color: fg),
                tooltip: 'الإعدادات',
                onPressed: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الشريط السفلي العائم: شريط تنقّل الصفحات/الجزء (`_PageNavStrip`، جديد)
/// فوق شريط الصوت الحالي (`QuranAudioBar` — بلا تغيير بمنطقه، يختفي وحده
/// لو لا تشغيل جارٍ)، يظهران/يختفيان معاً بنفس حركة الشريط العلوي.
class _BottomChromeBar extends StatelessWidget {
  const _BottomChromeBar({
    required this.bg,
    required this.fg,
    required this.currentPage,
    required this.onJump,
  });
  final Color bg;
  final Color fg;
  final int currentPage;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageNavStrip(
            bg: bg,
            fg: fg,
            currentPage: currentPage,
            onJump: onJump,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            key: mushafAudioBarKey,
            borderRadius: BorderRadius.circular(18),
            child: const QuranAudioBar(),
          ),
        ],
      ),
    );
  }
}

/// شريط هوية الصفحة: الجزء/الربع (بجهة) · اسم السورة (بالجهة المقابلة) +
/// زرَّي حفظ/إعدادات — **دائم الظهور** (بخلاف `_TopChromeBar`/
/// `_BottomChromeBar` المتبدّلين مع لمسة الصفحة). **تبويبان منفصلان
/// بالفهرس** بطلب صاحب المشروع: لمسة اسم السورة تفتح الفهرس على تبويب
/// السور (مظلَّلة السورة الحالية، [onSurahTap] →
/// `MushafScreen._openSurahIndex`)، ولمسة الجزء/الربع تفتحه على تبويب
/// الأجزاء مباشرة على الجزء الحالي بربعه ([onJuzTap] →
/// `MushafScreen._openJuzIndex`). **لون الإطار يتبع لوحة الصفحة المختارة**
/// ([fg]) بدل ذهبي ثابت — بطلب صاحب المشروع "لونه بيتغيّر حسب اللون
/// المختار للصفحة" (راجع `mushaf_palettes.dart`). **إطار مستطيل بهوامش
/// جانبية وحواف مدوَّرة** (`Border.all` + `BorderRadius.circular(12)`) —
/// بطلب صاحب المشروع (٢٠٢٦-٠٩-٠١) الرجوع للشكل الأول المعتمَد، بعد جولة
/// إطار "مصحف المدينة" المزخرَف (`MushafTopHeaderPainter`، حُذف بهالطلب —
/// راجع الجولة الموثَّقة أعلى الملف لو احتاجه أحد لاحقاً). زرّا الحفظ/
/// الإعدادات انتقلا لـ`_TopChromeBar` (الشريط العائم المتبدّل، راجع
/// توثيقهما هناك)، فهالشريط صار مخصَّصاً بالكامل لهوية الصفحة بلا عناصر
/// تحكّم إضافية تزاحمه.
class _PageIdentityBar extends ConsumerStatefulWidget {
  const _PageIdentityBar({
    required this.bg,
    required this.fg,
    required this.page,
    required this.onSurahTap,
    required this.onJuzTap,
  });
  final Color bg;
  final Color fg;
  final int page;
  final VoidCallback onSurahTap;
  final VoidCallback onJuzTap;

  @override
  ConsumerState<_PageIdentityBar> createState() => _PageIdentityBarState();
}

class _PageIdentityBarState extends ConsumerState<_PageIdentityBar> {
  // آخر قيم **محلولة فعلياً** (لا لحظة تحميل) — تبقى محفوظة هون بين
  // إعادات البناء المتتالية أثناء التقليب السريع بين الصفحات. بدونها،
  // كل تصفّح صفحة جديدة يطلب provider جديد بمفتاح [Widget.page] المختلف
  // (`_pageSurahIdProvider(page)` مثلاً) يبدأ بحالة تحميل فارغة للحظة —
  // ولمّا كان الكود القديم يلجأ لقيمة افتراضية `?? 1` بتلك اللحظة، كان
  // يُظهر "الفاتحة" ومضاً خاطئاً قبل استقرار الاسم الصحيح (بلاغ صاحب
  // المشروع). هلق: نعرض آخر اسم/جزء **حقيقي** معروف طوال فترة التحميل
  // القصيرة، ولا نحدّثه إلا لمّا يصل فعلاً رقم/اسم الصفحة الجديدة —
  // فيتغيّر مرّة واحدة نظيفة عند الاستقرار، لا وميض بالمنتصف.
  int? _lastSurahId;
  String? _lastSurahText;
  String? _lastJuzText;
  String? _lastHizbFraction;

  @override
  Widget build(BuildContext context) {
    final juzAsync = ref.watch(_pageJuzProvider(widget.page));
    final hizbAsync = ref.watch(_pageHizbProvider(widget.page));
    final rubAsync = ref.watch(_pageRubProvider(widget.page));
    final surahAsync = ref.watch(_pageSurahNameProvider(widget.page));
    final surahIdAsync = ref.watch(_pageSurahIdProvider(widget.page));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final bg = widget.bg;
    final fg = widget.fg;
    final onSurahTap = widget.onSurahTap;
    final onJuzTap = widget.onJuzTap;

    if (juzAsync.hasValue) _lastJuzText = 'الجُزْءُ ${juzAsync.value}';
    if (hizbAsync.hasValue && rubAsync.hasValue) {
      _lastHizbFraction = _hizbFractionText(rubAsync.value!, hizbAsync.value!);
    }
    if (surahAsync.hasValue) _lastSurahText = 'سُورَةُ ${surahShortName(surahAsync.value!)}';
    if (surahIdAsync.hasValue) _lastSurahId = surahIdAsync.value;

    final String juzText = _lastJuzText ?? '';
    final String hizbFraction = _lastHizbFraction ?? '';
    final String surahText = _lastSurahText ?? '';
    final int? surahId = _lastSurahId;

    // شريط هوية الصفحة — إطار **متصل** واحد (بدل شريحتين منفصلتين + خط
    // سفلي فقط سابقاً): حدّ كامل حول الشريط بأكمله + خط فاصل عمودي واحد
    // بالنص يقسمه لمنطقتَي الجزء/اسم السورة، فيُقرأ كقطعة واحدة متماسكة لا
    // عنصرين طائفين. **بلا أي حركة/تحوّل** — كان فيه تلاشٍ+انزلاق بسيط مع
    // كل تصفّح صفحة (`AnimatedSwitcher`)، أُزيل بطلب صاحب المشروع (مزعج
    // مع التصفّح السريع المتكرر).
    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                // لمسة الجزء / الحزب
                Expanded(
                  child: InkWell(
                    onTap: onJuzTap,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            juzText,
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (hizbFraction.isNotEmpty) ...[
                            Container(
                              width: 3.5,
                              height: 3.5,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              hizbFraction,
                              style: TextStyle(
                                color: fg.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // الخط الفاصل — يوصل الإطارين ببعض بصرياً كقطعة واحدة
                Container(width: 1, height: 24, color: accent.withValues(alpha: 0.28)),

                // لمسة اسم السورة
                Expanded(
                  child: InkWell(
                    onTap: onSurahTap,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                    child: Center(
                      // `surahId == null` فقط أول رسمة إطلاقاً قبل حلّ أي
                      // provider مرّة — سريع جداً (استعلام SQLite محلي)،
                      // فراغ لحظي بلا وميض اسم خاطئ أفضل من عرض الفاتحة
                      // افتراضياً (كان السلوك القديم).
                      child: surahId == null
                          ? const SizedBox.shrink()
                          : Semantics(
                        label: surahText,
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // نفس غليف "سورة" + اسم السورة العثماني
                              // (SurahNameV4) المستخدَم بصفحة المصحف
                              // والفهرس — بدل نص AmiriQuran، بطلب صاحب
                              // المشروع.
                              Text(
                                'surah-icon',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFF3DA8E)
                                      : const Color(0xFF1B3022),
                                  fontSize: 19,
                                  fontFamily: 'SurahNameV4',
                                  fontFeatures: const [FontFeature.enable('liga')],
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'surah${surahId.toString().padLeft(3, '0')}',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFF3DA8E)
                                      : const Color(0xFF1B3022),
                                  fontSize: 19,
                                  fontFamily: 'SurahNameV4',
                                  fontFeatures: const [FontFeature.enable('liga')],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 18,
                                color: fg.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط تنقّل عائم بكل الـ٦٠٤ صفحة (لا نافذة محدودة حول الحالية كسابقاً)
/// — يُظهر/يُخفى مع باقي الشريط السفلي (`_BottomChromeBar`). **السحب اليدوي
/// الطبيعي بالقائمة هو آلية "الانتقال بالسحب لأي صفحة" المطلوبة**: عند
/// توقّف السحب/الرمي (`ScrollEndNotification`) نحسب أي صفحة استقرّت بمنتصف
/// الشريط ونقفز إليها فعلياً بالمصحف (`widget.onJump`) — الضغط المباشر على
/// رقم صفحة يبقى مسموحاً أيضاً لقفزة دقيقة فورية بلا سحب. اسم السورة/الحزب
/// يُعرَضان أعلى الشريط (بيانات حقيقية، راجع `_pageSurahNameProvider`/
/// `_pageHizbProvider` أعلى الملف).
class _PageNavStrip extends ConsumerStatefulWidget {
  const _PageNavStrip({
    required this.bg,
    required this.fg,
    required this.currentPage,
    required this.onJump,
  });
  final Color bg;
  final Color fg;
  final int currentPage;
  final ValueChanged<int> onJump;

  @override
  ConsumerState<_PageNavStrip> createState() => _PageNavStripState();
}

class _PageNavStripState extends ConsumerState<_PageNavStrip> {
  static const double _itemExtent = 36;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final viewport = _scrollController.position.viewportDimension;
        final target = _offsetFor(
          widget.currentPage,
          viewport > 0 ? viewport : MediaQuery.sizeOf(context).width - 20,
        ).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(target);
      }
    });
  }

  double _offsetFor(int page, double viewport) =>
      (page - 1) * _itemExtent - viewport / 2 + _itemExtent / 2;

  @override
  void didUpdateWidget(covariant _PageNavStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage &&
        _scrollController.hasClients) {
      final target = _offsetFor(
        widget.currentPage,
        _scrollController.position.viewportDimension,
      ).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// عند استقرار السحب: أي صفحة بمنتصف الشريط الآن؟ يقفز إليها فعلياً
  /// بالمصحف لو تغيّرت — هذا ما يترجم "سحب الشريط" لـ"تصفّح المصحف" فعلياً.
  void _handleScrollEnd() {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final centerOffset = _scrollController.offset + viewport / 2;
    final page =
        (centerOffset / _itemExtent).round().clamp(0, kMushafPageCount - 1) + 1;
    if (page != widget.currentPage) widget.onJump(page);
  }

  @override
  Widget build(BuildContext context) {
    final juzAsync = ref.watch(_pageJuzProvider(widget.currentPage));
    final hizbAsync = ref.watch(_pageHizbProvider(widget.currentPage));
    final surahAsync = ref.watch(_pageSurahNameProvider(widget.currentPage));
    final fg = widget.fg;

    return Material(
      color: widget.bg.withValues(alpha: 0.96),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  juzAsync.maybeWhen(data: (j) => 'ج $j', orElse: () => ''),
                  style: TextStyle(
                    color: fg,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    surahAsync.maybeWhen(data: (n) => n, orElse: () => ''),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'AmiriQuran',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hizbAsync.maybeWhen(
                    data: (h) => 'الحزب $h',
                    orElse: () => '',
                  ),
                  style: TextStyle(
                    color: fg,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 26,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // **`dragDetails != null` إلزامي** — باج حلقة لا نهائية
                  // حقيقي مُكتشَف: `didUpdateWidget` أدناه يستدعي
                  // `_scrollController.animateTo(...)` لإعادة توسيط الشريط
                  // برمجياً عند تغيّر الصفحة؛ هذا الـ`animateTo` نفسه يُطلِق
                  // `ScrollEndNotification` عند اكتماله (بلا فرق ظاهري عن
                  // سحبة يد فعلية بدون هذا الشرط) — فيستدعي `_handleScrollEnd`
                  // يحسب "الصفحة المُمركَزة" وقد يختلف بفارق تقريب بسيط عن
                  // `widget.currentPage`، فيقفز لصفحة قريبة → يُعيد توسيط
                  // الشريط برمجياً من جديد → `ScrollEndNotification` أخرى...
                  // حلقة تصفّح لا نهائية بلا أي تدخّل مستخدم (كانت تُظهر
                  // شاشة "عالقة" لا تستجيب للسحب فعلياً + إعادة رسم متواصلة
                  // بمعدّل الإطار). `dragDetails` بـ`ScrollEndNotification`
                  // غير `null` **فقط** لو السبب سحبة/رمية يد فعلية — القيمة
                  // الرسمية الموثَّقة بـFlutter للتفريق بين توقّف سحب حقيقي
                  // وتوقّف تمرير برمجي (`animateTo`/`jumpTo`).
                  if (notification is ScrollEndNotification &&
                      notification.dragDetails != null) {
                    _handleScrollEnd();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemExtent: _itemExtent,
                  itemCount: kMushafPageCount,
                  itemBuilder: (context, i) {
                    final p = i + 1;
                    final active = p == widget.currentPage;
                    return Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => widget.onJump(p),
                        child: Container(
                          width: 30,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? themeAccent(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$p',
                            style: TextStyle(
                              color: active
                                  ? AppColors.navyDeep
                                  : fg.withValues(alpha: 0.7),
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
