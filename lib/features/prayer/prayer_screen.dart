import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:just_audio/just_audio.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../azkar/azkar_full_repository.dart';
import '../azkar/azkar_library_category_screen.dart';
import '../notifications/adhan_notification_prefs.dart';
import '../notifications/adhan_notification_service.dart';
import '../onboarding/onboarding_target_keys.dart';
import 'adhan_download_service.dart';
import 'adhan_voices.dart';
import 'prayer_analytics_screen.dart';
import 'prayer_countdown_card.dart';
import 'prayer_location_controller.dart';
import 'prayer_times_service.dart';
import 'qibla_screen.dart';

/// فهرس قسم "الأَذْكَارُ بَعْدَ السَّلَامِ مِنَ الصَّلَاةِ" بمكتبة حصن المسلم
/// (`assets/azkar/azkar_categories.json`) — تحقّقتُ منه مباشرة بالملف، ثابت
/// عبر إعادة البناء (نفس ثبات `sleepAzkarProvider.id == 28`). يُستخدم لفتح
/// القسم مباشرة بعد تسجيل صلاة (بطلب صاحب المشروع: "أذكار بعد الصلاة تلقائياً").
const _kPostPrayerAzkarCategoryId = 24;

/// يفتح قسم أذكار ما بعد الصلاة مباشرة — يُستدعى بعد تسجيل صلاة (يدوياً
/// هون، أو من اقتراح بشريط سفلي). لا تنقّل مباشر من إشعار "هل صليت؟" نفسه
/// (`AdhanNotificationService`) — قد يصل الرد بمعزل خلفي بلا واجهة أصلاً،
/// فذاك المسار يكتفي بإشعار تذكير ثانٍ بدل تنقّل مباشر.
Future<void> _openPostPrayerAzkar(BuildContext context, WidgetRef ref) async {
  final categories = await ref.read(azkarLibraryProvider.future);
  final category = categories.firstWhere(
    (c) => c.id == _kPostPrayerAzkarCategoryId,
  );
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AzkarLibraryCategoryScreen(category: category),
    ),
  );
}

/// شاشة مواقيت الصلاة: مواقيت اليوم الستة (شاملة الشروق للعرض) + عدّاد
/// للصلاة القادمة + اختيار الموقع (GPS/مدينة) وطريقة الحساب. حساب محلي
/// بالكامل عبر `adhan_dart` — لا استدعاء شبكة، يعمل بوضع الطيران بعد
/// تحديد الموقع مرة واحدة. راجع `tools/raw/README.md` لقيود التحقّق الميداني.
class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(locationVersionProvider);
    ref.watch(adhanNotificationVersionProvider);
    // يحلّل اسم المنطقة تلقائياً لو كان محفوظاً بالنص الثابت القديم —
    // راجع توثيق `cityNameBackfillProvider` (بلا أي ضغطة من المستخدم).
    ref.watch(cityNameBackfillProvider);
    final prefs = ref.watch(locationPrefsProvider);
    final notifPrefs = ref.watch(adhanNotificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(
            icon: Icon(
              notifPrefs.masterEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
            tooltip: notifPrefs.masterEnabled
                ? 'إشعارات الأذان مفعّلة'
                : 'إشعارات الأذان معطّلة',
            onPressed: () =>
                _toggleNotifications(context, ref, prefs, notifPrefs),
          ),
          IconButton(
            key: qiblaButtonKey,
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'القبلة',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const QiblaScreen())),
          ),
        ],
      ),
      body: prefs.hasLocation
          ? _TimesView(prefs: prefs)
          : const _LocationPrompt(),
    );
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — الخدمة نفسها آمنة على
  /// أندرويد/iOS (فشل داخلي = تراجع أو `debugPrint`)، لكن على منصّات
  /// أخرى (ويندوز مثلاً بلا `WindowsInitializationSettings`) `initialize`
  /// نفسها ترمي. جُرِّب هذا فعلياً (`flutter run -d windows`) ورُصد
  /// استثناء غير مُمسَك قبل إضافة try/catch هون — راجع أيضاً ملاحظة
  /// `main.dart` بخصوص اقتصار التفعيل التلقائي على أندرويد/iOS.
  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    LocationPrefs prefs,
    AdhanNotificationPrefs notifPrefs,
  ) async {
    final next = !notifPrefs.masterEnabled;
    await notifPrefs.setMasterEnabled(next);
    ref.read(adhanNotificationVersionProvider.notifier).bump();

    try {
      if (next) {
        await AdhanNotificationService.instance.requestPermissions();
        if (prefs.hasLocation) {
          final userPrefs = ref.read(userPrefsProvider);
          await AdhanNotificationService.instance.rescheduleUpcoming(
            lat: prefs.lat!,
            lon: prefs.lon!,
            methodKey: prefs.calculationMethod,
            isEnabled: notifPrefs.effectivelyEnabled,
            voiceId: userPrefs.adhanVoiceId,
            // إعداد متابعة "هل صليت؟" مستقل عن تفعيل/تعطيل الأذان نفسه —
            // مرَّر كما هو محفوظاً بدل تعطيله ضمنياً بإعادة الجدولة هون
            // (راجع `_PrayerCheckinCard`, `rescheduleUpcoming` تلغي وتعيد
            // جدولة **كل** سلاسل المتابعة بكل استدعاء).
            checkinEnabled: userPrefs.prayerCheckinEnabled,
            checkinFirstDelayMinutes: userPrefs.prayerCheckinFirstDelayMinutes,
          );
        }
      } else {
        await AdhanNotificationService.instance.cancelAll();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط إشعارات الأذان على هذا الجهاز: $e')),
      );
    }
  }
}

class _LocationPrompt extends ConsumerWidget {
  const _LocationPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationControllerProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 48,
              color: themeAccent(context),
            ),
            const SizedBox(height: 16),
            Text(
              'حدّد موقعك لحساب مواقيت الصلاة',
              style: TextStyle(
                color: onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              icon: Icons.my_location,
              label: 'استخدام موقعي الحالي (GPS)',
              onPressed: locationState.isLoading
                  ? null
                  : () =>
                        ref.read(locationControllerProvider.notifier).useGps(),
            ),
            if (locationState.hasError) ...[
              const SizedBox(height: 12),
              Text(
                '${locationState.error}',
                style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            if (locationState.isLoading) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimesView extends ConsumerWidget {
  const _TimesView({required this.prefs});
  final LocationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final now = ref.watch(prayerTickProvider).value ?? DateTime.now();
    final dayTimes = computeDayTimes(
      lat: prefs.lat!,
      lon: prefs.lon!,
      date: now,
      methodKey: prefs.calculationMethod,
    );
    var next = nextPrayer(dayTimes, now);
    // كل صلوات اليوم فاتت — نعرض فجر الغد كبديل بدل ترك العدّاد فارغاً.
    if (next == null) {
      final tomorrow = computeDayTimes(
        lat: prefs.lat!,
        lon: prefs.lon!,
        date: now.add(const Duration(days: 1)),
        methodKey: prefs.calculationMethod,
      );
      next = tomorrow.firstWhere((t) => t.moment.isPrayer);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 95),
      children: [
        PrayerCountdownCard(
          lat: prefs.lat!,
          lon: prefs.lon!,
          methodKey: prefs.calculationMethod,
        ),
        const SizedBox(height: 16),
        // رجّعناها لشكلها البسيط الأصلي بطلب صاحب المشروع — راجع
        // `prefs.cityName` (`location_controller.dart`) لمصدر اسم المنطقة
        // نفسه (Geocoding عكسي حقيقي عبر GPS، لا اسم ثابت).
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      prefs.cityName ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'تحديث بـGPS',
              onPressed: () =>
                  ref.read(locationControllerProvider.notifier).useGps(),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'طريقة الحساب',
              onPressed: () => _showMethodPicker(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final t in dayTimes)
          Card(
            key:
                t.moment == dayTimes.firstWhere((x) => x.moment.isPrayer).moment
                ? firstPrayerRowKey
                : null,
            color: t.moment == next.moment
                ? themeAccent(context).withValues(alpha: 0.12)
                : null,
            child: ListTile(
              onTap: () {
                if (t.moment.isPrayer) {
                  _showPrayerDetailBottomSheet(
                    context,
                    ref,
                    prefs,
                    t.moment,
                    t.time,
                    dayTimes,
                  );
                }
              },
              leading: Icon(
                _iconFor(t.moment),
                color: onSurface.withValues(alpha: 0.7),
              ),
              title: Text(
                t.moment.nameAr,
                style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
              ),
              subtitle: t.moment.isPrayer
                  ? Text(
                      'الإقامة بعد ${ref.watch(userPrefsProvider).iqamahMinutesFor(t.moment.name)} دقيقة — اضغط للتعديل والتفاصيل',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.55),
                      ),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(
                      t.time.add(
                        Duration(
                          minutes: ref
                              .watch(userPrefsProvider)
                              .prayerOffsetFor(t.moment.name),
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (t.moment.isPrayer) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        _modeIcon(ref, t.moment),
                        size: 19,
                        color: themeAccent(context),
                      ),
                      tooltip: 'تفاصيل الصلاة والإقامة',
                      onPressed: () => _showPrayerDetailBottomSheet(
                        context,
                        ref,
                        prefs,
                        t.moment,
                        t.time,
                        dayTimes,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        // بطلب صاحب المشروع: أُزيلت بطاقة "الصلوات والعبادات" اللي كانت
        // هون — أصبح الوصول لـ`PrayerChecklistScreen` عبر زر "سجّل صلواتك
        // وعباداتك" داخل `PrayerCountdownCard` أعلى نفس هذه الشاشة، فبطاقة
        // ثانية بنفس الوجهة أسفل الشاشة صارت تكراراً لا داعي له.
        _PrayerCheckinCard(prefs: prefs),
      ],
    );
  }

  void _showMethodPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      builder: (sheetContext) {
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        // `kCalculationMethods` أطول من نصف الشاشة الافتراضي لصفحة سفلية
        // بلا تمرير داخلي — كانت تفيض فعلياً (BOTTOM OVERFLOWED) على
        // الشاشات الأقصر بدل التمرير. `isScrollControlled` + سقف ارتفاع +
        // `SingleChildScrollView` يحلّانها.
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'طريقة الحساب',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  for (final m in kCalculationMethods)
                    ListTile(
                      leading: Icon(
                        m.key == prefs.calculationMethod
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: m.key == prefs.calculationMethod
                            ? themeAccent(context)
                            : onSurface.withValues(alpha: 0.5),
                      ),
                      title: Text(m.nameAr, style: TextStyle(color: onSurface)),
                      onTap: () {
                        ref
                            .read(locationControllerProvider.notifier)
                            .setCalculationMethod(m.key);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "قسم الصلوات والعبادات" — سلسلة استمرار **مستقلة لكل صلاة فرض على
/// حدة** ("كل صلاة منفصلة إذا تمت أو لا"). إعادة استخدام كاملة لآلية
/// `UserCategories`/`bumpCategoryStreakIfNewDay`/`completedTodayFor`
/// الموجودة أصلاً — لا جدول جديد. **شاشة مستقلة** (لا بطاقة ضمن شاشة
/// الصلاة الرئيسية كما كانت) — راجع توثيق [_PrayersChecklistCard].
class PrayerChecklistScreen extends ConsumerStatefulWidget {
  const PrayerChecklistScreen({super.key});

  static const fardItems = [
    (
      category: UserCategories.fajr,
      label: 'الفجر',
      icon: Icons.nights_stay_outlined,
      moment: PrayerMoment.fajr,
    ),
    (
      category: UserCategories.dhuhr,
      label: 'الظهر',
      icon: Icons.wb_sunny_outlined,
      moment: PrayerMoment.dhuhr,
    ),
    (
      category: UserCategories.asr,
      label: 'العصر',
      icon: Icons.wb_sunny,
      moment: PrayerMoment.asr,
    ),
    (
      category: UserCategories.maghrib,
      label: 'المغرب',
      icon: Icons.wb_twilight,
      moment: PrayerMoment.maghrib,
    ),
    (
      category: UserCategories.isha,
      label: 'العشاء',
      icon: Icons.dark_mode_outlined,
      moment: PrayerMoment.isha,
    ),
  ];

  static const rawatibItems = [
    (
      category: UserCategories.sunnahFajrQabliyah,
      label: 'ركعتان قبل الفجر',
      confirmed: true,
      moment: PrayerMoment.fajr,
    ),
    (
      category: UserCategories.sunnahDuha,
      label: 'صلاة الضحى (ركعتان إلى ثمان)',
      confirmed: true,
      moment: PrayerMoment.sunrise,
    ),
    (
      category: UserCategories.sunnahDhuhrQabliyah,
      label: 'أربع ركعات قبل الظهر',
      confirmed: true,
      moment: PrayerMoment.dhuhr,
    ),
    (
      category: UserCategories.sunnahDhuhrBadiyah,
      label: 'ركعتان بعد الظهر',
      confirmed: true,
      moment: PrayerMoment.dhuhr,
    ),
    (
      category: UserCategories.sunnahAsrQabliyah,
      label: 'أربع ركعات قبل العصر',
      confirmed: false,
      moment: PrayerMoment.asr,
    ),
    (
      category: UserCategories.sunnahMaghribQabliyah,
      label: 'ركعتان قبل المغرب',
      confirmed: false,
      moment: PrayerMoment.maghrib,
    ),
    (
      category: UserCategories.sunnahMaghribBadiyah,
      label: 'ركعتان بعد المغرب',
      confirmed: true,
      moment: PrayerMoment.maghrib,
    ),
    (
      category: UserCategories.sunnahIshaBadiyah,
      label: 'ركعتان بعد العشاء',
      confirmed: true,
      moment: PrayerMoment.isha,
    ),
  ];

  @override
  ConsumerState<PrayerChecklistScreen> createState() =>
      _PrayerChecklistScreenState();
}

class _PrayerChecklistScreenState extends ConsumerState<PrayerChecklistScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncStreaks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncStreaks();
    }
  }

  Future<void> _syncStreaks() async {
    await ref.read(userPrefsProvider).reloadCategoryStreaks();
    if (mounted) {
      ref.read(categoryStreakVersionProvider.notifier).bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(categoryStreakVersionProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final loc = ref.watch(locationPrefsProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final fardDone = PrayerChecklistScreen.fardItems
        .where((i) => userPrefs.completedTodayFor(i.category))
        .length;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // هيدر بتدرّج كحلي مطابق للوحة التصميم المعتمدة (`Prayer.dc.html`)
          // — بدل `AppBar` الأبيض الافتراضي، مع ملخّص "X من ٥ فرائض" حي.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 14,
                16,
                18,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.blue, AppColors.navy],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'صلوات اليوم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$fardDone من ${PrayerChecklistScreen.fardItems.length} فرائض اليوم',
                          style: const TextStyle(
                            color: AppColors.goldSoft,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrayerAnalyticsScreen(),
                      ),
                    ),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: themeAccent(context).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: themeAccent(context).withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.tealDeep,
                    ),
                    title: const Text(
                      'تقرير وإحصائيات مواظبة الصلاة 📊',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: const Text(
                      'عرض مواظبة الجماعة، المنفرد، والقضاء أسبوعياً وشهرياً',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrayerAnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'سجّل كل صلاة بعد أدائها — سلسلة استمرار مستقلة لكل واحدة. كل صلاة/سنة تُفتح بدخول وقتها.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: onSurface.withValues(alpha: 0.55),
                  ),
                ),
                for (final item in PrayerChecklistScreen.fardItems)
                  _PrayerCheckRow(
                    category: item.category,
                    label: item.label,
                    icon: item.icon,
                    promptAzkar: true,
                    locked: !hasMomentArrivedToday(
                      lat: loc.lat,
                      lon: loc.lon,
                      methodKey: loc.calculationMethod,
                      moment: item.moment,
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 4),
                  child: Divider(height: 1),
                ),
                Text(
                  'السنن والرواتب',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'المؤكَّدة (الاثنتا عشرة + الضحى) والسنن المهجورة المستحبة.',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
                for (final item in PrayerChecklistScreen.rawatibItems)
                  _PrayerCheckRow(
                    category: item.category,
                    label: item.label,
                    icon: Icons.auto_awesome_outlined,
                    tag: item.confirmed ? null : 'سنة مهجورة',
                    locked: !hasMomentArrivedToday(
                      lat: loc.lat,
                      lon: loc.lon,
                      methodKey: loc.calculationMethod,
                      moment: item.moment,
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

/// إعداد متابعة "هل صليت؟" — تفعيل مستقل عن إشعار الأذان العادي (بطلب
/// صاحب المشروع: "اشعار بعد كل صلاة... مع تذكير وسؤال صليت؟... وتكرير
/// الاشعار كل ١٠ دقايق اذا ما جاوب"). تأخير أول سؤال (١٠ أو ١٥ دقيقة)
/// إعداد يختاره المستخدم بدل تثبيته بالكود — نفس روح تذكيرات قيام
/// الليل/الحفظ المخصَّصة. الضغط على "صليت" بالإشعار نفسه يسجّل بنفس آلية
/// "الصلوات والعبادات" أعلاه (`CategoryStreaks`) — راجع توثيق
/// `AdhanNotificationService._bumpCategoryStreakIfNewDay`.
class _PrayerCheckinCard extends ConsumerWidget {
  const _PrayerCheckinCard({required this.prefs});
  final LocationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final userPrefs = ref.watch(userPrefsProvider);
    final enabled = userPrefs.prayerCheckinEnabled;
    final delay = userPrefs.prayerCheckinFirstDelayMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'متابعة "هل صليت؟"',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (v) =>
                      _apply(context, ref, enabled: v, delay: delay),
                ),
              ],
            ),
            Text(
              'سؤال متكرّر كل ١٠ دقائق حتى تجيب — يبدأ بعد دخول وقت الصلاة بالمدة المختارة.',
              style: TextStyle(
                fontSize: 11.5,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            if (enabled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'أول سؤال بعد:',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  for (final m in [10, 15]) ...[
                    ChoiceChip(
                      label: Text('$m دقيقة'),
                      selected: delay == m,
                      onSelected: (_) =>
                          _apply(context, ref, enabled: true, delay: m),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.send_outlined, size: 16),
                label: const Text('إرسال إشعار متابعة تجريبي الآن'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  try {
                    await AdhanNotificationService.instance
                        .requestPermissions();
                    PrayerMoment? currentMoment;
                    if (prefs.hasLocation) {
                      final now = DateTime.now();
                      final dayTimes = computeDayTimes(
                        lat: prefs.lat!,
                        lon: prefs.lon!,
                        date: now,
                        methodKey: prefs.calculationMethod,
                      ).where((t) => t.moment.isPrayer).toList();
                      for (final t in dayTimes) {
                        if (!t.time.isAfter(now)) {
                          currentMoment = t.moment;
                        }
                      }
                      currentMoment ??= dayTimes.first.moment;
                    }
                    await AdhanNotificationService.instance
                        .sendTestCheckinNotification(moment: currentMoment);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('راقب شريط الإشعارات خلال ٣ ثوانٍ...'),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذّر إرسال الإشعار: $e')),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — نفس قيد
  /// `PrayerScreen._toggleNotifications`.
  Future<void> _apply(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
    required int delay,
  }) async {
    final userPrefs = ref.read(userPrefsProvider);
    await userPrefs.setPrayerCheckinSettings(
      enabled: enabled,
      firstDelayMinutes: delay,
    );
    try {
      if (!prefs.hasLocation) return;
      final notifPrefs = ref.read(adhanNotificationPrefsProvider);
      if (enabled) await AdhanNotificationService.instance.requestPermissions();
      await AdhanNotificationService.instance.rescheduleUpcoming(
        lat: prefs.lat!,
        lon: prefs.lon!,
        methodKey: prefs.calculationMethod,
        isEnabled: notifPrefs.effectivelyEnabled,
        voiceId: userPrefs.adhanVoiceId,
        checkinEnabled: enabled,
        checkinFirstDelayMinutes: delay,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط متابعة الصلاة على هذا الجهاز: $e')),
      );
    }
  }
}

/// بطاقة اختيار صوت الأذان والمؤذن مباشرة من شاشة الصلاة مع الاستماع والمعاينة
class _AdhanVoiceCard extends ConsumerStatefulWidget {
  const _AdhanVoiceCard({required this.prefs});
  final LocationPrefs prefs;

  @override
  ConsumerState<_AdhanVoiceCard> createState() => _AdhanVoiceCardState();
}

class _AdhanVoiceCardState extends ConsumerState<_AdhanVoiceCard> {
  final _player = AudioPlayer();
  String? _previewingId;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(AdhanVoice voice) async {
    if (_previewingId == voice.id) {
      await _player.stop();
      if (mounted) setState(() => _previewingId = null);
      return;
    }

    try {
      await _player.stop();
      if (mounted) setState(() => _previewingId = voice.id);
      final path = await AdhanDownloadService.instance.getEffectiveAudioPath(
        voice,
      );
      if (path == null) {
        if (mounted) setState(() => _previewingId = null);
        return;
      }
      if (path.startsWith('assets/')) {
        await _player.setAsset(path);
      } else if (path.startsWith('http')) {
        await _player.setUrl(path);
      } else {
        await _player.setFilePath(path);
      }
      await _player.play();
      if (mounted) {
        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) setState(() => _previewingId = null);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _previewingId = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذّر تشغيل المقطع: $e')));
      }
    }
  }

  Future<void> _select(AdhanVoice voice) async {
    await _player.stop();
    if (mounted) setState(() => _previewingId = null);
    await ref.read(userPrefsProvider).setAdhanVoiceId(voice.id);
    ref.read(adhanVoiceVersionProvider.notifier).bump();
    final loc = ref.read(locationPrefsProvider);
    if (!loc.hasLocation) return;
    final notifPrefs = ref.read(adhanNotificationPrefsProvider);
    final userPrefs = ref.read(userPrefsProvider);
    await AdhanNotificationService.instance.rescheduleUpcoming(
      lat: loc.lat!,
      lon: loc.lon!,
      methodKey: loc.calculationMethod,
      isEnabled: notifPrefs.effectivelyEnabled,
      voiceId: userPrefs.adhanVoiceId,
      checkinEnabled: userPrefs.prayerCheckinEnabled,
      checkinFirstDelayMinutes: userPrefs.prayerCheckinFirstDelayMinutes,
    );
  }

  void _showAllVoicesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final currentSelected = ref.watch(userPrefsProvider).adhanVoiceId;
            final onSurface = Theme.of(context).colorScheme.onSurface;
            final downloadedVoices = ref.watch(adhanDownloadedVoicesProvider);

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.record_voice_over_outlined,
                            color: themeAccent(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'اختيار صوت الأذان (المؤذن)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: RadioGroup<String>(
                        groupValue: currentSelected,
                        onChanged: (value) {
                          if (value == null) return;
                          _select(
                            kAdhanVoices.firstWhere((v) => v.id == value),
                          );
                          setModalState(() {});
                          setState(() {});
                        },
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: kAdhanVoices.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (c, idx) {
                            final voice = kAdhanVoices[idx];
                            final isSelected = voice.id == currentSelected;
                            final isThisPlaying = _previewingId == voice.id;
                            final isDownloaded = downloadedVoices.contains(
                              voice.id,
                            );

                            return ListTile(
                              leading: Radio<String>(
                                value: voice.id,
                                activeColor: themeAccent(context),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      voice.label,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 13.5,
                                        color: isSelected
                                            ? themeAccent(context)
                                            : onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isDownloaded && voice.remoteUrl != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1B8A72,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'محلي ✓',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF1B8A72),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: voice.subLabel != null
                                  ? Text(
                                      voice.subLabel!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: onSurface.withValues(alpha: 0.6),
                                      ),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (voice.remoteUrl != null && !isDownloaded)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.download_for_offline_outlined,
                                        size: 20,
                                      ),
                                      tooltip: 'تنزيل للاستماع بلا إنترنت',
                                      onPressed: () async {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'جاري تنزيل أذان ${voice.label}...',
                                            ),
                                          ),
                                        );
                                        final success =
                                            await AdhanDownloadService.instance
                                                .downloadVoice(voice);
                                        if (success) {
                                          await ref
                                              .read(
                                                adhanDownloadedVoicesProvider
                                                    .notifier,
                                              )
                                              .refresh();
                                          setModalState(() {});
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'تم تنزيل أذان ${voice.label} بنجاح ✓',
                                                ),
                                                backgroundColor: const Color(
                                                  0xFF1B8A72,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  if (voice.assetPath != null ||
                                      voice.remoteUrl != null)
                                    IconButton(
                                      icon: Icon(
                                        isThisPlaying
                                            ? Icons.stop_circle_outlined
                                            : Icons.play_circle_outline,
                                        color: isThisPlaying
                                            ? Colors.redAccent
                                            : themeAccent(context),
                                      ),
                                      tooltip: isThisPlaying
                                          ? 'إيقاف'
                                          : 'استماع للمعاينة',
                                      onPressed: () async {
                                        await _togglePreview(voice);
                                        setModalState(() {});
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                ],
                              ),
                              onTap: () {
                                _select(voice);
                                setModalState(() {});
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(adhanVoiceVersionProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selectedId = ref.watch(userPrefsProvider).adhanVoiceId;
    final selectedVoice = adhanVoiceById(selectedId);
    final isPreviewing = _previewingId == selectedVoice.id;

    return Card(
      key: adhanVoiceCardKey,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeAccent(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.record_voice_over_outlined,
                    size: 20,
                    color: themeAccent(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صوت الأذان والمؤذن',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedVoice.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeAccent(context),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAllVoicesSheet,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('تغيير', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (selectedVoice.subLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                selectedVoice.subLabel!,
                style: TextStyle(
                  fontSize: 11.5,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (selectedVoice.assetPath != null ||
                    selectedVoice.remoteUrl != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _togglePreview(selectedVoice),
                      icon: Icon(
                        isPreviewing ? Icons.stop : Icons.play_arrow,
                        size: 16,
                        color: isPreviewing
                            ? Colors.redAccent
                            : themeAccent(context),
                      ),
                      label: Text(
                        isPreviewing ? 'إيقاف المعاينة' : 'استماع للأذان',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isPreviewing ? Colors.redAccent : onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await AdhanNotificationService.instance
                            .requestPermissions();
                        await AdhanNotificationService.instance
                            .sendTestNotification(voiceId: selectedId);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم إرسال إشعار تجريبي — سيصلك خلال ٣ ثوانٍ 🔔',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('تعذّر إرسال الإشعار: $e')),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'فحص الإشعار',
                      style: TextStyle(fontSize: 11.5),
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

class PrayerPerformanceNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  void setChoice(String category, String choice) {
    state = {...state, category: choice};
  }
}

final prayerPerformanceMapProvider =
    NotifierProvider<PrayerPerformanceNotifier, Map<String, String>>(
      PrayerPerformanceNotifier.new,
    );

class _PrayerCheckRow extends ConsumerWidget {
  const _PrayerCheckRow({
    required this.category,
    required this.label,
    required this.icon,
    this.tag,
    this.promptAzkar = false,
    this.locked = false,
  });
  final String category;
  final String label;
  final IconData icon;
  final String? tag;
  final bool locked;
  final bool promptAzkar;

  Widget _buildPerfBadge(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(prayerPerformanceMapProvider)[category];
    final accent = themeAccent(context);

    final (badgeText, badgeColor, badgeIcon) = switch (choice) {
      'jamaah' => ('جماعة 🕌', Colors.green, Icons.mosque_outlined),
      'on_time' => ('منفرد 👤', accent, Icons.person_outlined),
      'qadaa' => ('قضاء ⏳', Colors.amber.shade800, Icons.history_toggle_off),
      _ => ('تمت 🟢', AppColors.tealDeep, Icons.check_circle),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: promptAzkar
          ? () async {
              final newChoice = await showModalBottomSheet<String>(
                context: context,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                builder: (ctx) => _PrayerPerformanceSheet(prayerName: label),
              );
              if (newChoice != null) {
                ref
                    .read(prayerPerformanceMapProvider.notifier)
                    .setChoice(category, newChoice);
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badgeIcon, size: 14, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final done = userPrefs.completedTodayFor(category);
    final days = userPrefs.streakDaysFor(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurface = isDark ? AppColors.surfaceDark : Colors.white;
    final cardBorder = isDark ? AppColors.lineDark : AppColors.line;
    final badgeColor = done
        ? AppColors.tealDeep
        : (locked ? onSurface.withValues(alpha: 0.35) : themeAccent(context));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // إبراز خفيف للفرض القابل للتسجيل الآن (لا مقفل ولا منجَز بعد) —
          // نفس فكرة "الصلاة الحالية" باللوحة المعتمدة، بلون التمييز.
          color: (!done && !locked)
              ? themeAccent(context).withValues(alpha: 0.5)
              : cardBorder,
          width: (!done && !locked) ? 1.4 : 1,
        ),
      ),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                locked ? Icons.lock_outline : icon,
                color: badgeColor,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: themeAccent(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: themeAccent(context),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (days > 0)
                    Text(
                      '$days يوم متتالي',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            done
                ? _buildPerfBadge(context, ref)
                : locked
                ? Tooltip(
                    message: 'لسا ما جا وقتها',
                    child: Text(
                      'مقفل',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () async {
                      if (promptAzkar) {
                        final choice = await showModalBottomSheet<String>(
                          context: context,
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          builder: (ctx) =>
                              _PrayerPerformanceSheet(prayerName: label),
                        );
                        if (choice == null || !context.mounted) return;
                        ref
                            .read(prayerPerformanceMapProvider.notifier)
                            .setChoice(category, choice);
                      }
                      await userPrefs.bumpCategoryStreakIfNewDay(category);
                      ref.read(categoryStreakVersionProvider.notifier).bump();
                      if (!promptAzkar || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'تقبّل الله — تحب تفتح أذكار ما بعد الصلاة؟',
                          ),
                          action: SnackBarAction(
                            label: 'فتح',
                            onPressed: () => _openPostPrayerAzkar(context, ref),
                          ),
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    },
                    child: const Text(
                      'صلّيتها',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _PrayerPerformanceSheet extends StatelessWidget {
  const _PrayerPerformanceSheet({required this.prayerName});
  final String prayerName;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'كيف صليت $prayerName اليوم؟',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mosque_outlined, color: AppColors.goldDeep),
              title: const Text(
                'جماعة في المسجد 🕌',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'أعلى أجر وتنافس مبارك',
                style: TextStyle(fontSize: 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.line),
              ),
              onTap: () => Navigator.of(context).pop('jamaah'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.tealDeep),
              title: const Text(
                'في وقتها (منفرد) ⏱️',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'في أول وقتها',
                style: TextStyle(fontSize: 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.line),
              ),
              onTap: () => Navigator.of(context).pop('on_time'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.history_toggle_off,
                color: AppColors.navy,
              ),
              title: const Text(
                'قضاء (بعد فوات وقتها) ⏳',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'أداء الفرض واستدراك الوقت',
                style: TextStyle(fontSize: 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.line),
              ),
              onTap: () => Navigator.of(context).pop('qadaa'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(PrayerMoment m) => switch (m) {
  PrayerMoment.fajr => Icons.nights_stay_outlined,
  PrayerMoment.sunrise => Icons.wb_twilight_outlined,
  PrayerMoment.dhuhr => Icons.wb_sunny_outlined,
  PrayerMoment.asr => Icons.wb_sunny,
  PrayerMoment.maghrib => Icons.wb_twilight,
  PrayerMoment.isha => Icons.dark_mode_outlined,
};

String _formatTime(DateTime t) {
  final h24 = t.hour;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final period = h24 < 12 ? 'ص' : 'م';
  final m = t.minute.toString().padLeft(2, '0');
  return '$h12:$m $period';
}

// بطلب صاحب المشروع: أُزيلت من هون بطاقة "الأوقات المستحبة وأوقات
// الكراهة" الثابتة اللي كانت تظهر دوماً تحت تفاصيل الفجر (`_MustahabAndMakroohTimesSection`
// و`_MustahabTile`) — الاتفاق إنه أوقات كهذي تظهر بشاشة الصلاة فقط لمّا
// يجي وقتها فعلاً (زي `PrayerCountdownCard` أعلى الشاشة)، لا كقائمة ثابتة.
// ملاحظة: مفتاح "نية صيام الإثنين والخميس" (`sunnahFastingEnabled`) كان
// جزءاً من هالبطاقة وأُزيل معها — إذا لسا مطلوب، يحتاج مكاناً جديداً
// (الإعدادات مثلاً) بطلب صريح لاحقاً.

IconData _modeIcon(WidgetRef ref, PrayerMoment moment) {
  final notifPrefs = ref.watch(adhanNotificationPrefsProvider);
  final mode = notifPrefs.notificationModeFor(moment);
  return switch (mode) {
    'adhan' => Icons.volume_up_outlined,
    'tone' => Icons.notifications_active_outlined,
    'silent' => Icons.notifications_paused_outlined,
    _ => Icons.notifications_off_outlined,
  };
}

Future<void> _rescheduleAdhans(WidgetRef ref, LocationPrefs prefs) async {
  if (!prefs.hasLocation) return;
  final notifPrefs = ref.read(adhanNotificationPrefsProvider);
  final userPrefs = ref.read(userPrefsProvider);
  await AdhanNotificationService.instance.rescheduleUpcoming(
    lat: prefs.lat!,
    lon: prefs.lon!,
    methodKey: prefs.calculationMethod,
    isEnabled: notifPrefs.effectivelyEnabled,
    voiceId: userPrefs.adhanVoiceId,
    getVoiceIdFor: (m) => userPrefs.adhanVoiceFor(m.name),
    getModeFor: (m) => notifPrefs.notificationModeFor(m),
    preAdhanMinutes: userPrefs.preAdhanMinutes,
    checkinEnabled: userPrefs.prayerCheckinEnabled,
    checkinFirstDelayMinutes: userPrefs.prayerCheckinFirstDelayMinutes,
  );
}

void _showVoicePickerForMoment(
  BuildContext context,
  WidgetRef ref,
  LocationPrefs prefs,
  PrayerMoment moment,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return _VoicePickerContent(
        prefs: prefs,
        moment: moment,
        sheetCtx: sheetCtx,
      );
    },
  );
}

class _VoicePickerContent extends ConsumerStatefulWidget {
  const _VoicePickerContent({
    required this.prefs,
    required this.moment,
    required this.sheetCtx,
  });

  final LocationPrefs prefs;
  final PrayerMoment moment;
  final BuildContext sheetCtx;

  @override
  ConsumerState<_VoicePickerContent> createState() =>
      _VoicePickerContentState();
}

class _VoicePickerContentState extends ConsumerState<_VoicePickerContent> {
  AudioPlayer? _player;
  String? _playingVoiceId;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  @override
  void dispose() {
    _player?.stop();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(AdhanVoice voice) async {
    if (voice.assetPath == null) return;
    if (_playingVoiceId == voice.id) {
      await _player?.stop();
      if (mounted) setState(() => _playingVoiceId = null);
      return;
    }

    try {
      await _player?.stop();
      if (mounted) setState(() => _playingVoiceId = voice.id);
      await _player?.setAsset(voice.assetPath!);
      await _player?.play();
      _player?.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _playingVoiceId = null);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _playingVoiceId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVoiceId = ref
        .watch(userPrefsProvider)
        .adhanVoiceFor(widget.moment.name);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'مؤذن صلاة ${widget.moment.nameAr}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: kAdhanVoices.length,
                itemBuilder: (ctx, idx) {
                  final voice = kAdhanVoices[idx];
                  final isSelected = voice.id == currentVoiceId;
                  final isPlaying = _playingVoiceId == voice.id;

                  return ListTile(
                    title: Text(
                      voice.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: voice.subLabel != null
                        ? Text(
                            voice.subLabel!,
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                    leading: voice.assetPath != null
                        ? IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.stop_circle_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: isPlaying ? Colors.redAccent : accent,
                              size: 28,
                            ),
                            tooltip: isPlaying
                                ? 'إيقاف الاستماع'
                                : 'استماع لصوت المؤذن',
                            onPressed: () => _togglePlay(voice),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) Icon(Icons.check_circle, color: accent),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.done_all_rounded, size: 20),
                          tooltip: 'اعتماد هذا المؤذن لجميع الصلوات',
                          onPressed: () async {
                            await _player?.stop();
                            final userPrefs = ref.read(userPrefsProvider);
                            for (final m in PrayerMoment.values) {
                              if (m.isPrayer) {
                                await userPrefs.setAdhanVoiceFor(
                                  m.name,
                                  voice.id,
                                );
                              }
                            }
                            await userPrefs.setAdhanVoiceId(voice.id);
                            ref
                                .read(adhanNotificationVersionProvider.notifier)
                                .bump();
                            if (context.mounted)
                              Navigator.of(widget.sheetCtx).pop();
                            if (widget.prefs.hasLocation)
                              unawaited(_rescheduleAdhans(ref, widget.prefs));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم اعتماد مؤذن "${voice.label}" لجميع الصلوات الخمس 🕌',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      await _player?.stop();
                      await ref
                          .read(userPrefsProvider)
                          .setAdhanVoiceFor(widget.moment.name, voice.id);
                      ref
                          .read(adhanNotificationVersionProvider.notifier)
                          .bump();
                      if (context.mounted) Navigator.of(widget.sheetCtx).pop();
                      if (widget.prefs.hasLocation)
                        unawaited(_rescheduleAdhans(ref, widget.prefs));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<PrayerMoment, String> kPrayerVirtues = {
  PrayerMoment.fajr:
      'صلاة الفجر أو صلاة الصبح ركعتان يُجهر بهما، وفي الحديث: «من صلى العشاء في جماعة فكأنما قام نصف الليل، ومن صلى الصبح في جماعة فكأنما صلى الليل كله» [أخرجه مسلم]، وقال صلى الله عليه وسلم أيضًا: «من صلى الصبح فهو في ذمة الله» [أخرجه مسلم]. وراتبتها ركعتان قبلها؛ قال صلى الله عليه وسلم في فضلهما: «ركعتا الفجر خير من الدنيا وما فيها» [أخرجه مسلم].',
  PrayerMoment.dhuhr:
      'صلاة الظهر أربع ركعات يُسرّ بها، وهي أول صلاة صلاها جبريل بالنبي ﷺ. وفي الحديث: «تلك ساعة تُفتح فيها أبواب السماء، فأحب أن يصعد لي فيها عمل صالح» [أخرجه الترمذي]. وسنتها أربع ركعات قبلها وركعتان بعدها.',
  PrayerMoment.asr:
      'صلاة العصر أربع ركعات يُسرّ بها، وهي الصلاة الوسطى المذكورة في القرآن: ﴿حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَى﴾. وفي الحديث: «من صلى البردين دخل الجنة» [متفق عليه]، والبردان هما الفجر والعصر. وسنتها أربع ركعات قبلها.',
  PrayerMoment.maghrib:
      'صلاة المغرب ثلاث ركعات، ركعتان يُجهر بهما وثالثة يُسرّ بها. وهي وتر النهار، وفي الحديث: «لا تزال أمتي بخير - أو على الفطرة - ما لم يؤخروا المغرب حتى تشتبك النجوم» [أخرجه أبو داود]. وسنتها ركعتان بعدها.',
  PrayerMoment.isha:
      'صلاة العشاء أربع ركعات، ركعتان يُجهر بهما وركعتان يُسرّ بهما. وفي الحديث: «من صلى العشاء في جماعة فكأنما قام نصف الليل» [أخرجه مسلم]. وسنتها ركعتان بعدها، ويُشرع بعدها صلاة الوتر.',
};

void _showPrayerDetailBottomSheet(
  BuildContext context,
  WidgetRef ref,
  LocationPrefs prefs,
  PrayerMoment moment,
  DateTime time,
  List<PrayerMomentTime> dayTimes,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final userPrefs = ref.watch(userPrefsProvider);
          final notifPrefs = ref.watch(adhanNotificationPrefsProvider);
          final now = ref.watch(prayerTickProvider).value ?? DateTime.now();
          final accent = themeAccent(context);
          final onSurface = Theme.of(context).colorScheme.onSurface;

          final offset = userPrefs.prayerOffsetFor(moment.name);
          final adjustedTime = time.add(Duration(minutes: offset));
          final iqamahMins = userPrefs.iqamahMinutesFor(moment.name);
          final preMins = userPrefs.preAdhanMinutes;

          final currentVoiceId = userPrefs.adhanVoiceFor(moment.name);
          final currentVoice = adhanVoiceById(currentVoiceId);
          final currentMode = notifPrefs.notificationModeFor(moment);

          final diff = now.difference(adjustedTime);
          final isPast = !diff.isNegative;
          final absDiff = diff.abs();

          final hours = absDiff.inHours.toString().padLeft(2, '0');
          final mins = (absDiff.inMinutes % 60).toString().padLeft(2, '0');
          final secs = (absDiff.inSeconds % 60).toString().padLeft(2, '0');
          final timerString = '$hours:$mins:$secs';

          final virtueText = kPrayerVirtues[moment] ?? '';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconFor(moment), color: accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'صلاة ${moment.nameAr}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            Text(
                              'وقت الأذان: ${_formatTime(adjustedTime)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (virtueText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              virtueText,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.55,
                                color: onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.9),
                          HSVColor.fromColor(accent)
                              .withValue(
                                (HSVColor.fromColor(accent).value * 0.6).clamp(
                                  0.1,
                                  1.0,
                                ),
                              )
                              .toColor(),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
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
                            Text(
                              isPast ? 'مضي على الأذان' : 'متبقي على الأذان',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timerString,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'إقامة: $iqamahMins دقيقة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'إعدادات الأوقات والإقامة والتنبيه',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'تعديل وقت الأذان (دقائق):',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 22,
                                    ),
                                    color: accent,
                                    onPressed: () async {
                                      await userPrefs.setPrayerOffsetFor(
                                        moment.name,
                                        offset - 1,
                                      );
                                      ref
                                          .read(
                                            adhanNotificationVersionProvider
                                                .notifier,
                                          )
                                          .bump();
                                      if (prefs.hasLocation)
                                        unawaited(
                                          _rescheduleAdhans(ref, prefs),
                                        );
                                    },
                                  ),
                                  Text(
                                    '${offset >= 0 ? "+$offset" : offset} دقيقة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 22,
                                    ),
                                    color: accent,
                                    onPressed: () async {
                                      await userPrefs.setPrayerOffsetFor(
                                        moment.name,
                                        offset + 1,
                                      );
                                      ref
                                          .read(
                                            adhanNotificationVersionProvider
                                                .notifier,
                                          )
                                          .bump();
                                      if (prefs.hasLocation)
                                        unawaited(
                                          _rescheduleAdhans(ref, prefs),
                                        );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'مدة الإقامة في المسجد:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 22,
                                    ),
                                    color: accent,
                                    onPressed: () async {
                                      if (iqamahMins > 1) {
                                        await userPrefs.setIqamahMinutesFor(
                                          moment.name,
                                          iqamahMins - 1,
                                        );
                                        ref
                                            .read(
                                              adhanNotificationVersionProvider
                                                  .notifier,
                                            )
                                            .bump();
                                        if (prefs.hasLocation)
                                          unawaited(
                                            _rescheduleAdhans(ref, prefs),
                                          );
                                      }
                                    },
                                  ),
                                  Text(
                                    '$iqamahMins دقيقة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 22,
                                    ),
                                    color: accent,
                                    onPressed: () async {
                                      if (iqamahMins < 60) {
                                        await userPrefs.setIqamahMinutesFor(
                                          moment.name,
                                          iqamahMins + 1,
                                        );
                                        ref
                                            .read(
                                              adhanNotificationVersionProvider
                                                  .notifier,
                                            )
                                            .bump();
                                        if (prefs.hasLocation)
                                          unawaited(
                                            _rescheduleAdhans(ref, prefs),
                                          );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 12),

                          Text(
                            'تنبيه مبكر قبل الأذان:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final m in [5, 10, 15, 20, 30])
                                ChoiceChip(
                                  label: Text(
                                    '$m دقائق',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: preMins == m
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: preMins == m,
                                  selectedColor: accent.withValues(alpha: 0.2),
                                  onSelected: (_) async {
                                    await userPrefs.setPreAdhanMinutes(m);
                                    ref
                                        .read(
                                          adhanNotificationVersionProvider
                                              .notifier,
                                        )
                                        .bump();
                                    if (prefs.hasLocation)
                                      unawaited(_rescheduleAdhans(ref, prefs));
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'الصوت والتنبيه',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.record_voice_over_outlined,
                            color: accent,
                          ),
                          title: const Text(
                            'المؤذن المفصل لهذه الصلاة',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            currentVoice.label,
                            style: TextStyle(fontSize: 11.5, color: accent),
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () {
                            _showVoicePickerForMoment(
                              context,
                              ref,
                              prefs,
                              moment,
                            );
                          },
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نمط التنبيه للصلاة:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _modeChip(
                                    context,
                                    ref,
                                    prefs,
                                    moment,
                                    'adhan',
                                    '🔊 أذان',
                                    currentMode,
                                  ),
                                  const SizedBox(width: 6),
                                  _modeChip(
                                    context,
                                    ref,
                                    prefs,
                                    moment,
                                    'tone',
                                    '🔔 نغمة',
                                    currentMode,
                                  ),
                                  const SizedBox(width: 6),
                                  _modeChip(
                                    context,
                                    ref,
                                    prefs,
                                    moment,
                                    'silent',
                                    '🔕 صامت',
                                    currentMode,
                                  ),
                                  const SizedBox(width: 6),
                                  _modeChip(
                                    context,
                                    ref,
                                    prefs,
                                    moment,
                                    'off',
                                    '🚫 إيقاف',
                                    currentMode,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // بطلب صاحب المشروع: أُزيلت بطاقة الأوقات المستحبة/الكراهة
                  // الثابتة من تفاصيل الفجر بالكامل — الاتفاق إنه أوقات
                  // كهذي تظهر بشاشة الصلاة فقط لمّا يجي وقتها فعلاً (زي
                  // `PrayerCountdownCard` أعلى الشاشة)، لا كقائمة ثابتة دوماً.
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: AppPrimaryButton(
                      label: 'تم الحفظ',
                      color: accent,
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _modeChip(
  BuildContext context,
  WidgetRef ref,
  LocationPrefs prefs,
  PrayerMoment moment,
  String modeKey,
  String label,
  String currentMode,
) {
  final notifPrefs = ref.watch(adhanNotificationPrefsProvider);
  final isSelected = currentMode == modeKey;
  final accent = themeAccent(context);

  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await notifPrefs.setNotificationModeFor(moment, modeKey);
        ref.read(adhanNotificationVersionProvider.notifier).bump();
        if (prefs.hasLocation) await _rescheduleAdhans(ref, prefs);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accent : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? accent
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ),
  );
}
