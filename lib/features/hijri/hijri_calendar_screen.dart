import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/hijri/hijri_date.dart';
import '../../core/hijri/hijri_occasions.dart';
import '../../core/text/time_format.dart';
import '../../core/theme/app_colors.dart';
import '../prayer/prayer_times_service.dart';

/// شاشة التقويم الهجري الكامل:
/// - استعراض الأشهر الهجرية يوماً بيوم مع المقابل الميلادي
/// - تمييز الأيام البيض والمناسبات الإسلامية
/// - عرض مواقيت الصلاة لليوم المحدد
/// - أداة تحويل فوري بين التاريخ الهجري والميلادي
class HijriCalendarScreen extends ConsumerStatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  ConsumerState<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends ConsumerState<HijriCalendarScreen> {
  late int _hYear;
  late int _hMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    HijriCalendar.language = 'ar';
    final now = DateTime.now();
    final hNow = HijriCalendar.fromDate(now);
    _hYear = hNow.hYear;
    _hMonth = hNow.hMonth;
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      if (_hMonth == 1) {
        _hMonth = 12;
        _hYear--;
      } else {
        _hMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_hMonth == 12) {
        _hMonth = 1;
        _hYear++;
      } else {
        _hMonth++;
      }
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    final hNow = HijriCalendar.fromDate(now);
    setState(() {
      _hYear = hNow.hYear;
      _hMonth = hNow.hMonth;
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);
    final loc = ref.watch(locationPrefsProvider);

    final firstDayGregorian = HijriCalendar().hijriToGregorian(_hYear, _hMonth, 1);
    final hCal = HijriCalendar.fromDate(firstDayGregorian);

    final monthName = hCal.getLongMonthName();
    final monthLength = hCal.lengthOfMonth;

    // 1=Mon..7=Sun -> السبت = 6، الأحد = 7
    // نريد بداية الأسبوع من السبت (index 0) إلى الجمعة (index 6)
    final firstWeekdaySaturdayBased = (firstDayGregorian.weekday % 7 + 1) % 7;

    final now = DateTime.now();
    final todayTruncated = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقويم الهجري'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: 'اليوم',
            onPressed: _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_outlined),
            tooltip: 'تحويل التاريخ',
            onPressed: _showDateConverterSheet,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // كرت رأس الشهر وأزرار التنقل
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'الشهر السابق',
                    onPressed: _prevMonth,
                  ),
                  Column(
                    children: [
                      Text(
                        '$monthName $_hYear هـ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                        ),
                      ),
                      Text(
                        '${firstDayGregorian.year}/${firstDayGregorian.month}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'الشهر القادم',
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // عناوين أيام الأسبوع (السبت..الجمعة)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _WeekdayLabel('س'),
                      _WeekdayLabel('ح'),
                      _WeekdayLabel('ن'),
                      _WeekdayLabel('ث'),
                      _WeekdayLabel('ر'),
                      _WeekdayLabel('خ'),
                      _WeekdayLabel('ج'),
                    ],
                  ),
                  const Divider(height: 16),

                  // شبكة أيام الشهر
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: firstWeekdaySaturdayBased + monthLength,
                    itemBuilder: (context, index) {
                      if (index < firstWeekdaySaturdayBased) {
                        return const SizedBox.shrink();
                      }
                      final hDay = index - firstWeekdaySaturdayBased + 1;
                      final gDate = HijriCalendar().hijriToGregorian(_hYear, _hMonth, hDay);
                      final isToday = gDate.year == todayTruncated.year &&
                          gDate.month == todayTruncated.month &&
                          gDate.day == todayTruncated.day;
                      final isSelected = gDate.year == _selectedDate.year &&
                          gDate.month == _selectedDate.month &&
                          gDate.day == _selectedDate.day;
                      final isWhiteDay = hDay == 13 || hDay == 14 || hDay == 15;
                      final occasion = hijriOccasionFor(gDate);

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selectedDate = gDate),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.2)
                                : (isToday ? accent.withValues(alpha: 0.08) : null),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : (isToday ? accent.withValues(alpha: 0.4) : Colors.transparent),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$hDay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: (isToday || isSelected)
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? accent
                                      : (isToday
                                          ? accent
                                          : onSurface.withValues(alpha: 0.85)),
                                ),
                              ),
                              Text(
                                '${gDate.day}',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                              if (occasion != null || isWhiteDay)
                                Container(
                                  margin: const EdgeInsets.only(top: 1),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: occasion != null ? AppColors.gold : AppColors.teal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // تفاصيل اليوم المحدد
          _SelectedDayCard(
            date: _selectedDate,
            loc: loc,
            accent: accent,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDateConverterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const _DateConverterSheet(),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.date,
    required this.loc,
    required this.accent,
  });

  final DateTime date;
  final LocationPrefs loc;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final occasion = hijriOccasionFor(date);
    final hCal = HijriCalendar.fromDate(date);
    final isWhiteDay = hCal.hDay == 13 || hCal.hDay == 14 || hCal.hDay == 15;

    List<PrayerMomentTime>? dayTimes;
    if (loc.hasLocation) {
      dayTimes = computeDayTimes(
        lat: loc.lat!,
        lon: loc.lon!,
        date: date,
        methodKey: loc.calculationMethod,
      ).where((t) => t.moment.isPrayer).toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note_outlined, size: 20, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    todayHijriWithDayArabic(date),
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(right: 28),
              child: Text(
                'الموافق: ${date.year}/${date.month}/${date.day} م',
                style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.55)),
              ),
            ),
            if (occasion != null || isWhiteDay) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_outline, color: AppColors.goldDeep, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            occasion?.title ?? 'من الأيام البيض المباركة (يُستحب صيامها)',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.goldDeep),
                          ),
                          if (occasion != null)
                            Text(
                              occasion.subtitle,
                              style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.7)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (dayTimes != null && dayTimes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'مواقيت الصلاة لهذا اليوم:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final t in dayTimes)
                    Column(
                      children: [
                        Text(t.moment.nameAr, style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6))),
                        const SizedBox(height: 2),
                        Text(
                          formatTimeOfDay(t.time.hour, t.time.minute),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurface),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateConverterSheet extends StatefulWidget {
  const _DateConverterSheet();

  @override
  State<_DateConverterSheet> createState() => _DateConverterSheetState();
}

class _DateConverterSheetState extends State<_DateConverterSheet> {
  DateTime _selectedGregorian = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hCal = HijriCalendar.fromDate(_selectedGregorian);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'أداة تحويل التاريخ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.line)),
              title: const Text('اختر التاريخ الميلادي:'),
              subtitle: Text('${_selectedGregorian.year}/${_selectedGregorian.month}/${_selectedGregorian.day}'),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedGregorian,
                  firstDate: DateTime(1930),
                  lastDate: DateTime(2090),
                );
                if (picked != null) {
                  setState(() => _selectedGregorian = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeAccent(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: themeAccent(context).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('التاريخ الهجري المقابل:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    '${hCal.hDay} ${hCal.getLongMonthName()} ${hCal.hYear} هـ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: themeAccent(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
