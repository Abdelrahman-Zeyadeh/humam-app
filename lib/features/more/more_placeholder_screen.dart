import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/tool_usage_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../azkar/tasbih_screen.dart';
import '../fasting/ui/fasting_assistant_screen.dart';
import '../groups/ui/groups_hub_screen.dart';
import '../hadith/hadith_hub_screen.dart';
import '../hifz/hifz_screen.dart';
import '../hijri/hijri_calendar_screen.dart';
import '../home/weekly_report_screen.dart';
import '../khatma/khatma_screen.dart';
import '../mushaf/bookmarks_screen.dart';
import '../mushaf/notes_screen.dart';
import '../names_of_allah/names_of_allah_screen.dart';
import '../prayer/qibla_screen.dart';
import '../profile/achievements_screen.dart';
import '../profile/profile_stats_screen.dart';
import '../qiyam/qiyam_screen.dart';
import '../radio/radio_and_duroos_screen.dart';
import '../tajweed/ui/tajweed_screen.dart';
import 'reminders_screen.dart';
import '../onboarding/onboarding_target_keys.dart';
import '../settings/settings_screen.dart';
import '../wrapped/ui/faith_wrapped_screen.dart';

/// أداة داخل مركز الأدوات
class _ToolItem {
  const _ToolItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    required this.color,
    required this.onTap,
    this.featured = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final String category;
  final Color color;
  final void Function(BuildContext context, WidgetRef ref) onTap;

  /// ميزة رئيسية بالتطبيق (خطة ختمة/حفظ) — تُميَّز بصرياً عن باقي
  /// الأدوات البسيطة داخل نفس الفئة بدل ما تكون بنفس الوزن حرفياً.
  final bool featured;
}

/// تعريف فئة الأدوات
class _CategoryDef {
  const _CategoryDef({
    required this.title,
    required this.icon,
    required this.color,
    required this.darkColor,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color darkColor;
}

/// يشتق درجة (أفتح/أغمق) من لون فئة الأداة الأساسي حسب موقع الأداة
/// ضمن فئتها — بدل تلوين كل أداة بلون عشوائي منفصل بلا نظام (كانت أيقونات
/// "أدواتي" خليطاً من بنفسجي/أخضر/برتقالي/وردي بلا رابط)، فتنتمي كل أدوات
/// نفس الفئة لعائلة لونية واحدة بتدرجات فقط. `index`/`count` يحدّدان موقع
/// الأداة ضمن ترتيب فئتها لتوزيع التدرّج بالتساوي.
Color _toolShade(Color base, int index, int count) {
  final hsl = HSLColor.fromColor(base);
  final spread = count <= 1 ? 0.0 : (index / (count - 1) - 0.5) * 0.36;
  final lightness = (hsl.lightness + spread).clamp(0.16, 0.82);
  return hsl.withLightness(lightness).toColor();
}

const List<_CategoryDef> _kToolCategories = [
  _CategoryDef(
    title: 'عبادات وطاعات',
    icon: Icons.notifications_none_outlined,
    color: Color(0xFF9E7A3E),
    darkColor: Color(0xFFD4AF67),
  ),
  _CategoryDef(
    title: 'الصحبة والمنافسة',
    icon: Icons.people_alt_outlined,
    color: Color(0xFF3F8275),
    darkColor: Color(0xFF64B5A5),
  ),
  _CategoryDef(
    title: 'المكتبة والعلوم',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF6A5787),
    darkColor: Color(0xFFA592C2),
  ),
];

/// شاشة أدواتي — تصميم القوائم المبوّبة النظيفة مع شريط البحث والأكثر استخداماً والملف الشخصي
class MorePlaceholderScreen extends ConsumerStatefulWidget {
  const MorePlaceholderScreen({super.key});

  @override
  ConsumerState<MorePlaceholderScreen> createState() =>
      _MorePlaceholderScreenState();
}

class _MorePlaceholderScreenState extends ConsumerState<MorePlaceholderScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  /// الفئات المفتوحة حالياً — كلها **مفتوحة افتراضياً** بطلب صريح لاحق
  /// (تراجع عن قرار سابق كانت كلها مطوية فيه) — بعد دمج عناصر الحديث
  /// الثلاثة بمدخل واحد وتقليص القائمة، صار عدد العناصر الإجمالي أصغر بما
  /// يكفي لعرضها كلها دفعة وحدة بلا إرباك، ويوفّر ضغطة إضافية لكل فتح.
  late final Set<String> _openCategories = _kToolCategories
      .map((c) => c.title)
      .toSet();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleCategory(String title) {
    setState(() {
      if (!_openCategories.remove(title)) {
        _openCategories.add(title);
      }
    });
  }

  /// يسجّل ضغطة الاستخدام لتغذية إحصائيات الأدوات
  void _handleToolTap(BuildContext context, WidgetRef ref, _ToolItem tool) {
    tool.onTap(context, ref);
    ref.read(toolUsagePrefsProvider).recordTap(tool.id).then((_) {
      if (context.mounted) {
        ref.read(toolUsageVersionProvider.notifier).bump();
      }
    });
  }

  List<_ToolItem> _getAllTools() => [
    // 1. عبادات وطاعات — الختمة والحفظ أولاً ومميَّزتان (`featured`): أكبر
    // ميزتين بالتطبيق (خطط متعددة، جدولة، تتبّع تقدّم) لا يجوز تكونا بنفس
    // وزن أداة بسيطة كالقبلة أو التقويم بقائمة طويلة.
    _ToolItem(
      id: 'khatma',
      title: 'خطة الختمة',
      icon: Icons.bookmark_outline,
      category: 'عبادات وطاعات',
      color: _toolShade(_kToolCategories[0].color, 0, 8),
      featured: true,
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const KhatmaScreen())),
    ),
    _ToolItem(
      id: 'hifz',
      title: 'خطة الحفظ والمراجعة',
      icon: Icons.sticky_note_2_outlined,
      category: 'عبادات وطاعات',
      color: _toolShade(_kToolCategories[0].color, 1, 8),
      featured: true,
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const HifzScreen())),
    ),
    _ToolItem(
      id: 'qibla',
      title: 'اتجاه القبلة',
      icon: Icons.explore_outlined,
      category: 'عبادات وطاعات',
      color: _toolShade(_kToolCategories[0].color, 2, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const QiblaScreen())),
    ),
    // رجّعتها بطلب صريح — بشرط توجيه مباشر لشاشة `TasbihScreen` المستقلة
    // (لا `AzkarLibraryScreen` العامة كالسابق، كانت مطابقة حرفياً لتبويب
    // "الأذكار" السفلي فاعتُبرت تكراراً؛ هالمرة وجهة مختلفة فعلياً).
    _ToolItem(
      id: 'tasbih',
      title: 'المسبحة الإلكترونية',
      icon: Icons.grain_rounded,
      category: 'عبادات وطاعات',
      color: _toolShade(_kToolCategories[0].color, 3, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const TasbihScreen())),
    ),
    _ToolItem(
      id: 'hijri',
      title: 'التقويم الهجري',
      icon: Icons.calendar_today_outlined,
      category: 'عبادات وطاعات',
      color: _toolShade(_kToolCategories[0].color, 4, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const HijriCalendarScreen())),
    ),
    _ToolItem(
      id: 'qiyam',
      title: 'قيام الليل والوتر',
      icon: Icons.nights_stay_outlined,
      category: 'عبادات وطاعات',
      color: _toolShade(_kToolCategories[0].color, 5, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const QiyamScreen())),
    ),
    _ToolItem(
      id: 'fasting',
      title: 'مساعد صيام التطوع',
      icon: Icons.dark_mode_outlined,
      category: 'عبادات وطاعات',
      color: _toolShade(_kToolCategories[0].color, 6, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const FastingAssistantScreen())),
    ),
    // نُقلت من شاشة الإعدادات بالكامل بطلب صريح — التذكيرات كلها هون
    // بمكان واحد الآن (كانت موزَّعة داخل الإعدادات نفسها)، راجع
    // `reminders_screen.dart`.
    _ToolItem(
      id: 'reminders',
      title: 'التذكيرات',
      icon: Icons.notifications_active_outlined,
      category: 'عبادات وطاعات',
      color: _toolShade(_kToolCategories[0].color, 7, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const RemindersScreen())),
    ),

    // 2. الصحبة والمنافسة
    _ToolItem(
      id: 'groups',
      title: 'مجموعات التنافس',
      icon: Icons.people_outline,
      category: 'الصحبة والمنافسة',
      color: _toolShade(_kToolCategories[1].color, 0, 4),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const GroupsHubScreen())),
    ),
    _ToolItem(
      id: 'weekly_report',
      title: 'التقرير الأسبوعي',
      icon: Icons.bar_chart_rounded,
      category: 'الصحبة والمنافسة',
      color: _toolShade(_kToolCategories[1].color, 1, 4),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const WeeklyReportScreen())),
    ),
    _ToolItem(
      id: 'faith_wrapped',
      title: 'التقرير الإيماني المرئي (Wrapped)',
      icon: Icons.auto_awesome_rounded,
      category: 'الصحبة والمنافسة',
      color: _toolShade(_kToolCategories[1].color, 2, 4),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const FaithWrappedScreen())),
    ),
    // جديد — تجميع بصري لكل سلاسل الاستمرار الموجودة أصلاً (`CategoryStreaks`)
    // بشكل أوسمة/درجات، بلا أي جدول قاعدة بيانات جديد. راجع `AchievementsScreen`.
    _ToolItem(
      id: 'achievements',
      title: 'الإنجازات والأوسمة',
      icon: Icons.emoji_events_outlined,
      category: 'الصحبة والمنافسة',
      color: _toolShade(_kToolCategories[1].color, 3, 4),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const AchievementsScreen())),
    ),

    // 3. المكتبة والعلوم
    _ToolItem(
      id: 'bookmarks',
      title: 'العلامات المرجعية',
      icon: Icons.bookmark_outline,
      category: 'المكتبة والعلوم',
      color: _toolShade(_kToolCategories[2].color, 0, 6),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const BookmarksScreen())),
    ),
    _ToolItem(
      id: 'notes',
      title: 'ملاحظاتي',
      icon: Icons.edit_note_rounded,
      category: 'المكتبة والعلوم',
      color: _toolShade(_kToolCategories[2].color, 1, 6),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const NotesScreen())),
    ),
    // ثلاثة عناصر سابقة ("موسوعة الحديث"/"التحقق من صحة الحديث"/"حديث
    // اليوم والفوائد") دُمجت بمدخل واحد بطلب صريح لتقليل زحمة هالقائمة —
    // راجع تعليق `HadithHubScreen` لتفاصيل قرار الدمج (بطاقات لا تبويبات).
    // إحصاء "الأكثر استخداماً" لأي ضغطة قديمة على المعرّفات الثلاثة
    // القديمة تُتجاهَل بأمان تلقائياً (نفس آلية `radio_duroos` أعلاه).
    _ToolItem(
      id: 'hadith_hub',
      title: 'الحديث الشريف',
      icon: Icons.menu_book_outlined,
      category: 'المكتبة والعلوم',
      color: _toolShade(_kToolCategories[2].color, 2, 6),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const HadithHubScreen())),
    ),
    _ToolItem(
      id: 'names_of_allah',
      title: 'أسماء الله الحسنى والتدبر',
      icon: Icons.auto_awesome_rounded,
      category: 'المكتبة والعلوم',
      color: _toolShade(_kToolCategories[2].color, 3, 6),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const NamesOfAllahScreen())),
    ),
    // نُقل من قسم "الصلاة والتذكيرات" بالإعدادات (بطلب صريح) — أحكام
    // التجويد وألوانه علم قرآني عام، مالوش علاقة بالصلاة/الأذان، فمكانه
    // الطبيعي هون مع بقية أدوات "المكتبة والعلوم". راجع `TajweedScreen`.
    _ToolItem(
      id: 'tajweed',
      title: 'أحكام التجويد والضبط',
      icon: Icons.menu_book_outlined,
      category: 'المكتبة والعلوم',
      color: _toolShade(_kToolCategories[2].color, 4, 6),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const TajweedScreen())),
    ),
    _ToolItem(
      // id جديد مقصود (لا 'radio' ولا 'duroos') — الاثنان دُمجا بشاشة واحدة
      // بتبويبين (`RadioAndDuroosScreen`، بطلب صريح لتقليل زحمة هالقائمة).
      // إحصاء "الأكثر استخدامًا" لأي ضغطة قديمة على المعرّفين السابقين
      // تُتجاهَل بأمان تلقائياً (`byId[id] case final tool?` بأسفل هالملف
      // يرشّح أي id غير موجود بالقائمة الحالية — نفس آلية حذفيات سابقة).
      id: 'radio_duroos',
      title: 'الإذاعة والدروس الصوتية',
      icon: Icons.radio_outlined,
      category: 'المكتبة والعلوم',
      color: _toolShade(_kToolCategories[2].color, 5, 6),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const RadioAndDuroosScreen())),
    ),

    // فئة "خدمات وتخصيص" (كانت آخر فئة) صارت فاضية بالكامل وأُزيلت —
    // "التلاوات المحملة"/"الإعدادات العامة"/"دليل دقة الأذان"/"عن هُمَام"
    // أُزيلت سابقاً (تكرار مع الإعدادات/الترس)، و"استوديو بطاقات الآيات
    // والستوري" أُزيل بطلب صريح لاحق (يُفتح من داخل شاشة "مشاركة" الآية
    // مباشرة — زر 🎨 بـ`ayah_share_sheet.dart` — فمش محتاج مدخل مستقل هون).
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final allTools = _getAllTools();
    final dividerColor = isDark
        ? const Color(0xFF243040)
        : const Color(0xFFECE5D6);

    final filteredTools = _searchQuery.trim().isEmpty
        ? allTools
        : allTools
              .where(
                (t) =>
                    t.title.contains(_searchQuery.trim()) ||
                    t.category.contains(_searchQuery.trim()),
              )
              .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // هيدر بتدرّج مطابق لأسلوب لوحة التصميم المعتمدة — `AppBar` عادي
        // بلا لمس هيكل الجسم، فقط زُيِّن بصرياً (`flexibleSpace`).
        appBar: GradientAppBar(
          title: 'أدواتي',
          centerTitle: true,
          colors: const [AppColors.blue, AppColors.navy],
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'الإعدادات',
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 100),
          children: [
            // 1. بطاقة الملف الشخصي البارزة أعلى الشاشة
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _ProfileHeaderCard(),
            ),

            // 2. شريط البحث التفاعلي في الأدوات
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2630)
                      : const Color(0xFFF3EFE6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? AppColors.lineDark : AppColors.line)
                        .withValues(alpha: 0.6),
                  ),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث في الأدوات والخدمات...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: themeAccent(context),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // في حال البحث: عرض النتائج مباشرة
            if (_searchQuery.trim().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'نتائج البحث (${filteredTools.length})',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ),
              if (filteredTools.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'لم يتم العثور على أي أداة مطابقة للبحث',
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              else
                for (int i = 0; i < filteredTools.length; i++) ...[
                  _ToolListTile(
                    tool: filteredTools[i],
                    isDark: isDark,
                    onTap: () => _handleToolTap(context, ref, filteredTools[i]),
                  ),
                  if (i < filteredTools.length - 1)
                    Divider(height: 1, thickness: 0.7, color: dividerColor),
                ],
            ] else ...[
              // 3. قسم الأكثر استخداماً
              _PinnedMostUsedSection(
                allTools: allTools,
                isDark: isDark,
                onToolTap: (t) => _handleToolTap(context, ref, t),
              ),

              // 4. القوائم المبوّبة القابلة للطي
              for (
                int catIdx = 0;
                catIdx < _kToolCategories.length;
                catIdx++
              ) ...[
                Builder(
                  builder: (context) {
                    final category = _kToolCategories[catIdx];
                    final catTools = allTools
                        .where((t) => t.category == category.title)
                        .toList();
                    if (catTools.isEmpty) return const SizedBox.shrink();

                    final catColor = isDark
                        ? category.darkColor
                        : category.color;
                    final isOpen = _openCategories.contains(category.title);

                    return Column(
                      key: catIdx == 0
                          ? toolsKhatmaCardKey
                          : catIdx == 1
                              ? toolsGroupsCardKey
                              : catIdx == 2
                                  ? toolsHadithCardKey
                                  : null,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ترويسة الفئة القابلة للضغط للطي والفتح (اليمين: أيقونة مرقّمة + العنوان | الشمال: سهم الطي)
                        InkWell(
                          onTap: () => _toggleCategory(category.title),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                            child: Row(
                              children: [
                                // أيقونة الفئة داخل شارة دائرية ملوّنة — أكثر
                                // وضوحاً وتعبيراً من أيقونة صغيرة عارية بجانب
                                // النص، وتُميّز بداية كل فئة بصرياً بسرعة.
                                IconBadge(icon: category.icon, color: catColor, tintAlpha: 0.15),
                                const SizedBox(width: 10),
                                Text(
                                  category.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: catColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // عدد أدوات الفئة — يعطي فكرة سريعة عن حجمها
                                // قبل حتى التمرير خلالها.
                                Text(
                                  '(${catTools.length})',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: catColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                const Spacer(),
                                // سهم الدوران لحالة الطي/الفتح على الشمال في RTL
                                AnimatedRotation(
                                  duration: const Duration(milliseconds: 200),
                                  turns: isOpen ? 0 : 0.25,
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color:
                                        (isDark
                                                ? Colors.white70
                                                : const Color(0xFF6B5840))
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // محتوى الفئة القابل للطي والفتح
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: isOpen
                              ? Column(
                                  children: [
                                    for (
                                      int i = 0;
                                      i < catTools.length;
                                      i++
                                    ) ...[
                                      _ToolListTile(
                                        tool: catTools[i],
                                        isDark: isDark,
                                        onTap: () => _handleToolTap(
                                          context,
                                          ref,
                                          catTools[i],
                                        ),
                                      ),
                                      if (i < catTools.length - 1)
                                        Divider(
                                          height: 1,
                                          thickness: 0.7,
                                          color: dividerColor,
                                        ),
                                    ],
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        // فاصل أسفل نهاية كل فئة
                        Divider(height: 1, thickness: 0.7, color: dividerColor),
                      ],
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// قسم الأكثر استخداماً المثبّت أعلى القوائم
class _PinnedMostUsedSection extends ConsumerWidget {
  const _PinnedMostUsedSection({
    required this.allTools,
    required this.isDark,
    required this.onToolTap,
  });

  final List<_ToolItem> allTools;
  final bool isDark;
  final void Function(_ToolItem) onToolTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(mostUsedToolIdsProvider).value ?? const <String>[];
    if (ids.isEmpty) return const SizedBox.shrink();

    final byId = {for (final t in allTools) t.id: t};
    final pinned = [
      for (final id in ids)
        if (byId[id] case final tool?) tool,
    ];
    if (pinned.isEmpty) return const SizedBox.shrink();

    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: AppColors.goldDeep),
              const SizedBox(width: 6),
              Text(
                'الأكثر استخدامًا',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final tool in pinned)
                Expanded(
                  child: _PinnedToolTile(
                    tool: tool,
                    onTap: () => onToolTap(tool),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinnedToolTile extends StatelessWidget {
  const _PinnedToolTile({required this.tool, required this.onTap});

  final _ToolItem tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          children: [
            IconBadge(icon: tool.icon, color: tool.color, large: true, tintAlpha: 0.12),
            const SizedBox(height: 6),
            Text(
              tool.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الملف الشخصي البارزة أعلى شاشة الأدوات
class _ProfileHeaderCard extends ConsumerWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userNameVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final userName = userPrefs.userName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: isDark ? const Color(0xFF182230) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileStatsScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (isDark ? AppColors.lineDark : AppColors.line).withValues(
                alpha: 0.8,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [const Color(0xFF1C2736), const Color(0xFF131A24)]
                  : [const Color(0xFFFAF8F5), const Color(0xFFF0EAE0)],
            ),
          ),
          child: Row(
            children: [
              // الصورة الرمزية على اليمين
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.navy,
                backgroundImage:
                    (userPrefs.userAvatar.isNotEmpty &&
                        File(userPrefs.userAvatar).existsSync())
                    ? FileImage(File(userPrefs.userAvatar))
                    : null,
                child:
                    (userPrefs.userAvatar.isEmpty ||
                        !File(userPrefs.userAvatar).existsSync())
                    ? const Icon(Icons.person, color: AppColors.gold, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              // النصوص في المنتصف
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.trim().isEmpty
                          ? 'الملف الشخصي والإحصائيات'
                          : userName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'عرض إنجازاتك وسلاسل الاستمرار وسجل العبادات',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // السهم على الشمال
              Icon(
                Icons.chevron_left,
                color: onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنصر صف الأداة الواحد (اليمين: الأيقونة والعنوان | الشمال: سهم التنقل)
class _ToolListTile extends StatelessWidget {
  const _ToolListTile({
    required this.tool,
    required this.isDark,
    required this.onTap,
  });

  final _ToolItem tool;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // أيقونة الأداة داخل خلفية دائرية ملوّنة (على اليمين في RTL) —
            // بدل أيقونة عارية على الخلفية مباشرة، ليتماشى شكلها مع نمط
            // "الأكثر استخداماً" الدائري أعلى القائمة ويصير أكثر تعبيراً
            // بصرياً (وزن/تمييز لكل أداة بلونها الخاص).
            IconBadge(icon: tool.icon, color: tool.color, large: true, tintAlpha: 0.14),
            const SizedBox(width: 12),
            // عنوان الأداة (+ شارة "مميزة" للأدوات الرئيسية كالختمة/الحفظ)
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      tool.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  if (tool.featured) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'مميزة',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldDeep,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // سهم الانتقال (على الشمال في RTL)
            Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: isDark ? Colors.white24 : const Color(0xFFC7BEB0),
            ),
          ],
        ),
      ),
    );
  }
}
