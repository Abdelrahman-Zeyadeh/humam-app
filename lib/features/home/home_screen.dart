import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/names_of_allah/names_of_allah_data.dart';
import '../../core/data/user/dashboard_prefs.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_accent_colors.dart';
import '../../core/theme/app_card.dart';
import '../../core/data/user/user_repository.dart'
    show UserCategories, KhatmaPlan, HifzPlan;
import '../../core/hijri/hijri_date.dart';
import '../../core/hijri/hijri_occasions.dart';
import '../../core/text/arabic_normalizer.dart' show formatAyahForWidgetDisplay;
import '../../core/theme/app_colors.dart';
import '../azkar/azkar_repository.dart' show AzkarPeriod;
import '../auth/cloud_sync_service.dart';
import '../habits/custom_habits_screen.dart';
import '../hadith/daily_hadith_screen.dart';
import '../hifz/hifz_screen.dart';
import '../hijri/hijri_calendar_screen.dart';
import '../khatma/khatma_screen.dart' show KhatmaScreen;
import '../names_of_allah/names_of_allah_screen.dart';
import '../profile/profile_stats_screen.dart';
import '../mushaf/mushaf_screen.dart' show MushafScreen;
import '../mushaf/mushaf_settings.dart' show mushafJumpRequestProvider;
import '../onboarding/onboarding_target_keys.dart';
import '../prayer/prayer_countdown_card.dart';
import '../prayer/prayer_location_controller.dart';
import '../prayer/prayer_screen.dart' show PrayerChecklistScreen;
import '../prayer/prayer_times_service.dart';
import '../qiyam/qiyam_screen.dart';
import '../shell/root_shell.dart';
import '../widget/home_widget_service.dart';
import 'dashboard_customize_sheet.dart';
import 'home_dashboard_data.dart';
import 'weekly_report_screen.dart';

enum _DaySlot { beforeFajr, morning, midday, evening, night, unknown }

_DaySlot _slotFor(List<PrayerMomentTime> dayTimes, DateTime now) {
  DateTime timeOf(PrayerMoment m) =>
      dayTimes.firstWhere((t) => t.moment == m).time;
  if (now.isBefore(timeOf(PrayerMoment.fajr))) return _DaySlot.beforeFajr;
  if (now.isBefore(timeOf(PrayerMoment.dhuhr))) return _DaySlot.morning;
  if (now.isBefore(timeOf(PrayerMoment.asr))) return _DaySlot.midday;
  if (now.isBefore(timeOf(PrayerMoment.maghrib))) return _DaySlot.evening;
  return _DaySlot.night;
}

Color _cardSurface(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.surfaceDark
    : Colors.white;
Color _cardBorder(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.lineDark
    : AppColors.line;
Color _textStrong(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkOnDark
    : AppColors.navy;
Color _textSoft(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkSoftOnDark
    : AppColors.inkSoft;
List<BoxShadow> _cardShadow(BuildContext c) => [
  BoxShadow(
    color:
        (Theme.of(c).brightness == Brightness.dark
                ? Colors.black
                : AppColors.navy)
            .withValues(
              alpha: Theme.of(c).brightness == Brightness.dark ? 0.32 : 0.06,
            ),
    blurRadius: 14,
    offset: const Offset(0, 4),
  ),
];

/// الشاشة الرئيسية الكلاسيكية المدمجة والمصغرة الحجم (سطران كحد أقصى)
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
    // مراقَب هون (لا بس بـ`_Header`) عشان `dispatchWidgetSync` تحت يعيد
    // دفع لون التمييز الحالي لودجت الشاشة الرئيسية أول ما يتغيّر مباشرة.
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

    void dispatchWidgetSync(HomeDashboardData data) {
      final now = DateTime.now();
      final next2 = dayTimes == null ? null : nextPrayer(dayTimes, now);

      String formatClock(DateTime dt) {
        final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }

      String formatCountdown(DateTime target) {
        final diff = target.difference(now);
        if (diff.isNegative) return '';
        final hours = diff.inHours.toString().padLeft(2, '0');
        final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
        return 'بعد $hours:$minutes';
      }

      String formattedHijriToday() {
        final raw = todayHijriWithDayArabic(now);
        return raw.replaceAll(RegExp(r'\s+هـ$'), '');
      }

      final fajr = dayTimes
          ?.where((t) => t.moment == PrayerMoment.fajr)
          .firstOrNull;
      final sunrise = dayTimes
          ?.where((t) => t.moment == PrayerMoment.sunrise)
          .firstOrNull;
      final dhuhr = dayTimes
          ?.where((t) => t.moment == PrayerMoment.dhuhr)
          .firstOrNull;
      final asr = dayTimes
          ?.where((t) => t.moment == PrayerMoment.asr)
          .firstOrNull;
      final maghrib = dayTimes
          ?.where((t) => t.moment == PrayerMoment.maghrib)
          .firstOrNull;
      final isha = dayTimes
          ?.where((t) => t.moment == PrayerMoment.isha)
          .firstOrNull;

      unawaited(
        updateHumamHomeWidget(
          ayahText: data.ayahOfDay.textUthmani,
          ayahRef: '${data.ayahOfDaySurah} - ${data.ayahOfDay.ayah}',
          dhikrText: data.dhikrOfDay,
          hijriDate: formattedHijriToday(),
          nextPrayerName: next2?.moment.nameAr,
          nextPrayerTime: next2 == null ? null : formatClock(next2.time),
          nextPrayerCountdown: next2 == null
              ? null
              : formatCountdown(next2.time),
          nextPrayerTargetEpochMs: next2?.time.millisecondsSinceEpoch,
          timeFajr: fajr != null ? formatClock(fajr.time) : null,
          timeSunrise: sunrise != null ? formatClock(sunrise.time) : null,
          timeDhuhr: dhuhr != null ? formatClock(dhuhr.time) : null,
          timeAsr: asr != null ? formatClock(asr.time) : null,
          timeMaghrib: maghrib != null ? formatClock(maghrib.time) : null,
          timeIsha: isha != null ? formatClock(isha.time) : null,
          timeFajrMs: fajr?.time.millisecondsSinceEpoch,
          timeSunriseMs: sunrise?.time.millisecondsSinceEpoch,
          timeDhuhrMs: dhuhr?.time.millisecondsSinceEpoch,
          timeAsrMs: asr?.time.millisecondsSinceEpoch,
          timeMaghribMs: maghrib?.time.millisecondsSinceEpoch,
          timeIshaMs: isha?.time.millisecondsSinceEpoch,
          activeMoment: next2?.moment.name,
          accentId: accentId,
        ),
      );
    }

    if (dashboardAsync.hasValue) {
      dispatchWidgetSync(dashboardAsync.value!);
    }

    final Widget heroCard;
    if (locationPrefs.hasLocation) {
      heroCard = PrayerCountdownCard(
        lat: locationPrefs.lat!,
        lon: locationPrefs.lon!,
        methodKey: locationPrefs.calculationMethod,
        onTap: () => ref.read(rootTabIndexProvider.notifier).select(2),
        footer: dashboardAsync.value == null
            ? null
            : _PeriodVerseFooter(data: dashboardAsync.value!),
      );
    } else {
      heroCard = _NoLocationPrayerCard(
        footer: dashboardAsync.value == null
            ? null
            : _PeriodVerseFooter(data: dashboardAsync.value!),
      );
    }

    final dashboardCards = ref.watch(dashboardCardsPrefsProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 95),
          children: [
            _Header(
              key: homeStreakWirdKey,
              hijri: todayHijriWithDayArabic(now),
            ),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (hijriOccasionFor(now) case final occasion?) ...[
                      _OccasionCard(occasion: occasion),
                      const SizedBox(height: 12),
                    ],
                    if (dashboardCards.contains('prayer_hero')) ...[
                      heroCard,
                      const SizedBox(height: 12),
                    ],
                    if (dayTimes != null) ...[
                      _LeadingCard(dayTimes: dayTimes, now: now),
                      const SizedBox(height: 12),
                    ],
                    if (!dashboardCards.contains('prayer_hero') &&
                        dashboardCards.contains('period_ayah')) ...[
                      dashboardAsync.when(
                        data: (data) => _PeriodVerseCard(data: data),
                        loading: () => const _CardSkeleton(height: 90),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // بطاقة "حديث اليوم واسم من أسماء الله الحسنى" — بطلب
                    // صاحب المشروع "بحب... يظهر في الشاشة عند فتح التطبيق"
                    // (كانا موجودين فقط كشاشتين بقائمة "المزيد" يحتاج
                    // المستخدم يفتحهما يدوياً، هون يظهران تلقائياً بالرئيسية).
                    if (dashboardCards.contains('daily_hadith_name')) ...[
                      const _DailyHadithNameCard(),
                      const SizedBox(height: 12),
                    ],
                    // بطاقة "أهدافي اليوم" المجمَّعة — تحل محل ٣ بطاقات منفصلة
                    // (ختمة/حفظ/متابعة قراءة) كانت تتكدّس بنفس الشكل تباعاً.
                    // كل صف يظهر فقط لو مفعَّل بتخصيص الداشبورد وله بيانات فعلية
                    // — نفس شروط الإظهار الأصلية، بلا كسر ميزة التخصيص.
                    _GoalsGroupCard(
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
                    if (dashboardCards.contains('start_plan_cta') &&
                        (khatmaPrefs.activePlans.isEmpty ||
                            hifzPrefs.plans.isEmpty)) ...[
                      _StartPlanPrompt(
                        showKhatma: khatmaPrefs.activePlans.isEmpty,
                        showHifz: hifzPrefs.plans.isEmpty,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (dashboardCards.contains('streaks_section')) ...[
                      const _StreaksRow(),
                      const SizedBox(height: 10),
                    ],
                    if ((dashboardAsync.value?.audioMinutesThisWeek ?? 0) >
                        0) ...[
                      _ListeningMinutesChip(
                        minutes: dashboardAsync.value!.audioMinutesThisWeek,
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _PillActionButton(
                            icon: Icons.bar_chart_outlined,
                            label: 'تقرير أسبوعي',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const WeeklyReportScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PillActionButton(
                            key: dashboardCustomizeButtonKey,
                            icon: Icons.dashboard_customize_outlined,
                            label: 'تخصيص الواجهة',
                            accent: true,
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => const DashboardCustomizeSheet(),
                            ),
                          ),
                        ),
                      ],
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

/// زرّا الإجراء أسفل الرئيسية ("تقرير أسبوعي"/"تخصيص الواجهة") — حبّة
/// (pill) مستديرة بالكامل بارتفاع ٤٨ وأيقونة برُقعة دائرية، مطابقة
/// لأسلوب لوحة التصميم المعتمدة، بدل `OutlinedButton` مستطيل الحواف.
class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final badgeColor = accent ? themeAccent(context) : _textStrong(context);
    return Material(
      color: _cardSurface(context),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _cardBorder(context)),
            boxShadow: _cardShadow(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: badgeColor),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textStrong(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({super.key, required this.hijri});
  final String hijri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userNameVersionProvider);
    ref.watch(accentColorVersionProvider);
    final accent = appAccentColorById(
      ref.read(userPrefsProvider).accentColorId,
    );
    final name = ref.watch(userPrefsProvider).userName.trim();
    final syncState = ref.watch(cloudSyncControllerProvider);
    final h = DateTime.now().hour;
    final greeting = h < 4
        ? 'طاب ليلك وقيامك 🌙'
        : h < 12
        ? 'صباح الخير والبركة 🌅'
        : h < 17
        ? 'طاب يومك بطاعة الله ☀️'
        : 'مساء الخير والسكينة 🕌';

    final welcome = name.isNotEmpty
        ? 'أهلاً بك يا $name في هُمَام'
        : 'أهلاً بك في هُمَام';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 42, 16, 38),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [accent.primaryLight, accent.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            welcome,
                            style: const TextStyle(
                              color: AppColors.goldSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileStatsScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              syncState.isSignedIn
                                  ? Icons.cloud_done
                                  : Icons.account_circle_outlined,
                              color: syncState.isSignedIn
                                  ? const Color(0xFF81C784)
                                  : Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              syncState.isSignedIn
                                  ? (syncState.user?.displayName
                                            ?.split(' ')
                                            .first ??
                                        'متزامن')
                                  : 'حسابي',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HijriCalendarScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 13,
                          color: AppColors.goldSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hijri,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_left,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة مناسبة هجرية (زي "ترقّب ليلة القدر") — بمعالجة ذهبية مميّزة
/// (تدرّج + نقشة نجوم صغيرة) بدل بطاقة بيضاء إضافية، مطابقة لأسلوب لوحة
/// التصميم المعتمدة (راجع الكانفاس، بطاقة "Occasion banner").
class _OccasionCard extends StatelessWidget {
  const _OccasionCard({required this.occasion});
  final HijriOccasion occasion;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.gold, AppColors.goldSoft],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _OccasionPatternPainter()),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occasion.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        occasion.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// نقشة نجوم صغيرة على بطاقة المناسبة الذهبية — راجع [_OccasionCard].
class _OccasionPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    const spacing = 30.0;
    const angle = 20 * math.pi / 180;
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle);
        canvas.drawPath(_smallStar(9), paint);
        canvas.restore();
      }
    }
  }

  Path _smallStar(double outerR) {
    final innerR = outerR * 0.42;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = (math.pi / 4) * i;
      final r = i.isEven ? outerR : innerR;
      final point = Offset(r * math.cos(a), r * math.sin(a));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _OccasionPatternPainter oldDelegate) => false;
}

/// بطاقة آية الفترة مع الذكر — مع إمكانية القفز للآية بالمصحف وفتح الأذكار
/// بطاقة "حديث اليوم واسم من أسماء الله الحسنى" — تختار عنصراً واحداً
/// حتمياً (بيوم السنة `DateTime.now()`، لا عشوائي) من كل قائمة فتبقى
/// **نفس** الحديث/الاسم طول اليوم بغض النظر عن كم مرة يُفتح التطبيق أو
/// تُعاد بناء الشاشة، ويتغيّران تلقائياً غداً — نفس فكرة "آية الفترة"
/// أعلاه لكن ليومياً لا لفترة اليوم. بطلب صاحب المشروع: "حديث اليوم...
/// يظهر في الشاشة عند فتح التطبيق واسماء الله الحسنى كذلك".
class _DailyHadithNameCard extends StatelessWidget {
  const _DailyHadithNameCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final hadith =
        kCuratedDailyHadiths[dayOfYear % kCuratedDailyHadiths.length];
    final name =
        NamesOfAllahData.items[dayOfYear % NamesOfAllahData.items.length];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DailyHadithScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 13,
                          color: AppColors.tealDeep,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'حديث اليوم',
                          style: TextStyle(
                            color: _textSoft(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_left,
                          size: 13,
                          color: _textSoft(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hadith.matn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textStrong(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: _cardBorder(context), height: 1),
            InkWell(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NamesOfAllahScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 13,
                      color: AppColors.goldDeep,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name.name,
                      style: const TextStyle(
                        color: AppColors.goldDeep,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name.meaning,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textStrong(context).withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_left,
                      size: 13,
                      color: _textSoft(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _PeriodVerseCard extends ConsumerWidget {
  const _PeriodVerseCard({required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // آية الفترة — النقر عليها يفتح المصحف عند الصفحة المحددة مع تظليل الآية
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                ref
                    .read(mushafJumpRequestProvider.notifier)
                    .request(
                      page: data.ayahOfDay.page,
                      ayahId: data.ayahOfDay.id,
                    );
                ref.read(rootTabIndexProvider.notifier).select(1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          size: 13,
                          color: AppColors.goldDeep,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'آية الفترة',
                          style: TextStyle(
                            color: _textSoft(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${data.ayahOfDaySurah} · ${data.ayahOfDay.ayah}',
                          style: const TextStyle(
                            color: AppColors.goldDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.chevron_left,
                          size: 13,
                          color: _textSoft(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatAyahForWidgetDisplay(data.ayahOfDay.textUthmani),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textStrong(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (data.dhikrOfDay.isNotEmpty) ...[
              const SizedBox(height: 6),
              Divider(color: _cardBorder(context), height: 1),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '📿 ذكر الفترة:',
                        style: TextStyle(
                          color: _textSoft(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data.dhikrOfDay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textStrong(context).withValues(alpha: 0.95),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_left,
                        size: 13,
                        color: _textSoft(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
    );
  }
}

class _PeriodVerseFooter extends ConsumerWidget {
  const _PeriodVerseFooter({required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // آية الفترة — النقر عليها يفتح المصحف عند الصفحة المحددة مع تظليل الآية
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ref
                .read(mushafJumpRequestProvider.notifier)
                .request(page: data.ayahOfDay.page, ayahId: data.ayahOfDay.id);
            ref.read(rootTabIndexProvider.notifier).select(1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 13,
                      color: AppColors.goldSoft,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'آية الفترة',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${data.ayahOfDaySurah} · ${data.ayahOfDay.ayah}',
                      style: const TextStyle(
                        color: AppColors.goldSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_left,
                      size: 13,
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  formatAyahForWidgetDisplay(data.ayahOfDay.textUthmani),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (data.dhikrOfDay.isNotEmpty) ...[
          const SizedBox(height: 6),
          Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                children: [
                  const Text(
                    '📿 ذكر الفترة:',
                    style: TextStyle(
                      color: AppColors.goldSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.dhikrOfDay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_left,
                    size: 13,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// بطاقة "بلا موقع بعد" — **بنفس هوية `PrayerCountdownCard` اللونية
/// تماماً** (تدرّج `accent.primaryLight/primaryDark` + نص أبيض/ذهبي فاتح)
/// عمداً لا بطاقة بيضاء عادية. قبل هالتعديل كانت بيضاء (`_cardSurface`)
/// بينما البطاقة الحقيقية بعد تحديد الموقع كحلي/بلون التمييز — يعني
/// المستخدم يشوف "ومضة بيضاء" ثم تنقلب أزرق فجأة أول ما يحدَّد الموقع.
/// هلق الانتقال بلا قفزة لونية محسوسة، بس المحتوى يتبدّل.
class _NoLocationPrayerCard extends ConsumerWidget {
  const _NoLocationPrayerCard({this.footer});
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accentColorVersionProvider);
    final accent = appAccentColorById(
      ref.read(userPrefsProvider).accentColorId,
    );

    return Card(
      color: accent.primaryDark,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeAccent(context).withValues(alpha: 0.35)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [accent.primaryLight, accent.primaryDark],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    ref.read(locationControllerProvider.notifier).useGps(),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.goldSoft,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مواقيت الصلاة بحسب موقعك',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'اضغط لتحديد موقعك تلقائياً وعرض أوقات الأذان والقبلة',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.my_location,
                      color: AppColors.goldSoft,
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 10),
                Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                const SizedBox(height: 8),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingCard extends ConsumerWidget {
  const _LeadingCard({required this.dayTimes, required this.now});
  final List<PrayerMomentTime>? dayTimes;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dayTimes == null) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.goldDeep,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'حدّد موقعك لحساب مواقيت الصلاة وأذكار الفترة',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: _textStrong(context)),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(locationControllerProvider.notifier).useGps(),
              child: const Text('تحديد', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final slot = _slotFor(dayTimes!, now);

    return switch (slot) {
      _DaySlot.beforeFajr || _DaySlot.night => _NightQiyamCard(
        title: slot == _DaySlot.beforeFajr ? 'سحر مبارك' : 'أذكار النوم والوتر',
        subtitle: slot == _DaySlot.beforeFajr
            ? 'وقت السحر والتهجد والاستغفار'
            : 'أوتر قبل أن تنام واقرأ أذكارك',
      ),
      _DaySlot.morning => const _AzkarLeadingCard(
        title: 'أذكار الصباح',
        subtitle: 'أصبحنا وأصبح الملك لله — ابدأ يومك بالذكر',
        period: AzkarPeriod.morning,
        icon: Icons.wb_sunny_outlined,
      ),
      _DaySlot.midday => const _MiddayLeadingCard(),
      _DaySlot.evening => const _AzkarLeadingCard(
        title: 'أذكار المساء',
        subtitle: 'أمسينا وأمسى الملك لله — حصّن نفسك',
        period: AzkarPeriod.evening,
        icon: Icons.wb_twilight,
      ),
      _DaySlot.unknown => const _AzkarLeadingCard(
        title: 'أذكار اليوم',
        subtitle: '«ألا بذكر الله تطمئن القلوب»',
        period: AzkarPeriod.morning,
        icon: Icons.brightness_2_outlined,
      ),
    };
  }
}

class _NightQiyamCard extends StatelessWidget {
  const _NightQiyamCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const QiyamScreen())),
      child: Row(
            children: [
              const _TintedIconBadge(
                icon: Icons.dark_mode_outlined,
                color: AppColors.navy,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textStrong(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: _textSoft(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: _textSoft(context), size: 18),
            ],
          ),
    );
  }
}

class _AzkarLeadingCard extends ConsumerWidget {
  const _AzkarLeadingCard({
    required this.title,
    required this.subtitle,
    required this.period,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final AzkarPeriod period;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
      child: Row(
            children: [
              _TintedIconBadge(icon: icon, color: AppColors.teal, iconColor: AppColors.tealDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textStrong(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: _textSoft(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: _textSoft(context), size: 18),
            ],
          ),
    );
  }
}

class _MiddayLeadingCard extends ConsumerWidget {
  const _MiddayLeadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
      child: Row(
            children: [
              const _TintedIconBadge(
                icon: Icons.fingerprint,
                color: AppColors.gold,
                iconColor: AppColors.goldDeep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المسبحة الإلكترونية',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textStrong(context),
                      ),
                    ),
                    Text(
                      '«سُبْحَانَ اللَّهِ وَبِحَمْدِهِ» — رطّب لسانك بذكر الله',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: _textSoft(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: _textSoft(context), size: 18),
            ],
          ),
    );
  }
}

class _StreaksRow extends ConsumerWidget {
  const _StreaksRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final activeKeys = ref.watch(dashboardCustomPrefsProvider);

    final allItems = [
      (
        key: 'prayers_fard',
        icon: Icons.mosque_outlined,
        label: 'الصلوات\nالمكتوبة',
        days: userPrefs.streakDaysFor(UserCategories.fajr),
        color: AppColors.navy,
        action: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrayerChecklistScreen()),
        ),
      ),
      (
        key: UserCategories.morningAzkar,
        icon: Icons.wb_sunny_outlined,
        label: 'أذكار\nالصباح',
        days: userPrefs.streakDaysFor(UserCategories.morningAzkar),
        color: AppColors.gold,
        action: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      (
        key: UserCategories.eveningAzkar,
        icon: Icons.wb_twilight,
        label: 'أذكار\nالمساء',
        days: userPrefs.streakDaysFor(UserCategories.eveningAzkar),
        color: AppColors.teal,
        action: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      (
        key: 'daily_quran',
        icon: Icons.menu_book_outlined,
        label: 'الورد\nاليومي',
        days: userPrefs.streakDays,
        color: AppColors.blue,
        action: () => ref.read(rootTabIndexProvider.notifier).select(1),
      ),
      (
        key: UserCategories.hifz,
        icon: Icons.school_outlined,
        label: 'الحفظ',
        days: userPrefs.streakDaysFor(UserCategories.hifz),
        // نفس لون أيقونة `_HifzCard` أسفل هالملف — لا لون عشوائي جديد.
        color: AppColors.purple,
        action: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HifzScreen())),
      ),
      (
        key: UserCategories.nightAzkar,
        icon: Icons.bedtime_outlined,
        label: 'أذكار\nالنوم',
        days: userPrefs.streakDaysFor(UserCategories.nightAzkar),
        color: AppColors.navyDeep,
        action: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      (
        key: UserCategories.qiyam,
        icon: Icons.dark_mode_outlined,
        label: 'قيام\nالليل',
        days: userPrefs.streakDaysFor(UserCategories.qiyam),
        // نفس لون `_NightQiyamCard._TintedIconBadge` أعلاه — لا لون عشوائي جديد.
        color: AppColors.navy,
        action: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const QiyamScreen())),
      ),
      (
        key: 'prayers_rawatib',
        icon: Icons.auto_awesome_outlined,
        label: 'السنن\nالرواتب',
        days: userPrefs.streakDaysFor(UserCategories.rawatib),
        color: AppColors.blue,
        action: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrayerChecklistScreen()),
        ),
      ),
      (
        key: 'tasbih',
        icon: Icons.fingerprint,
        label: 'التسبيح\nوالذكر',
        days: userPrefs.streakDaysFor('tasbih'),
        // نفس لون `_MiddayLeadingCard._TintedIconBadge` أعلاه — لا لون عشوائي جديد.
        color: AppColors.gold,
        action: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      (
        key: UserCategories.customHabitsAny,
        icon: Icons.checklist_rtl_outlined,
        label: 'عاداتي',
        days: userPrefs.streakDaysFor(UserCategories.customHabitsAny),
        color: AppColors.purple,
        action: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CustomHabitsScreen())),
      ),
    ];

    final filtered = allItems
        .where((it) => activeKeys.contains(it.key))
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.local_fire_department_outlined,
          label: 'سلاسل الاستمرار',
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: [
            for (final item in filtered)
              _StreakChip(
                icon: item.icon,
                label: item.label,
                days: item.days,
                color: item.color,
                iconColor: switch (item.color) {
                  AppColors.gold => AppColors.goldDeep,
                  AppColors.teal => AppColors.tealDeep,
                  final c => c,
                },
                onTap: item.action,
              ),
          ],
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({
    required this.icon,
    required this.label,
    required this.days,
    required this.color,
    required this.onTap,
    Color? iconColor,
  }) : iconColor = iconColor ?? color;

  final IconData icon;
  final String label;
  final int days;
  final Color color;
  // خلفية الدائرة تبقى بلون [color] بشفافية خفيفة (زخرفة). الأيقونة نفسها
  // تحتاج ٣:١ على الأقل فوق البطاقة البيضاء — [iconColor] يسمح بدرجة أغمق
  // (goldDeep) عند الحاجة بدل [color] مباشرة.
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      onTap: onTap,
      child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  '$days',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textStrong(context),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: _textSoft(context),
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _TintedIconBadge extends StatelessWidget {
  const _TintedIconBadge({required this.icon, required this.color, Color? iconColor})
    : iconColor = iconColor ?? color;
  final IconData icon;
  final Color color;
  // خلفية الدائرة تبقى بلون [color] الأصلي بشفافية خفيفة (زخرفة، لا حاجة
  // لتباين). الأيقونة نفسها تحتاج ٣:١ على الأقل فوق البطاقة البيضاء —
  // [iconColor] يسمح بتمرير درجة أغمق (goldDeep) بدل [color] عند الحاجة.
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return IconBadge(icon: icon, color: color, iconColor: iconColor);
  }
}

/// شارة صغيرة "دقائق التلاوة هذا الأسبوع" — راجع
/// `UserRepository.getAudioMinutes`/`audio_log` (`quran_audio_controller.dart`
/// يسجّل ثواني الاستماع الفعلية). تظهر فقط لو استمع المستخدم فعلياً هذا
/// الأسبوع (>٠ دقيقة) — بلا بطاقة فارغة لمستخدم جديد.
class _ListeningMinutesChip extends StatelessWidget {
  const _ListeningMinutesChip({required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.headphones_outlined,
            color: AppColors.tealDeep,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'دقائق التلاوة هذا الأسبوع: $minutes دقيقة',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textStrong(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// ورد اليوم لخطة ختمة — إعادة حساب **حيّة** حسب التقدّم الفعلي الحالي
/// (لا الوتيرة الأصلية الثابتة `plan.dailyPages` المحسوبة عند بدء الخطة
/// فقط): الصفحات المتبقّية ÷ الأيام المتبقّية من مدّة الخطة الأصلية. لو
/// انتهت المدّة الأصلية ولم تكتمل الختمة بعد، "حساب جديد تلقائياً" — نرجع
/// لنفس وتيرة الخطة الأصلية بدل قسمة كل الصفحات المتبقّية على يوم واحد
/// (رقم غير معقول بصفحة واحدة قد يعني ٢٠٠+ صفحة).
int wirdPagesForToday(KhatmaPlan plan) {
  final pagesRemaining = 604 - plan.currentPage;
  if (pagesRemaining <= 0) return 0;

  // **لا** نستخدم `plan.daysElapsed` هون — مُقيَّد عمداً بحد أقصى
  // `targetDays` (لعرض "الصفحة المتوقَّعة اليوم" بمكان آخر)، فـ"الأيام
  // المتبقّية" المحسوبة منه لا تقل عن ١ أبداً حتى لو تجاوزت الخطة مدّتها
  // الأصلية فعلياً بأسابيع — يمنع اكتشاف "انتهت المدّة" كلياً. نحسب هون
  // عدد الأيام الحقيقي المنقضي (بلا تقييد) للكشف الصحيح عن انتهاء المدّة.
  final rawDaysElapsed = DateTime.now().difference(plan.startDate).inDays + 1;
  final expired = rawDaysElapsed > plan.targetDays;
  if (expired) {
    // "حساب جديد تلقائياً" — وتيرة الخطة الأصلية بدل قسمة كل الصفحات
    // المتبقّية على يوم واحد فقط (رقم غير معقول).
    return plan.dailyPages.clamp(1, pagesRemaining);
  }

  final daysRemaining = plan.targetDays - rawDaysElapsed + 1;
  return (pagesRemaining / daysRemaining).ceil().clamp(1, pagesRemaining);
}

/// بطاقة "أهدافي اليوم" المجمَّعة — تحل محل ٣ بطاقات منفصلة (ختمة/حفظ/
/// متابعة قراءة) كانت متطابقة الشكل تقريباً (نفس الحد/الظل/الاستدارة)
/// ومتكدّسة تباعاً، بشكوى صريحة "سيل بطاقات متطابقة". كل صف يستخدم حلقة
/// تقدّم دائرية (`CircularProgressIndicator`) بدل الشريط المسطّح — نفس
/// تدرّج اللون الدلالي الأصلي (أزرق للختمة، بنفسجي للحفظ) بلا تغيير.
class _GoalsGroupCard extends ConsumerWidget {
  const _GoalsGroupCard({
    this.khatmaPlan,
    this.hifzPlan,
    this.continueReadingSurah,
  });

  final KhatmaPlan? khatmaPlan;
  final HifzPlan? hifzPlan;
  final String? continueReadingSurah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <Widget>[
      if (khatmaPlan != null) _KhatmaGoalRow(plan: khatmaPlan!),
      if (hifzPlan != null) _HifzGoalRow(plan: hifzPlan!),
      if (continueReadingSurah != null)
        _ContinueReadingGoalRow(
          surahName: continueReadingSurah!,
          onTap: () => ref.read(rootTabIndexProvider.notifier).select(1),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.auto_awesome_outlined,
            label: 'أهدافي اليوم',
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: _cardBorder(context)),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// عنوان قسم صغير (أيقونة برُقعة + نص) — يُستخدَم فوق البطاقات المجمَّعة
/// (الأهداف، سلاسل الاستمرار) بنفس أسلوب لوحة التصميم المعتمدة، بدل
/// قفز مباشر من بطاقة لبطاقة بلا عنوان يفصلها.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _cardBorder(context),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 13, color: _textStrong(context)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _textStrong(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalDonut extends StatelessWidget {
  const _GoalDonut({
    required this.size,
    required this.progress,
    required this.color,
    this.fontSize = 11,
  });
  final double size;
  final double progress;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: size >= 50 ? 6 : 5,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '${(progress * 100).round()}٪',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _KhatmaGoalRow extends StatelessWidget {
  const _KhatmaGoalRow({required this.plan});
  final KhatmaPlan plan;

  @override
  Widget build(BuildContext context) {
    final progress = (plan.expectedPageByNow / 604).clamp(0.0, 1.0);
    final wirdPages = wirdPagesForToday(plan);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          _GoalDonut(size: 52, progress: progress, color: AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ختمة القرآن',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _textStrong(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wirdPages > 0
                      ? 'ورد اليوم: $wirdPages صفحة'
                      : 'أتممت وردك بالكامل اليوم',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: _textSoft(context)),
                ),
              ],
            ),
          ),
          if (wirdPages > 0) ...[
            const SizedBox(width: 6),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MushafScreen(
                    initialPage: plan.currentPage,
                    khatmaPracticeMode: true,
                    khatmaPlanId: plan.id,
                    wirdTargetPage: (plan.currentPage + wirdPages - 1).clamp(
                      1,
                      604,
                    ),
                  ),
                ),
              ),
              child: const Text('ابدأ وردي', style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ],
      ),
    );
  }
}

class _HifzGoalRow extends StatelessWidget {
  const _HifzGoalRow({required this.plan});
  final HifzPlan plan;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HifzScreen())),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            _GoalDonut(
              size: 44,
              progress: plan.progress,
              color: AppColors.purple,
              fontSize: 9.5,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الحفظ والمراجعة',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _textStrong(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(plan.progress * 100).round()}٪ من الخطة الحالية',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _textSoft(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: _textSoft(context), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ContinueReadingGoalRow extends StatelessWidget {
  const _ContinueReadingGoalRow({required this.surahName, required this.onTap});
  final String surahName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _cardBorder(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.menu_book_outlined,
                color: _textStrong(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متابعة القراءة',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textStrong(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'آخر قراءة: $surahName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _textSoft(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: _textSoft(context), size: 18),
          ],
        ),
      ),
    );
  }
}

/// دعوة لبدء خطة ختمة/حفظ — تظهر فقط لو ما عند المستخدم خطة نشطة من
/// النوع المعني بعد (سدّ فجوة الاكتشاف: بطاقتَي `_KhatmaCard`/`_HifzCard`
/// لا تظهران إلا بعد بدء خطة أصلاً، فبلا هاي الدعوة ما فيه أي إشارة
/// بالداشبورد توجّه مستخدم جديد لبدء واحدة).
class _StartPlanPrompt extends StatelessWidget {
  const _StartPlanPrompt({required this.showKhatma, required this.showHifz});
  final bool showKhatma;
  final bool showHifz;

  @override
  Widget build(BuildContext context) {
    final bothMissing = showKhatma && showHifz;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TintedIconBadge(
                icon: Icons.rocket_launch_outlined,
                color: AppColors.gold,
                iconColor: AppColors.goldDeep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bothMissing
                      ? 'ابدأ رحلتك مع القرآن اليوم'
                      : showKhatma
                      ? 'ما بدأت خطة ختمة بعد'
                      : 'ما بدأت خطة حفظ بعد',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _textStrong(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bothMissing
                ? 'خطة ختمة أو خطة حفظ بتساعدك تلتزم بوردك اليومي بانتظام'
                : showKhatma
                ? 'حدّد وتيرتك اليومية وتابع تقدّمك صفحة بصفحة'
                : 'حدّد ما تحفظه وتابع مراجعتك بجدول ذكي',
            style: TextStyle(fontSize: 11, color: _textSoft(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (showKhatma)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const KhatmaScreen()),
                    ),
                    child: const Text(
                      'ابدأ خطة ختمة',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ),
              if (showKhatma && showHifz) const SizedBox(width: 8),
              if (showHifz)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HifzScreen()),
                    ),
                    child: const Text(
                      'ابدأ خطة حفظ',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _cardBorder(context),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
