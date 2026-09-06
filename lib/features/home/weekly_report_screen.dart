import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories, UserRepository;
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../wrapped/ui/faith_wrapped_screen.dart';

/// صفوف التقرير: الصلوات الخمس + قيام الليل + الحفظ + أذكار الصباح/المساء/النوم
const _kReportRows = [
  (category: UserCategories.fajr, label: 'الفجر', icon: Icons.nights_stay_outlined, color: AppColors.navy),
  (category: UserCategories.dhuhr, label: 'الظهر', icon: Icons.wb_sunny_outlined, color: AppColors.goldDeep),
  (category: UserCategories.asr, label: 'العصر', icon: Icons.wb_sunny, color: AppColors.goldDeep),
  (category: UserCategories.maghrib, label: 'المغرب', icon: Icons.wb_twilight, color: AppColors.blue),
  (category: UserCategories.isha, label: 'العشاء', icon: Icons.dark_mode_outlined, color: AppColors.navy),
  (category: UserCategories.qiyam, label: 'قيام الليل', icon: Icons.bedtime_outlined, color: Color(0xFF8E5B45)),
  (category: UserCategories.hifz, label: 'الحفظ', icon: Icons.school_outlined, color: AppColors.purple),
  (category: UserCategories.morningAzkar, label: 'أذكار الصباح', icon: Icons.wb_sunny_outlined, color: AppColors.goldDeep),
  (category: UserCategories.eveningAzkar, label: 'أذكار المساء', icon: Icons.nights_stay_outlined, color: AppColors.blue),
  (category: UserCategories.nightAzkar, label: 'أذكار النوم', icon: Icons.dark_mode_outlined, color: AppColors.tealDeep),
];

const _kFardCategories = [
  UserCategories.fajr,
  UserCategories.dhuhr,
  UserCategories.asr,
  UserCategories.maghrib,
  UserCategories.isha,
];

class WeeklyReportData {
  const WeeklyReportData({
    required this.categoryWeeks,
    required this.qiyamAyahsThisWeek,
    required this.dailyWirdStreak,
    required this.todayIndex,
    required this.audioMinutesThisWeek,
    required this.audioMinutesThisMonth,
    required this.khatmaProgressPercent,
    required this.khatmaPagesRemaining,
    required this.overallScorePercent,
  });

  final Map<String, List<bool>> categoryWeeks; // فئة → ٧ أيام ثابتة (السبت..الجمعة)
  final int qiyamAyahsThisWeek;
  final int dailyWirdStreak;
  final int todayIndex; // 0..6 (0=السبت..6=الجمعة)

  /// راجع `UserRepository.getAudioMinutes`.
  final int audioMinutesThisWeek;
  final int audioMinutesThisMonth;

  /// نسبة تقدّم خطة الختمة الأكثر تقدّماً بين خطط المستخدم النشطة (0-100)،
  /// أو `null` لو ماله أي خطة ختمة نشطة حالياً — بطلب صريح بالتودو: التقرير
  /// الأسبوعي كان يغطّي الصلوات/الحفظ/الأذكار/القيام بس بلا الختمة، رغم
  /// كونها أحد أكبر ميزتين بالتطبيق (راجع `more_placeholder_screen.dart`).
  final int? khatmaProgressPercent;
  final int khatmaPagesRemaining;

  /// **درجة إيمانية إجمالية موحَّدة (0-100)** تجمع كل الأقسام معاً بنظرة
  /// واحدة — بطلب صريح بالتودو: "وسّع التقرير الأسبوعي ليشمل كل الأقسام
  /// معاً (حفظ + ختمة + أذكار + صلوات) بدل إحصائيات كل قسم منفصلة". قبل
  /// هذا الحقل كان التقرير يعرض كل قسم بصفّه/بطاقته المستقلة بلا أي رقم
  /// واحد يلخّص الأسبوع ككل. متوسط بسيط (لا وزن تفضيلي لقسم عن آخر) بين:
  /// نسبة إنجاز الفرائض، الحفظ، متوسط أذكار الصباح/المساء/النوم، قيام
  /// الليل (الأربعة كنسبة أيام مكتملة من ٧)، وتقدّم خطة الختمة النشطة إن
  /// وُجدت (مباشرة كنسبة مئوية) — يُحسب بـ`weeklyReportProvider`.
  final int overallScorePercent;

  int get fardCompletedCount =>
      _kFardCategories.fold(0, (sum, c) => sum + (categoryWeeks[c]?.where((d) => d).length ?? 0));
}

/// يجمع بيانات التقرير للأسبوع الحالي الثابت (من السبت إلى الجمعة)
final weeklyReportProvider = FutureProvider.autoDispose<WeeklyReportData>((ref) async {
  ref.watch(categoryStreakVersionProvider);
  final prefs = ref.watch(userPrefsProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daysSinceSaturday = (today.weekday % 7 + 1) % 7;
  final saturday = today.subtract(Duration(days: daysSinceSaturday));

  final weeks = <String, List<bool>>{};
  for (final row in _kReportRows) {
    weeks[row.category] = await prefs.fixedWeekCompletionFor(row.category);
  }

  var qiyamAyahs = 0;
  for (var i = 0; i <= daysSinceSaturday; i++) {
    final day = saturday.add(Duration(days: i));
    qiyamAyahs += await prefs.qiyamAyahCountFor(UserRepository.dateKeyFor(day));
  }

  final audioMinutesThisWeek = await prefs.getAudioMinutes(7);
  final audioMinutesThisMonth = await prefs.getAudioMinutes(30);

  // خطة الختمة الأكثر تقدّماً بين خطط المستخدم النشطة (لو أكثر من خطة) —
  // لا معنى لجمع تقدّم خطط متعددة، فنعرض الأبرز فقط.
  final khatmaPlans = ref.watch(khatmaPrefsProvider).activePlans;
  int? khatmaProgressPercent;
  var khatmaPagesRemaining = 0;
  if (khatmaPlans.isNotEmpty) {
    final best = khatmaPlans.reduce(
      (a, b) =>
          (a.currentPage - a.startPage) >= (b.currentPage - b.startPage)
          ? a
          : b,
    );
    final read = best.currentPage - best.startPage;
    khatmaProgressPercent = ((read / best.totalPagesToRead) * 100)
        .clamp(0, 100)
        .round();
    khatmaPagesRemaining = (best.totalPagesToRead - read).clamp(0, 604);
  }

  // درجة إجمالية موحَّدة — راجع توثيق [WeeklyReportData.overallScorePercent].
  double weekRate(String category) {
    final week = weeks[category];
    if (week == null || week.isEmpty) return 0;
    return week.where((d) => d).length / week.length * 100;
  }

  final fardRate = _kFardCategories.isEmpty
      ? 0.0
      : _kFardCategories.map(weekRate).reduce((a, b) => a + b) / _kFardCategories.length;
  final azkarRate =
      (weekRate(UserCategories.morningAzkar) +
          weekRate(UserCategories.eveningAzkar) +
          weekRate(UserCategories.nightAzkar)) /
      3;
  final sectionScores = <double>[
    fardRate,
    weekRate(UserCategories.hifz),
    azkarRate,
    weekRate(UserCategories.qiyam),
    if (khatmaProgressPercent != null) khatmaProgressPercent.toDouble(),
  ];
  final overallScorePercent = sectionScores.isEmpty
      ? 0
      : (sectionScores.reduce((a, b) => a + b) / sectionScores.length).round();

  return WeeklyReportData(
    categoryWeeks: weeks,
    qiyamAyahsThisWeek: qiyamAyahs,
    dailyWirdStreak: prefs.streakDays,
    todayIndex: daysSinceSaturday,
    audioMinutesThisWeek: audioMinutesThisWeek,
    audioMinutesThisMonth: audioMinutesThisMonth,
    khatmaProgressPercent: khatmaProgressPercent,
    khatmaPagesRemaining: khatmaPagesRemaining,
    overallScorePercent: overallScorePercent,
  );
});

/// تقرير أسبوعي منظم بأيام ثابتة من السبت إلى الجمعة
class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير أسبوعي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.goldDeep),
            tooltip: 'التقرير المرئي (Faith Wrapped)',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FaithWrappedScreen()),
            ),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذّر تحميل التقرير')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // الدرجة الإيمانية الإجمالية — نظرة واحدة على كل الأقسام معاً
            // (فرائض + حفظ + أذكار + قيام + ختمة)، راجع توثيق
            // `WeeklyReportData.overallScorePercent`.
            _OverallScoreCard(percent: data.overallScorePercent),
            const SizedBox(height: 14),
            // بطاقة التقرير المرئي (Faith Wrapped)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.2),
              ),
              child: ListTile(
                leading: const IconBadge(
                  icon: Icons.auto_awesome,
                  color: AppColors.gold,
                  large: true,
                ),
                title: const Text(
                  'التقرير الإيماني المرئي (Wrapped) ✨',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                subtitle: const Text(
                  'شاهد ملخصك الأسبوعي في قصة تفاعلية مميزة',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gold),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaithWrappedScreen()),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.mosque_outlined,
                    label: 'الصلوات هذا الأسبوع',
                    value: '${data.fardCompletedCount}/35',
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.menu_book_outlined,
                    label: 'آيات قيام الأسبوع',
                    value: '${data.qiyamAyahsThisWeek}',
                    color: const Color(0xFF8E5B45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SummaryCard(
              icon: Icons.local_fire_department_outlined,
              label: 'سلسلة الورد اليومي الحالية',
              value: '${data.dailyWirdStreak} يوم',
              color: AppColors.tealDeep,
              wide: true,
            ),
            const SizedBox(height: 10),
            // تقدّم خطة الختمة — كان التقرير الأسبوعي يغطّي الصلوات/الحفظ/
            // الأذكار/القيام بس بلا الختمة رغم كونها أحد أكبر ميزتين
            // بالتطبيق (بطلب صريح لاحق بالتودو).
            _SummaryCard(
              icon: Icons.bookmark_outline,
              label: data.khatmaProgressPercent != null
                  ? 'تقدّم خطة الختمة — باقي ${data.khatmaPagesRemaining} صفحة'
                  : 'لا يوجد خطة ختمة نشطة حالياً',
              value: data.khatmaProgressPercent != null
                  ? '${data.khatmaProgressPercent}%'
                  : '—',
              color: AppColors.infoBlue,
              wide: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.headphones_outlined,
                    label: 'دقائق التلاوة هذا الأسبوع',
                    value: '${data.audioMinutesThisWeek}',
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.headphones_outlined,
                    label: 'دقائق التلاوة هذا الشهر',
                    value: '${data.audioMinutesThisMonth}',
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('سجل أيام الأسبوع', style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'أيام الأسبوع بترتيب ثابت (السبت..الجمعة) — النقطة الملونة تمثل اليوم الحالي.',
              style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12),
            ),
            const SizedBox(height: 16),
            _WeekdayHeaderRow(todayIndex: data.todayIndex),
            const SizedBox(height: 8),
            for (final row in _kReportRows) ...[
              _ReportRow(
                label: row.label,
                icon: row.icon,
                color: row.color,
                week: data.categoryWeeks[row.category] ?? const [],
                todayIndex: data.todayIndex,
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// بطاقة الدرجة الإجمالية — دائرة تقدّم واحدة تلخّص كل أقسام الأسبوع
/// (فرائض/حفظ/أذكار/قيام/ختمة) برقم واحد، بدل الاكتفاء بصفوف منفصلة لكل
/// قسم أسفلها. راجع توثيق `WeeklyReportData.overallScorePercent`.
class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = percent >= 70
        ? AppColors.tealDeep
        : (percent >= 40 ? AppColors.goldDeep : AppColors.navy);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الدرجة الإيمانية الإجمالية لهذا الأسبوع',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'متوسط الفرائض والحفظ والأذكار والقيام وتقدّم الختمة معاً',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow({required this.todayIndex});
  final int todayIndex;

  static const _dayNames = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']; // السبت..الجمعة

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        const SizedBox(width: 110),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      Text(
                        _dayNames[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: i == todayIndex ? FontWeight.w800 : FontWeight.w600,
                          color: i == todayIndex ? themeAccent(context) : onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (i == todayIndex)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeAccent(context),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label, required this.value, required this.color, this.wide = false});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: wide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 12.5))),
                  Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 8),
                  Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 11)),
                ],
              ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.week,
    required this.todayIndex,
  });

  final String label;
  final IconData icon;
  final Color color;
  final List<bool> week;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: onSurface, fontSize: 12.5, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (i < week.length && week[i]) ? color : Colors.transparent,
                    border: Border.all(
                      color: (i < week.length && week[i])
                          ? color
                          : (i > todayIndex
                              ? onSurface.withValues(alpha: 0.08)
                              : onSurface.withValues(alpha: 0.22)),
                      width: 1.5,
                    ),
                  ),
                  child: (i < week.length && week[i])
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
