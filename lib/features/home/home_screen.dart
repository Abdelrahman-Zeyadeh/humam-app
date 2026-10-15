import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/dashboard_prefs.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/hijri/hijri_date.dart';
import '../../core/hijri/hijri_occasions.dart';
import '../onboarding/onboarding_target_keys.dart';
import '../prayer/prayer_countdown_card.dart';
import '../prayer/prayer_location_controller.dart';
import '../prayer/prayer_times_service.dart';
import '../shell/root_shell.dart';
import 'home_dashboard_data.dart';
import 'home_widget_sync.dart';
import 'weekly_report_screen.dart';
import 'widgets/home_daily_challenge_card.dart';
import 'widgets/home_daily_wisdom_card.dart';
import 'widgets/home_goals_group.dart';
import 'widgets/home_header.dart';
import 'widgets/home_misc_cards.dart';
import 'widgets/home_occasion_card.dart';
import 'widgets/home_prayer_leading_cards.dart';
import 'widgets/home_streaks_row.dart';


/// الشاشة الرئيسية المحدثة بتصميم هادئ ومريح مستوحى من تطبيقي «منار» و«فذكر».
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(locationVersionProvider);
    final locationPrefs = ref.watch(locationPrefsProvider);
    final khatmaPrefs = ref.watch(khatmaPrefsProvider);
    ref.watch(hifzVersionProvider);
    final hifzPrefs = ref.watch(hifzPrefsProvider);
    final dashboardAsync = ref.watch(homeDashboardDataProvider);

    final userPrefs = ref.watch(userPrefsProvider);
    final accentId = userPrefs.accentColorId;
    final now = DateTime.now();

    List<PrayerMomentTime>? dayTimes;
    if (locationPrefs.hasLocation) {
      dayTimes = computeDayTimes(
        lat: locationPrefs.lat!,
        lon: locationPrefs.lon!,
        date: now,
        methodKey: locationPrefs.calculationMethod,
      );
    }

    // إرسال البيانات كاملة لودجت الشاشة الرئيسية في أندرويد (لا يُحذف شيء منه)
    if (dashboardAsync.hasValue) {
      dispatchHomeWidgetSync(
        data: dashboardAsync.value!,
        dayTimes: dayTimes,
        accentId: accentId,
        userPrefs: userPrefs,
      );
    }

    final dashboardCards = ref.watch(dashboardCardsPrefsProvider);
    final isMinimal = ref.watch(dashboardMinimalModeProvider);

    // بطاقة الصلاة بدون حشو النصوص الطويلة (نظيفة وهادئة)
    final Widget heroCard;
    if (locationPrefs.hasLocation) {
      heroCard = PrayerCountdownCard(
        lat: locationPrefs.lat!,
        lon: locationPrefs.lon!,
        methodKey: locationPrefs.calculationMethod,
        onTap: () => ref.read(rootTabIndexProvider.notifier).select(2),
        footer: null,
      );
    } else {
      heroCard = const NoLocationPrayerCard(
        footer: null,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // النقوش والزخارف الإسلامية الممتدة على كامل الصفحة بشفافية هادئة
          Positioned.fill(
            child: CustomPaint(
              painter: _FullPageIslamicWallpaperPainter(
                color: (isDark
                        ? const Color(0xFFD4AF67)
                        : const Color(0xFFC5A059))
                    .withValues(alpha: isDark ? 0.025 : 0.022),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 95),
              children: [
                HomeHeader(
                  key: homeStreakWirdKey,
                  hijri: todayHijriWithDayArabic(now),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isMinimal
                      ? Column(
                          children: [
                            heroCard,
                            const SizedBox(height: 10),
                            GoalsGroupCard(
                              khatmaPlan: khatmaPrefs.activePlans.isNotEmpty
                                  ? khatmaPrefs.activePlans.first
                                  : null,
                              hifzPlan: hifzPrefs.plans.isNotEmpty
                                  ? hifzPrefs.plans.first
                                  : null,
                              continueReadingSurah:
                                  dashboardAsync.value?.continueReadingSurah,
                            ),
                            const SizedBox(height: 10),
                            PillActionButton(
                              icon: Icons.tune_rounded,
                              label: 'العودة للواجهة الكاملة',
                              onTap: () => ref
                                  .read(dashboardMinimalModeProvider.notifier)
                                  .toggle(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            if (hijriOccasionFor(now) case final occasion?) ...[
                              HomeOccasionCard(occasion: occasion),
                              const SizedBox(height: 10),
                            ],

                            // ١. قسم أوقات الصلاة (العنصر اللحظي الأهم مباشرة تحت الترويسة)
                            if (dashboardCards.contains('prayer_hero')) ...[
                              _HomePrayerSectionHeader(
                                cityName: locationPrefs.cityName ??
                                    (locationPrefs.hasLocation
                                        ? 'موقعي الحالي'
                                        : null),
                                onLocationTap: () => ref
                                    .read(locationControllerProvider.notifier)
                                    .useGps(),
                              ),
                              heroCard,
                              const SizedBox(height: 10),
                            ],



                            // ٢. بطاقة «قبس اليوم» الموحدة مع زر المشاركة كبطاقة ستوري
                            if (dashboardCards.contains('period_ayah') ||
                                dashboardCards.contains('daily_hadith_name')) ...[
                              dashboardAsync.when(
                                data: (data) => HomeDailyWisdomCard(data: data),
                                loading: () => const CardSkeleton(height: 80),
                                error: (_, _) => const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // ٣. بطاقة أهدافي وقراءتي اليوم (مجمعة وموحدة بأناقة)
                            GoalsGroupCard(
                              khatmaPlan:
                                  dashboardCards.contains('khatma_card') &&
                                          khatmaPrefs.activePlans.isNotEmpty
                                      ? khatmaPrefs.activePlans.first
                                      : null,
                              hifzPlan: dashboardCards.contains('hifz_card') &&
                                      hifzPrefs.plans.isNotEmpty
                                  ? hifzPrefs.plans.first
                                  : null,
                              continueReadingSurah:
                                  dashboardCards.contains('continue_reading')
                                      ? dashboardAsync.value?.continueReadingSurah
                                      : null,
                            ),

                            // ٥. تحدي اليوم
                            const DailyChallengeCard(),
                            const SizedBox(height: 10),

                            // ٦. المواظبة والتقرير الأسبوعي
                            if (dashboardCards.contains('streaks_section')) ...[
                              StreaksRow(
                                trailing: (dashboardAsync
                                                .value?.audioMinutesThisWeek ??
                                            0) >
                                        0
                                    ? ListeningMinutesChip(
                                        minutes: dashboardAsync
                                            .value!.audioMinutesThisWeek,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 8),
                            ] else if ((dashboardAsync
                                        .value?.audioMinutesThisWeek ??
                                    0) >
                                0) ...[
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: ListeningMinutesChip(
                                  minutes:
                                      dashboardAsync.value!.audioMinutesThisWeek,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            PillActionButton(
                              icon: Icons.bar_chart_outlined,
                              label: 'تقرير أسبوعي',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WeeklyReportScreen(),
                                ),
                              ),
                            ),
                          ],
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



class _HomePrayerSectionHeader extends StatelessWidget {
  const _HomePrayerSectionHeader({this.cityName, this.onLocationTap});
  final String? cityName;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
      child: Row(
        children: [
          if (cityName != null && cityName!.isNotEmpty) ...[
            InkWell(
              onTap: onLocationTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ios_share_rounded,
                    size: 14,
                    color: Color(0xFFC5A059),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cityName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFD4AF67) : const Color(0xFF8C6D3F),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xFFC5A059),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Text(
            'أوقات الصلاة',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E2833),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3.5,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFC5A059),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسام الزخارف والنقوش الهندسية الإسلامية والزهور والأقواس الممتدة على كامل الصفحة
class _FullPageIslamicWallpaperPainter extends CustomPainter {
  const _FullPageIslamicWallpaperPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: color.a * 1.3)
      ..style = PaintingStyle.fill;

    const step = 85.0;
    const r = 24.0;

    // شبكة هندسية إسلامية مكونة من أقواس متقاطعة وزهور ثمانية تغطي الشاشة كاملة
    for (double y = 0; y < size.height + step; y += step) {
      for (double x = 0; x < size.width + step; x += step) {
        // دائرة هندسية مركزية
        canvas.drawCircle(Offset(x, y), r, strokePaint);
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);

        // أقواس دائرية متقاطعة بين المراكز الأربعة
        final archR = step * 0.48;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: archR),
          0,
          2 * math.pi,
          false,
          strokePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FullPageIslamicWallpaperPainter oldDelegate) =>
      oldDelegate.color != color;
}
