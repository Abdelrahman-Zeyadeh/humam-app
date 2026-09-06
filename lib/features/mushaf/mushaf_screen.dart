import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/platform/dnd_service.dart';
import '../../core/data/user/user_repository.dart'
    show BookmarkTypes, UserCategories, UserRepository;
import '../../core/theme/app_colors.dart';
import '../../core/theme/mushaf_palettes.dart';
import '../audio/quran_audio_controller.dart';
import '../notifications/smart_reminder_sync.dart';
import '../settings/settings_screen.dart';
import 'font_download_screen.dart';
import 'font_download_service.dart';
import 'mushaf_page_widget.dart';
import 'mushaf_search_screen.dart';
import 'mushaf_settings.dart';
import 'mushaf_surah_index_sheet.dart';
import 'tafsir_reading_screen.dart';
import 'widgets/mushaf_chrome_bars.dart';

const int kMushafPageCount = 604;

/// مفتاح "طيّ" شريط تنبيه تنزيل الخطوط الباقية — **محفوظ بين الجلسات**
/// (كان قبلاً `bool` محلي بالودجت فقط، يرجع يظهر كل فتح تطبيق جديد رغم
/// ضغط "لاحقاً" — بلاغ صاحب المشروع "مزعج وماخذ مساحة"). **مستقل لكل طبعة**
/// (`.name` مضافاً لاحقة) — الشريط هلق يتبع طبعة المصحف المختارة فعلياً
/// (`fontDownloadedCountProvider`، لا V2 حصراً كالسابق)، فطيّه لطبعة لا
/// يطويه تلقائياً عن طبعة أخرى بعد تبديل الخط. **لم يعد إخفاءً نهائياً**
/// (تعديل لاحق: طلب صاحب المشروع تحويله لأيقونة صغيرة قابلة لإعادة الفتح
/// بدل الاختفاء الكامل) — راجع `_collapseDownloadBanner`/`_expandDownloadBanner`.
String _fontDownloadBannerDismissedKey(MushafFontEdition edition) =>
    'mushaf_font_download_banner_dismissed_${edition.name}';

/// شاشة عرض المصحف: تقليب أفقي بين الصفحات (٦٠٤ صفحة)، كل صفحة تُبنى
/// وتُحمَّل خطها عند زيارتها فقط. الاتجاه العام RTL (مضبوط بجذر التطبيق)
/// فيخلي السحب الطبيعي يقدّم للصفحة التالية بترتيب المصحف.
///
/// **قراءة غامرة:** لا `AppBar` تقليدياً — عناصر التحكّم (فهرس السور،
/// رقم الصفحة، وضع الحفظ، بحث، حجم الخط، الوضع الليلي، وشريط الصوت)
/// شريطان عائمان (`TopChromeBar`/`BottomChromeBar`) فوق الصفحة مباشرة،
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
  /// أسماء طبعات (`MushafFontEdition.name`) طوى المستخدم شريط تنزيلها
  /// لأيقونة صغيرة — راجع توثيق [_fontDownloadBannerDismissedKey]. **لم
  /// يعد "إخفاء نهائي"** كما كان سابقاً (بلاغ: الشريط الكامل يزعج بعد أول
  /// ظهور) — بل طيّ قابل للتراجع: أيقونة صغيرة تبقى ظاهرة طالما فيه صفحات
  /// ناقصة فعلياً، والضغط عليها يعيد فتح الشريط الكامل من جديد.
  final Set<String> _collapsedFontDownloadBanners = {};
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
        _collapsedFontDownloadBanners.add(edition.name);
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
      // يدوياً من الشريط العلوي (`TopChromeBar.onToggleMemorization`)، لكن
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

    // وضع "لا تُزعجني وقت القراءة" — يفعّل الكتم فقط لو الإعداد مفعّل
    // **والتصريح ممنوح فعلاً** (`DndService` تتحقّق داخلياً وتفشل بصمت
    // بدونه). لا يُطبَّق بأوضاع اختيار نطاق حفظ فرعية (`pickingHifzRange`)
    // لأنها شاشة مؤقتة جداً تُفتح وتُغلَق بثوانٍ ضمن تدفّق آخر أصلاً.
    if (ref.read(userPrefsProvider).dndWhileReadingEnabled &&
        !widget.pickingHifzRange) {
      unawaited(DndService.setActive(true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _highlightClearTimer?.cancel();
    _readingLogIdleTimer?.cancel();
    _flushReadingLog();
    if (ref.read(userPrefsProvider).dndWhileReadingEnabled &&
        !widget.pickingHifzRange) {
      unawaited(DndService.setActive(false));
    }
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
  /// الحالي وربعه — راجع توثيق [PageIdentityBar] لسبب فصل هذا عن
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

  /// يطوي شريط "تنزيل الخطوط الباقية" لأيقونة صغيرة **لهذه الطبعة تحديداً**
  /// (لا لهالجلسة فقط، ولا لبقية الطبعات) — محفوظ فيبقى مطوياً بعد إعادة
  /// فتح التطبيق أيضاً. راجع توثيق [_fontDownloadBannerDismissedKey] أعلى
  /// الملف و[_expandDownloadBanner] للعملية العكسية.
  void _collapseDownloadBanner(MushafFontEdition edition) {
    setState(() => _collapsedFontDownloadBanners.add(edition.name));
    ref.read(sharedPreferencesProvider).setBool(_fontDownloadBannerDismissedKey(edition), true);
  }

  /// يعيد فتح الشريط الكامل بعد طيّه لأيقونة — الضغط على الأيقونة الصغيرة.
  void _expandDownloadBanner(MushafFontEdition edition) {
    setState(() => _collapsedFontDownloadBanners.remove(edition.name));
    ref.read(sharedPreferencesProvider).setBool(_fontDownloadBannerDismissedKey(edition), false);
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
    final downloadBannerRelevant =
        !bulkRunningForCurrentEdition && downloadedCountAsync.hasValue && missingPages > 0;
    final showDownloadBanner =
        downloadBannerRelevant && !_collapsedFontDownloadBanners.contains(currentFontEdition.name);
    final showCollapsedDownloadIcon =
        downloadBannerRelevant && _collapsedFontDownloadBanners.contains(currentFontEdition.name);

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
          // الطيّ **دائم لكل طبعة على حدة** (`_fontDownloadBannerDismissedKey`)
          // لا جلسة واحدة فقط، لكنه **قابل للتراجع** (بخلاف "تجاهل نهائي"
          // السابق) — × يطويه لأيقونة صغيرة (`showCollapsedDownloadIcon`
          // بالأسفل) تبقى ظاهرة بدل الاختفاء الكامل، والضغط عليها يعيد فتح
          // الشريط الكامل. العدّاد نفسه يتبع طبعة المصحف الحالية دايماً
          // (`fontDownloadedCountProvider`).
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
                        _collapseDownloadBanner(currentFontEdition);
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
                      tooltip: 'طيّ الشريط',
                      icon: const Icon(Icons.close, size: 15),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      color: fg.withValues(alpha: 0.6),
                      onPressed: () => _collapseDownloadBanner(currentFontEdition),
                    ),
                  ],
                ),
              ),
            ),
          // أيقونة صغيرة بديلة عن الشريط الكامل بعد طيّه — راجع توثيق
          // `_collapseDownloadBanner`/`_expandDownloadBanner`. تبقى ظاهرة
          // طالما فيه صفحات ناقصة فعلياً، بمساحة أقل بكثير من الشريط.
          if (showCollapsedDownloadIcon)
            SafeArea(
              bottom: false,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10, top: 4),
                  child: Material(
                    color: themeAccent(context).withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _expandDownloadBanner(currentFontEdition),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.cloud_download_outlined,
                          size: 16,
                          color: themeAccent(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          PageIdentityBar(
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
                  child: ChromeSlide(
                    visible: chromeVisible,
                    fromTop: true,
                    child: TopChromeBar(
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
                  child: ChromeSlide(
                    visible: chromeVisible,
                    fromTop: false,
                    child: BottomChromeBar(
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
