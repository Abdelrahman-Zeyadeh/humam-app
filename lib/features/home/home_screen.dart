import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../../core/hijri/hijri_date.dart';
import '../../core/theme/app_colors.dart';
import '../prayer/prayer_countdown_card.dart';
import '../prayer/prayer_location_controller.dart';
import '../prayer/prayer_times_service.dart';
import '../qiyam/qiyam_screen.dart';
import '../shell/root_shell.dart';
import 'home_dashboard_data.dart';

/// نافذة زمنية مبنية على مواقيت اليوم — تقرّر محتوى بطاقة الصدارة.
enum _DaySlot { beforeFajr, morning, midday, evening, night, unknown }

_DaySlot _slotFor(List<PrayerMomentTime> dayTimes, DateTime now) {
  DateTime timeOf(PrayerMoment m) => dayTimes.firstWhere((t) => t.moment == m).time;
  if (now.isBefore(timeOf(PrayerMoment.fajr))) return _DaySlot.beforeFajr;
  if (now.isBefore(timeOf(PrayerMoment.dhuhr))) return _DaySlot.morning;
  if (now.isBefore(timeOf(PrayerMoment.asr))) return _DaySlot.midday;
  if (now.isBefore(timeOf(PrayerMoment.maghrib))) return _DaySlot.evening;
  return _DaySlot.night;
}

/// ألوان سطوح البطاقات حسب الثيم — نفس نمط `mushaf_screen.dart`
/// (`Theme.of(context).brightness`) بدل الاعتماد على `ThemeData.cardColor`
/// العام (غير مضبوط بهويتنا). كانت كل بطاقات الرئيسية بيضاء صراحة بلا
/// نظر للوضع الليلي — يبدو ذلك مسطّحاً/متعارضاً بخلفية داكنة، وهذا سبب
/// إعادة الضبط هون.
Color _cardSurface(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white;
Color _cardBorder(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.lineDark : AppColors.line;
Color _textStrong(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.inkOnDark : AppColors.navy;
Color _textSoft(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.inkSoftOnDark : AppColors.inkSoft;
List<BoxShadow> _cardShadow(BuildContext c) => [
      BoxShadow(
        color: (Theme.of(c).brightness == Brightness.dark ? Colors.black : AppColors.navy)
            .withValues(alpha: Theme.of(c).brightness == Brightness.dark ? 0.32 : 0.08),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];

/// الرئيسية — داشبورد مبني على بيانات حقيقية فقط: لا نِسَب تقدّم مختلَقة.
/// أذكار اليوم مثلاً غير معروضة كنسبة لأن عدّها جلسة-فقط عمداً (راجع
/// `azkar_progress.dart`)، لا سجلّاً يومياً دائماً — لا نعرض رقماً وهمياً.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(locationVersionProvider);
    final locationPrefs = ref.watch(locationPrefsProvider);
    final khatmaPrefs = ref.watch(khatmaPrefsProvider);
    final dashboardAsync = ref.watch(homeDashboardDataProvider);
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

    // بطاقة الصدارة الموحَّدة: عدّاد الصلاة القادمة + آية/ذكر الفترة معاً
    // بنفس "الودجت" (كانا بطاقتين منفصلتين تحته سابقاً). بلا موقع مضبوط
    // نعرض آية/ذكر الفترة وحدها ببطاقة بديلة أخف بدل فقدانهما كلياً.
    final Widget heroCard;
    if (locationPrefs.hasLocation) {
      heroCard = PrayerCountdownCard(
        lat: locationPrefs.lat!,
        lon: locationPrefs.lon!,
        methodKey: locationPrefs.calculationMethod,
        onTap: () => ref.read(rootTabIndexProvider.notifier).select(2),
        footer: dashboardAsync.maybeWhen(
          data: (data) => _PeriodVerseBlock(
            data: data,
            labelColor: AppColors.goldSoft,
            textColor: Colors.white,
            dividerColor: Colors.white.withValues(alpha: 0.14),
          ),
          orElse: () => null,
        ),
      );
    } else {
      heroCard = dashboardAsync.when(
        data: (data) => _StandalonePeriodCard(data: data),
        loading: () => const _CardSkeleton(height: 220),
        error: (_, _) => const SizedBox.shrink(),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Header(hijri: todayHijriArabic()),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    heroCard,
                    const SizedBox(height: 16),
                    _LeadingCard(dayTimes: dayTimes, now: now),
                    const SizedBox(height: 16),
                    const _StreaksRow(),
                    if (khatmaPrefs.activePlan != null) ...[
                      const SizedBox(height: 12),
                      _KhatmaCard(plan: khatmaPrefs.activePlan!),
                    ],
                    if (dashboardAsync.value?.continueReadingSurah != null) ...[
                      const SizedBox(height: 16),
                      _ContinueReadingCard(surahName: dashboardAsync.value!.continueReadingSurah!),
                    ],
                    const SizedBox(height: 20),
                    const _QuickActionsGrid(),
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

class _Header extends StatelessWidget {
  const _Header({required this.hijri});
  final String hijri;

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting = h < 4
        ? 'طاب ليلك'
        : h < 12
            ? 'صباح الخير'
            : h < 17
                ? 'مساء الخير'
                : 'مساء الخير';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 56),
      decoration: const BoxDecoration(
        // نفس تخفيف تدرّج `PrayerCountdownCard` (طلب "ألوان أفتح") —
        // كحلي متوسط بدل كحلي شبه أسود.
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.blue, AppColors.navy],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('أهلاً بك في هُمَام', style: const TextStyle(color: AppColors.goldSoft, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Text(hijri, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// آية اليوم وذكره معاً — يظهر إما داخل [PrayerCountdownCard] (فوتر على
/// خلفية كحلية) أو ببطاقة مستقلة (`_StandalonePeriodCard`) لو لا موقع
/// مضبوط. المحتوى يتغيّر كل ٤ ساعات (راجع `home_dashboard_data.dart`)،
/// لا يبقى ثابتاً طول اليوم. الألوان تُمرَّر صراحة لأنها تختلف حسب السطح
/// اللي يُرسَم فوقه.
class _PeriodVerseBlock extends StatelessWidget {
  const _PeriodVerseBlock({
    required this.data,
    required this.labelColor,
    required this.textColor,
    required this.dividerColor,
  });
  final HomeDashboardData data;
  final Color labelColor;
  final Color textColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('آية الفترة', style: TextStyle(fontSize: 10.5, color: labelColor, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Text(
          data.ayahOfDay.textUthmani,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: 'Amiri', fontSize: 15, height: 1.7, color: textColor),
        ),
        const SizedBox(height: 3),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('${data.ayahOfDaySurah} - ${data.ayahOfDay.ayah}', style: TextStyle(fontSize: 10.5, color: labelColor)),
        ),
        if (data.dhikrOfDay.isNotEmpty) ...[
          const SizedBox(height: 10),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text('ذكر الفترة', style: TextStyle(fontSize: 10.5, color: labelColor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          Text(
            data.dhikrOfDay,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, height: 1.6, color: textColor),
          ),
        ],
      ],
    );
  }
}

/// بديل [_PeriodVerseBlock] لو لا موقع مضبوط بعد — بطاقة مستقلة بدل ضياع
/// آية/ذكر الفترة كلياً ريثما يضبط المستخدم موقعه (`PrayerCountdownCard`
/// نفسها تحتاج إحداثيات لحساب العدّاد).
class _StandalonePeriodCard extends StatelessWidget {
  const _StandalonePeriodCard({required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? AppColors.lineDark : AppColors.goldSoft),
        boxShadow: _cardShadow(context),
      ),
      child: _PeriodVerseBlock(
        data: data,
        labelColor: AppColors.gold,
        textColor: _textStrong(context),
        dividerColor: _cardBorder(context),
      ),
    );
  }
}

/// بطاقة الصدارة الديناميكية — محتواها حسب موقع الوقت الحالي من مواقيت
/// اليوم (لو الموقع مضبوط)، وإلا دعوة لضبط الموقع. **لا نص دعاء/ذِكر
/// مكتوب هون مباشرة** — فقط تسميات تنقّل، النص الديني الفعلي يُقرأ من
/// شاشة الأذكار نفسها (مصدره الموثّق) عند الانتقال إليها.
class _LeadingCard extends ConsumerWidget {
  const _LeadingCard({required this.dayTimes, required this.now});
  final List<PrayerMomentTime>? dayTimes;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dayTimes == null) {
      return _cardShell(
        context,
        icon: Icons.location_on_outlined,
        title: 'اضبط موقعك',
        subtitle: 'لحساب مواقيت الصلاة وتخصيص بطاقتك اليومية',
        onTap: () => ref.read(rootTabIndexProvider.notifier).select(2),
      );
    }

    final slot = _slotFor(dayTimes!, now);
    final fajr = dayTimes!.firstWhere((t) => t.moment == PrayerMoment.fajr).time;

    return switch (slot) {
      _DaySlot.beforeFajr => _cardShell(
          context,
          icon: Icons.nights_stay_outlined,
          title: 'قبل الفجر',
          subtitle: 'الفجر خلال ${_formatRemaining(fajr.difference(now))}',
          onTap: () => ref.read(rootTabIndexProvider.notifier).select(2),
        ),
      _DaySlot.morning => _cardShell(
          context,
          icon: Icons.wb_sunny_outlined,
          title: 'أذكار الصباح',
          subtitle: 'ابدأ يومك بورد الصباح',
          onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
        ),
      _DaySlot.evening => _cardShell(
          context,
          icon: Icons.wb_twilight,
          title: 'أذكار المساء',
          subtitle: 'وقت ورد المساء',
          onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
        ),
      _DaySlot.night => _cardShell(
          context,
          icon: Icons.dark_mode_outlined,
          title: 'قيام الليل',
          subtitle: 'تابع مصحفك أو أذكار النوم',
          onTap: () => ref.read(rootTabIndexProvider.notifier).select(1),
        ),
      _DaySlot.midday || _DaySlot.unknown => _cardShell(
          context,
          icon: Icons.menu_book_outlined,
          title: 'تابع القراءة',
          subtitle: 'افتح مصحفك من حيث توقّفت',
          onTap: () => ref.read(rootTabIndexProvider.notifier).select(1),
        ),
    };
  }

  Widget _cardShell(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _cardSurface(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldSoft),
            boxShadow: _cardShadow(context),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textStrong(context))),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 12.5, color: _textSoft(context))),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: _textSoft(context)),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatRemaining(Duration d) {
  final positive = d.isNegative ? Duration.zero : d;
  final h = positive.inHours;
  final m = positive.inMinutes % 60;
  if (h > 0) return '$hس $mد';
  return '$mد';
}

/// شبكة مربّعة (٣×٢) بسلاسل الاستمرار الست المستقلة (راجع [UserCategories])
/// — بديل بطاقة "يوم متتالي" الوحيدة القديمة اللي كانت تخلط "قراءة
/// المصحف" بكل الأنشطة، وبديل الصف الأفقي القابل للتمرير اللي كان يخفي
/// آخر خانتين بلا سحب. الضغط على أي خانة ينقل للتبويب/الشاشة المسؤولة عنها.
class _StreaksRow extends ConsumerWidget {
  const _StreaksRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final items = <({IconData icon, String label, int days, int? tab})>[
      (icon: Icons.wb_sunny_outlined, label: 'أذكار\nالصباح', days: userPrefs.streakDaysFor(UserCategories.morningAzkar), tab: 3),
      (icon: Icons.nights_stay_outlined, label: 'أذكار\nالمساء', days: userPrefs.streakDaysFor(UserCategories.eveningAzkar), tab: 3),
      (icon: Icons.menu_book_outlined, label: 'الورد\nاليومي', days: userPrefs.streakDays, tab: 1),
      (icon: Icons.school_outlined, label: 'الحفظ', days: userPrefs.streakDaysFor(UserCategories.hifz), tab: 1),
      (icon: Icons.bedtime_outlined, label: 'أذكار\nالنوم', days: userPrefs.streakDaysFor(UserCategories.nightAzkar), tab: 3),
      (icon: Icons.dark_mode_outlined, label: 'قيام\nالليل', days: userPrefs.streakDaysFor(UserCategories.qiyam), tab: null),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1,
      children: [
        for (final item in items)
          _StreakChip(
            icon: item.icon,
            label: item.label,
            days: item.days,
            onTap: () {
              if (item.tab == null) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiyamScreen()));
              } else {
                ref.read(rootTabIndexProvider.notifier).select(item.tab!);
              }
            },
          ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.icon, required this.label, required this.days, required this.onTap});
  final IconData icon;
  final String label;
  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardSurface(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder(context)),
            boxShadow: _cardShadow(context),
          ),
          padding: const EdgeInsets.all(8),
          // `FittedBox` بدل ارتفاع/خط ثابتَين: يضمن عدم فيض المحتوى مهما
          // كبر مقياس خط النظام — نفس درس فيض شيت إجراءات الآية سابقاً،
          // هون طُبِّق وقائياً بدل انتظار بلاغ عطل تاني.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.gold, size: 20),
                const SizedBox(height: 6),
                Text('$days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textStrong(context))),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: _textSoft(context), fontWeight: FontWeight.w600, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KhatmaCard extends StatelessWidget {
  const _KhatmaCard({required this.plan});
  final KhatmaPlan plan;

  @override
  Widget build(BuildContext context) {
    final progress = (plan.expectedPageByNow / 604).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder(context)),
        boxShadow: _cardShadow(context),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(progress * 100).round()}٪ من الختمة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textStrong(context))),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: _cardBorder(context),
                    color: AppColors.blue,
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

class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard({required this.surahName});
  final String surahName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: _cardSurface(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => ref.read(rootTabIndexProvider.notifier).select(1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder(context)),
            boxShadow: _cardShadow(context),
          ),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined, color: _textStrong(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('متابعة القراءة', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textStrong(context))),
                    // `surahName` = `nameArPlain` وهو أصلاً "سورة الكهف" مثلاً
                    // (الكلمة جزء من الاسم بقاعدة البيانات) — لا نضيف "سورة" هون.
                    Text('آخر قراءة: $surahName', style: TextStyle(fontSize: 12, color: _textSoft(context))),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: _textSoft(context)),
            ],
          ),
        ),
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
      decoration: BoxDecoration(color: _cardBorder(context), borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      (icon: Icons.menu_book_outlined, label: 'المصحف', color: AppColors.navy, tab: 1),
      (icon: Icons.access_time_outlined, label: 'الصلاة', color: AppColors.blue, tab: 2),
      (icon: Icons.brightness_2_outlined, label: 'الأذكار', color: AppColors.teal, tab: 3),
      (icon: Icons.more_horiz, label: 'المزيد', color: AppColors.purple, tab: 4),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final item in items)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => ref.read(rootTabIndexProvider.notifier).select(item.tab),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: item.color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                  child: Icon(item.icon, color: item.color, size: 21),
                ),
                const SizedBox(height: 6),
                Text(item.label, style: TextStyle(fontSize: 11, color: _textSoft(context), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}
