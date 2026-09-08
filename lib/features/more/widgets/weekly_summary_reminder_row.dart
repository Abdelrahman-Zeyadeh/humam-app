import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/khatma_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/text/time_format.dart';
import '../../notifications/adhan_notification_service.dart';
import '../../notifications/weekly_summary_text.dart';

/// إعداد "ملخّص الأسبوع" — نفس تخزين [EveningSummaryReminderRow] تماماً
/// (`ActivityReminders` بمفتاح `weekly_summary` جديد) لكن يُطلَق مرّة واحدة
/// أسبوعياً مساء الجمعة (نهاية الأسبوع الثابت بـ`weekly_report_screen.dart`)
/// لا يومياً؛ لا صف فاصل زمني (`RepeatIntervalTile`) هنا لأن المعنى
/// "أسبوعي" أصلاً، لا حاجة لتخصيص التكرار.
class WeeklySummaryReminderRow extends ConsumerWidget {
  const WeeklySummaryReminderRow({super.key});

  static const _category = 'weekly_summary';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final enabled = userPrefs.reminderEnabledFor(_category);
    final hour = userPrefs.reminderHourFor(_category);
    final minute = userPrefs.reminderMinuteFor(_category);

    return ListTile(
      leading: Icon(
        Icons.insert_chart_outlined_rounded,
        color: onSurface.withValues(alpha: 0.7),
      ),
      title: const Text('ملخّص الأسبوع'),
      subtitle: Text(
        hour != null
            ? 'كل جمعة الساعة ${formatTimeOfDay(hour, minute)}'
            : 'الافتراضي: الجمعة ٢٠:٠٠',
        style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.55)),
      ),
      onTap: () => _pickTime(context, ref),
      trailing: Switch(
        value: enabled,
        onChanged: (v) => _toggle(context, ref, v),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final initial = TimeOfDay(
      hour: userPrefs.reminderHourFor(_category) ?? 20,
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

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final userPrefs = ref.read(userPrefsProvider);
    if (value && userPrefs.reminderHourFor(_category) == null) {
      await _pickTime(context, ref);
      return;
    }
    await userPrefs.setActivityReminder(_category, enabled: value);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  Future<void> _applyState(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final khatmaPrefs = ref.read(khatmaPrefsProvider);
    final svc = AdhanNotificationService.instance;
    try {
      final hour = userPrefs.reminderHourFor(_category);
      if (userPrefs.reminderEnabledFor(_category) && hour != null) {
        await svc.requestPermissions();
        final body = await buildWeeklySummaryBodyFor(userPrefs, khatmaPrefs);
        await svc.scheduleWeeklySummary(
          hour: hour,
          minute: userPrefs.reminderMinuteFor(_category),
          body: body,
        );
      } else {
        await svc.cancelWeeklySummary();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط ملخّص الأسبوع على هذا الجهاز: $e')),
      );
    }
  }
}
