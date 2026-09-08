import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_repository.dart' show UserCategories;
import '../../../core/theme/app_colors.dart';
import '../../azkar/azkar_full_repository.dart';
import '../../azkar/azkar_library_category_screen.dart';
import '../prayer_analytics_screen.dart';
import '../prayer_times_service.dart';

/// فهرس قسم "الأَذْكَارُ بَعْدَ السَّلَامِ مِنَ الصَّلَاةِ" بمكتبة حصن المسلم
/// (`assets/azkar/azkar_categories.json`) — تحقّقتُ منه مباشرة بالملف، ثابت
/// عبر إعادة البناء (نفس ثبات `sleepAzkarProvider.id == 28`). يُستخدم لفتح
/// القسم مباشرة بعد تسجيل صلاة (بطلب صاحب المشروع: "أذكار بعد الصلاة تلقائياً").
const _kPostPrayerAzkarCategoryId = 24;

/// يفتح قسم أذكار ما بعد الصلاة مباشرة — يُستدعى بعد تسجيل صلاة (يدوياً
/// هون، أو من اقتراح بشريط سفلي). لا تنقّل مباشر من إشعار "هل صليت؟" نفسه
/// (`AdhanNotificationService`) — قد يصل الرد بمعزل خلفي بلا واجهة أصلاً،
/// فذاك المسار يكتفي بإشعار تذكير ثانٍ بدل تنقّل مباشر.
Future<void> _openPostPrayerAzkar(BuildContext context, WidgetRef ref) async {
  final categories = await ref.read(azkarLibraryProvider.future);
  final category = categories.firstWhere(
    (c) => c.id == _kPostPrayerAzkarCategoryId,
  );
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AzkarLibraryCategoryScreen(category: category),
    ),
  );
}

/// "قسم الصلوات والعبادات" — سلسلة استمرار **مستقلة لكل صلاة فرض على
/// حدة** ("كل صلاة منفصلة إذا تمت أو لا"). إعادة استخدام كاملة لآلية
/// `UserCategories`/`bumpCategoryStreakIfNewDay`/`completedTodayFor`
/// الموجودة أصلاً — لا جدول جديد. **شاشة مستقلة** (لا بطاقة ضمن شاشة
/// الصلاة الرئيسية كما كانت) — راجع توثيق [_PrayerCheckRow].
class PrayerChecklistScreen extends ConsumerStatefulWidget {
  const PrayerChecklistScreen({super.key});

  static const fardItems = [
    (
      category: UserCategories.fajr,
      label: 'الفجر',
      icon: Icons.nights_stay_outlined,
      moment: PrayerMoment.fajr,
    ),
    (
      category: UserCategories.dhuhr,
      label: 'الظهر',
      icon: Icons.wb_sunny_outlined,
      moment: PrayerMoment.dhuhr,
    ),
    (
      category: UserCategories.asr,
      label: 'العصر',
      icon: Icons.wb_sunny,
      moment: PrayerMoment.asr,
    ),
    (
      category: UserCategories.maghrib,
      label: 'المغرب',
      icon: Icons.wb_twilight,
      moment: PrayerMoment.maghrib,
    ),
    (
      category: UserCategories.isha,
      label: 'العشاء',
      icon: Icons.dark_mode_outlined,
      moment: PrayerMoment.isha,
    ),
  ];

  static const rawatibItems = [
    (
      category: UserCategories.sunnahFajrQabliyah,
      label: 'ركعتان قبل الفجر',
      confirmed: true,
      moment: PrayerMoment.fajr,
    ),
    (
      category: UserCategories.sunnahDuha,
      label: 'صلاة الضحى (ركعتان إلى ثمان)',
      confirmed: true,
      moment: PrayerMoment.sunrise,
    ),
    (
      category: UserCategories.sunnahDhuhrQabliyah,
      label: 'أربع ركعات قبل الظهر',
      confirmed: true,
      moment: PrayerMoment.dhuhr,
    ),
    (
      category: UserCategories.sunnahDhuhrBadiyah,
      label: 'ركعتان بعد الظهر',
      confirmed: true,
      moment: PrayerMoment.dhuhr,
    ),
    (
      category: UserCategories.sunnahAsrQabliyah,
      label: 'أربع ركعات قبل العصر',
      confirmed: false,
      moment: PrayerMoment.asr,
    ),
    (
      category: UserCategories.sunnahMaghribQabliyah,
      label: 'ركعتان قبل المغرب',
      confirmed: false,
      moment: PrayerMoment.maghrib,
    ),
    (
      category: UserCategories.sunnahMaghribBadiyah,
      label: 'ركعتان بعد المغرب',
      confirmed: true,
      moment: PrayerMoment.maghrib,
    ),
    (
      category: UserCategories.sunnahIshaBadiyah,
      label: 'ركعتان بعد العشاء',
      confirmed: true,
      moment: PrayerMoment.isha,
    ),
  ];

  @override
  ConsumerState<PrayerChecklistScreen> createState() =>
      _PrayerChecklistScreenState();
}

class _PrayerChecklistScreenState extends ConsumerState<PrayerChecklistScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncStreaks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncStreaks();
    }
  }

  Future<void> _syncStreaks() async {
    await ref.read(userPrefsProvider).reloadCategoryStreaks();
    if (mounted) {
      ref.read(categoryStreakVersionProvider.notifier).bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(categoryStreakVersionProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final loc = ref.watch(locationPrefsProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final fardDone = PrayerChecklistScreen.fardItems
        .where((i) => userPrefs.completedTodayFor(i.category))
        .length;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // هيدر بتدرّج كحلي مطابق للوحة التصميم المعتمدة (`Prayer.dc.html`)
          // — بدل `AppBar` الأبيض الافتراضي، مع ملخّص "X من ٥ فرائض" حي.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 14,
                16,
                18,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.blue, AppColors.navy],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'صلوات اليوم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$fardDone من ${PrayerChecklistScreen.fardItems.length} فرائض اليوم',
                          style: const TextStyle(
                            color: AppColors.goldSoft,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrayerAnalyticsScreen(),
                      ),
                    ),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: themeAccent(context).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: themeAccent(context).withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.tealDeep,
                    ),
                    title: const Text(
                      'تقرير وإحصائيات مواظبة الصلاة 📊',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: const Text(
                      'عرض مواظبة الجماعة، المنفرد، والقضاء أسبوعياً وشهرياً',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrayerAnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'سجّل كل صلاة بعد أدائها — سلسلة استمرار مستقلة لكل واحدة. كل صلاة/سنة تُفتح بدخول وقتها.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: onSurface.withValues(alpha: 0.55),
                  ),
                ),
                for (final item in PrayerChecklistScreen.fardItems)
                  _PrayerCheckRow(
                    category: item.category,
                    label: item.label,
                    icon: item.icon,
                    promptAzkar: true,
                    prayerShortKey: item.moment.name,
                    locked: !hasMomentArrivedToday(
                      lat: loc.lat,
                      lon: loc.lon,
                      methodKey: loc.calculationMethod,
                      moment: item.moment,
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 4),
                  child: Divider(height: 1),
                ),
                Text(
                  'السنن والرواتب',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'المؤكَّدة (الاثنتا عشرة + الضحى) والسنن المهجورة المستحبة.',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
                for (final item in PrayerChecklistScreen.rawatibItems)
                  _PrayerCheckRow(
                    category: item.category,
                    label: item.label,
                    icon: Icons.auto_awesome_outlined,
                    tag: item.confirmed ? null : 'سنة مهجورة',
                    locked: !hasMomentArrivedToday(
                      lat: loc.lat,
                      lon: loc.lon,
                      methodKey: loc.calculationMethod,
                      moment: item.moment,
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

/// مفتاح تاريخ بصيغة `YYYY-MM-DD` — **مطابق حرفياً** لـ
/// `PrayerAnalyticsScreen._formatDateKey` (لا يمكن استخدام
/// `UserRepository.dateKeyFor` هون رغم تشابه الفكرة — الصيغتان مختلفتان،
/// وشاشة الإحصائيات تقرأ هذه الصيغة تحديداً من `prayer_perf_<فرض>_<تاريخ>`).
String _perfDateKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// يحفظ اختيار "جماعة/منفرد/قضاء" بـSharedPreferences — **الإصلاح الفعلي**
/// لتتبّع صلاة الجماعة بالمسجد: كان الاختيار يُخزَّن بـ
/// [PrayerPerformanceNotifier] فقط (حالة Riverpod بالذاكرة، تُمسَح بإغلاق
/// التطبيق) بينما `PrayerAnalyticsScreen` تقرأ من مفاتيح
/// `prayer_perf_<فرض>_<تاريخ>` بـSharedPreferences التي لم تكن تُكتَب
/// إطلاقاً — فشاشة الإحصائيات الكاملة (مواظبة الجماعة/المنفرد/القضاء) كانت
/// تعرض صفراً دائماً بلا استثناء رغم وجود واجهتها كاملة. `[prayerShortKey]`
/// هو `PrayerMoment.name` (`fajr`/`dhuhr`/...)، مطابق لما تقرأه شاشة
/// الإحصائيات تحديداً — لا `UserCategories` (بادئة `prayer_` إضافية).
Future<void> _savePrayerPerformance(String prayerShortKey, String choice) async {
  try {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      'prayer_perf_${prayerShortKey}_${_perfDateKey(DateTime.now())}',
      choice,
    );
  } catch (_) {}
}

/// حالة اختيار "جماعة/منفرد/قضاء" لكل فرض اليوم — تُعرض كشارة بعد التسجيل.
/// حالة داخل الجلسة الحالية فقط للعرض الفوري (لا تنتظر إعادة قراءة
/// SharedPreferences)، لكن [_savePrayerPerformance] أعلاه يحفظها فعلياً
/// أيضاً — راجع `_PrayerPerformanceSheet` لواجهة الاختيار نفسها.
class PrayerPerformanceNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  void setChoice(String category, String choice) {
    state = {...state, category: choice};
  }
}

final prayerPerformanceMapProvider =
    NotifierProvider<PrayerPerformanceNotifier, Map<String, String>>(
      PrayerPerformanceNotifier.new,
    );

class _PrayerCheckRow extends ConsumerWidget {
  const _PrayerCheckRow({
    required this.category,
    required this.label,
    required this.icon,
    this.tag,
    this.promptAzkar = false,
    this.locked = false,
    this.prayerShortKey,
  });
  final String category;
  final String label;
  final IconData icon;
  final String? tag;
  final bool locked;
  final bool promptAzkar;
  /// `PrayerMoment.name` — فقط للفرائض الخمس (راجع `_savePrayerPerformance`)،
  /// `null` للسنن الرواتب (لا خيار جماعة/منفرد/قضاء لها أصلاً).
  final String? prayerShortKey;

  Widget _buildPerfBadge(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(prayerPerformanceMapProvider)[category];
    final accent = themeAccent(context);

    final (badgeText, badgeColor, badgeIcon) = switch (choice) {
      'jamaah' => ('جماعة 🕌', Colors.green, Icons.mosque_outlined),
      'on_time' => ('منفرد 👤', accent, Icons.person_outlined),
      'qadaa' => ('قضاء ⏳', Colors.amber.shade800, Icons.history_toggle_off),
      _ => ('تمت 🟢', AppColors.tealDeep, Icons.check_circle),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: promptAzkar
          ? () async {
              final newChoice = await showModalBottomSheet<String>(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                builder: (ctx) => _PrayerPerformanceSheet(prayerName: label),
              );
              if (newChoice != null) {
                ref
                    .read(prayerPerformanceMapProvider.notifier)
                    .setChoice(category, newChoice);
                if (prayerShortKey != null) {
                  await _savePrayerPerformance(prayerShortKey!, newChoice);
                }
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badgeIcon, size: 14, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final done = userPrefs.completedTodayFor(category);
    final days = userPrefs.streakDaysFor(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.surfaceDark : Colors.white;
    final cardBorder = isDark ? AppColors.lineDark : AppColors.line;
    final badgeColor = done
        ? AppColors.tealDeep
        : (locked ? onSurface.withValues(alpha: 0.35) : themeAccent(context));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // إبراز خفيف للفرض القابل للتسجيل الآن (لا مقفل ولا منجَز بعد) —
          // نفس فكرة "الصلاة الحالية" باللوحة المعتمدة، بلون التمييز.
          color: (!done && !locked)
              ? themeAccent(context).withValues(alpha: 0.5)
              : cardBorder,
          width: (!done && !locked) ? 1.4 : 1,
        ),
      ),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                locked ? Icons.lock_outline : icon,
                color: badgeColor,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: themeAccent(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: themeAccent(context),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (days > 0)
                    Text(
                      '$days يوم متتالي',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            done
                ? _buildPerfBadge(context, ref)
                : locked
                ? Tooltip(
                    message: 'لسا ما جا وقتها',
                    child: Text(
                      'مقفل',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () async {
                      if (promptAzkar) {
                        final choice = await showModalBottomSheet<String>(
                          context: context,
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          builder: (ctx) =>
                              _PrayerPerformanceSheet(prayerName: label),
                        );
                        if (choice == null || !context.mounted) return;
                        ref
                            .read(prayerPerformanceMapProvider.notifier)
                            .setChoice(category, choice);
                        if (prayerShortKey != null) {
                          await _savePrayerPerformance(prayerShortKey!, choice);
                        }
                      }
                      await userPrefs.bumpCategoryStreakIfNewDay(category);
                      ref.read(categoryStreakVersionProvider.notifier).bump();
                      if (!promptAzkar || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'تقبّل الله — تحب تفتح أذكار ما بعد الصلاة؟',
                          ),
                          action: SnackBarAction(
                            label: 'فتح',
                            onPressed: () => _openPostPrayerAzkar(context, ref),
                          ),
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    },
                    child: const Text(
                      'صلّيتها',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _PrayerPerformanceSheet extends StatelessWidget {
  const _PrayerPerformanceSheet({required this.prayerName});
  final String prayerName;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'كيف صليت $prayerName اليوم؟',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mosque_outlined, color: AppColors.goldDeep),
              title: const Text(
                'جماعة في المسجد 🕌',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'أعلى أجر وتنافس مبارك',
                style: TextStyle(fontSize: 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.line),
              ),
              onTap: () => Navigator.of(context).pop('jamaah'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.tealDeep),
              title: const Text(
                'في وقتها (منفرد) ⏱️',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'في أول وقتها',
                style: TextStyle(fontSize: 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.line),
              ),
              onTap: () => Navigator.of(context).pop('on_time'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.history_toggle_off,
                color: AppColors.navy,
              ),
              title: const Text(
                'قضاء (بعد فوات وقتها) ⏳',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'أداء الفرض واستدراك الوقت',
                style: TextStyle(fontSize: 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.line),
              ),
              onTap: () => Navigator.of(context).pop('qadaa'),
            ),
          ],
        ),
      ),
    );
  }
}
