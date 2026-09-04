import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_providers.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../../core/text/time_format.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/adhan_notification_prefs.dart';
import '../notifications/adhan_notification_service.dart';
import '../notifications/evening_summary_text.dart';
import '../notifications/reminder_messages.dart'
    show
        dailyHadithReminderMessages,
        dailyNameOfAllahReminderMessages,
        hifzReminderMessages,
        qiyamReminderMessages;

/// شاشة "التذكيرات" — كل ما يخصّ تذكيرات التطبيق مجمَّعاً بمكان واحد
/// (كانت موزَّعة داخل شاشة الإعدادات نفسها: تذكيرات يومية، أذكار كل ساعة،
/// تنبيهات السنن). نُقلت هون بالكامل بطلب صاحب المشروع — الإعدادات
/// أصبحت مخصَّصة للمظهر/الصوت/النسخ الاحتياطي، والتذكيرات قسم مستقل
/// بشاشة "أدواتي".
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التذكيرات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('تذكيرات يومية'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const _ReminderRow(
                  category: UserCategories.morningAzkar,
                  label: 'أذكار الصباح',
                  icon: Icons.wb_sunny_outlined,
                ),
                const Divider(height: 1),
                const _ReminderRow(
                  category: UserCategories.eveningAzkar,
                  label: 'أذكار المساء',
                  icon: Icons.nights_stay_outlined,
                ),
                const Divider(height: 1),
                const _ReminderRow(
                  category: UserCategories.dailyWird,
                  label: 'الورد اليومي',
                  icon: Icons.menu_book_outlined,
                ),
                const Divider(height: 1),
                const _EveningSummaryReminderRow(),
                const Divider(height: 1),
                // بطلب صاحب المشروع "اشعارات التذكير الموجودة بكل مكان
                // اجمعها بمكان واحد" — تذكير قيام الليل والحفظ كانا مخفيَّين
                // داخل شاشتيهما فقط (`qiyam_screen.dart`/`hifz_screen.dart`)
                // رغم استخدامهما نفس نظام التذكيرات؛ هون **نفس** التخزين
                // (`userPrefsProvider`/`hifzPrefsProvider`) لا نسخة موازية،
                // فالتعديل من أي شاشة ينعكس تلقائياً بالثانية.
                const _QiyamReminderRow(),
                const Divider(height: 1),
                const _HifzReminderRow(),
                const Divider(height: 1),
                // بطلب صاحب المشروع "حديث اليوم بحب ينبعث كاشعار... واسماء
                // الله الحسنى كذلك"، وبنفس منطق "هو يحدد اي ساعة".
                const _DailyHadithReminderRow(),
                const Divider(height: 1),
                const _DailyNameOfAllahReminderRow(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('أذكار وأدعية كل ساعة 📿'),
          const _HourlyDhikrSection(),
          const SizedBox(height: 24),
          _SectionTitle('تنبيهات السنن والأيام الفاضلة'),
          const _SunnahRemindersSection(),
        ],
      ),
    );
  }
}

/// خيارات "كل كم" لأي تذكير — بطلب صاحب المشروع "اضافة الوقت للتكرار
/// ربع ساعة نصف ساعة ساعة... وبقدر اضيف التكرارات على كل التذكيرات مثلا
/// الصلاة على النبي وغيرها". `null` = مرة واحدة (بلا تكرار، السلوك
/// القديم).
const _kRepeatIntervalOptions = <int?>[null, 15, 30, 60, 120, 180, 240, 360];

String repeatIntervalLabel(int? minutes) {
  if (minutes == null) return 'مرة واحدة';
  if (minutes < 60) return 'كل $minutes دقيقة';
  final hours = minutes ~/ 60;
  return hours == 1 ? 'كل ساعة' : 'كل $hours ساعات';
}

Future<int?> pickRepeatIntervalMinutes(BuildContext context, int? current) {
  return showDialog<int?>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('التكرار'),
      children: [
        for (final option in _kRepeatIntervalOptions)
          RadioListTile<int?>(
            // ignore: deprecated_member_use
            value: option,
            // ignore: deprecated_member_use
            groupValue: current,
            title: Text(repeatIntervalLabel(option)),
            // ignore: deprecated_member_use
            onChanged: (v) => Navigator.of(dialogContext).pop(v),
          ),
      ],
    ),
  );
}

/// صف فرعي مضغوط "التكرار: ..." — يُعرَض تحت أي صف تذكير أساسي (بعد
/// تفعيله)، بنفس أسلوب صفوف "الساعة" الفرعية بقسم السنن أسفل.
class _RepeatIntervalTile extends StatelessWidget {
  const _RepeatIntervalTile({required this.minutes, required this.onTap});
  final int? minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(right: 16, left: 16),
      leading: const SizedBox(width: 24),
      title: Text(
        'التكرار: ${repeatIntervalLabel(minutes)}',
        style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.7)),
      ),
      trailing: const Icon(Icons.chevron_left, size: 18),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// صف تذكير نشاط واحد (أذكار الصباح/المساء، الورد اليومي) — تفعيل + وقت،
/// بنفس نمط قسم التذكير بـ`hifz_screen.dart`/`qiyam_screen.dart` لكن مضغوطاً
/// بصفّ واحد بدل قسم كامل (٣ أنشطة هون بشاشة واحدة).
class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({
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
          _RepeatIntervalTile(
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
    if (value && userPrefs.reminderHourFor(category) == null) {
      // ما في وقت مختار بعد — نفتح المنتقي مباشرة، يفعّل ضمنياً عند الاختيار.
      await _pickTime(context, ref);
      return;
    }
    await userPrefs.setActivityReminder(category, enabled: value);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    if (!context.mounted) return;
    await _applyState(context, ref);
  }

  /// **لا يجب أن يرمي هون أي استثناء غير مُمسَك** — نفس قيد
  /// `qiyam_screen.dart._applyReminderState`. لو فُعِّل تكرار (راجع
  /// [_RepeatIntervalTile]) نستخدم [AdhanNotificationService.
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

/// إعداد "الملخّص المسائي" — نفس تخزين [_ReminderRow] تماماً (`ActivityReminders`
/// بمفتاح `evening_summary` جديد، بلا جدول مخصَّص) لكن جدولته مختلفة جوهرياً:
/// النص **يُحسَب فعلياً** من نشاط اليوم الحقيقي عند كل تفعيل/تغيير وقت
/// (`AdhanNotificationService.scheduleEveningSummary`)، لا نص ثابت من خريطة
/// كـ[_ReminderRow] العادية — لذا لا يمكن إعادة استخدام تلك الودجت مباشرة.
class _EveningSummaryReminderRow extends ConsumerWidget {
  const _EveningSummaryReminderRow();

  static const _category = 'evening_summary';

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
            Icons.summarize_outlined,
            color: onSurface.withValues(alpha: 0.7),
          ),
          title: const Text('الملخّص المسائي'),
          subtitle: Text(
            hour != null ? formatTimeOfDay(hour, minute) : 'الافتراضي ٢١:٠٠',
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
          _RepeatIntervalTile(
            minutes: interval,
            onTap: () => _pickInterval(context, ref),
          ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final initial = TimeOfDay(
      hour: userPrefs.reminderHourFor(_category) ?? 21,
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
    final svc = AdhanNotificationService.instance;
    try {
      final hour = userPrefs.reminderHourFor(_category);
      final interval = userPrefs.reminderIntervalMinutesFor(_category);
      if (userPrefs.reminderEnabledFor(_category) && hour != null) {
        await svc.requestPermissions();
        final body = await buildEveningSummaryBodyFor(userPrefs);
        if (interval != null) {
          await svc.cancelEveningSummary();
          await svc.scheduleRepeatingReminder(
            category: _category,
            body: body,
            startHour: hour,
            startMinute: userPrefs.reminderMinuteFor(_category),
            intervalMinutes: interval,
          );
        } else {
          await svc.cancelRepeatingReminder(_category);
          await svc.scheduleEveningSummary(
            hour: hour,
            minute: userPrefs.reminderMinuteFor(_category),
            body: body,
          );
        }
      } else {
        await svc.cancelEveningSummary();
        await svc.cancelRepeatingReminder(_category);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر ضبط الملخّص المسائي على هذا الجهاز: $e')),
      );
    }
  }
}

/// صف تذكير قيام الليل — **نفس التخزين** المستخدَم بـ`qiyam_screen.dart`
/// حرفياً (`userPrefs.qiyamEnabled`/`.qiyamHour`/`.qiyamMinute`)، لا نسخة
/// موازية؛ موجود هون أيضاً بطلب صاحب المشروع "اجمع التذكيرات بمكان واحد".
class _QiyamReminderRow extends ConsumerWidget {
  const _QiyamReminderRow();

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
          _RepeatIntervalTile(
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

/// صف تذكير الحفظ — **نفس التخزين** المستخدَم بـ`hifz_screen.dart` حرفياً
/// (`hifzPrefs.reminderEnabled`/`.reminderHour`/`.reminderMinute`)، لا
/// نسخة موازية؛ راجع توثيق [_QiyamReminderRow] لنفس السبب.
class _HifzReminderRow extends ConsumerWidget {
  const _HifzReminderRow();

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
          _RepeatIntervalTile(
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
    if (value && hifzPrefs.reminderHour == null) {
      await _pickTime(context, ref);
      return;
    }
    await hifzPrefs.setReminder(enabled: value);
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

/// صف تذكير "حديث اليوم" — يستخدم نظام [ActivityReminders] العام
/// (`userPrefs.reminderEnabledFor(UserCategories.dailyHadith)` وما شابه)
/// للتفعيل/الوقت فقط، لكن الجدولة الفعلية عبر
/// `AdhanNotificationService.scheduleDailyHadithReminder` المخصَّصة (محتوى
/// متجدّد يومياً، لا نص ثابت — راجع توثيقها).
class _DailyHadithReminderRow extends ConsumerWidget {
  const _DailyHadithReminderRow();

  static const _category = UserCategories.dailyHadith;

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
            Icons.menu_book_outlined,
            color: onSurface.withValues(alpha: 0.7),
          ),
          title: const Text('حديث اليوم'),
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
          _RepeatIntervalTile(
            minutes: interval,
            onTap: () => _pickInterval(context, ref),
          ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final initial = TimeOfDay(
      hour: userPrefs.reminderHourFor(_category) ?? 8,
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
    final svc = AdhanNotificationService.instance;
    try {
      final hour = userPrefs.reminderHourFor(_category);
      final interval = userPrefs.reminderIntervalMinutesFor(_category);
      if (userPrefs.reminderEnabledFor(_category) && hour != null) {
        await svc.requestPermissions();
        final messages = dailyHadithReminderMessages();
        if (interval != null) {
          await svc.cancelDailyHadithReminder();
          await svc.scheduleRepeatingReminder(
            category: _category,
            body: messages[DateTime.now().day % messages.length],
            startHour: hour,
            startMinute: userPrefs.reminderMinuteFor(_category),
            intervalMinutes: interval,
          );
        } else {
          await svc.cancelRepeatingReminder(_category);
          await svc.scheduleDailyHadithReminder(
            hour: hour,
            minute: userPrefs.reminderMinuteFor(_category),
            messages: messages,
          );
        }
      } else {
        await svc.cancelDailyHadithReminder();
        await svc.cancelRepeatingReminder(_category);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر ضبط تذكير حديث اليوم على هذا الجهاز: $e'),
        ),
      );
    }
  }
}

/// صف تذكير "اسم من أسماء الله الحسنى" — نفس مبدأ [_DailyHadithReminderRow]
/// تماماً.
class _DailyNameOfAllahReminderRow extends ConsumerWidget {
  const _DailyNameOfAllahReminderRow();

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
          _RepeatIntervalTile(
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

class _SunnahRemindersSection extends ConsumerWidget {
  const _SunnahRemindersSection();

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
            _RepeatIntervalTile(
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
            _RepeatIntervalTile(
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
            _RepeatIntervalTile(
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
              'تذكير مساء الأحد والأربعاء لتبييت نية الصيام (الساعة 08:30 م)',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            value: prefs.sunnahFastingEnabled,
            onChanged: (v) async {
              await notifService.requestPermissions();
              await prefs.setSunnahFastingEnabled(v);
              await notifService.scheduleFastingReminders(enabled: v);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: Icon(
              Icons.brightness_2_outlined,
              color: onSurface.withValues(alpha: 0.7),
            ),
            title: const Text('صيام الأيام البيض'),
            subtitle: Text(
              'تذكير ليلة 13 من كل شهر هجري بصيام (13، 14، 15)',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
            value: prefs.sunnahWhiteDaysEnabled,
            onChanged: (v) async {
              await notifService.requestPermissions();
              await prefs.setSunnahWhiteDaysEnabled(v);
              await notifService.scheduleWhiteDaysReminder(enabled: v);
              ref.read(adhanNotificationVersionProvider.notifier).bump();
            },
          ),
        ],
      ),
    );
  }
}

class _HourlyDhikrSection extends ConsumerWidget {
  const _HourlyDhikrSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hourlyDhikrVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final enabled = userPrefs.hourlyDhikrEnabled;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'أذكار وأدعية كل ساعة',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'إشعار دوري بذكر مأثور أو دعاء جامع — أنت تحدّد الفترة وكل كم يتكرر',
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
              value: enabled,
              activeThumbColor: themeAccent(context),
              onChanged: (val) async {
                await userPrefs.setHourlyDhikr(enabled: val);
                ref.read(hourlyDhikrVersionProvider.notifier).bump();
                await AdhanNotificationService.instance.rescheduleHourlyDhikr(
                  isEnabled: val,
                  startHour: userPrefs.hourlyDhikrStartHour,
                  endHour: userPrefs.hourlyDhikrEndHour,
                  intervalHours: userPrefs.hourlyDhikrIntervalHours,
                );
              },
            ),
            if (enabled) ...[
              const Divider(height: 1),
              // بطلب صاحب المشروع: "هو يحدد اي ساعة او اكثر من وقت" و"خلي
              // المستخدم يقرر... كل كم يبعث ذكر او اشعار" — كانت الفترة
              // ثابتة "٨ ص حتى ١١ م" وكان التكرار ثابتاً كل ساعة بلا أي
              // تحكّم؛ هون منتقٍ فعلي للفترة **والتكرار معاً** يفتحه
              // المستخدم بنفسه.
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: onSurface.withValues(alpha: 0.6),
                ),
                title: Text(
                  'من ${_hour12Label(userPrefs.hourlyDhikrStartHour)} إلى ${_hour12Label(userPrefs.hourlyDhikrEndHour)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: onSurface.withValues(alpha: 0.8),
                  ),
                ),
                subtitle: Text(
                  'يتكرر كل ${userPrefs.hourlyDhikrIntervalHours} ${userPrefs.hourlyDhikrIntervalHours == 1 ? 'ساعة' : 'ساعات'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.55),
                  ),
                ),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => _pickHourRange(context, ref),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.send_outlined, size: 14),
                    label: const Text(
                      'تجربة إشعار الآن',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    onPressed: () async {
                      await AdhanNotificationService.instance
                          .sendTestHourlyDhikrNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم إرسال إشعار ذكر الساعة التجريبي 🔔',
                            ),
                            backgroundColor: Color(0xFF1B8A72),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _hour12Label(int hour24) {
    final period = hour24 < 12 ? 'ص' : 'م';
    var h = hour24 % 12;
    if (h == 0) h = 12;
    return '$h:00 $period';
  }

  Future<void> _pickHourRange(BuildContext context, WidgetRef ref) async {
    final userPrefs = ref.read(userPrefsProvider);
    final result = await showDialog<(int, int, int)>(
      context: context,
      builder: (dialogContext) => _HourRangePickerDialog(
        initialStart: userPrefs.hourlyDhikrStartHour,
        initialEnd: userPrefs.hourlyDhikrEndHour,
        initialInterval: userPrefs.hourlyDhikrIntervalHours,
      ),
    );
    if (result == null) return;
    final (start, end, interval) = result;
    await userPrefs.setHourlyDhikr(
      enabled: true,
      startHour: start,
      endHour: end,
      intervalHours: interval,
    );
    ref.read(hourlyDhikrVersionProvider.notifier).bump();
    await AdhanNotificationService.instance.rescheduleHourlyDhikr(
      isEnabled: true,
      startHour: start,
      endHour: end,
      intervalHours: interval,
    );
  }
}

/// حوار اختيار "من ساعة إلى ساعة" + "كل كم ساعة" لتذكير الأذكار — قائمتان
/// منسدلتان للفترة (٠-٢٣) بدل `showTimePicker` (لا معنى للدقائق هون، كل
/// إشعار بساعة كاملة)، وقائمة ثالثة لاختيار التكرار (كل ١/٢/٣/٤/٦ ساعات)
/// — بطلب صاحب المشروع "خلي المستخدم يقرر... كل كم يبعث ذكر او اشعار".
/// يمنع حفظ نهاية قبل أو تساوي البداية.
class _HourRangePickerDialog extends StatefulWidget {
  const _HourRangePickerDialog({
    required this.initialStart,
    required this.initialEnd,
    required this.initialInterval,
  });

  final int initialStart;
  final int initialEnd;
  final int initialInterval;

  @override
  State<_HourRangePickerDialog> createState() => _HourRangePickerDialogState();
}

class _HourRangePickerDialogState extends State<_HourRangePickerDialog> {
  late int _start = widget.initialStart;
  late int _end = widget.initialEnd;
  late int _interval = widget.initialInterval;

  static const _intervalOptions = [1, 2, 3, 4, 6];

  @override
  Widget build(BuildContext context) {
    final invalid = _end <= _start;
    return AlertDialog(
      title: const Text('أذكار وأدعية كل ساعة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _HourDropdown(
                  label: 'من',
                  value: _start,
                  onChanged: (v) => setState(() => _start = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HourDropdown(
                  label: 'إلى',
                  value: _end,
                  onChanged: (v) => setState(() => _end = v),
                ),
              ),
            ],
          ),
          if (invalid) ...[
            const SizedBox(height: 10),
            const Text(
              'وقت النهاية لازم يكون بعد وقت البداية',
              style: TextStyle(color: Color(0xFFB3261E), fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'يتكرر كل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            initialValue: _interval,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final n in _intervalOptions)
                DropdownMenuItem(
                  value: n,
                  child: Text(n == 1 ? 'كل ساعة' : 'كل $n ساعات'),
                ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _interval = v);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: invalid
              ? null
              : () => Navigator.of(context).pop((_start, _end, _interval)),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(),
          ),
          items: [
            for (var h = 0; h < 24; h++)
              DropdownMenuItem(
                value: h,
                child: Text(_HourlyDhikrSection._hour12Label(h)),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
