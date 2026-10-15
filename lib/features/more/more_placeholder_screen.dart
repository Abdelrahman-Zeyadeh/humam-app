import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/tool_usage_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/text/arabic_normalizer.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../azkar/tasbih_screen.dart';
import '../fasting/ui/fasting_assistant_screen.dart';
import '../groups/ui/groups_hub_screen.dart';
import '../hadith/hadith_books_screen.dart';
import '../hifz/hifz_mushaf_screen.dart';
import '../hifz/hifz_screen.dart';
import '../hifz/mutashabihat_screen.dart';
import '../hijri/hijri_calendar_screen.dart';
import '../home/weekly_report_screen.dart';
import '../khatma/khatma_screen.dart';
import '../mushaf/bookmarks_screen.dart';
import '../mushaf/notes_screen.dart';
import '../names_of_allah/names_of_allah_screen.dart';
import '../prayer/qibla_screen.dart';
import '../duroos/duroos_screen.dart';
import '../profile/achievements_screen.dart';
import '../profile/profile_stats_screen.dart';
import '../qiyam/qiyam_screen.dart';
import '../radio/quran_radio_screen.dart';
import '../tajweed/ui/tajweed_screen.dart';
import 'reminders_screen.dart';
import '../notifications/notifications_screen.dart';
import '../onboarding/onboarding_target_keys.dart';
import '../settings/permissions_guide_screen.dart';
import '../settings/settings_screen.dart';
import '../story_maker/ui/ayah_story_maker_screen.dart';
import '../hadith_verification/ui/hadith_verification_screen.dart';
import '../wallpapers/wallpapers_screen.dart';

/// أداة داخل مركز الأدوات
class _ToolItem {
  const _ToolItem({
    required this.id,
    required this.title,
    this.nameEn = '',
    this.keywords = const [],
    required this.icon,
    required this.category,
    required this.color,
    required this.onTap,
    this.featured = false,
  });

  final String id;
  final String title;
  final String nameEn;
  final List<String> keywords;
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
    title: 'القرآن والتعليم',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF2E7D32),
    darkColor: Color(0xFF81C784),
  ),
  _CategoryDef(
    title: 'الحديث الشريف',
    icon: Icons.verified_outlined,
    color: Color(0xFF1E88E5),
    darkColor: Color(0xFF64B5F6),
  ),
  _CategoryDef(
    title: 'العبادة والشعائر',
    icon: Icons.nights_stay_outlined,
    color: Color(0xFF9E7A3E),
    darkColor: Color(0xFFD4AF67),
  ),
  _CategoryDef(
    title: 'المجتمع والمتابعة',
    icon: Icons.emoji_events_outlined,
    color: Color(0xFF3F8275),
    darkColor: Color(0xFF64B5A5),
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

  late Set<String> _openCategories;
  bool _openCategoriesInitialized = false;

  void _initOpenCategoriesIfNeeded() {
    if (_openCategoriesInitialized) return;
    _openCategoriesInitialized = true;
    _openCategories = _kToolCategories.map((c) => c.title).toSet();
  }

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

  /// يسجّل ضغطة الاستخدام ويحفظ الأداة في المستخدمة مؤخراً
  void _handleToolTap(BuildContext context, WidgetRef ref, _ToolItem tool) {
    ref.read(recentlyUsedToolsProvider.notifier).recordUse(tool.id);
    tool.onTap(context, ref);
    ref.read(toolUsagePrefsProvider).recordTap(tool.id).then((_) {
      if (context.mounted) {
        ref.read(toolUsageVersionProvider.notifier).bump();
      }
    });
  }

  List<_ToolItem> _getAllTools() => [
    // 1. القرآن والتعليم
    _ToolItem(
      id: 'khatma',
      title: 'خطة الختمة',
      nameEn: 'Khatma Plan',
      keywords: const ['ختمة', 'مصحف', 'تلاوة', 'قراءة', 'أجزاء', 'khatma', 'quran'],
      icon: Icons.menu_book_rounded, // مصحف مفتوح معبّر للختمة
      category: 'القرآن والتعليم',
      color: _toolShade(_kToolCategories[0].color, 0, 10),
      featured: true,
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const KhatmaScreen())),
    ),
    _ToolItem(
      id: 'hifz',
      title: 'خطة الحفظ والجدول',
      nameEn: 'Hifz Plan & Schedule',
      keywords: const ['حفظ', 'جدول', 'تسميع', 'سورة', 'آيات', 'hifz'],
      icon: Icons.calendar_month_rounded, // جدول وتقويم الحفظ المعبّر
      category: 'القرآن والتعليم',
      color: _toolShade(_kToolCategories[0].color, 1, 10),
      featured: true,
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const HifzScreen())),
    ),
    _ToolItem(
      id: 'hifz_center',
      title: 'مركز الحفظ والمراجعة الذكي',
      nameEn: 'Hifz & Review Hub',
      keywords: const [
        'مراجعة',
        'تثبيت',
        'اختبار',
        'كويز',
        'خريطة',
        'إتقان',
        'كلمات ناقصة',
        'تسميع',
        'حفظ',
        'review',
        'hifz',
        'quiz',
        'heatmap',
      ],
      icon: Icons.fact_check_rounded,
      category: 'القرآن والتعليم',
      color: _toolShade(_kToolCategories[0].color, 2, 8),
      featured: true,
      onTap: (ctx, ref) {
        final plans = ref.read(hifzPrefsProvider).plans;
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => HifzMushafScreen(
              planId: plans.isNotEmpty ? plans.first.id : null,
            ),
          ),
        );
      },
    ),
    _ToolItem(
      id: 'mutashabihat',
      title: 'متشابهات القرآن الكريم',
      nameEn: 'Quran Mutashabihat',
      keywords: const ['متشابهات', 'تشابه', 'آيات', 'مصحف', 'حفظ', 'mutashabihat'],
      icon: Icons.compare_arrows_rounded,
      category: 'القرآن والتعليم',
      color: _toolShade(_kToolCategories[0].color, 5, 10),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const MutashabihatScreen())),
    ),
    _ToolItem(
      id: 'tajweed',
      title: 'أحكام التجويد والضبط',
      nameEn: 'Tajweed Rules',
      keywords: const ['تجويد', 'أحكام', 'ترتيل', 'مخارج', 'صفات', 'tajweed'],
      icon: Icons.menu_book_outlined,
      category: 'القرآن والتعليم',
      color: _toolShade(_kToolCategories[0].color, 6, 10),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const TajweedScreen())),
    ),
    _ToolItem(
      id: 'bookmarks',
      title: 'العلامات المرجعية',
      nameEn: 'Bookmarks',
      keywords: const ['علامات', 'فواصل', 'حفظ الصفحة', 'مرجع', 'bookmarks'],
      icon: Icons.bookmark_outline,
      category: 'القرآن والتعليم',
      color: _toolShade(_kToolCategories[0].color, 7, 10),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const BookmarksScreen())),
    ),
    _ToolItem(
      id: 'notes',
      title: 'ملاحظاتي',
      nameEn: 'Quran Notes',
      keywords: const ['ملاحظات', 'تدبر', 'خواطر', 'فوائد', 'تعليق', 'notes'],
      icon: Icons.edit_note_rounded,
      category: 'القرآن والتعليم',
      color: _toolShade(_kToolCategories[0].color, 8, 10),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const NotesScreen())),
    ),
    _ToolItem(
      id: 'story_maker',
      title: 'صانع بطاقات الآيات والستوري',
      nameEn: 'Ayah Story Maker',
      keywords: const ['ستوري', 'بطاقات', 'تصميم', 'مشاركة', 'آية', 'story', 'maker'],
      icon: Icons.photo_size_select_actual_outlined,
      category: 'القرآن والتعليم',
      color: _toolShade(_kToolCategories[0].color, 9, 10),
      featured: true,
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const AyahStoryMakerScreen())),
    ),

    // 2. الحديث الشريف
    _ToolItem(
      id: 'hadith_verification',
      title: 'التحقق من صحة الحديث (الدرر السنية)',
      nameEn: 'Hadith Verification',
      keywords: const ['حديث', 'صحة الحديث', 'درر سنية', 'تخريج', 'سند', 'dorar', 'hadith', 'verification'],
      icon: Icons.verified_outlined,
      category: 'الحديث الشريف',
      color: _toolShade(_kToolCategories[1].color, 0, 2),
      featured: true,
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const HadithVerificationScreen())),
    ),
    _ToolItem(
      id: 'hadith_hub',
      title: 'موسوعة وكتب الحديث الشريف',
      nameEn: 'Hadith Library & Search',
      keywords: const ['حديث', 'كتب', 'بخاري', 'مسلم', 'نووي', 'رياض الصالحين', 'سنن', 'أربعين', 'hadith'],
      icon: Icons.auto_stories_outlined,
      category: 'الحديث الشريف',
      color: _toolShade(_kToolCategories[1].color, 1, 2),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const HadithBooksScreen())),
    ),

    // 3. العبادة والشعائر
    _ToolItem(
      id: 'qiyam',
      title: 'قيام الليل والوتر',
      nameEn: 'Qiyam Al-Layl & Witr',
      keywords: const ['قيام', 'ليل', 'وتر', 'تهجد', 'ثلث الليل', 'صلاة', 'qiyam', 'witr'],
      icon: Icons.nights_stay_outlined,
      category: 'العبادة والشعائر',
      color: _toolShade(_kToolCategories[2].color, 0, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const QiyamScreen())),
    ),
    _ToolItem(
      id: 'fasting',
      title: 'مساعد صيام التطوع',
      nameEn: 'Fasting Assistant',
      keywords: const ['صيام', 'تطوع', 'إثنين وخميس', 'أيام البيض', 'عاشوراء', 'عرفة', 'fasting'],
      icon: Icons.dark_mode_outlined,
      category: 'العبادة والشعائر',
      color: _toolShade(_kToolCategories[2].color, 1, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const FastingAssistantScreen())),
    ),
    _ToolItem(
      id: 'qibla',
      title: 'اتجاه القبلة',
      nameEn: 'Qibla Direction',
      keywords: const ['قبلة', 'كعبة', 'بوصلة', 'اتجاه', 'صلاة', 'qibla', 'compass'],
      icon: Icons.explore_outlined,
      category: 'العبادة والشعائر',
      color: _toolShade(_kToolCategories[2].color, 2, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const QiblaScreen())),
    ),
    _ToolItem(
      id: 'tasbih',
      title: 'المسبحة الإلكترونية',
      nameEn: 'Electronic Tasbih',
      keywords: const ['تسبيح', 'سبحة', 'مسبحة', 'استغفار', 'أذكار', 'عداد', 'tasbih'],
      icon: Icons.grain_rounded,
      category: 'العبادة والشعائر',
      color: _toolShade(_kToolCategories[2].color, 3, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const TasbihScreen())),
    ),
    _ToolItem(
      id: 'hijri',
      title: 'التقويم الهجري',
      nameEn: 'Hijri Calendar',
      keywords: const ['تقويم', 'هجري', 'تاريخ', 'شهر', 'مناسبات', 'hijri', 'calendar'],
      icon: Icons.calendar_today_outlined,
      category: 'العبادة والشعائر',
      color: _toolShade(_kToolCategories[2].color, 4, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const HijriCalendarScreen())),
    ),
    _ToolItem(
      id: 'names_of_allah',
      title: 'أسماء الله الحسنى والتدبر',
      nameEn: 'Names of Allah',
      keywords: const ['أسماء الله', 'حسنى', 'تدبر', 'معاني', 'names of allah'],
      icon: Icons.auto_awesome_rounded,
      category: 'العبادة والشعائر',
      color: _toolShade(_kToolCategories[2].color, 5, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const NamesOfAllahScreen())),
    ),
    _ToolItem(
      id: 'radio',
      title: 'الإذاعات والبث المباشر',
      nameEn: 'Quran Radio & Broadcasts',
      keywords: const ['إذاعة', 'بث مباشر', 'راديو', 'تلاوات', 'radio'],
      icon: Icons.podcasts_rounded,
      category: 'العبادة والشعائر',
      color: _toolShade(_kToolCategories[2].color, 6, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const QuranRadioScreen(isStandalone: true))),
    ),
    _ToolItem(
      id: 'duroos',
      title: 'الدروس والمحاضرات العلمية',
      nameEn: 'Islamic Lessons & Lectures',
      keywords: const ['دروس', 'محاضرات', 'خطب', 'شروح', 'علم', 'duroos', 'lectures'],
      icon: Icons.school_outlined,
      category: 'العبادة والشعائر',
      color: _toolShade(_kToolCategories[2].color, 7, 8),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const DuroosScreen(isStandalone: true))),
    ),

    // 4. المجتمع والمتابعة
    _ToolItem(
      id: 'groups',
      title: 'مجموعات التنافس (الصحبة الصالحة)',
      nameEn: 'Community Groups',
      keywords: const ['مجموعات', 'صحبة', 'تنافس', 'تحدي', 'أصدقاء', 'groups', 'community'],
      icon: Icons.people_outline,
      category: 'المجتمع والمتابعة',
      color: _toolShade(_kToolCategories[3].color, 0, 7),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const GroupsHubScreen())),
    ),
    _ToolItem(
      id: 'achievements',
      title: 'الإنجازات والأوسمة',
      nameEn: 'Achievements & Badges',
      keywords: const ['إنجازات', 'أوسمة', 'شارات', 'تصنيف', 'achievements', 'badges', 'leaderboards'],
      icon: Icons.emoji_events_outlined,
      category: 'المجتمع والمتابعة',
      color: _toolShade(_kToolCategories[3].color, 1, 7),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const AchievementsScreen())),
    ),
    _ToolItem(
      id: 'weekly_report',
      title: 'التقرير الأسبوعي',
      nameEn: 'Weekly Report',
      keywords: const ['تقرير', 'أسبوعي', 'إحصائيات', 'متابعة', 'weekly', 'report'],
      icon: Icons.bar_chart_rounded,
      category: 'المجتمع والمتابعة',
      color: _toolShade(_kToolCategories[3].color, 2, 7),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const WeeklyReportScreen())),
    ),

    _ToolItem(
      id: 'reminders',
      title: 'منبهات الطاعات والأذكار',
      nameEn: 'Worship Alarms & Reminders',
      keywords: const ['تذكير', 'منبه', 'تنبيهات', 'أذكار الصباح', 'أذكار المساء', 'قيام', 'reminders'],
      icon: Icons.notifications_active_outlined,
      category: 'المجتمع والمتابعة',
      color: _toolShade(_kToolCategories[3].color, 4, 7),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const RemindersScreen())),
    ),
    _ToolItem(
      id: 'notifications',
      title: 'سجل الإشعارات الواردة',
      nameEn: 'Incoming Notifications Log',
      keywords: const ['إشعارات', 'تنبيهات', 'سجل', 'صندوق', 'notifications'],
      icon: Icons.notifications_none_outlined,
      category: 'المجتمع والمتابعة',
      color: _toolShade(_kToolCategories[3].color, 5, 7),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
    ),
    _ToolItem(
      id: 'wallpapers',
      title: 'خلفيات هُمَام',
      nameEn: 'Islamic Wallpapers',
      keywords: const ['خلفيات', 'صور', 'فذكر', 'wallpapers'],
      icon: Icons.wallpaper_rounded,
      category: 'المجتمع والمتابعة',
      color: _toolShade(_kToolCategories[3].color, 6, 7),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const WallpapersScreen())),
    ),
    _ToolItem(
      id: 'permissions',
      title: 'أذونات وصلاحيات التطبيق',
      nameEn: 'App Permissions & Privacy',
      keywords: const ['أذونات', 'صلاحيات', 'إذن', 'موقع', 'إشعارات', 'بطارية', 'permissions'],
      icon: Icons.security_rounded,
      category: 'المجتمع والمتابعة',
      color: const Color(0xFF1B8A72),
      onTap: (ctx, _) => Navigator.of(
        ctx,
      ).push(MaterialPageRoute(builder: (_) => const PermissionsGuideScreen())),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    _initOpenCategoriesIfNeeded();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final allTools = _getAllTools();
    final dividerColor = isDark
        ? const Color(0xFF243040)
        : const Color(0xFFECE5D6);

    final queryTrimmed = _searchQuery.trim();
    final normQuery = normalizeArabicSearch(queryTrimmed.toLowerCase());
    final filteredTools = queryTrimmed.isEmpty
        ? allTools
        : allTools.where((t) {
            if (normalizeArabicSearch(t.title).contains(normQuery)) return true;
            if (t.nameEn.toLowerCase().contains(queryTrimmed.toLowerCase())) return true;
            if (normalizeArabicSearch(t.category).contains(normQuery)) return true;
            for (final kw in t.keywords) {
              if (normalizeArabicSearch(kw).contains(normQuery) ||
                  kw.toLowerCase().contains(queryTrimmed.toLowerCase())) {
                return true;
              }
            }
            return false;
          }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'أدواتي',
          centerTitle: true,
          colors: const [Color(0xFF1B6E53), Color(0xFF114B3A)],
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
                            tooltip: 'مسح البحث',
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

            // في حال البحث: عرض نتائج البحث الفورية أو الحالة الفارغة
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: onSurface.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لم نجد أي أداة تطابق "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'جرّب البحث بكلمات أخرى مثل: حديث، حفظ، صلاة، قبلة، ختمة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          label: const Text('مسح البحث'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.75,
                    ),
                    itemCount: filteredTools.length,
                    itemBuilder: (context, i) => _ToolGridCard(
                      tool: filteredTools[i],
                      isDark: isDark,
                      onTap: () => _handleToolTap(context, ref, filteredTools[i]),
                    ),
                  ),
                ),
            ] else ...[
              // 4. قسم المفضلة (يظهر فقط عند وجود مفضلات)
              _FavoritesSection(
                allTools: allTools,
                isDark: isDark,
                onToolTap: (t) => _handleToolTap(context, ref, t),
              ),

              // 5. قسم المستخدمة مؤخراً
              _RecentlyUsedSection(
                allTools: allTools,
                isDark: isDark,
                onToolTap: (t) => _handleToolTap(context, ref, t),
              ),

              // 6. القوائم المبوّبة القابلة للطي
              for (int catIdx = 0; catIdx < _kToolCategories.length; catIdx++) ...[
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
                                ? toolsHadithCardKey
                                : catIdx == 3
                                    ? toolsGroupsCardKey
                                    : null,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ترويسة الفئة القابلة للطي
                          InkWell(
                            onTap: () => _toggleCategory(category.title),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Row(
                                children: [
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
                                  Text(
                                    '(${catTools.length})',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: catColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const Spacer(),
                                  AnimatedRotation(
                                    duration: const Duration(milliseconds: 200),
                                    turns: isOpen ? 0 : 0.25,
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: (isDark
                                              ? Colors.white70
                                              : const Color(0xFF6B5840))
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // محتوى الفئة
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            child: isOpen
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                                    child: GridView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        childAspectRatio: 2.75,
                                      ),
                                      itemCount: catTools.length,
                                      itemBuilder: (context, i) => _ToolGridCard(
                                        tool: catTools[i],
                                        isDark: isDark,
                                        onTap: () => _handleToolTap(
                                          context,
                                          ref,
                                          catTools[i],
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
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

/// قسم المفضلة أعلى الشاشة
class _FavoritesSection extends ConsumerWidget {
  const _FavoritesSection({
    required this.allTools,
    required this.isDark,
    required this.onToolTap,
  });

  final List<_ToolItem> allTools;
  final bool isDark;
  final void Function(_ToolItem) onToolTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedIds = ref.watch(pinnedToolsProvider);
    if (pinnedIds.isEmpty) return const SizedBox.shrink();

    final byId = {for (final t in allTools) t.id: t};
    final favoriteTools = [
      for (final id in pinnedIds)
        if (byId[id] case final tool?) tool,
    ];
    if (favoriteTools.isEmpty) return const SizedBox.shrink();

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: AppColors.goldDeep,
              ),
              const SizedBox(width: 6),
              Text(
                'المفضلة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${favoriteTools.length})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tool in favoriteTools)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _ToolCompactCard(
                      tool: tool,
                      isDark: isDark,
                      isFavorite: true,
                      onTap: () => onToolTap(tool),
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

/// قسم المستخدمة مؤخراً
class _RecentlyUsedSection extends ConsumerWidget {
  const _RecentlyUsedSection({
    required this.allTools,
    required this.isDark,
    required this.onToolTap,
  });

  final List<_ToolItem> allTools;
  final bool isDark;
  final void Function(_ToolItem) onToolTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentIds = ref.watch(recentlyUsedToolsProvider);
    if (recentIds.isEmpty) return const SizedBox.shrink();

    final byId = {for (final t in allTools) t.id: t};
    final recentTools = [
      for (final id in recentIds)
        if (byId[id] case final tool?) tool,
    ];
    if (recentTools.isEmpty) return const SizedBox.shrink();

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18,
                color: onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'المستخدمة مؤخراً',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: onSurface.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(recentlyUsedToolsProvider.notifier).clear(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'مسح',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tool in recentTools)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _ToolCompactCard(
                      tool: tool,
                      isDark: isDark,
                      isFavorite: ref.watch(pinnedToolsProvider).contains(tool.id),
                      onTap: () => onToolTap(tool),
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

/// بطاقة أداة مدمجة لقسمي المفضلة والمستخدمة مؤخراً
class _ToolCompactCard extends StatelessWidget {
  const _ToolCompactCard({
    required this.tool,
    required this.isDark,
    required this.isFavorite,
    required this.onTap,
  });

  final _ToolItem tool;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: isDark ? const Color(0xFF1E2630) : const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2E3A4A) : const Color(0xFFEADBCA),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A24) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      tool.icon,
                      size: 18,
                      color: isDark ? const Color(0xFFD4AF67) : const Color(0xFF8C6B45),
                    ),
                  ),
                  if (isFavorite)
                    const PositionedDirectional(
                      top: -2,
                      start: -2,
                      child: Icon(Icons.star_rounded, size: 14, color: AppColors.goldDeep),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                tool.title,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة الأداة المستطيلة الأنيقة (تصميم متقابل اثنتين اثنتين بشكل مستطيل بلوري جميل)
class _ToolGridCard extends ConsumerWidget {
  const _ToolGridCard({
    required this.tool,
    required this.isDark,
    required this.onTap,
  });

  final _ToolItem tool;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isPinned = ref.watch(pinnedToolsProvider).contains(tool.id);

    return Material(
      color: isDark ? const Color(0xFF1E2632) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF2B3848)
              : (tool.featured
                  ? const Color(0xFFC5A059).withValues(alpha: 0.38)
                  : const Color(0xFFEADBCA).withValues(alpha: 0.85)),
          width: tool.featured ? 1.2 : 1.0,
        ),
      ),
      elevation: isDark ? 0 : 0.6,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          ref.read(pinnedToolsProvider.notifier).togglePin(tool.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                isPinned
                    ? 'تمت إزالة "${tool.title}" من المفضلة'
                    : 'تمت إضافة "${tool.title}" إلى المفضلة ⭐',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? tool.color.withValues(alpha: 0.22)
                      : tool.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tool.color.withValues(alpha: isDark ? 0.35 : 0.22),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  tool.icon,
                  size: 21,
                  color: isDark
                      ? const Color(0xFFD4AF67)
                      : (tool.color.computeLuminance() > 0.4
                          ? const Color(0xFF8C6B45)
                          : tool.color),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tool.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: onSurface.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                        if (isPinned)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(start: 3),
                            child: Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.goldDeep,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

