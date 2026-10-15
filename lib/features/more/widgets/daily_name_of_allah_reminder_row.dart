import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_repository.dart' show UserCategories;
import '../../../core/text/time_format.dart';
import '../../notifications/adhan_notification_service.dart';
import '../../notifications/reminder_messages.dart'
    show dailyNameOfAllahReminderMessages;
import 'reminder_repeat_interval.dart';

/// صف تذكير "اسم من أسماء الله الحسنى" — نفس مبدأ [DailyHadithReminderRow]
/// تماماً.
class DailyNameOfAllahReminderRow extends ConsumerWidget {
  const DailyNameOfAllahReminderRow({super.key});

  static const _category = UserCategories.dailyNameOfAllah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final enabled = userPrefs.reminderEnabledFor(_category);
    final hour = userPrefs.reminderHourFor(_category);
    final minute = userPrefs.reminderMinuteFor(_category);
    final interval = userPrefs.reminderIntervalMinutesFor(_category);

    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.auto_awesome_outlined,
            color: onSurface.withValues(alpha: 0.7),
          ),
          title: const Text('اسم من أسماء الله الحسنى'),
          subtitle: Text(
            hour != null ? formatTimeOfDay(hour, minute) : 'لا وقت محدَّد',
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.55),
            ),
          ),
          onTap: () => _pickTime(context, ref),
          trailing: Switch(
            value: enabled,
            onChanged: (v) => _toggle(context, ref, v),
          ),
        ),
        if (enabled)
          RepeatIntervalTile(
            minutes: interval,
            onTap: () => _pickInterval(context, ref),
          ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final initial = TimeOfDay(
      hour: userPrefs.reminderHourFor(_category) ?? 9,
      minute: userPrefs.reminderMinuteFor(_category),
    );
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: initial,
    );
    if (picked == null || !context.mounted) return;
    await userPrefs.setActivityReminder(
      _category,
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _pickInterval(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final picked = await pickRepeatIntervalMinutes(
      context,
      userPrefs.reminderIntervalMinutesFor(_category),
    );
    if (!context.mounted) return;
    await userPrefs.setReminderIntervalMinutes(_category, picked);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final userPrefs = ref.read(userPrefsProvider);
    final hour = userPrefs.reminderHourFor(_category) ?? 9;
    final minute = userPrefs.reminderMinuteFor(_category);
    await userPrefs.setActivityReminder(
      _category,
      enabled: value,
      hour: hour,
      minute: minute,
    );
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _applyState(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final svc = AdhanNotificationService.instance;
    try {
      final hour = userPrefs.reminderHourFor(_category);
      final interval = userPrefs.reminderIntervalMinutesFor(_category);
      if (userPrefs.reminderEnabledFor(_category) && hour != null) {
        await svc.requestPermissions();
        final messages = dailyNameOfAllahReminderMessages();
        if (interval != null) {
          await svc.cancelDailyNameOfAllahReminder();
          await svc.scheduleRepeatingReminder(
            category: _category,
            body: messages[DateTime.now().day % messages.length],
            startHour: hour,
            startMinute: userPrefs.reminderMinuteFor(_category),
            intervalMinutes: interval,
          );
        } else {
          await svc.cancelRepeatingReminder(_category);
          await svc.scheduleDailyNameOfAllahReminder(
            hour: hour,
            minute: userPrefs.reminderMinuteFor(_category),
            messages: messages,
          );
        }
      } else {
        await svc.cancelDailyNameOfAllahReminder();
        await svc.cancelRepeatingReminder(_category);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر ضبط تذكير أسماء الله الحسنى على هذا الجهاز: $e'),
        ),
      );
    }
  }
}
