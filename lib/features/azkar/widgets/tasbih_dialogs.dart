import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/tasbih_prefs.dart';
import '../../../core/theme/app_card.dart';

/// حوارا شاشة المسبحة (تصفير الدورة/الكل، وإضافة ذكر خاص) — استُخرجا من
/// `tasbih_screen.dart` أثناء تفكيكه بلا أي تغيير سلوكي. الحالة (العدّ،
/// الدورات، الذكر المختار...) تبقى مُدارة بالشاشة الأمّ وتُحدَّث عبر دوال
/// رد نداء تمرَّر هون.

/// حوار "إعادة ضبط المسبحة" — يخيّر بين تصفير الدورة الحالية فقط أو
/// تصفير الإجمالي بالكامل.
void showTasbihResetDialog(
  BuildContext context, {
  required VoidCallback onResetCycle,
  required VoidCallback onResetAll,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'إعادة ضبط المسبحة',
        textAlign: TextAlign.right,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      content: const Text(
        'هل ترغب في تصفير عداد الدورة الحالية أم تصفير الإجمالي بالكامل؟',
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 14),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onResetCycle();
          },
          child: const Text('تصفير الدورة'),
        ),
        AppPrimaryButton(
          label: 'تصفير الكل',
          color: Theme.of(context).colorScheme.error,
          onPressed: () {
            Navigator.of(ctx).pop();
            onResetAll();
          },
        ),
      ],
    ),
  );
}

/// حوار "إضافة ذكر خاص" — يضيف صيغة/هدفاً مخصَّصين إلى قائمة التفضيلات
/// (`tasbihPrefsProvider`) ثم يطبّقهما فوراً عبر [onApply].
Future<void> showAddCustomDhikrDialog(
  BuildContext context,
  WidgetRef ref, {
  required void Function(String phrase, int goal) onApply,
}) async {
  final phraseCtrl = TextEditingController();
  final goalCtrl = TextEditingController(text: '100');

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'إضافة ذكر خاص ➕',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: phraseCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'صيغة الذكر (مثلاً: أستغفر الله العظيم)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: goalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'العدد المستهدف (مثلاً: 100 أو 33)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        AppPrimaryButton(
          label: 'إضافة والبدء',
          onPressed: () async {
            final phrase = phraseCtrl.text.trim();
            final goal = int.tryParse(goalCtrl.text.trim()) ?? 100;
            if (phrase.isNotEmpty) {
              final prefs = ref.read(tasbihPrefsProvider);
              await prefs.addCustomPhrase(phrase);
              onApply(phrase, goal);
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
        ),
      ],
    ),
  );
}
