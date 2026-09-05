import 'package:flutter/material.dart';

/// خيارات "كل كم" لأي تذكير — بطلب صاحب المشروع "اضافة الوقت للتكرار
/// ربع ساعة نصف ساعة ساعة... وبقدر اضيف التكرارات على كل التذكيرات مثلا
/// الصلاة على النبي وغيرها". `null` = مرة واحدة (بلا تكرار، السلوك
/// القديم).
const kRepeatIntervalOptions = <int?>[null, 15, 30, 60, 120, 180, 240, 360];

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
        for (final option in kRepeatIntervalOptions)
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
/// تفعيله)، بنفس أسلوب صفوف "الساعة" الفرعية بقسم السنن.
class RepeatIntervalTile extends StatelessWidget {
  const RepeatIntervalTile({super.key, required this.minutes, required this.onTap});
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
