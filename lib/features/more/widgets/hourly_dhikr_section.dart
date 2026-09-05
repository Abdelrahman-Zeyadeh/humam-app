import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_service.dart';

class HourlyDhikrSection extends ConsumerWidget {
  const HourlyDhikrSection({super.key});

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
                child: Text(HourlyDhikrSection._hour12Label(h)),
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
