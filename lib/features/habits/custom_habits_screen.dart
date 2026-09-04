import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/custom_habits_prefs.dart';
import '../../core/text/time_format.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/adhan_notification_service.dart';

/// تقدّم اليوم لعادة معيّنة — `FutureProvider.family` لأن الاستعلام مباشر
/// من `CustomHabitLogs` (لا تحميل بالذاكرة، نفس منطق `qiyamAyahCountFor`).
/// `ref.watch(customHabitsVersionProvider)` داخل الدالة يجبر إعادة الجلب
/// بعد أي `bump()` (نفس نمط `_hifzRangeLabelProvider`).
final _habitProgressTodayProvider = FutureProvider.family<int, int>((
  ref,
  habitId,
) {
  ref.watch(customHabitsVersionProvider);
  return ref.read(customHabitsPrefsProvider).progressToday(habitId);
});

final _habitStreakProvider =
    FutureProvider.family<int, (int habitId, int target)>((ref, key) {
      ref.watch(customHabitsVersionProvider);
      return ref.read(customHabitsPrefsProvider).streakDays(key.$1, key.$2);
    });

/// هل جاء وقت هذه العادة اليوم؟ — نفس مبدأ `hasMomentArrivedToday` بشاشة
/// الصلاة بالضبط (`prayer_times_service.dart`) لكن مبني على وقت حرّ
/// (ساعة/دقيقة) يختاره المستخدم نفسه بدل موقع جغرافي، بطلب صريح: عادة
/// بلا وقت تذكير محدَّد أصلاً **تبقى مفتوحة دائماً** (لا مرجع زمني نقفلها
/// عليه، ولا داعي لإجبار المستخدم على اختيار وقت لمجرّد رفع القفل — نفس
/// فلسفة "لا نقفل ميزة كاملة بسبب غياب بيانات" المعتمدة بالمشروع).
bool _habitTimeArrived(CustomHabit habit) {
  if (habit.reminderHour == null) return true;
  final now = TimeOfDay.now();
  return now.hour * 60 + now.minute >=
      habit.reminderHour! * 60 + habit.reminderMinute;
}

/// شاشة "عاداتي" — عادات يعرّفها المستخدم بنفسه (عنوان/هدف يومي/تذكير حرّ)،
/// **مستقلة تماماً** عن أنظمة الأنشطة المتخصّصة الجاهزة (أذكار/قيام/حفظ/
/// ختمة). راجع خطة الميزة بـ`memory/humam-app-project.md`.
class CustomHabitsScreen extends ConsumerWidget {
  const CustomHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(customHabitsVersionProvider); // يجبر إعادة البناء بعد bump()
    final habits = ref.watch(customHabitsPrefsProvider).habits;

    return Scaffold(
      appBar: AppBar(title: const Text('عاداتي')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('عادة جديدة'),
        onPressed: () => _createHabit(context, ref),
      ),
      body: habits.isEmpty
          ? _EmptyState(onCreate: () => _createHabit(context, ref))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                for (final habit in habits) ...[
                  _HabitCard(habit: habit),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Future<void> _createHabit(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const _CreateHabitSheet(),
    );
    if (created == true) {
      ref.read(customHabitsVersionProvider.notifier).bump();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist_rtl_outlined,
            size: 48,
            color: themeAccent(context),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا عادات مخصّصة بعد',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف أي نشاط تريد تتبّعه بنفسك — اسمه، هدفه اليومي، ووقت تذكير اختياري.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('أضف عادة'),
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  const _HabitCard({required this.habit});
  final CustomHabit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final progress =
        ref.watch(_habitProgressTodayProvider(habit.id)).value ?? 0;
    final streak =
        ref.watch(_habitStreakProvider((habit.id, habit.targetDaily))).value ??
        0;
    final done = progress >= habit.targetDaily;
    // مقفلة فقط لو فيها وقت تذكير محدَّد ولسا ما جاء — ولو انتهت أصلاً
    // اليوم (`done`) ما تُقفَل بأثر رجعي (نفس مبدأ القفل أحادي الاتجاه
    // بشاشة الصلاة: قبل الوقت مقفل، بعده مفتوح للأبد بلا إغلاق ثانٍ).
    final locked = !done && !_habitTimeArrived(habit);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (locked) ...[
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    habit.title,
                    style: TextStyle(
                      color: locked ? onSurface.withValues(alpha: 0.6) : onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (streak > 0) ...[
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.goldDeep,
                    size: 16,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: AppColors.goldDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'حذف العادة',
                  color: onSurface.withValues(alpha: 0.5),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: habit.targetDaily <= 0
                          ? (done ? 1 : 0)
                          : (progress / habit.targetDaily).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.line,
                      color: done ? AppColors.teal : themeAccent(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$progress/${habit.targetDaily}',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.7),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: locked
                      ? Tooltip(
                          message: 'لسا ما جا وقتها',
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.lock_outline, size: 16),
                            label: Text(
                              'يُفتح الساعة ${formatTimeOfDay(habit.reminderHour!, habit.reminderMinute)}',
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          icon: Icon(
                            done ? Icons.check_circle_outline : Icons.add,
                            size: 18,
                          ),
                          label: Text(done ? 'تمّ اليوم' : 'سجّل تقدّماً (+١)'),
                          onPressed: () async {
                            await ref
                                .read(customHabitsPrefsProvider)
                                .addProgress(habit.id);
                            ref.read(customHabitsVersionProvider.notifier).bump();
                          },
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    habit.remindersEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none_outlined,
                  ),
                  tooltip: 'تذكير يومي',
                  color: habit.remindersEnabled
                      ? themeAccent(context)
                      : onSurface.withValues(alpha: 0.5),
                  onPressed: () => _pickReminder(context, ref),
                ),
              ],
            ),
            if (habit.remindersEnabled && habit.reminderHour != null) ...[
              const SizedBox(height: 4),
              Text(
                'تذكير يومي: ${formatTimeOfDay(habit.reminderHour!, habit.reminderMinute)}',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.5),
                  fontSize: 11.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminder(BuildContext context, WidgetRef ref) async {
    final initial = TimeOfDay(
      hour: habit.reminderHour ?? 20,
      minute: habit.reminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: initial,
    );
    if (picked == null || !context.mounted) return;

    final prefs = ref.read(customHabitsPrefsProvider);
    await prefs.setReminder(
      habit.id,
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    ref.read(customHabitsVersionProvider.notifier).bump();
    if (!context.mounted) return;
    try {
      await AdhanNotificationService.instance.requestPermissions();
      await AdhanNotificationService.instance.scheduleCustomHabitReminder(
        habit.id,
        title: habit.title,
        hour: picked.hour,
        minute: picked.minute,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر ضبط تذكير "${habit.title}" على هذا الجهاز: $e'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف العادة؟'),
        content: Text('سيُحذف "${habit.title}" وسلسلة استمراره نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(customHabitsPrefsProvider).delete(habit.id);
    if (habit.remindersEnabled) {
      await AdhanNotificationService.instance.cancelCustomHabitReminder(
        habit.id,
      );
    }
    ref.read(customHabitsVersionProvider.notifier).bump();
  }
}

class _CreateHabitSheet extends ConsumerStatefulWidget {
  const _CreateHabitSheet();

  @override
  ConsumerState<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<_CreateHabitSheet> {
  final _titleController = TextEditingController();
  int _target = 1;
  TimeOfDay? _reminderTime;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'عادة جديدة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'اسم العادة',
                hintText: 'مثلاً: قراءة كتاب ديني',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('الهدف اليومي'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _target > 1
                      ? () => setState(() => _target--)
                      : null,
                ),
                Text(
                  '$_target',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _target++),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(
                _reminderTime == null
                    ? 'بلا تذكير (اختياري)'
                    : 'تذكير الساعة ${formatTimeOfDay(_reminderTime!.hour, _reminderTime!.minute)}',
              ),
              trailing: _reminderTime != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _reminderTime = null),
                    )
                  : const Icon(Icons.chevron_left),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialEntryMode: TimePickerEntryMode.input,
                  initialTime:
                      _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
                );
                if (picked != null) setState(() => _reminderTime = picked);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);

    final prefs = ref.read(customHabitsPrefsProvider);
    final habit = await prefs.create(
      title: title,
      targetDaily: _target,
      reminderHour: _reminderTime?.hour,
      reminderMinute: _reminderTime?.minute ?? 0,
    );

    if (_reminderTime != null) {
      try {
        await AdhanNotificationService.instance.requestPermissions();
        await AdhanNotificationService.instance.scheduleCustomHabitReminder(
          habit.id,
          title: habit.title,
          hour: _reminderTime!.hour,
          minute: _reminderTime!.minute,
        );
      } catch (_) {
        // فشل جدولة التذكير لا يمنع حفظ العادة نفسها — نفس تسامح بقية
        // مسارات التذكير بالمشروع (`_ReminderSection._applyReminderState`).
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}
