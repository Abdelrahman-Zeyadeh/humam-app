import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/hadith/hadith_providers.dart';
import '../../../core/data/user/hifz_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_repository.dart' show UserCategories;
import '../../../core/text/time_format.dart';
import '../../notifications/adhan_notification_service.dart';
import '../../notifications/reminder_messages.dart' show hifzReminderMessages;
import 'reminder_repeat_interval.dart';

/// صف تذكير الحفظ — **نفس التخزين** المستخدَم بـ`hifz_screen.dart` حرفياً
/// (`hifzPrefs.reminderEnabled`/`.reminderHour`/`.reminderMinute`)، لا
/// نسخة موازية؛ راجع توثيق [QiyamReminderRow] لنفس السبب.
class HifzReminderRow extends ConsumerWidget {
  const HifzReminderRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hifzVersionProvider);
    final hifzPrefs = ref.watch(hifzPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final enabled = hifzPrefs.reminderEnabled;
    final hour = hifzPrefs.reminderHour;
    final minute = hifzPrefs.reminderMinute;
    final interval = ref
        .watch(userPrefsProvider)
        .reminderIntervalMinutesFor(UserCategories.hifz);

    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.menu_book_rounded,
            color: onSurface.withValues(alpha: 0.7),
          ),
          title: const Text('تذكير الحفظ'),
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
    final hifzPrefs = ref.read(hifzPrefsProvider);
    final initial = TimeOfDay(
      hour: hifzPrefs.reminderHour ?? 20,
      minute: hifzPrefs.reminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: initial,
    );
    if (picked == null || !context.mounted) return;
    await hifzPrefs.setReminder(
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    ref.read(hifzVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _pickInterval(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final picked = await pickRepeatIntervalMinutes(
      context,
      userPrefs.reminderIntervalMinutesFor(UserCategories.hifz),
    );
    if (!context.mounted) return;
    await userPrefs.setReminderIntervalMinutes(UserCategories.hifz, picked);
    ref.read(hifzVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final hifzPrefs = ref.read(hifzPrefsProvider);
    final hour = hifzPrefs.reminderHour ?? 16;
    final minute = hifzPrefs.reminderMinute;
    await hifzPrefs.setReminder(enabled: value, hour: hour, minute: minute);
    ref.read(hifzVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _applyState(BuildContext context, WidgetRef ref) async {
    final hifzPrefs = ref.read(hifzPrefsProvider);
    final userPrefs = ref.read(userPrefsProvider);
    final svc = AdhanNotificationService.instance;
    try {
      final hour = hifzPrefs.reminderHour;
      final interval = userPrefs.reminderIntervalMinutesFor(
        UserCategories.hifz,
      );
      if (hifzPrefs.reminderEnabled && hour != null) {
        await svc.requestPermissions();
        final messages = await hifzReminderMessages(
          ref.read(hadithRepositoryProvider),
        );
        if (interval != null) {
          await svc.cancelHifzReminder();
          await svc.scheduleRepeatingReminder(
            category: UserCategories.hifz,
            body: messages[DateTime.now().day % messages.length],
            startHour: hour,
            startMinute: hifzPrefs.reminderMinute,
            intervalMinutes: interval,
          );
        } else {
          await svc.cancelRepeatingReminder(UserCategories.hifz);
          await svc.scheduleHifzReminder(
            hour: hour,
            minute: hifzPrefs.reminderMinute,
            messages: messages,
          );
        }
      } else {
        await svc.cancelHifzReminder();
        await svc.cancelRepeatingReminder(UserCategories.hifz);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط تذكير الحفظ على هذا الجهاز: $e')),
      );
    }
  }
}
