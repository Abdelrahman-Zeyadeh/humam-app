import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../azkar/streak_status_row.dart';
import '../notifications/adhan_notification_service.dart';

/// شاشة قيام الليل: تسجيل يدوي (لا طريقة لرصد قيامك تلقائياً) بسلسلة
/// استمرار مستقلة (`UserCategories.qiyam`، معروضة أيضاً بالداشبورد)، +
/// تذكير يومي اختياري بساعة يحدّدها المستخدم (`AdhanNotificationService.
/// scheduleQiyamReminder` — تكرار يومي حقيقي على مستوى النظام، لا إعادة
/// جدولة يدوية كإشعارات الأذان).
class QiyamScreen extends ConsumerWidget {
  const QiyamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final loggedToday = prefs.completedTodayFor(UserCategories.qiyam);

    return Scaffold(
      appBar: AppBar(title: const Text('قيام الليل')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // نفس صف الحالة المستخدَم بكل خانات الأذكار الأخرى ("زي الثانيات")
          // — سلسلة الاستمرار + هل تمّت اليوم أم لا، بنفس التصميم حرفياً.
          const StreakStatusRow(category: UserCategories.qiyam),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  icon: Icon(loggedToday ? Icons.check_circle : Icons.bedtime_outlined),
                  label: Text(loggedToday ? 'سجّلت قيامك الليلة' : 'سجّل قيامك الليلة'),
                  onPressed: loggedToday
                      ? null
                      : () async {
                          await prefs.bumpCategoryStreakIfNewDay(UserCategories.qiyam);
                          ref.read(categoryStreakVersionProvider.notifier).bump();
                        },
                ),
                const SizedBox(height: 6),
                Text(
                  'تسجيل يدوي — ما في طريقة نرصد قيامك تلقائياً، فقط اضغط الزر بعد ما تصلّي.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 11.5),
                ),
                const Divider(height: 44),
                Text('تذكير يومي', style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'إشعار يتكرر كل يوم بالساعة اللي تختارها لتذكيرك بالقيام.',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تفعيل التذكير'),
                  value: prefs.qiyamEnabled,
                  onChanged: (v) => _toggleEnabled(context, ref, v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(prefs.qiyamHour != null ? _formatTimeOfDay(prefs.qiyamHour!, prefs.qiyamMinute) : 'اختر الساعة'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _pickTime(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(userPrefsProvider);
    final initial = TimeOfDay(hour: prefs.qiyamHour ?? 2, minute: prefs.qiyamMinute);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !context.mounted) return;
    await prefs.setQiyamReminder(enabled: true, hour: picked.hour, minute: picked.minute);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyReminderState(context, ref);
  }

  Future<void> _toggleEnabled(BuildContext context, WidgetRef ref, bool value) async {
    final prefs = ref.read(userPrefsProvider);
    if (value && prefs.qiyamHour == null) {
      // ما في ساعة مختارة بعد — نفتح منتقي الوقت مباشرة، وهو يفعّل ضمنياً
      // (`setQiyamReminder(enabled: true, ...)`) عند الاختيار.
      await _pickTime(context, ref);
      return;
    }
    await prefs.setQiyamReminder(enabled: value);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyReminderState(context, ref);
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — نفس قيد
  /// `prayer_screen.dart._toggleNotifications` (الخدمة آمنة على أندرويد/
  /// iOS فقط، ترمي على منصّات أخرى بلا إعدادات مخصَّصة).
  Future<void> _applyReminderState(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(userPrefsProvider);
    try {
      if (prefs.qiyamEnabled && prefs.qiyamHour != null) {
        await AdhanNotificationService.instance.requestPermissions();
        await AdhanNotificationService.instance.scheduleQiyamReminder(hour: prefs.qiyamHour!, minute: prefs.qiyamMinute);
      } else {
        await AdhanNotificationService.instance.cancelQiyamReminder();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط تذكير قيام الليل على هذا الجهاز: $e')),
      );
    }
  }
}

String _formatTimeOfDay(int hour, int minute) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? 'ص' : 'م';
  final m = minute.toString().padLeft(2, '0');
  return '$h12:$m $period';
}
