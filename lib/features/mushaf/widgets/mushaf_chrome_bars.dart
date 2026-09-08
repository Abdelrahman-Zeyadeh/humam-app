import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/quran/quran_providers.dart';
import '../../../core/text/arabic_normalizer.dart' show surahShortName;
import '../../../core/theme/app_colors.dart';
import '../../onboarding/onboarding_target_keys.dart';
import '../quran_audio_bar.dart';
import '../mushaf_screen.dart' show kMushafPageCount;
import '../mushaf_settings.dart';

/// أشرطة/شرائط المصحف العائمة والدائمة — استُخرجت من `mushaf_screen.dart`
/// أثناء تفكيك الملف بلا أي تغيير سلوكي: كل هذي الودجتات كانت أصلاً
/// خاصة (`_`) وذاتية الاعتماد بالكامل (بارامترات/دوال رجوع فقط، بلا لمس
/// مباشر لحالة `_MushafScreenState`)، فتحوّلت لأسماء علنية (`ChromeSlide`،
/// `TopChromeBar`، `BottomChromeBar`، `PageIdentityBar`، `PageNavStrip`)
/// ليمكن استخدامها من ملف آخر.

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
/// هوية الصفحة (`PageIdentityBar` أسفل). مستقل عن `_surahNameProvider`
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
/// (`PageIdentityBar`)، بدل الاكتفاء بالاسم النصي أعلاه.
final _pageSurahIdProvider = FutureProvider.family<int, int>((ref, page) async {
  final ayahs = await ref.watch(quranRepositoryProvider).ayahsForPage(page);
  return ayahs.isEmpty ? 1 : ayahs.first.surah;
});

/// يغلّف شريطاً عائماً بحركة ظهور/اختفاء (انزلاق + شفافية)، ويمنع لمسه
/// (`IgnorePointer`) حين مخفيّاً حتى لا يحجب اللمس عن الصفحة تحته رغم بقائه
/// بالشجرة لأجل الحركة السلسة.
class ChromeSlide extends StatelessWidget {
  const ChromeSlide({
    super.key,
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
class TopChromeBar extends StatelessWidget {
  const TopChromeBar({
    super.key,
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
              // وضع الحفظ الذاتي وإخفاء الآيات
              Consumer(
                builder: (context, ref, _) {
                  final isHifzMode = ref.watch(memorizationModeProvider);
                  final accent = themeAccent(context);
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                    iconSize: 20,
                    icon: Icon(
                      isHifzMode ? Icons.visibility_off_rounded : Icons.visibility_outlined,
                      color: isHifzMode ? accent : fg,
                    ),
                    tooltip: isHifzMode ? 'إيقاف وضع اختبار الحفظ' : 'بدء وضع اختبار الحفظ والتسميع',
                    onPressed: () => ref.read(memorizationModeProvider.notifier).toggle(),
                  );
                },
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

/// الشريط السفلي العائم: شريط تنقّل الصفحات/الجزء (`PageNavStrip`، جديد)
/// فوق شريط الصوت الحالي (`QuranAudioBar` — بلا تغيير بمنطقه، يختفي وحده
/// لو لا تشغيل جارٍ)، يظهران/يختفيان معاً بنفس حركة الشريط العلوي.
class BottomChromeBar extends StatelessWidget {
  const BottomChromeBar({
    super.key,
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
          PageNavStrip(
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
/// زرَّي حفظ/إعدادات — **دائم الظهور** (بخلاف `TopChromeBar`/
/// `BottomChromeBar` المتبدّلين مع لمسة الصفحة). **تبويبان منفصلان
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
/// الإعدادات انتقلا لـ`TopChromeBar` (الشريط العائم المتبدّل، راجع
/// توثيقهما هناك)، فهالشريط صار مخصَّصاً بالكامل لهوية الصفحة بلا عناصر
/// تحكّم إضافية تزاحمه.
class PageIdentityBar extends ConsumerStatefulWidget {
  const PageIdentityBar({
    super.key,
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
  ConsumerState<PageIdentityBar> createState() => _PageIdentityBarState();
}

class _PageIdentityBarState extends ConsumerState<PageIdentityBar> {
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
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 3),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
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
/// — يُظهر/يُخفى مع باقي الشريط السفلي (`BottomChromeBar`). **السحب اليدوي
/// الطبيعي بالقائمة هو آلية "الانتقال بالسحب لأي صفحة" المطلوبة**: عند
/// توقّف السحب/الرمي (`ScrollEndNotification`) نحسب أي صفحة استقرّت بمنتصف
/// الشريط ونقفز إليها فعلياً بالمصحف (`widget.onJump`) — الضغط المباشر على
/// رقم صفحة يبقى مسموحاً أيضاً لقفزة دقيقة فورية بلا سحب. اسم السورة/الحزب
/// يُعرَضان أعلى الشريط (بيانات حقيقية، راجع `_pageSurahNameProvider`/
/// `_pageHizbProvider` أعلى الملف).
class PageNavStrip extends ConsumerStatefulWidget {
  const PageNavStrip({
    super.key,
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
  ConsumerState<PageNavStrip> createState() => _PageNavStripState();
}

class _PageNavStripState extends ConsumerState<PageNavStrip> {
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
  void didUpdateWidget(covariant PageNavStrip oldWidget) {
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
