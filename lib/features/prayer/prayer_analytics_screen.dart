import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';

/// شاشة إحصائيات وتقارير الصلاة الأسبوعية والشهرية
class PrayerAnalyticsScreen extends ConsumerStatefulWidget {
  const PrayerAnalyticsScreen({super.key});

  @override
  ConsumerState<PrayerAnalyticsScreen> createState() => _PrayerAnalyticsScreenState();
}

class _PrayerAnalyticsScreenState extends ConsumerState<PrayerAnalyticsScreen> {
  int _selectedTab = 0; // 0 = 7 أيام, 1 = 30 يوم

  String _formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Map<String, Map<String, String>>> _loadPrayerHistory(int days) async {
    final sp = await SharedPreferences.getInstance();
    final Map<String, Map<String, String>> history = {};
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final dt = now.subtract(Duration(days: i));
      final dateKey = _formatDateKey(dt);
      final Map<String, String> dayData = {};

      for (final prayer in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        final val = sp.getString('prayer_perf_${prayer}_$dateKey');
        if (val != null) {
          dayData[prayer] = val;
        }
      }
      history[dateKey] = dayData;
    }
    return history;
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final daysCount = _selectedTab == 0 ? 7 : 30;

    return Scaffold(
      appBar: const GradientAppBar(
        title: 'إحصائيات وتقارير الصلاة 📊',
        centerTitle: true,
        colors: [AppColors.blue, AppColors.navy],
      ),
      body: FutureBuilder<Map<String, Map<String, String>>>(
        future: _loadPrayerHistory(daysCount),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? {};
          int jamaahCount = 0;
          int onTimeCount = 0;
          int qadaaCount = 0;
          int totalLogged = 0;

          history.forEach((_, dayMap) {
            dayMap.forEach((_, status) {
              totalLogged++;
              if (status == 'jamaah') jamaahCount++;
              if (status == 'on_time') onTimeCount++;
              if (status == 'qadaa') qadaaCount++;
            });
          });

          final jamaahPercent = totalLogged > 0 ? (jamaahCount / totalLogged * 100).round() : 0;
          final onTimePercent = totalLogged > 0 ? (onTimeCount / totalLogged * 100).round() : 0;
          final qadaaPercent = totalLogged > 0 ? (qadaaCount / totalLogged * 100).round() : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // زر التبديل بين أسبوع و 30 يوم
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 0),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'آخر ٧ أيام',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedTab == 0 ? Colors.white : onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'آخر ٣٠ يوماً',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedTab == 1 ? Colors.white : onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // كارت نسبة صلاة الجماعة الرئيسية
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade700,
                        Colors.teal.shade800,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مواظبة صلاة الجماعة 🕌',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$jamaahPercent%',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$jamaahCount صلاة في المسجد والجماعة',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mosque_outlined, size: 36, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقات ملخص الحالات الثلاث
                Row(
                  children: [
                    _StatCard(
                      title: 'جماعة 🕌',
                      count: jamaahCount,
                      percent: jamaahPercent,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      title: 'منفرد 👤',
                      count: onTimeCount,
                      percent: onTimePercent,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      title: 'قضاء ⏳',
                      count: qadaaCount,
                      percent: qadaaPercent,
                      color: Colors.amber.shade800,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // جدول الصلوات الخمس للأيام الأخيرة
                Text(
                  'تفاصيل الصلوات الأخيرة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  elevation: 0,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (int i = 0; i < (daysCount > 7 ? 7 : daysCount); i++) ...[
                          _DayRow(
                            date: DateTime.now().subtract(Duration(days: i)),
                            dayMap: history[_formatDateKey(DateTime.now().subtract(Duration(days: i)))] ?? {},
                          ),
                          if (i < 6) const Divider(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // حديث شريف عن الفضل
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote_rounded, color: accent, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '«صَلاَةُ الْجَمَاعَةِ تَفْضُلُ صَلاَةَ الْفَذِّ بِسَبْعٍ وَعِشْرِينَ دَرَجَةً» — متفق عليه',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.count,
    required this.percent,
    required this.color,
  });

  final String title;
  final int count;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              '$count صلاة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              '$percent%',
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.date, required this.dayMap});
  final DateTime date;
  final Map<String, String> dayMap;

  String _dayNameAr(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'الإثنين',
      DateTime.tuesday => 'الثلاثاء',
      DateTime.wednesday => 'الأربعاء',
      DateTime.thursday => 'الخميس',
      DateTime.friday => 'الجمعة',
      DateTime.saturday => 'السبت',
      _ => 'الأحد',
    };
  }

  Widget _statusIcon(String? status) {
    return switch (status) {
      'jamaah' => const Tooltip(message: 'جماعة', child: Icon(Icons.mosque_outlined, color: Colors.green, size: 18)),
      'on_time' => const Tooltip(message: 'منفرد', child: Icon(Icons.person_outlined, color: Colors.teal, size: 18)),
      'qadaa' => const Tooltip(message: 'قضاء', child: Icon(Icons.history_toggle_off, color: Colors.amber, size: 18)),
      _ => Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 14),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = _dayNameAr(date.weekday);
    final dateNum = '${date.day}/${date.month}';

    return Row(
      children: [
        SizedBox(
          width: 75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dayLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(dateNum, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final p in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) _statusIcon(dayMap[p]),
            ],
          ),
        ),
      ],
    );
  }
}
