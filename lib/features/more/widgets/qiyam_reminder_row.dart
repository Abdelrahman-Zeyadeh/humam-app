import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/hadith/hadith_providers.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_repository.dart' show UserCategories;
import '../../../core/text/time_format.dart';
import '../../notifications/adhan_notification_service.dart';
import '../../notifications/reminder_messages.dart' show qiyamReminderMessages;
import 'reminder_repeat_interval.dart';

/// صف تذكير قيام الليل — **نفس التخزين** المستخدَم بـ`qiyam_screen.dart`
/// حرفياً (`userPrefs.qiyamEnabled`/`.qiyamHour`/`.qiyamMinute`)، لا نسخة
/// موازية؛ موجود هون أيضاً بطلب صاحب المشروع "اجمع التذكيرات بمكان واحد".
class QiyamReminderRow extends ConsumerWidget {
  const QiyamReminderRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final enabled = userPrefs.qiyamEnabled;
    final hour = userPrefs.qiyamHour;
    final minute = userPrefs.qiyamMinute;
    final interval = userPrefs.reminderIntervalMinutesFor(UserCategories.qiyam);

    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.bedtime_outlined,
            color: onSurface.withValues(alpha: 0.7),
          ),
          title: const Text('قيام الليل'),
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
      hour: userPrefs.qiyamHour ?? 2,
      minute: userPrefs.qiyamMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: initial,
    );
    if (picked == null || !context.mounted) return;
    await userPrefs.setQiyamReminder(
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
      userPrefs.reminderIntervalMinutesFor(UserCategories.qiyam),
    );
    if (!context.mounted) return;
    await userPrefs.setReminderIntervalMinutes(UserCategories.qiyam, picked);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final userPrefs = ref.read(userPrefsProvider);
    if (value && userPrefs.qiyamHour == null) {
      await _pickTime(context, ref);
      return;
    }
    await userPrefs.setQiyamReminder(enabled: value);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _applyState(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final svc = AdhanNotificationService.instance;
    try {
      final hour = userPrefs.qiyamHour;
      final interval = userPrefs.reminderIntervalMinutesFor(
        UserCategories.qiyam,
      );
      if (userPrefs.qiyamEnabled && hour != null) {
        await svc.requestPermissions();
        final messages = await qiyamReminderMessages(
          ref.read(hadithRepositoryProvider),
        );
        if (interval != null) {
          await svc.cancelQiyamReminder();
          await svc.scheduleRepeatingReminder(
            category: UserCategories.qiyam,
            body: messages[DateTime.now().day % messages.length],
            startHour: hour,
            startMinute: userPrefs.qiyamMinute,
            intervalMinutes: interval,
          );
        } else {
          await svc.cancelRepeatingReminder(UserCategories.qiyam);
          await svc.scheduleQiyamReminder(
            hour: hour,
            minute: userPrefs.qiyamMinute,
            messages: messages,
          );
        }
      } else {
        await svc.cancelQiyamReminder();
        await svc.cancelRepeatingReminder(UserCategories.qiyam);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر ضبط تذكير قيام الليل على هذا الجهاز: $e'),
        ),
      );
    }
  }
}
