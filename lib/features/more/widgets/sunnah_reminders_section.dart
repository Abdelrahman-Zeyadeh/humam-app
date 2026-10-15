import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/text/time_format.dart';
import '../../notifications/adhan_notification_prefs.dart';
import '../../notifications/adhan_notification_service.dart';
import 'reminder_repeat_interval.dart';

/// مفاتيح تخزين ساعة تذكيرَي سورة الكهف/الصلاة على النبي — تُستخدَم
/// عبر نظام [ActivityReminders] العام (`userPrefs.reminderHourFor`/
/// `.setActivityReminder`) **لتخزين الساعة فقط**، لا للتفعيل (ذاك يبقى
/// عبر `AdhanNotificationPrefs.sunnah*Enabled` كما كان)؛ إعادة استخدام
/// جدول موجود بدل عمود جديد بقاعدة بيانات drift (يحتاج ترحيل مخطط) —
/// بطلب صاحب المشروع "هو كمان يحدد كل كم يتذكر" (سورة الكهف والصلاة على
/// النبي مرتبطتان بيوم الجمعة تحديداً بحكم السنّة نفسها، فالتحكّم
/// المتاح هو **بأي ساعة** من ذاك اليوم يصل التذكير، لا تغيير التكرار
/// الأسبوعي).
const _kSunnahKahfHourKey = 'sunnah_kahf_hour';
const _kSunnahSalawatEveHourKey = 'sunnah_salawat_eve_hour';
const _kSunnahSalawatFridayHourKey = 'sunnah_salawat_friday_hour';
const _kSunnahFastingHourKey = 'sunnah_fasting_hour';
const _kSunnahWhiteDaysHourKey = 'sunnah_white_days_hour';

class SunnahRemindersSection extends ConsumerWidget {
  const SunnahRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adhanNotificationVersionProvider);
    ref.watch(categoryStreakVersionProvider);
    final prefs = ref.watch(adhanNotificationPrefsProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final notifService = AdhanNotificationService.instance;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final kahfHour = userPrefs.reminderHourFor(_kSunnahKahfHourKey) ?? 9;
    final kahfMinute = userPrefs.reminderMinuteFor(_kSunnahKahfHourKey);
    final kahfInterval = userPrefs.reminderIntervalMinutesFor('sunnah_kahf');
    final salawatEveHour =
        userPrefs.reminderHourFor(_kSunnahSalawatEveHourKey) ?? 20;
    final salawatEveMinute = userPrefs.reminderMinuteFor(
      _kSunnahSalawatEveHourKey,
    );
    final salawatEveInterval = userPrefs.reminderIntervalMinutesFor(
      'sunnah_salawat_eve',
    );
    final salawatFridayHour =
        userPrefs.reminderHourFor(_kSunnahSalawatFridayHourKey) ?? 10;
    final salawatFridayMinute = userPrefs.reminderMinuteFor(
      _kSunnahSalawatFridayHourKey,
    );
    final salawatFridayInterval = userPrefs.reminderIntervalMinutesFor(
      'sunnah_salawat_friday',
    );
    final fastingHour =
        userPrefs.reminderHourFor(_kSunnahFastingHourKey) ?? 20;
    final fastingMinute =
        userPrefs.reminderMinuteFor(_kSunnahFastingHourKey);
    final whiteDaysHour =
        userPrefs.reminderHourFor(_kSunnahWhiteDaysHourKey) ?? 20;
    final whiteDaysMinute =
        userPrefs.reminderMinuteFor(_kSunnahWhiteDaysHourKey);

    Future<void> applyKahf({int? hour, int? minute, bool? enabled}) async {
      final h = hour ?? kahfHour;
      final m = minute ?? kahfMinute;
      final en = enabled ?? prefs.sunnahKahfEnabled;
      await notifService.requestPermissions();
      if (!en) {
        await notifService.scheduleFridayKahfReminder(enabled: false);
        await notifService.cancelRepeatingReminder('sunnah_kahf');
        return;
      }
      if (kahfInterval != null) {
        await notifService.scheduleFridayKahfReminder(enabled: false);
        await notifService.scheduleRepeatingReminder(
          category: 'sunnah_kahf',
          body: 'نورٌ ما بين الجمعتين — لا تنسَ قراءة سورة الكهف اليوم',
          startHour: h,
          startMinute: m,
          intervalMinutes: kahfInterval,
          onlyWeekday: DateTime.friday,
        );
      } else {
        await notifService.cancelRepeatingReminder('sunnah_kahf');
        await notifService.scheduleFridayKahfReminder(
          enabled: true,
          hour: h,
          minute: m,
        );
      }
    }

    // الصلاة على النبي: وقتان مستقلّان (ليلة الجمعة/صباح الجمعة)، كل
    // واحد قد يكون "مرة واحدة" أو تكراراً مستقلاً — `scheduleEve`/
    // `scheduleFriday` بـ`scheduleFridaySalawatReminder` يسمحان بتفعيل
    // الجدولة القديمة لأحد الوقتين فقط بينما الآخر يُدار عبر
    // [scheduleRepeatingReminder] بمعزل تام.
    Future<void> applySalawat({bool? enabled}) async {
      final en = enabled ?? prefs.sunnahSalawatEnabled;
      await notifService.requestPermissions();
      if (!en) {
        await notifService.scheduleFridaySalawatReminder(enabled: false);
        await notifService.cancelRepeatingReminder('sunnah_salawat_eve');
        await notifService.cancelRepeatingReminder('sunnah_salawat_friday');
        return;
      }
      await notifService.scheduleFridaySalawatReminder(
        enabled: true,
        fridayHour: salawatFridayHour,
        fridayMinute: salawatFridayMinute,
        eveHour: salawatEveHour,
        eveMinute: salawatEveMinute,
        scheduleEve: salawatEveInterval == null,
        scheduleFriday: salawatFridayInterval == null,
      );
      const eveBody =
          'إن من أفضل أيامكم يوم الجمعة، فأكثروا عليّ من الصلاة فيه فإن صلاتكم معروضة عليّ';
      const fridayBody =
          'أكثروا من الصلاة والسلام على نبينا محمد ﷺ في هذا اليوم المبارك';
      if (salawatEveInterval != null) {
        await notifService.scheduleRepeatingReminder(
          category: 'sunnah_salawat_eve',
          body: eveBody,
          startHour: salawatEveHour,
          startMinute: salawatEveMinute,
          intervalMinutes: salawatEveInterval,
          onlyWeekday: DateTime.thursday,
        );
      } else {
        await notifService.cancelRepeatingReminder('sunnah_salawat_eve');
      }
      if (salawatFridayInterval != null) {
        await notifService.scheduleRepeatingReminder(
          category: 'sunnah_salawat_friday',
          body: fridayBody,
          startHour: salawatFridayHour,
          startMinute: salawatFridayMinute,
          intervalMinutes: salawatFridayInterval,
          onlyWeekday: DateTime.friday,
        );
      } else {
        await notifService.cancelRepeatingReminder('sunnah_salawat_friday');
      }
    }

    Future<void> applyFasting({int? hour, int? minute, bool? enabled}) async {
      final h = hour ?? fastingHour;
      final m = minute ?? fastingMinute;
      final en = enabled ?? prefs.sunnahFastingEnabled;
      await notifService.requestPermissions();
      await notifService.scheduleFastingReminders(
        enabled: en,
        hour: h,
        minute: m,
      );
    }

    Future<void> applyWhiteDays({int? hour, int? minute, bool? enabled}) async {
      final h = hour ?? whiteDaysHour;
      final m = minute ?? whiteDaysMinute;
      final en = enabled ?? prefs.sunnahWhiteDaysEnabled;
      await notifService.requestPermissions();
      await notifService.scheduleWhiteDaysReminder(
        enabled: en,
        hour: h,
        minute: m,
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.auto_stories_outlined,
              color: onSurface.withValues(alpha: 0.7),
            ),
            title: const Text('سورة الكهف'),
            subtitle: Text(
              'تذكير صباح كل جمعة (${formatTimeOfDay(kahfHour, kahfMinute)})',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            value: prefs.sunnahKahfEnabled,
            onChanged: (v) async {
              await prefs.setSunnahKahfEnabled(v);
              await applyKahf(enabled: v);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
            },
          ),
          if (prefs.sunnahKahfEnabled) ...[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(right: 16, left: 16),
              leading: const SizedBox(width: 24),
              title: Text(
                'الساعة: ${formatTimeOfDay(kahfHour, kahfMinute)}',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_left, size: 18),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialEntryMode: TimePickerEntryMode.input,
                  initialTime: TimeOfDay(hour: kahfHour, minute: kahfMinute),
                );
                if (picked == null || !context.mounted) return;
                await userPrefs.setActivityReminder(
                  _kSunnahKahfHourKey,
                  enabled: true,
                  hour: picked.hour,
                  minute: picked.minute,
                );
                ref.read(categoryStreakVersionProvider.notifier).bump();
                await applyKahf(hour: picked.hour, minute: picked.minute);
              },
            ),
            RepeatIntervalTile(
              minutes: kahfInterval,
              onTap: () async {
                final picked = await pickRepeatIntervalMinutes(
                  context,
                  kahfInterval,
                );
                if (!context.mounted) return;
                await userPrefs.setReminderIntervalMinutes(
                  'sunnah_kahf',
                  picked,
                );
                ref.read(categoryStreakVersionProvider.notifier).bump();
                if (!context.mounted) return;
                await applyKahf();
              },
            ),
          ],
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              Icons.favorite_outline,
              color: onSurface.withValues(alpha: 0.7),
            ),
            title: const Text('الصلاة على النبي ﷺ'),
            subtitle: Text(
              'تذكير ليلة الجمعة (${formatTimeOfDay(salawatEveHour, salawatEveMinute)}) وصباح الجمعة (${formatTimeOfDay(salawatFridayHour, salawatFridayMinute)})',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            value: prefs.sunnahSalawatEnabled,
            onChanged: (v) async {
              await prefs.setSunnahSalawatEnabled(v);
              await applySalawat(enabled: v);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
            },
          ),
          if (prefs.sunnahSalawatEnabled) ...[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(right: 16, left: 16),
              leading: const SizedBox(width: 24),
              title: Text(
                'ليلة الجمعة: ${formatTimeOfDay(salawatEveHour, salawatEveMinute)}',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_left, size: 18),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialEntryMode: TimePickerEntryMode.input,
                  initialTime: TimeOfDay(
                    hour: salawatEveHour,
                    minute: salawatEveMinute,
                  ),
                );
                if (picked == null || !context.mounted) return;
                await userPrefs.setActivityReminder(
                  _kSunnahSalawatEveHourKey,
                  enabled: true,
                  hour: picked.hour,
                  minute: picked.minute,
                );
                ref.read(categoryStreakVersionProvider.notifier).bump();
                if (!context.mounted) return;
                await applySalawat();
              },
            ),
            RepeatIntervalTile(
              minutes: salawatEveInterval,
              onTap: () async {
                final picked = await pickRepeatIntervalMinutes(
                  context,
                  salawatEveInterval,
                );
                if (!context.mounted) return;
                await userPrefs.setReminderIntervalMinutes(
                  'sunnah_salawat_eve',
                  picked,
                );
                ref.read(categoryStreakVersionProvider.notifier).bump();
                if (!context.mounted) return;
                await applySalawat();
              },
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(right: 16, left: 16),
              leading: const SizedBox(width: 24),
              title: Text(
                'صباح الجمعة: ${formatTimeOfDay(salawatFridayHour, salawatFridayMinute)}',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_left, size: 18),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialEntryMode: TimePickerEntryMode.input,
                  initialTime: TimeOfDay(
                    hour: salawatFridayHour,
                    minute: salawatFridayMinute,
                  ),
                );
                if (picked == null || !context.mounted) return;
                await userPrefs.setActivityReminder(
                  _kSunnahSalawatFridayHourKey,
                  enabled: true,
                  hour: picked.hour,
                  minute: picked.minute,
                );
                ref.read(categoryStreakVersionProvider.notifier).bump();
                if (!context.mounted) return;
                await applySalawat();
              },
            ),
            RepeatIntervalTile(
              minutes: salawatFridayInterval,
              onTap: () async {
                final picked = await pickRepeatIntervalMinutes(
                  context,
                  salawatFridayInterval,
                );
                if (!context.mounted) return;
                await userPrefs.setReminderIntervalMinutes(
                  'sunnah_salawat_friday',
                  picked,
                );
                ref.read(categoryStreakVersionProvider.notifier).bump();
                if (!context.mounted) return;
                await applySalawat();
              },
            ),
          ],
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              Icons.calendar_today_outlined,
              color: onSurface.withValues(alpha: 0.7),
            ),
            title: const Text('صيام الإثنين والخميس'),
            subtitle: Text(
              'تذكير مساء الأحد والأربعاء لتبييت نية الصيام (${formatTimeOfDay(fastingHour, fastingMinute)})',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            value: prefs.sunnahFastingEnabled,
            onChanged: (v) async {
              await prefs.setSunnahFastingEnabled(v);
              await applyFasting(enabled: v);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
            },
          ),
          if (prefs.sunnahFastingEnabled) ...[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(right: 16, left: 16),
              leading: const SizedBox(width: 24),
              title: Text(
                'الساعة: ${formatTimeOfDay(fastingHour, fastingMinute)}',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_left, size: 18),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialEntryMode: TimePickerEntryMode.input,
                  initialTime: TimeOfDay(
                    hour: fastingHour,
                    minute: fastingMinute,
                  ),
                );
                if (picked == null || !context.mounted) return;
                await userPrefs.setActivityReminder(
                  _kSunnahFastingHourKey,
                  enabled: true,
                  hour: picked.hour,
                  minute: picked.minute,
                );
                ref.read(categoryStreakVersionProvider.notifier).bump();
                await applyFasting(hour: picked.hour, minute: picked.minute);
              },
            ),
          ],
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              Icons.brightness_2_outlined,
              color: onSurface.withValues(alpha: 0.7),
            ),
            title: const Text('صيام الأيام البيض'),
            subtitle: Text(
              'تذكير ليلة 13 من كل شهر هجري بصيام (13، 14، 15) (${formatTimeOfDay(whiteDaysHour, whiteDaysMinute)})',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            value: prefs.sunnahWhiteDaysEnabled,
            onChanged: (v) async {
              await prefs.setSunnahWhiteDaysEnabled(v);
              await applyWhiteDays(enabled: v);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
            },
          ),
          if (prefs.sunnahWhiteDaysEnabled) ...[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(right: 16, left: 16),
              leading: const SizedBox(width: 24),
              title: Text(
                'الساعة: ${formatTimeOfDay(whiteDaysHour, whiteDaysMinute)}',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_left, size: 18),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialEntryMode: TimePickerEntryMode.input,
                  initialTime: TimeOfDay(
                    hour: whiteDaysHour,
                    minute: whiteDaysMinute,
                  ),
                );
                if (picked == null || !context.mounted) return;
                await userPrefs.setActivityReminder(
                  _kSunnahWhiteDaysHourKey,
                  enabled: true,
                  hour: picked.hour,
                  minute: picked.minute,
                );
                ref.read(categoryStreakVersionProvider.notifier).bump();
                await applyWhiteDays(hour: picked.hour, minute: picked.minute);
              },
            ),
          ],
        ],
      ),
    );
  }
}
