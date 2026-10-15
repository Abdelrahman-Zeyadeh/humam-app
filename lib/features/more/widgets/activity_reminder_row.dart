import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_repository.dart' show UserCategories;
import '../../../core/text/time_format.dart';
import '../../notifications/adhan_notification_service.dart';
import 'reminder_repeat_interval.dart';

/// صف تذكير نشاط واحد (أذكار الصباح/المساء، الورد اليومي) — تفعيل + وقت،
/// بنفس نمط قسم التذكير بـ`hifz_screen.dart`/`qiyam_screen.dart` لكن مضغوطاً
/// بصفّ واحد بدل قسم كامل (٣ أنشطة هون بشاشة واحدة).
class ActivityReminderRow extends ConsumerWidget {
  const ActivityReminderRow({
    super.key,
    required this.category,
    required this.label,
    required this.icon,
  });
  final String category;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final enabled = userPrefs.reminderEnabledFor(category);
    final hour = userPrefs.reminderHourFor(category);
    final minute = userPrefs.reminderMinuteFor(category);
    final interval = userPrefs.reminderIntervalMinutesFor(category);

    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: onSurface.withValues(alpha: 0.7)),
          title: Text(label),
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
      hour: userPrefs.reminderHourFor(category) ?? 6,
      minute: userPrefs.reminderMinuteFor(category),
    );
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: initial,
    );
    if (picked == null || !context.mounted) return;
    await userPrefs.setActivityReminder(
      category,
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
      userPrefs.reminderIntervalMinutesFor(category),
    );
    if (!context.mounted) return;
    await userPrefs.setReminderIntervalMinutes(category, picked);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final userPrefs = ref.read(userPrefsProvider);
    final defaultHour = category == UserCategories.morningAzkar
        ? 6
        : (category == UserCategories.eveningAzkar
            ? 18
            : (category == UserCategories.dailyWird ? 8 : 9));
    final hour = userPrefs.reminderHourFor(category) ?? defaultHour;
    final minute = userPrefs.reminderMinuteFor(category);
    await userPrefs.setActivityReminder(
      category,
      enabled: value,
      hour: hour,
      minute: minute,
    );
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — نفس قيد
  /// `qiyam_screen.dart._applyReminderState`. لو فُعِّل تكرار (راجع
  /// [RepeatIntervalTile]) نستخدم [AdhanNotificationService.
  /// scheduleRepeatingReminder] بدل الجدولة الثابتة القديمة.
  Future<void> _applyState(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final svc = AdhanNotificationService.instance;
    try {
      final hour = userPrefs.reminderHourFor(category);
      final interval = userPrefs.reminderIntervalMinutesFor(category);
      if (userPrefs.reminderEnabledFor(category) && hour != null) {
        await svc.requestPermissions();
        if (interval != null) {
          await svc.cancelActivityReminder(category);
          await svc.scheduleRepeatingReminder(
            category: category,
            body: 'حان وقت التذكير الذي اخترته لـ$label',
            startHour: hour,
            startMinute: userPrefs.reminderMinuteFor(category),
            intervalMinutes: interval,
          );
        } else {
          await svc.cancelRepeatingReminder(category);
          await svc.scheduleActivityReminder(
            category,
            hour: hour,
            minute: userPrefs.reminderMinuteFor(category),
          );
        }
      } else {
        await svc.cancelActivityReminder(category);
        await svc.cancelRepeatingReminder(category);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط التذكير على هذا الجهاز: $e')),
      );
    }
  }
}
