import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/adhan_notification_prefs.dart';
import '../notifications/adhan_notification_service.dart';
import 'prayer_countdown_card.dart';
import 'prayer_location_controller.dart';
import 'prayer_times_service.dart';
import 'qibla_screen.dart';

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
    final prefs = ref.watch(locationPrefsProvider);
    final notifPrefs = ref.watch(adhanNotificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(
            icon: Icon(notifPrefs.masterEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
            tooltip: notifPrefs.masterEnabled ? 'إشعارات الأذان مفعّلة' : 'إشعارات الأذان معطّلة',
            onPressed: () => _toggleNotifications(context, ref, prefs, notifPrefs),
          ),
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'القبلة',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen())),
          ),
        ],
      ),
      body: prefs.hasLocation ? _TimesView(prefs: prefs) : const _LocationPrompt(),
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
          await AdhanNotificationService.instance.rescheduleUpcoming(
            lat: prefs.lat!,
            lon: prefs.lon!,
            methodKey: prefs.calculationMethod,
            isEnabled: notifPrefs.effectivelyEnabled,
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
            const Icon(Icons.location_on_outlined, size: 48, color: AppColors.gold),
            const SizedBox(height: 16),
            Text('حدّد موقعك لحساب مواقيت الصلاة', style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('استخدام موقعي الحالي (GPS)'),
              onPressed: locationState.isLoading ? null : () => ref.read(locationControllerProvider.notifier).useGps(),
            ),
            if (locationState.hasError) ...[
              const SizedBox(height: 12),
              Text('${locationState.error}', style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12), textAlign: TextAlign.center),
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
    final dayTimes = computeDayTimes(lat: prefs.lat!, lon: prefs.lon!, date: now, methodKey: prefs.calculationMethod);
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
      padding: const EdgeInsets.all(16),
      children: [
        PrayerCountdownCard(lat: prefs.lat!, lon: prefs.lon!, methodKey: prefs.calculationMethod),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      prefs.cityName ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: onSurface.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'تحديث بـGPS',
              onPressed: () => ref.read(locationControllerProvider.notifier).useGps(),
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
            color: t.moment == next.moment ? AppColors.gold.withValues(alpha: 0.12) : null,
            child: ListTile(
              leading: Icon(_iconFor(t.moment), color: onSurface.withValues(alpha: 0.7)),
              title: Text(t.moment.nameAr, style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
              trailing: Text(_formatTime(t.time), style: TextStyle(color: onSurface, fontSize: 15)),
            ),
          ),
      ],
    );
  }

  void _showMethodPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('طريقة الحساب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: onSurface)),
              for (final m in kCalculationMethods)
                ListTile(
                  leading: Icon(
                    m.key == prefs.calculationMethod ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: m.key == prefs.calculationMethod ? AppColors.gold : onSurface.withValues(alpha: 0.5),
                  ),
                  title: Text(m.nameAr, style: TextStyle(color: onSurface)),
                  onTap: () {
                    ref.read(locationControllerProvider.notifier).setCalculationMethod(m.key);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
