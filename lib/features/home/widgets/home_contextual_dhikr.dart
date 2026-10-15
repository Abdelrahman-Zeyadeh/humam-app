import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../azkar/azkar_full_repository.dart';
import '../../azkar/azkar_library_category_screen.dart';
import '../../azkar/azkar_repository.dart' show AzkarPeriod;
import '../../azkar/azkar_screen.dart';
import '../../azkar/tasbih_screen.dart';
import '../../prayer/prayer_times_service.dart';
import '../../qiyam/qiyam_screen.dart';
import '../home_style_helpers.dart';

enum DaySlot { beforeFajr, morning, midday, evening, night, unknown }

DaySlot slotForDayTimes(List<PrayerMomentTime> dayTimes, DateTime now) {
  DateTime timeOf(PrayerMoment m) =>
      dayTimes.firstWhere((t) => t.moment == m).time;
  if (now.isBefore(timeOf(PrayerMoment.fajr))) return DaySlot.beforeFajr;
  if (now.isBefore(timeOf(PrayerMoment.dhuhr))) return DaySlot.morning;
  if (now.isBefore(timeOf(PrayerMoment.asr))) return DaySlot.midday;
  if (now.isBefore(timeOf(PrayerMoment.maghrib))) return DaySlot.evening;
  return DaySlot.night;
}

Future<void> navigateToDhikrDirectly(
  BuildContext context,
  WidgetRef ref,
  DaySlot slot,
) async {
  switch (slot) {
    case DaySlot.beforeFajr:
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QiyamScreen()),
      );
      break;
    case DaySlot.morning:
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AzkarScreen(period: AzkarPeriod.morning),
        ),
      );
      break;
    case DaySlot.midday:
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TasbihScreen()),
      );
      break;
    case DaySlot.evening:
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AzkarScreen(period: AzkarPeriod.evening),
        ),
      );
      break;
    case DaySlot.night:
    case DaySlot.unknown:
      final cached = ref.read(sleepAzkarProvider).value;
      if (cached != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AzkarLibraryCategoryScreen(category: cached),
          ),
        );
      } else {
        final cat = await ref.read(sleepAzkarProvider.future);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AzkarLibraryCategoryScreen(category: cat),
            ),
          );
        }
      }
      break;
  }
}

/// كبسولة الذِكر السياقي الذكي (Contextual Dhikr Pill) — تتغير تلقائياً
/// بحسب وقت اليوم (أذكار الصباح، المساء، الوتر وقيام الليل) بنمط مدمج
/// وأنيق مستوحى من تطبيق «فذكر» دون استهلاك مساحة رأسية كبيرة.
class HomeContextualDhikr extends ConsumerWidget {
  const HomeContextualDhikr({
    super.key,
    required this.dayTimes,
    required this.now,
  });

  final List<PrayerMomentTime>? dayTimes;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dayTimes == null) return const SizedBox.shrink();

    final slot = slotForDayTimes(dayTimes!, now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String title;
    final String subtitle;
    final IconData icon;
    final Color color;

    switch (slot) {
      case DaySlot.beforeFajr:
        title = 'سحر مبارك والتهجد';
        subtitle = 'وقت السحر والاستغفار وقيام الليل';
        icon = Icons.nightlight_round;
        color = const Color(0xFF6C63FF);
        break;
      case DaySlot.morning:
        title = 'أذكار الصباح';
        subtitle = 'أصبحنا وأصبح الملك لله • ابدأ يومك بالذكر';
        icon = Icons.wb_sunny_rounded;
        color = const Color(0xFF135B4C);
        break;
      case DaySlot.midday:
        title = 'صلاة الضحى والاستغفار';
        subtitle = 'صلاة الأوابين • رطّب لسانك بذكر الله';
        icon = Icons.light_mode_rounded;
        color = const Color(0xFFC5A059);
        break;
      case DaySlot.evening:
        title = 'أذكار المساء';
        subtitle = 'أمسينا وأمسى الملك لله • حصّن نفسك';
        icon = Icons.wb_twilight_rounded;
        color = const Color(0xFF135B4C);
        break;
      case DaySlot.night:
      case DaySlot.unknown:
        title = 'أذكار النوم والوتر';
        subtitle = 'أوتر قبل أن تنام واقرأ وردك من الأذكار';
        icon = Icons.bedtime_rounded;
        color = const Color(0xFF135B4C);
        break;
    }

    void onTap() => navigateToDhikrDirectly(context, ref, slot);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: isDark
              ? [
                  color.withValues(alpha: 0.16),
                  AppColors.surfaceDark,
                ]
              : [
                  Color.alphaBlend(
                    color.withValues(alpha: 0.1),
                    const Color(0xFFFFFDF8),
                  ),
                  Color.alphaBlend(
                    color.withValues(alpha: 0.04),
                    const Color(0xFFF7F2E6),
                  ),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.24 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: homeTextStrong(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: homeTextSoft(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'متابعة للذكر',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_left_rounded, size: 14, color: color),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
