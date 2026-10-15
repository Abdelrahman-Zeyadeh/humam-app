import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';

/// اختصارات أيام الأسبوع العربية المطابقة للتقويم في التصميم
String _dayAbbr(int weekday) {
  return switch (weekday) {
    DateTime.thursday => 'خم',
    DateTime.friday => 'جم',
    DateTime.saturday => 'سب',
    DateTime.sunday => 'أح',
    DateTime.monday => 'إث',
    DateTime.tuesday => 'ثل',
    DateTime.wednesday => 'أر',
    _ => '',
  };
}

class _PrayerItemDef {
  const _PrayerItemDef({required this.key, required this.label});
  final String key;
  final String label;
}

const _kPrayersList = [
  _PrayerItemDef(key: 'fajr', label: 'الفجر'),
  _PrayerItemDef(key: 'dhuhr', label: 'الظهر'),
  _PrayerItemDef(key: 'asr', label: 'العصر'),
  _PrayerItemDef(key: 'maghrib', label: 'المغرب'),
  _PrayerItemDef(key: 'isha', label: 'العشاء'),
];

/// ألوان حالات الصلاة المطابقة للتصميم في الصورة
class PrayerStatusColors {
  static const Color masjid = Color(0xFF2A9D8F); // مسجد - أخضر
  static const Color jamaah = Color(0xFF48CAE4); // جماعة - سماوي
  static const Color onTime = Color(0xFFD48B38); // في الوقت - برتقالي دافئ
  static const Color qadaa = Color(0xFFE9C46A);  // قضاء - أصفر ذهبي
  static const Color missed = Color(0xFFE63946); // فائتة - أحمر
}

/// شاشة إحصائيات وتقارير الصلاة (اليوم / الأسبوع / الشهر)
/// مطابقة تماماً للتصميم المرفق بالصور
class PrayerAnalyticsScreen extends ConsumerStatefulWidget {
  const PrayerAnalyticsScreen({super.key});

  @override
  ConsumerState<PrayerAnalyticsScreen> createState() => _PrayerAnalyticsScreenState();
}

class _PrayerAnalyticsScreenState extends ConsumerState<PrayerAnalyticsScreen> {
  // 0: اليوم, 1: الأسبوع, 2: الشهر
  int _selectedTab = 1; // الافتراضي هو "الأسبوع" كما بالصورة
  int _reloadKey = 0;

  String _formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Map<String, Map<String, String>>> _loadHistory(int days) async {
    final sp = await SharedPreferences.getInstance();
    final Map<String, Map<String, String>> history = {};
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final dt = now.subtract(Duration(days: i));
      final dateKey = _formatDateKey(dt);
      final Map<String, String> dayData = {};

      for (final p in _kPrayersList) {
        final val = sp.getString('prayer_perf_${p.key}_$dateKey');
        if (val != null) {
          dayData[p.key] = val;
        }
      }
      history[dateKey] = dayData;
    }
    return history;
  }

  int _calculateStreak(Map<String, Map<String, String>> history) {
    final now = DateTime.now();
    int streak = 0;
    // ابدأ من اليوم، إذا صليت فيه صلاة واحدة على الأقل احسبه، وإلا افحص من الأمس
    for (int i = 0; i < 60; i++) {
      final dt = now.subtract(Duration(days: i));
      final key = _formatDateKey(dt);
      final dayMap = history[key];
      if (dayMap != null && dayMap.isNotEmpty) {
        streak++;
      } else {
        if (i == 0) {
          // اليوم لم يسجل بعد، ربما لم يحن الوقت
          continue;
        }
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final cardBg = isDark ? const Color(0xFF1E2420) : Colors.white;
    final cardBorder = isDark ? Colors.white12 : const Color(0xFFEDE8E1);

    final daysCount = switch (_selectedTab) {
      0 => 1,
      1 => 7,
      _ => 30,
    };

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141916) : const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.refresh_rounded, color: onSurface.withValues(alpha: 0.8)),
          tooltip: 'تحديث',
          onPressed: () => setState(() => _reloadKey++),
        ),
        title: Text(
          'الإحصاءات',
          style: TextStyle(
            color: onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, size: 28, color: onSurface),
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, Map<String, String>>>(
        key: ValueKey('analytics_history_${_selectedTab}_$_reloadKey'),
        future: _loadHistory(daysCount > 7 ? 60 : 14),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? {};
          final now = DateTime.now();

          // حساب الإحصائيات للفترة المختارة
          int totalPerformed = 0;
          int onTimeCount = 0;

          // إحصائيات كل صلاة على حدة
          final Map<String, Map<String, int>> prayerStats = {
            for (final p in _kPrayersList)
              p.key: {
                'masjid': 0,
                'jamaah': 0,
                'on_time': 0,
                'qadaa': 0,
                'missed': 0,
                'total': 0,
              }
          };

          for (int i = 0; i < daysCount; i++) {
            final dt = now.subtract(Duration(days: i));
            final dateKey = _formatDateKey(dt);
            final dayData = history[dateKey] ?? {};

            for (final p in _kPrayersList) {
              final status = dayData[p.key];
              if (status != null) {
                totalPerformed++;
                prayerStats[p.key]!['total'] = (prayerStats[p.key]!['total'] ?? 0) + 1;

                if (status == 'masjid') {
                  prayerStats[p.key]!['masjid'] = (prayerStats[p.key]!['masjid'] ?? 0) + 1;
                } else if (status == 'jamaah') {
                  prayerStats[p.key]!['jamaah'] = (prayerStats[p.key]!['jamaah'] ?? 0) + 1;
                } else if (status == 'on_time') {
                  onTimeCount++;
                  prayerStats[p.key]!['on_time'] = (prayerStats[p.key]!['on_time'] ?? 0) + 1;
                } else if (status == 'qadaa') {
                  prayerStats[p.key]!['qadaa'] = (prayerStats[p.key]!['qadaa'] ?? 0) + 1;
                }
              } else {
                // صلاة فائتة فقط للأيام السابقة
                if (i > 0) {
                  prayerStats[p.key]!['missed'] = (prayerStats[p.key]!['missed'] ?? 0) + 1;
                }
              }
            }
          }

          final totalTargetPrayers = daysCount * 5;
          final performanceRate = totalTargetPrayers > 0
              ? ((totalPerformed / totalTargetPrayers) * 100).round()
              : 0;
          final streakDays = _calculateStreak(history);

          // تحديد عناوين كارت اللمحة
          final glanceTitle = switch (_selectedTab) {
            0 => 'يومك في لمحة',
            1 => 'أسبوعك في لمحة',
            _ => 'شهرك في لمحة',
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. شريط التبويبات الثلاثي (اليوم | الأسبوع | الشهر)
                _buildSegmentedTab(context, isDark, accent),
                const SizedBox(height: 16),

                // 2. كارت ملخص اللمحة (ذهبي/تان كالتصميم)
                _buildGlanceCard(
                  glanceTitle: glanceTitle,
                  totalPerformed: totalPerformed,
                ),
                const SizedBox(height: 22),

                // 3. قسم أداء الصلوات
                Text(
                  'أداء الصلوات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPerformanceMetricsCard(
                  performanceRate: performanceRate,
                  streakDays: streakDays,
                  onTimeCount: onTimeCount,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  onSurface: onSurface,
                ),
                const SizedBox(height: 22),

                // 4. قسم تقويم الصلوات
                Text(
                  'تقويم الصلوات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCalendarCard(
                  history: history,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const SizedBox(height: 22),

                // 5. قسم تفاصيل الصلوات
                Text(
                  'تفاصيل الصلوات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailsCard(
                  prayerStats: prayerStats,
                  daysCount: daysCount,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  onSurface: onSurface,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  /// شريط التبويبات الثلاثي
  Widget _buildSegmentedTab(BuildContext context, bool isDark, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final pillBg = isDark ? const Color(0xFF1E2420) : const Color(0xFFF0EAE1);
    final activeColor = const Color(0xFFBA934B);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _tabItem(label: 'اليوم', index: 0, activeColor: activeColor, onSurface: onSurface),
          _tabItem(label: 'الأسبوع', index: 1, activeColor: activeColor, onSurface: onSurface),
          _tabItem(label: 'الشهر', index: 2, activeColor: activeColor, onSurface: onSurface),
        ],
      ),
    );
  }

  Widget _tabItem({
    required String label,
    required int index,
    required Color activeColor,
    required Color onSurface,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  /// كارت اللمحة الذهبي
  Widget _buildGlanceCard({
    required String glanceTitle,
    required int totalPerformed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC79E53),
            Color(0xFFA57D36),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA57D36).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            glanceTitle,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalPerformed',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'صلاة مؤدّاة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ثبات جميل. الاتساق أهم من الكمال.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  /// كارت أداء الصلوات
  Widget _buildPerformanceMetricsCard({
    required int performanceRate,
    required int streakDays,
    required int onTimeCount,
    required Color cardBg,
    required Color cardBorder,
    required Color onSurface,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metricColumn(
              value: '$performanceRate%',
              label: 'معدّل الأداء',
              onSurface: onSurface,
            ),
          ),
          Container(width: 1, height: 32, color: cardBorder),
          Expanded(
            child: _metricColumn(
              value: '$streakDays',
              label: 'أيام متتالية',
              onSurface: onSurface,
            ),
          ),
          Container(width: 1, height: 32, color: cardBorder),
          Expanded(
            child: _metricColumn(
              value: '$onTimeCount',
              label: 'في الوقت',
              onSurface: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricColumn({
    required String value,
    required String label,
    required Color onSurface,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// كارت تقويم الصلوات وجدول الأيام
  Widget _buildCalendarCard({
    required Map<String, Map<String, String>> history,
    required Color cardBg,
    required Color cardBorder,
    required Color onSurface,
    required bool isDark,
  }) {
    final now = DateTime.now();

    // 7 أيام لعرضها بالتقويم: من قبل 6 أيام حتى اليوم
    final List<DateTime> calendarDays = [];
    for (int i = 6; i >= 0; i--) {
      calendarDays.add(now.subtract(Duration(days: i)));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // رأس الجدول: أسماء الأيام السبعة
          Row(
            children: [
              for (final day in calendarDays)
                Expanded(
                  child: Center(
                    child: Text(
                      _dayAbbr(day.weekday),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 48), // مساحة لعمود اسم الصلاة
            ],
          ),
          const SizedBox(height: 12),

          // صفوف الصلوات الخمس
          for (final prayer in _kPrayersList) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (final day in calendarDays)
                    Expanded(
                      child: Center(
                        child: _buildCalendarDot(
                          status: history[_formatDateKey(day)]?[prayer.key],
                          isDark: isDark,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      prayer.label,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          Divider(height: 1, color: cardBorder),
          const SizedBox(height: 12),

          // دليل الألوان (الأسطورة) كما في الصورة تماماً
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('مسجد', PrayerStatusColors.masjid),
                const SizedBox(width: 12),
                _legendItem('جماعة', PrayerStatusColors.jamaah),
                const SizedBox(width: 12),
                _legendItem('في الوقت', PrayerStatusColors.onTime),
                const SizedBox(width: 12),
                _legendItem('قضاء', PrayerStatusColors.qadaa),
                const SizedBox(width: 12),
                _legendItem('فائتة', PrayerStatusColors.missed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDot({required String? status, required bool isDark}) {
    if (status == null) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFE8DFC8),
            width: 1.5,
          ),
        ),
      );
    }

    final color = switch (status) {
      'masjid' => PrayerStatusColors.masjid,
      'jamaah' => PrayerStatusColors.jamaah,
      'on_time' => PrayerStatusColors.onTime,
      'qadaa' => PrayerStatusColors.qadaa,
      _ => PrayerStatusColors.missed,
    };

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// كارت تفاصيل الصلوات (نسب وأعداد كل صلاة)
  Widget _buildDetailsCard({
    required Map<String, Map<String, int>> prayerStats,
    required int daysCount,
    required Color cardBg,
    required Color cardBorder,
    required Color onSurface,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _kPrayersList.length; i++) ...[
            Builder(builder: (context) {
              final p = _kPrayersList[i];
              final stats = prayerStats[p.key]!;
              final performed = stats['total'] ?? 0;
              final pct = daysCount > 0 ? ((performed / daysCount) * 100).round() : 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // أعداد الحالات الخمس بنقاطها الملونة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _detailStatItem('${stats['on_time'] ?? 0} وقت', PrayerStatusColors.onTime),
                          const SizedBox(width: 10),
                          _detailStatItem('${stats['jamaah'] ?? 0} جماعة', PrayerStatusColors.jamaah),
                          const SizedBox(width: 10),
                          _detailStatItem('${stats['masjid'] ?? 0} مسجد', PrayerStatusColors.masjid),
                          const SizedBox(width: 10),
                          _detailStatItem('${stats['qadaa'] ?? 0} قضاء', PrayerStatusColors.qadaa),
                          const SizedBox(width: 10),
                          _detailStatItem('${stats['missed'] ?? 0} فائتة', PrayerStatusColors.missed),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (i < _kPrayersList.length - 1)
              Divider(height: 1, color: cardBorder),
          ],
        ],
      ),
    );
  }

  Widget _detailStatItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ],
    );
  }
}
