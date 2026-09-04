import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final Map<String, List<bool>> categoryWeeks; // فئة → ٧ أيام ثابتة (السبت..الجمعة)
  final int qiyamAyahsThisWeek;
  final int dailyWirdStreak;
  final int todayIndex; // 0..6 (0=السبت..6=الجمعة)

  /// راجع `UserRepository.getAudioMinutes`.
  final int audioMinutesThisWeek;
  final int audioMinutesThisMonth;

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

  return WeeklyReportData(
    categoryWeeks: weeks,
    qiyamAyahsThisWeek: qiyamAyahs,
    dailyWirdStreak: prefs.streakDays,
    todayIndex: daysSinceSaturday,
    audioMinutesThisWeek: audioMinutesThisWeek,
    audioMinutesThisMonth: audioMinutesThisMonth,
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
