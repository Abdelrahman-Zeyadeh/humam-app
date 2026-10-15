import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_prefs.dart';
import '../../notifications/adhan_notification_service.dart';
import '../../prayer/prayer_location_controller.dart';
import '../../prayer/prayer_times_service.dart';

/// قسم إدارة تنبيهات الصلاة والأذان والإقامة وأذكار ما بعد الصلاة داخل شاشة التذكيرات
class PrayerRemindersOverview extends ConsumerWidget {
  const PrayerRemindersOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adhanNotificationVersionProvider);
    final notifPrefs = ref.watch(adhanNotificationPrefsProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final locationPrefs = ref.watch(locationPrefsProvider);
    final accent = themeAccent(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final masterEnabled = notifPrefs.masterEnabled;
    final preMins = userPrefs.preAdhanMinutes;
    final postAzkarEnabled = userPrefs.postPrayerAzkarEnabled;
    final rawatibEnabled = userPrefs.rawatibEnabled;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // 1. المفتاح العام للأذان
          SwitchListTile(
            secondary: Icon(
              masterEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              color: masterEnabled ? accent : onSurface.withValues(alpha: 0.5),
            ),
            title: const Text(
              'تفعيل إشعارات مواقيت الصلاة والأذان',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              masterEnabled
                  ? 'يتم تنبيهك عند حلول وقت كل صلاة'
                  : 'معطّل — لن تصلك إشعارات الأذان',
              style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
            ),
            value: masterEnabled,
            activeThumbColor: accent,
            onChanged: (val) async {
              await notifPrefs.setMasterEnabled(val);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
              if (val) {
                await AdhanNotificationService.instance.requestPermissions();
              }
              if (locationPrefs.hasLocation) {
                unawaited(rescheduleAdhanNotifications(ref, locationPrefs));
              }
            },
          ),
          if (masterEnabled) ...[
            const Divider(height: 1),
            // صف الصلوات الخمس للتحكم الفوري
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final p in [
                    PrayerMoment.fajr,
                    PrayerMoment.dhuhr,
                    PrayerMoment.asr,
                    PrayerMoment.maghrib,
                    PrayerMoment.isha,
                  ])
                    _PrayerQuickPill(
                      moment: p,
                      prefs: locationPrefs,
                    ),
                ],
              ),
            ),
          ],
          const Divider(height: 1),

          // 2. التذكير قبل الصلاة
          ListTile(
            leading: Icon(
              Icons.access_time_rounded,
              color: preMins > 0 ? accent : onSurface.withValues(alpha: 0.5),
            ),
            title: const Text(
              'التذكير قبل الصلاة (الاستعداد والوضوء)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              preMins > 0 ? 'قبل الأذان بـ $preMins دقائق' : 'معطّل (بلا تذكير)',
              style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
            ),
            trailing: DropdownButton<int>(
              value: [0, 5, 10, 15, 20, 30].contains(preMins) ? preMins : 10,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(value: 0, child: Text('بلا تذكير', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 5, child: Text('قبل 5 د', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 10, child: Text('قبل 10 د', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 15, child: Text('قبل 15 د', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 20, child: Text('قبل 20 د', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 30, child: Text('قبل 30 د', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) async {
                if (val != null) {
                  await userPrefs.setPreAdhanMinutes(val);
                  ref.read(adhanNotificationVersionProvider.notifier).bump();
                  if (locationPrefs.hasLocation) {
                    unawaited(rescheduleAdhanNotifications(ref, locationPrefs));
                  }
                }
              },
            ),
          ),
          const Divider(height: 1),

          // 3. تنبيه وقت الإقامة
          Builder(
            builder: (context) {
              final iqamahEnabled = [
                PrayerMoment.fajr,
                PrayerMoment.dhuhr,
                PrayerMoment.asr,
                PrayerMoment.maghrib,
                PrayerMoment.isha,
              ].any((m) => userPrefs.iqamahNotificationEnabledFor(m.name));

              return SwitchListTile(
                secondary: Icon(
                  Icons.notifications_paused_outlined,
                  color: iqamahEnabled ? accent : onSurface.withValues(alpha: 0.5),
                ),
                title: const Text(
                  'تنبيه وقت إقامة الصلاة',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  iqamahEnabled
                      ? 'يصلك تنبيه عند حلول وقت إقامة كل صلاة'
                      : 'معطّل',
                  style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                ),
                value: iqamahEnabled,
                activeThumbColor: accent,
                onChanged: (val) async {
                  for (final m in [
                    PrayerMoment.fajr,
                    PrayerMoment.dhuhr,
                    PrayerMoment.asr,
                    PrayerMoment.maghrib,
                    PrayerMoment.isha,
                  ]) {
                    await userPrefs.setIqamahNotificationEnabledFor(m.name, val);
                  }
                  ref.read(adhanNotificationVersionProvider.notifier).bump();
                  if (locationPrefs.hasLocation) {
                    unawaited(rescheduleAdhanNotifications(ref, locationPrefs));
                  }
                },
              );
            },
          ),
          const Divider(height: 1),

          // 4. أذكار بعد الصلاة
          SwitchListTile(
            secondary: Icon(
              Icons.format_quote_rounded,
              color: postAzkarEnabled ? accent : onSurface.withValues(alpha: 0.5),
            ),
            title: const Text(
              'تنبيه أذكار بعد الصلاة',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              postAzkarEnabled ? 'يصلك إشعار بالاستغفار والأذكار النبوية بعد الصلاة' : 'معطّل',
              style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
            ),
            value: postAzkarEnabled,
            activeThumbColor: accent,
            onChanged: (val) async {
              await userPrefs.setPostPrayerAzkarSettings(enabled: val);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
              if (locationPrefs.hasLocation) {
                unawaited(rescheduleAdhanNotifications(ref, locationPrefs));
              }
            },
          ),
          const Divider(height: 1),

          // 5. تذكير السنن الرواتب
          SwitchListTile(
            secondary: Icon(
              Icons.stars_rounded,
              color: rawatibEnabled ? accent : onSurface.withValues(alpha: 0.5),
            ),
            title: const Text(
              'تذكير السنن الرواتب',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              rawatibEnabled ? 'تنبيه لأداء ركعات السنن الرواتب (الفجر، الظهر، المغرب، العشاء)' : 'معطّل',
              style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
            ),
            value: rawatibEnabled,
            activeThumbColor: accent,
            onChanged: (val) async {
              await userPrefs.setRawatibEnabled(val);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
              if (locationPrefs.hasLocation) {
                unawaited(rescheduleAdhanNotifications(ref, locationPrefs));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PrayerQuickPill extends ConsumerWidget {
  const _PrayerQuickPill({
    required this.moment,
    required this.prefs,
  });

  final PrayerMoment moment;
  final LocationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifPrefs = ref.watch(adhanNotificationPrefsProvider);
    final accent = themeAccent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isEnabled = notifPrefs.effectivelyEnabled(moment);
    final mode = notifPrefs.notificationModeFor(moment);

    final isSilent = mode == 'silent';
    final isActive = isEnabled && mode != 'off';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        // دورة التبديل: أذان -> صامت -> إيقاف
        String nextMode;
        if (!isActive) {
          nextMode = 'adhan';
        } else if (isSilent) {
          nextMode = 'off';
        } else {
          nextMode = 'silent';
        }
        await notifPrefs.setNotificationModeFor(moment, nextMode);
        ref.read(adhanNotificationVersionProvider.notifier).bump();
        if (prefs.hasLocation) {
          unawaited(rescheduleAdhanNotifications(ref, prefs));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isSilent
                  ? Colors.blueGrey.withValues(alpha: 0.15)
                  : accent.withValues(alpha: 0.14))
              : (isDark ? const Color(0xFF2B3036) : const Color(0xFFF3ECE0)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? (isSilent ? Colors.blueGrey : accent)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              moment.nameAr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? (isSilent ? Colors.blueGrey : accent)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isActive ? (isSilent ? '🔕' : '🔊') : '🚫',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
