import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart' show themeAccent;
import '../notifications/adhan_notification_prefs.dart';
import '../notifications/adhan_notification_service.dart';
import '../onboarding/onboarding_target_keys.dart';
import 'prayer_countdown_card.dart';
import 'prayer_location_controller.dart';
import 'prayer_times_service.dart';
import 'qibla_screen.dart';
import 'widgets/prayer_checkin_card.dart';
import 'widgets/prayer_detail_sheet.dart';
import 'widgets/prayer_display_helpers.dart';

/// إعادة تصدير `PrayerChecklistScreen` من موقعها الفعلي
/// (`widgets/prayer_checklist_screen.dart`) — أُبقيَ هذا التصدير هون لأن
/// ملفات أخرى بالمشروع (`prayer_countdown_card.dart`, `home_screen.dart`)
/// تستورد `PrayerChecklistScreen` تحديداً عبر `prayer_screen.dart` (نمط
/// `show`)؛ نقلها لملف مستقل بلا هذا التصدير كان سيكسر تلك الاستيرادات.
export 'widgets/prayer_checklist_screen.dart' show PrayerChecklistScreen;

/// شاشة مواقيت الصلاة: مواقيت اليوم الستة (شاملة الشروق للعرض) + عدّاد
/// للصلاة القادمة + اختيار الموقع (GPS/مدينة) وطريقة الحساب. حساب محلي
/// بالكامل عبر `adhan_dart` — لا استدعاء شبكة، يعمل بوضع الطيران بعد
/// تحديد الموقع مرة واحدة. راجع `tools/raw/README.md` لقيود التحقّق الميداني.
///
/// الشاشة نفسها مجرّد تنسيق (orchestration) لعناصر مستقلة بملفات
/// `widgets/` — بطاقة العدّاد (`prayer_countdown_card.dart`)، ورقة تفاصيل
/// صلاة واحدة (`widgets/prayer_detail_sheet.dart`)، بطاقة متابعة "هل
/// صليت؟" (`widgets/prayer_checkin_card.dart`)، وشاشة "الصلوات والعبادات"
/// (`widgets/prayer_checklist_screen.dart`).
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
                  showPrayerDetailBottomSheet(
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
                prayerMomentIcon(t.moment),
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
                    formatPrayerTime12h(
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
                        prayerNotificationModeIcon(ref, t.moment),
                        size: 19,
                        color: themeAccent(context),
                      ),
                      tooltip: 'تفاصيل الصلاة والإقامة',
                      onPressed: () => showPrayerDetailBottomSheet(
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
        PrayerCheckinCard(prefs: prefs),
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
