import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/theme/app_colors.dart';
import 'cities.dart';
import 'prayer_location_controller.dart';
import 'prayer_times_service.dart';
import 'qibla_screen.dart';

final _tickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// شاشة مواقيت الصلاة: مواقيت اليوم الستة (شاملة الشروق للعرض) + عدّاد
/// للصلاة القادمة + اختيار الموقع (GPS/مدينة) وطريقة الحساب. حساب محلي
/// بالكامل عبر `adhan_dart` — لا استدعاء شبكة، يعمل بوضع الطيران بعد
/// تحديد الموقع مرة واحدة. راجع `tools/raw/README.md` لقيود التحقّق الميداني.
class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(locationVersionProvider);
    final prefs = ref.watch(locationPrefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.location_city_outlined),
              label: const Text('اختيار مدينة'),
              onPressed: () => _showCityPicker(context, ref),
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

void _showCityPicker(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (sheetContext) {
      final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
      return SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text('اختر مدينتك', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: onSurface)),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: kPrayerCities.length,
                  itemBuilder: (context, i) {
                    final city = kPrayerCities[i];
                    return ListTile(
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(city.nameAr, style: TextStyle(color: onSurface)),
                      onTap: () {
                        ref.read(locationControllerProvider.notifier).useCity(city);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _TimesView extends ConsumerWidget {
  const _TimesView({required this.prefs});
  final LocationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final now = ref.watch(_tickProvider).value ?? DateTime.now();
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
        Card(
          color: AppColors.navy,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('الصلاة القادمة', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                const SizedBox(height: 6),
                Text(next.moment.nameAr, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                _CountdownText(target: next.time),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: Text(prefs.cityName ?? '—', overflow: TextOverflow.ellipsis),
                onPressed: () => _showCityPicker(context, ref),
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

class _CountdownText extends ConsumerWidget {
  const _CountdownText({required this.target});
  final DateTime target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(_tickProvider).value ?? DateTime.now();
    final remaining = target.difference(now);
    final positive = remaining.isNegative ? Duration.zero : remaining;
    final h = positive.inHours.toString().padLeft(2, '0');
    final m = (positive.inMinutes % 60).toString().padLeft(2, '0');
    final s = (positive.inSeconds % 60).toString().padLeft(2, '0');
    return Text('باقي $h:$m:$s', style: const TextStyle(color: AppColors.goldSoft, fontSize: 16, fontWeight: FontWeight.w700));
  }
}
