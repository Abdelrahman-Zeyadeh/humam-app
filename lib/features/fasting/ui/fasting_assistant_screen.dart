import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_service.dart';
import '../data/fasting_prefs.dart';
import '../models/fasting_day.dart';

class FastingAssistantScreen extends ConsumerStatefulWidget {
  const FastingAssistantScreen({super.key});

  @override
  ConsumerState<FastingAssistantScreen> createState() => _FastingAssistantScreenState();
}

class _FastingAssistantScreenState extends ConsumerState<FastingAssistantScreen> {
  final List<FastingDay> _upcomingDays = FastingDay.getUpcomingFastingDays(daysAhead: 35);
  bool _eveReminder = true;
  bool _suhoorReminder = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(fastingPrefsProvider);
    final eve = await prefs.isEveReminderEnabled();
    final suhoor = await prefs.isSuhoorReminderEnabled();
    if (mounted) {
      setState(() {
        _eveReminder = eve;
        _suhoorReminder = suhoor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(fastingVersionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final now = DateTime.now();
    final todayHijri = HijriCalendar.now();

    final nextFastingDay = _upcomingDays.isNotEmpty ? _upcomingDays.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مساعد صيام التطوع 🌙'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. بطاقة الهيرو: صيام اليوم واليوم القادم
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F2B26), const Color(0xFF1B4D43)]
                    : [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF00796B).withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00796B).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${todayHijri.hDay} ${todayHijri.longMonthName} ${todayHijri.hYear} هـ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00796B),
                        ),
                      ),
                    ),
                    FutureBuilder<int>(
                      future: ref.read(fastingPrefsProvider).totalFastsThisYear(),
                      builder: (ctx, snap) => Row(
                        children: [
                          const Icon(Icons.stars_rounded, size: 16, color: AppColors.goldDeep),
                          const SizedBox(width: 4),
                          Text(
                            'صمت ${snap.data ?? 0} يوماً هذا العام',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // حالة اليوم القادم
                if (nextFastingDay != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00796B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.nights_stay_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextFastingDay.isToday
                                  ? 'اليوم: ${nextFastingDay.title}'
                                  : (nextFastingDay.isTomorrow
                                      ? 'غداً: ${nextFastingDay.title}'
                                      : 'الصيام القادم: ${nextFastingDay.title}'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextFastingDay.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // تسجيل صيام اليوم
                FutureBuilder<bool>(
                  future: ref.read(fastingPrefsProvider).isFasted(now),
                  builder: (context, snap) {
                    final isFasted = snap.data ?? false;
                    return InkWell(
                      onTap: () async {
                        await ref.read(fastingPrefsProvider).toggleFast(now);
                        ref.read(fastingVersionProvider.notifier).bump();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isFasted
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isFasted ? const Color(0xFF2E7D32) : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isFasted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: isFasted ? const Color(0xFF2E7D32) : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isFasted ? 'تقبل الله صيامك اليوم ✓' : 'أنا صائم اليوم (اضغط للتسجيل)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isFasted ? const Color(0xFF2E7D32) : null,
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
          const SizedBox(height: 20),

          // 2. إعدادات التنبيهات الذكية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 18, color: accent),
                    const SizedBox(width: 8),
                    const Text(
                      'التنبيهات الذكية لصيام التطوع',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تذكير النية مساء اليوم السابق', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text('تنبيه الساعة 08:30 م لتجهيز النية والسحور', style: TextStyle(fontSize: 11.5)),
                  value: _eveReminder,
                  activeThumbColor: accent,
                  onChanged: (val) async {
                    setState(() => _eveReminder = val);
                    await ref.read(fastingPrefsProvider).setEveReminderEnabled(val);
                    await AdhanNotificationService.instance.scheduleFastingReminders(enabled: val);
                  },
                ),
                Divider(height: 1, color: isDark ? AppColors.lineDark : AppColors.line),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تنبيه وقت السحور والإمساك', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text('تنبيه قبل أذان الفجر بـ 45 دقيقة لتناول السحور', style: TextStyle(fontSize: 11.5)),
                  value: _suhoorReminder,
                  activeThumbColor: accent,
                  onChanged: (val) async {
                    setState(() => _suhoorReminder = val);
                    await ref.read(fastingPrefsProvider).setSuhoorReminderEnabled(val);
                  },
                ),
                Divider(height: 1, color: isDark ? AppColors.lineDark : AppColors.line),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('إرسال تنبيه تجريبي لهاتفي الآن'),
                  onPressed: () async {
                    await AdhanNotificationService.instance.showInstantAlert(
                      id: 9799,
                      title: 'تذكير بصيام غداً 🌙',
                      body: 'سنة نبوية مباركة — تذكير بصيام يوم الغد وتجهيز نية الصيام والسحور ✨',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال إشعار الصيام التجريبي لهاتفك بنجاح')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. جدول صيام السنن للأيام القادمة
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 18, color: accent),
              const SizedBox(width: 8),
              const Text(
                'جدول صيام السنن للأيام القادمة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (final day in _upcomingDays)
            _buildFastingDayCard(context, day, isDark),

          const SizedBox(height: 20),

          // 4. حديث نبوي شريف في فضل الصيام
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF221F14) : const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_quote, size: 18, color: AppColors.goldDeep),
                    SizedBox(width: 6),
                    Text(
                      'فضل صيام التطوع',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.goldDeep),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'قال رسول الله ﷺ: «مَنْ صَامَ يَوْمًا فِي سَبِيلِ اللَّهِ، بَاعَدَ اللَّهُ وَجْهَهُ عَنِ النَّارِ سَبْعِينَ خَرِيفًا»\n[متفق عليه]',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingDayCard(BuildContext context, FastingDay day, bool isDark) {
    final accent = themeAccent(context);
    final dayNames = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final dayName = dayNames[day.date.weekday - 1];

    Color badgeColor;
    switch (day.type) {
      case FastingType.whiteDay:
        badgeColor = const Color(0xFF00796B);
        break;
      case FastingType.arafah:
      case FastingType.ashura:
        badgeColor = AppColors.goldDeep;
        break;
      default:
        badgeColor = const Color(0xFF3F51B5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: day.isToday
              ? accent
              : (isDark ? AppColors.lineDark : AppColors.line),
          width: day.isToday ? 1.5 : 1.1,
        ),
      ),
      child: FutureBuilder<bool>(
        future: ref.read(fastingPrefsProvider).isFasted(day.date),
        builder: (context, snap) {
          final isFasted = snap.data ?? false;

          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.hijriDate.hDay}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    day.hijriDate.longMonthName.split(' ').first,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '$dayName • ${day.title}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: day.isToday ? accent : null,
                    ),
                  ),
                ),
                if (day.isToday) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'اليوم',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '${day.date.day}/${day.date.month}/${day.date.year} م • ${day.description}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
            ),
            trailing: IconButton(
              icon: Icon(
                isFasted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                color: isFasted ? const Color(0xFF2E7D32) : Colors.grey.withValues(alpha: 0.4),
              ),
              tooltip: 'تسجيل الصيام',
              onPressed: () async {
                await ref.read(fastingPrefsProvider).toggleFast(day.date);
                ref.read(fastingVersionProvider.notifier).bump();
              },
            ),
          );
        },
      ),
    );
  }
}
