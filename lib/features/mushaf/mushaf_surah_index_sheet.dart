import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart' show RubDetail;
import '../../core/text/arabic_normalizer.dart'
    show sanitizeSurahNameForDisplay, stripQuranicMarksForDisplay;
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import 'mushaf_screen.dart' show kMushafPageCount;

enum _IndexTab { surahs, juz }

/// أي جزء يضمّ صفحة معيّنة — يبحث بترتيب الأجزاء تصاعدياً عن آخر جزء
/// صفحة بدايته `<=` الصفحة المطلوبة. `juzStarts` مرتّبة بالفعل (`juz` ١..٣٠
/// بترتيب الاستعلام بـ`QuranRepository.juzStartPages`، و`LinkedHashMap`
/// يحفظ ترتيب الإدراج) — يُستخدَم لإدراج فواصل "الجزء N" بقائمة السور.
int _juzForPage(Map<int, int> juzStarts, int page) {
  var result = 1;
  for (final entry in juzStarts.entries) {
    if (entry.value <= page) {
      result = entry.key;
    } else {
      break;
    }
  }
  return result;
}

Color _surface(BuildContext c) => AppCard.surface(c);
Color _border(BuildContext c) => AppCard.border(c);
Color _soft(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.inkSoftOnDark : AppColors.inkSoft;

/// نافذة سفلية بفهرس المصحف: تبويبان (السور/الأجزاء — "الصفحات" أُلغيت
/// بطلب صاحب المشروع)، بطاقات مدوّرة بظل ناعم بدل قوائم `ListTile` بخطوط
/// فاصلة عادية. تُرجع رقم الصفحة عند اختيار أي عنصر — الاستدعاء يقفز
/// إليها بالمصحف. [currentPage] يحدّد أي سورة/جزء يُظلَّل ويُمرَّر إليه
/// تلقائياً عند الفتح (راجع `_PageIdentityBar` بـ`mushaf_screen.dart`: لمسة
/// اسم السورة تفتح هون بـ[openJuzTab]=false، لمسة الجزء/الحزب بـ`true`).
class MushafSurahIndexSheet extends ConsumerStatefulWidget {
  const MushafSurahIndexSheet({super.key, required this.currentPage, this.openJuzTab = false});
  final int currentPage;
  final bool openJuzTab;

  static Future<int?> show(BuildContext context, {required int currentPage, bool openJuzTab = false}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => MushafSurahIndexSheet(currentPage: currentPage, openJuzTab: openJuzTab),
    );
  }

  @override
  ConsumerState<MushafSurahIndexSheet> createState() => _MushafSurahIndexSheetState();
}

class _MushafSurahIndexSheetState extends ConsumerState<MushafSurahIndexSheet> {
  late _IndexTab _tab = widget.openJuzTab ? _IndexTab.juz : _IndexTab.surahs;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('فهرس المصحف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface)),
            const SizedBox(height: 12),
            // **بطاقة "فاصل الصفحة" أُزيلت من هون** — بطلب صاحب المشروع
            // "شيله من الفهرس لأن التقدم محفوظ أصلاً" (كانت تكراراً: نفس
            // فاصلة `BookmarkTypes.reading` ظاهرة أصلاً بشاشة "الفواصل"
            // (`bookmarks_screen.dart`)، وزر الحفظ نفسه بشريط هوية الصفحة
            // صار يخزّنها أيضاً بالعلامات المرجعية العامة — راجع توثيق
            // `MushafScreen._saveCurrentPageBookmark`).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // بديل عن `SegmentedButton`: شرائح عربية (خصوصاً مع علامة
              // الاختيار) ما كانت تسع بعرض الشاشة — `SegmentedButton` لا
              // "يقلّص" نفسه ليطابق العرض المتاح، فيفيض ببساطة. صف بعرض
              // متساوٍ إجباري (`Expanded` لكل شريحة) يضمن عدم الفيضان أياً
              // كان طول النص. **تبويب "الصفحات" أُلغي** (بطلب صاحب المشروع
              // "الغي خانة الصفحات وخلي خانة السور بدالها") — "السور" الآن
              // أول شريحة (بدل مكان "الصفحات") وهي المختارة افتراضياً.
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _surface(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: _border(context))),
                child: Row(
                  children: [
                    for (final tab in _IndexTab.values)
                      Expanded(
                        child: _TabSegment(
                          label: switch (tab) { _IndexTab.juz => 'الأجزاء', _IndexTab.surahs => 'السور' },
                          selected: _tab == tab,
                          onTap: () => setState(() => _tab = tab),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: switch (_tab) {
                _IndexTab.juz => _JuzTab(currentPage: widget.currentPage),
                _IndexTab.surahs => _SurahsTab(currentPage: widget.currentPage),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// شريحة تبويب واحدة من صف التبويبات المخصَّص — راجع تعليق استبدال
/// `SegmentedButton` أعلاه لسبب وجودها.
class _TabSegment extends StatelessWidget {
  const _TabSegment({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: selected ? themeAccent(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? AppColors.navy : onSurface),
          ),
        ),
      ),
    );
  }
}

/// عنوان بطاقة سورة بفهرس السور — "سُورَةُ" نصاً عادياً (AmiriQuran) +
/// غليف اسم السورة الزخرفي (SurahNameV4، نفس خط بانر اسم السورة بصفحة
/// المصحف — راجع `mushaf_page_widget.dart`) بدل النص العثماني العادي،
/// لمطابقة بصرية بين الفهرس والمصحف (بطلب صاحب المشروع). [name] الحقيقي
/// يبقى Semantics label لقارئ الشاشة (الغليف نفسه بلا معنى نصي حقيقي).
Widget _surahTitleWidget(
  BuildContext context, {
  required int surahId,
  required String name,
  required bool highlighted,
}) {
  final color = highlighted ? Colors.white : Theme.of(context).colorScheme.onSurface;
  return Semantics(
    label: name,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // `surah-icon` من نفس خط SurahNameV4 — نفس الرسم العثماني الأصيل
          // لغليف "سورة" بدل نص AmiriQuran (بطلب صاحب المشروع، راجع
          // توثيق `mushaf_page_widget.dart`).
          Text(
            'surah-icon',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontFamily: 'SurahNameV4',
              fontFeatures: const [FontFeature.enable('liga')],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'surah${surahId.toString().padLeft(3, '0')}',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontFamily: 'SurahNameV4',
              fontFeatures: const [FontFeature.enable('liga')],
            ),
          ),
        ],
      ),
    ),
  );
}

/// بطاقة صف موحَّدة للتبويبات الثلاثة — شارة دائرية ملوَّنة + عنوان/عنوان
/// فرعي + طرف اختياري، حاوية مدوّرة بظل ناعم بدل `ListTile`+`Divider`
/// (بطلب صاحب المشروع "تعديل شكل فهرس المصحف... تصميم البطاقات الجديد").
class _IndexCard extends StatelessWidget {
  const _IndexCard({
    super.key,
    this.badgeText,
    this.badgeColor,
    this.badgeWidget,
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.trailing,
    this.titleFontFamily,
    this.highlighted = false,
    required this.onTap,
  }) : assert(badgeWidget != null || (badgeText != null && badgeColor != null), 'مرِّر إما badgeWidget أو badgeText+badgeColor');
  final String? badgeText;
  final Color? badgeColor;
  /// شارة مخصَّصة تحل محل الدائرة النصية الافتراضية — راجع
  /// `_QuarterCircleBadge` بـ`_RubList` لمثال (دائرة كسرية بدل رقم).
  final Widget? badgeWidget;
  final String title;
  /// بديل اختياري لعرض [title] الافتراضي (`Text` بخط [titleFontFamily]) —
  /// تستخدمه بطاقات السور لعرض خط "سُورَةُ" الزخرفي V4 (راجع
  /// `_surahTitleWidget` بالأسفل)؛ [title] يبقى مُمرَّراً دايماً كـSemantics
  /// label بغضّ النظر (قارئ الشاشة يقرأ الاسم الحقيقي دايماً).
  final Widget? titleWidget;
  final String? subtitle;
  final String? trailing;
  /// `true` = هذه البطاقة تطابق الموقع الحالي بالمصحف (السورة/الجزء
  /// الحالي) — تُملأ بخلفية ذهبية صريحة بدل الحد الفاتح المعتاد، بطلب
  /// صاحب المشروع "زي الصورة" (تصميم مرجعي: صف مظلَّل داكن للسورة الحالية
  /// بفهرس السور).
  final bool highlighted;
  /// خط عرض اختياري للعنوان فقط — أسماء السور (`nameAr`) مشكولة بالرسم
  /// القرآني الأصيل (ألف خنجرية `U+0670`، وسورة الإسراء فيها علامة ضبط
  /// قرآنية خاصة `U+06E1`)، وخط الواجهة العام (Cairo) لا يعرضهما بشكل
  /// صحيح فيظهران "مقطوعين/مكسورين". الحل هون: خط `AmiriQuran` المُضمَّن
  /// أصلاً للبسملة (مصمَّم خصيصاً للرسم العثماني، يدعم هذه العلامات
  /// كاملة) بدل تحريف التسمية الأصيلة أو الاكتفاء بتجريدها من علاماتها.
  final String? titleFontFamily;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = highlighted ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final subtitleColor = highlighted ? Colors.white.withValues(alpha: 0.85) : _soft(context);
    final badgeBg = highlighted ? Colors.white.withValues(alpha: 0.22) : badgeColor?.withValues(alpha: 0.15);
    final badgeFg = highlighted ? Colors.white : badgeColor;
    return Material(
      color: highlighted ? themeAccent(context) : _surface(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: highlighted ? themeAccent(context) : _border(context)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              badgeWidget ??
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                    child: Text(badgeText!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeFg)),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // `height: 1.5` مقصودة: أسماء السور (`nameAr`) مشكولة
                    // بالكامل ("سُوْرَةُ الْفَاتِحَةِ") بحركات متراكبة (شدّة+حركة
                    // فوق نفس الحرف أحياناً) — بلا ارتفاع سطر إضافي كانت
                    // الحركات العلوية تُقصّ بصرياً لأن صندوق النص لا يترك
                    // مساحة كافية فوق الحرف الأساسي.
                    titleWidget ??
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: titleFontFamily == 'AmiriQuran' ? FontWeight.normal : FontWeight.w700,
                            fontSize: titleFontFamily == 'AmiriQuran' ? 17.5 : 14.5,
                            height: 1.35,
                            fontFamily: titleFontFamily,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.4), textDirection: TextDirection.rtl),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(trailing!, style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SurahsTab extends ConsumerStatefulWidget {
  const _SurahsTab({required this.currentPage});
  final int currentPage;

  @override
  ConsumerState<_SurahsTab> createState() => _SurahsTabState();
}

class _SurahsTabState extends ConsumerState<_SurahsTab> {
  String _query = '';
  // مفتاح بطاقة السورة الحالية — يُستخدَم للتمرير التلقائي إليها بعد أول
  // رسم (`Scrollable.ensureVisible`) بدل حساب إزاحة يدوي (ارتفاع البطاقة
  // متغيّر مع فواصل الأجزاء المُدرَجة بينها). مرة واحدة فقط لكل فتحة
  // للشيت — راجع [_scrolledToCurrent].
  final _currentItemKey = GlobalKey();
  bool _scrolledToCurrent = false;

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(_allSurahsProvider);
    final juzStartsAsync = ref.watch(_juzStartPagesProvider);
    final currentSurahId = ref.watch(_currentSurahIdProvider(widget.currentPage)).value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ابحث باسم السورة...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: _surface(context),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border(context))),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: surahsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('تعذّر تحميل فهرس السور')),
            data: (surahs) {
              final filtered = _query.isEmpty ? surahs : surahs.where((s) => s.nameAr.contains(_query) || s.nameArPlain.contains(_query)).toList();
              if (filtered.isEmpty) return const Center(child: Text('لا نتائج'));

              // تمرير تلقائي للسورة الحالية — فقط بلا بحث فعّال (نتائج
              // البحث لها ترتيب/عدد مختلف، لا معنى للتمرير التلقائي فيها)،
              // ومرة واحدة فقط (`_scrolledToCurrent`) حتى لا يقاطع تمرير
              // المستخدم اليدوي اللاحق بإعادة بناء الودجت.
              if (!_scrolledToCurrent && _query.isEmpty && currentSurahId != null) {
                _scrolledToCurrent = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final ctx = _currentItemKey.currentContext;
                  if (ctx != null && mounted) {
                    Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
                  }
                });
              }

              final juzStarts = _query.isEmpty ? juzStartsAsync.value : null;
              int? lastJuz;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final s = filtered[i];
                  final isCurrent = s.id == currentSurahId;

                  // فاصل "الجزء N" — يظهر فقط أول سورة يبدأ جزء جديد عندها
                  // أو قبلها (بطلب صاحب المشروع "زي الصورة": فاصل جزء يظهر
                  // وسط قائمة السور المسطّحة، لا تبويب منفصل).
                  Widget? juzDivider;
                  if (juzStarts != null) {
                    final juz = _juzForPage(juzStarts, s.startPage);
                    if (juz != lastJuz) {
                      juzDivider = _JuzDividerLabel(juz: juz);
                      lastJuz = juz;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (juzDivider != null) juzDivider,
                        _IndexCard(
                          key: isCurrent ? _currentItemKey : null,
                          highlighted: isCurrent,
                          badgeText: '${s.id}',
                          badgeColor: themeAccent(context),
                          title: sanitizeSurahNameForDisplay(s.nameAr),
                          titleWidget: _surahTitleWidget(
                            context,
                            surahId: s.id,
                            name: sanitizeSurahNameForDisplay(s.nameAr),
                            highlighted: isCurrent,
                          ),
                          subtitle: '${s.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'} · ${s.ayahCount} آية',
                          trailing: 'ص ${s.startPage}',
                          onTap: () => Navigator.of(context).pop(s.startPage),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// فاصل "الجزء N" وسط قائمة السور المسطّحة — راجع توثيق استخدامه بـ
/// [_SurahsTabState.build].
class _JuzDividerLabel extends StatelessWidget {
  const _JuzDividerLabel({required this.juz});
  final int juz;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('الجزء $juz', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: onSurface.withValues(alpha: 0.7))),
          const SizedBox(width: 6),
          Container(width: 2, height: 14, decoration: BoxDecoration(color: themeAccent(context), borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }
}

class _JuzTab extends ConsumerStatefulWidget {
  const _JuzTab({required this.currentPage});
  final int currentPage;

  @override
  ConsumerState<_JuzTab> createState() => _JuzTabState();
}

class _JuzTabState extends ConsumerState<_JuzTab> {
  int? _expandedJuz;
  // مرة واحدة فقط: أول جزء تصله بيانات الجزء الحالي يوسِّعه ويمرِّر إليه
  // تلقائياً — بطلب صاحب المشروع "لما يضغط على الجزء فوق يعطيه الربع
  // الحالي". تعديل `_expandedJuz` هون مباشرة (لا `setState`) آمن: يحصل
  // أثناء نفس مسار `build` قبل استخدامه، ومرة واحدة بفضل هذا الحارس —
  // نفس نمط `_PageNavStripState.initState` (حساب تحليلي بلا `setState`).
  bool _initialized = false;
  final _currentJuzKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final juzAsync = ref.watch(_juzStartPagesProvider);
    final currentJuz = ref.watch(_currentJuzProvider(widget.currentPage)).value;

    if (!_initialized && currentJuz != null) {
      _initialized = true;
      _expandedJuz = currentJuz;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _currentJuzKey.currentContext;
        if (ctx != null && mounted) {
          Scrollable.ensureVisible(ctx, alignment: 0.1, duration: const Duration(milliseconds: 300));
        }
      });
    }

    // **لا أسماء أجزاء تقليدية هون عمداً** (الأسماء المتعارفة "الم"،
    // "سيقول"...) — ذاكرة النموذج بها احتمال خطأ لا يليق بتطبيق مصحف؛
    // رقم الجزء + رقم الصفحة كافيان، ومصدرهما `quran.db` نفسه لا نص مكتوب
    // بالكود.
    return juzAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('تعذّر تحميل فهرس الأجزاء')),
      data: (starts) => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: starts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final juz = i + 1;
          final page = starts[juz];
          final expanded = _expandedJuz == juz;
          final isCurrent = juz == currentJuz;
          return Column(
            key: isCurrent ? _currentJuzKey : null,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IndexCard(
                highlighted: isCurrent,
                badgeText: '$juz',
                badgeColor: AppColors.blue,
                title: 'الجزء $juz',
                // "ص X" لفتح الجزء مباشرة يبقى بالضغط على البطاقة نفسها؛
                // أيقونة التوسيع لعرض الأرباع الأربعة منفصلة عمداً (فتح
                // الأرباع لا يجب أن يقفز للمصحف بالخطأ، وبالعكس).
                trailing: page == null ? null : 'ص $page',
                onTap: page == null ? null : () => Navigator.of(context).pop(page),
              ),
              InkWell(
                onTap: () => setState(() => _expandedJuz = expanded ? null : juz),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        // "تفاصيل الأحزاب" لا "الأرباع الأربعة" — كل جزء
                        // حزبان، وكل حزب ٤ أرباع (٨ إجمالاً)، راجع توثيق
                        // [_RubList].
                        expanded ? 'إخفاء التفاصيل' : 'عرض تفاصيل الأحزاب',
                        style: TextStyle(fontSize: 11.5, color: _soft(context), fontWeight: FontWeight.w600),
                      ),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: _soft(context)),
                    ],
                  ),
                ),
              ),
              if (expanded) _RubList(juz: juz, juzStarts: starts, currentPage: isCurrent ? widget.currentPage : null),
            ],
          );
        },
      ),
    );
  }
}

/// تسمية الربع التقليدية بالمصحف ضمن حزبه — راجع توثيق [_RubList].
const _kHizbQuarterLabel = {1: 'ربع الحزب', 2: 'نصف الحزب', 3: 'ثلاثة أرباع الحزب', 4: 'الحزب كاملاً'};

/// أرباع الحزبين (٨ دوماً — كل جزء حزبان، وكل حزب ٤ أرباع، **تحقّق مباشر
/// بالبيانات**: `Ayahs.rub` ١..٢٤٠ = ٤ لكل حزب بالضبط ٦٠×٤). **مجمَّعة
/// بفاصل "الحزب N" بين مجموعتَي الأرباع الأربعة** — بطلب صاحب المشروع "كل
/// حزب والثاني فاصل، يعني ما يكون الربع الخامس هو الربع الثاني من الحزب
/// الثاني" (كانت مسطَّحة ١..٨ بلا تمييز حزب سابقاً). كل بطاقة: شارة دائرية
/// مملوءة بنسبة الربع ضمن حزبه ([_QuarterCircleBadge])، نص الآية الأولى،
/// اسم سورتها ورقم آيتها، ومدى صفحاتها (بداية الربع التالي/الجزء التالي
/// ناقص ١، أو آخر صفحة بالمصحف لآخر ربع). [currentPage] (لو غير `null`، أي
/// هذا جزء الصفحة الحالية) يحدّد أي ربع يُظلَّل.
class _RubList extends ConsumerWidget {
  const _RubList({required this.juz, required this.juzStarts, this.currentPage});
  final int juz;
  final Map<int, int> juzStarts;
  final int? currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rubAsync = ref.watch(_rubDetailsProvider(juz));
    return rubAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (rubs) {
        int? currentRubInJuz;
        if (currentPage != null) {
          for (final r in rubs) {
            if (r.startPage <= currentPage!) {
              currentRubInJuz = r.rubInJuz;
            } else {
              break;
            }
          }
        }

        // نهاية صفحات ربع = بداية الربع التالي ناقص ١، أو بداية الجزء
        // التالي ناقص ١ لآخر ربع بهالجزء، أو آخر صفحة بالمصحف لو آخر جزء.
        int endPageFor(int index) {
          if (index < rubs.length - 1) return rubs[index + 1].startPage - 1;
          final nextJuzStart = juzStarts[juz + 1];
          return nextJuzStart != null ? nextJuzStart - 1 : kMushafPageCount;
        }

        final children = <Widget>[];
        int? lastHizb;
        for (var i = 0; i < rubs.length; i++) {
          final r = rubs[i];
          final hizb = r.startAyah.hizb ?? 0;
          final quarterInHizb = ((r.startAyah.rub ?? 1) - 1) % 4 + 1;
          final isCurrentRub = r.rubInJuz == currentRubInJuz;
          if (hizb != lastHizb) {
            children.add(_HizbDividerLabel(hizb: hizb));
            lastHizb = hizb;
          }
          final surahName = ref.watch(_surahNameProvider(r.startAyah.surah)).value;
          final endPage = endPageFor(i);
          final pageRange = endPage > r.startPage ? 'ص ${r.startPage}-$endPage' : 'ص ${r.startPage}';
          children.add(
            _IndexCard(
              highlighted: isCurrentRub,
              badgeWidget: _QuarterCircleBadge(
                fraction: quarterInHizb / 4,
                color: AppColors.teal,
                highlighted: isCurrentRub,
              ),
              // نص الآية نفسه بدل وصف رقمي مجرَّد — بطلب صاحب المشروع
              // "معلومات الربع تكون زي اللي بالصورة".
              title: stripQuranicMarksForDisplay(r.startAyah.textUthmani),
              titleFontFamily: 'AmiriQuran',
              subtitle: surahName == null
                  ? _kHizbQuarterLabel[quarterInHizb]
                  : '$surahName : آية ${r.startAyah.ayah} — ${_kHizbQuarterLabel[quarterInHizb]}',
              trailing: pageRange,
              onTap: () => Navigator.of(context).pop(r.startPage),
            ),
          );
          children.add(const SizedBox(height: 6));
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(children: children),
        );
      },
    );
  }
}

/// فاصل "الحزب N" بين مجموعتَي أرباع الجزء — راجع توثيق [_RubList].
class _HizbDividerLabel extends StatelessWidget {
  const _HizbDividerLabel({required this.hizb});
  final int hizb;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(1.5))),
          const SizedBox(width: 6),
          Text('الحزب $hizb', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: onSurface.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

/// شارة دائرية مملوءة بنسبة [fraction] (٠٫٢٥/٠٫٥/٠٫٧٥/١) — بطلب صاحب
/// المشروع "دائرة شكلها حسب الربع، أول النصف وهيك" بدل شارة نصية. قطاع
/// مملوء (لا حلقة تقدّم) يبدأ من الأعلى (١٢ بالساعة) باتجاه عقارب الساعة.
class _QuarterCircleBadge extends StatelessWidget {
  const _QuarterCircleBadge({required this.fraction, required this.color, required this.highlighted});
  final double fraction;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: CustomPaint(
        painter: _QuarterCirclePainter(fraction: fraction, color: highlighted ? Colors.white : color),
      ),
    );
  }
}

class _QuarterCirclePainter extends CustomPainter {
  const _QuarterCirclePainter({required this.fraction, required this.color});
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.18));
    if (fraction >= 1) {
      canvas.drawCircle(center, radius, Paint()..color = color);
      return;
    }
    if (fraction <= 0) return;
    final sweep = fraction * 2 * pi;
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -pi / 2, sweep, false)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _QuarterCirclePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

final _currentSurahIdProvider = FutureProvider.family<int, int>((ref, page) async {
  final ayahs = await ref.watch(quranRepositoryProvider).ayahsForPage(page);
  return ayahs.isEmpty ? 1 : ayahs.first.surah;
});

final _currentJuzProvider = FutureProvider.family<int, int>((ref, page) async {
  final ayahs = await ref.watch(quranRepositoryProvider).ayahsForPage(page);
  return ayahs.isEmpty ? 1 : ayahs.first.juz;
});

final _surahNameProvider = FutureProvider.family<String, int>((ref, surahId) async {
  final surah = await ref.watch(quranRepositoryProvider).surahById(surahId);
  return surah.nameArPlain;
});

final _allSurahsProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).allSurahs();
});

final _juzStartPagesProvider = FutureProvider<Map<int, int>>((ref) {
  return ref.watch(quranRepositoryProvider).juzStartPages();
});

final _rubDetailsProvider = FutureProvider.family<List<RubDetail>, int>((ref, juz) {
  return ref.watch(quranRepositoryProvider).rubDetailsForJuz(juz);
});
