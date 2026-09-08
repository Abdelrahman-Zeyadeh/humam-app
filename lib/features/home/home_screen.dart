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
import 'widgets/home_daily_hadith_name_card.dart';
import 'widgets/home_daily_challenge_card.dart';
import 'widgets/home_goals_group.dart';
import 'widgets/home_header.dart';
import 'widgets/home_misc_cards.dart';
import 'widgets/home_occasion_card.dart';
import 'widgets/home_period_verse.dart';
import 'widgets/home_prayer_leading_cards.dart';
import 'widgets/home_streaks_row.dart';

/// الشاشة الرئيسية الكلاسيكية المدمجة والمصغرة الحجم (سطران كحد أقصى) —
/// راجع `home_style_helpers.dart`، `home_widget_sync.dart`، ومجلد
/// `widgets/` لبقية الودجتات (استُخرجت من هون أثناء تفكيك الملف، كان
/// ~٢١٠٠ سطر بكل شي بملف واحد، بلا أي تغيير سلوكي).
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
    // مراقَب هون (لا بس بـ`HomeHeader`) عشان دفع لون التمييز الحالي
    // لودجت الشاشة الرئيسية (`dispatchHomeWidgetSync` تحت) أول ما يتغيّر
    // مباشرة.
    ref.watch(accentColorVersionProvider);
    final accentId = ref.read(userPrefsProvider).accentColorId;
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

    if (dashboardAsync.hasValue) {
      dispatchHomeWidgetSync(
        data: dashboardAsync.value!,
        dayTimes: dayTimes,
        accentId: accentId,
      );
    }

    final dashboardCards = ref.watch(dashboardCardsPrefsProvider);
    final showPeriodVerseInPrayer = dashboardCards.contains('period_ayah');

    final Widget heroCard;
    if (locationPrefs.hasLocation) {
      heroCard = PrayerCountdownCard(
        lat: locationPrefs.lat!,
        lon: locationPrefs.lon!,
        methodKey: locationPrefs.calculationMethod,
        onTap: () => ref.read(rootTabIndexProvider.notifier).select(2),
        footer: (showPeriodVerseInPrayer && dashboardAsync.value != null)
            ? PeriodVerseFooter(data: dashboardAsync.value!)
            : null,
      );
    } else {
      heroCard = NoLocationPrayerCard(
        footer: (showPeriodVerseInPrayer && dashboardAsync.value != null)
            ? PeriodVerseFooter(data: dashboardAsync.value!)
            : null,
      );
    }

    final isMinimal = ref.watch(dashboardMinimalModeProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 95),
          children: [
            HomeHeader(
              key: homeStreakWirdKey,
              hijri: todayHijriWithDayArabic(now),
            ),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isMinimal
                    ? Column(
                        children: [
                          heroCard,
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
                          ],
                          if (dashboardCards.contains('prayer_hero')) ...[
                            heroCard,
                            const SizedBox(height: 12),
                          ],
                    if (dayTimes != null) ...[
                      LeadingCard(dayTimes: dayTimes, now: now),
                      const SizedBox(height: 12),
                    ],
                    if (!dashboardCards.contains('prayer_hero') &&
                        dashboardCards.contains('period_ayah')) ...[
                      dashboardAsync.when(
                        data: (data) => PeriodVerseCard(data: data),
                        loading: () => const CardSkeleton(height: 90),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // بطاقة "حديث اليوم واسم من أسماء الله الحسنى" — بطلب
                    // صاحب المشروع "بحب... يظهر في الشاشة عند فتح التطبيق"
                    // (كانا موجودين فقط كشاشتين بقائمة "المزيد" يحتاج
                    // المستخدم يفتحهما يدوياً، هون يظهران تلقائياً بالرئيسية).
                    if (dashboardCards.contains('daily_hadith_name')) ...[
                      const HomeDailyHadithNameCard(),
                      const SizedBox(height: 12),
                    ],
                    // بطاقة "أهدافي اليوم" المجمَّعة — تحل محل ٣ بطاقات منفصلة
                    // (ختمة/حفظ/متابعة قراءة) كانت تتكدّس بنفس الشكل تباعاً.
                    // كل صف يظهر فقط لو مفعَّل بتخصيص الداشبورد وله بيانات فعلية
                    // — نفس شروط الإظهار الأصلية، بلا كسر ميزة التخصيص.
                    GoalsGroupCard(
                      khatmaPlan:
                          dashboardCards.contains('khatma_card') &&
                              khatmaPrefs.activePlans.isNotEmpty
                          ? khatmaPrefs.activePlans.first
                          : null,
                      hifzPlan:
                          dashboardCards.contains('hifz_card') &&
                              hifzPrefs.plans.isNotEmpty
                          ? hifzPrefs.plans.first
                          : null,
                      continueReadingSurah:
                          dashboardCards.contains('continue_reading')
                          ? dashboardAsync.value?.continueReadingSurah
                          : null,
                    ),
                    // "تحدي اليوم" — مهمة صغيرة عشوائية إضافية (راجع
                    // `daily_challenge.dart`)، بلا شرط تخصيص داشبورد (خلافاً
                    // للبطاقات أعلاه): لا ترتبط بخطة موجودة مسبقاً فتظهر
                    // للجميع دائماً، بعكس بطاقات مرتبطة ببيانات فعلية.
                    const DailyChallengeCard(),
                    const SizedBox(height: 12),
                    if (dashboardCards.contains('start_plan_cta') &&
                        (khatmaPrefs.activePlans.isEmpty ||
                            hifzPrefs.plans.isEmpty)) ...[
                      StartPlanPrompt(
                        showKhatma: khatmaPrefs.activePlans.isEmpty,
                        showHifz: hifzPrefs.plans.isEmpty,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (dashboardCards.contains('streaks_section')) ...[
                      StreaksRow(
                        trailing:
                            (dashboardAsync.value?.audioMinutesThisWeek ??
                                    0) >
                                0
                            ? ListeningMinutesChip(
                                minutes:
                                    dashboardAsync.value!.audioMinutesThisWeek,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ] else if ((dashboardAsync.value?.audioMinutesThisWeek ??
                            0) >
                        0) ...[
                      // ما فيه قسم "سلاسل الاستمرار" ليتعلّق فيه (المستخدم
                      // عطّله بتخصيص الداشبورد) — نعرض الشارة لحالها بدل ما
                      // نخفيها بالكامل.
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ListeningMinutesChip(
                          minutes: dashboardAsync.value!.audioMinutesThisWeek,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // زر "تخصيص الواجهة" انتقل لأيقونة ثابتة بالهيدر
                    // (`HomeHeader`) — بقي هون فقط زر التقرير الأسبوعي،
                    // فصار بعرض كامل بدل نص الصف.
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
            ),
          ],
        ),
      ),
    );
  }
}
