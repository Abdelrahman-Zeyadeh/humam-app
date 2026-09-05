import 'package:flutter/material.dart';

/// عنوان قسم رئيسي بشاشة "التذكيرات" — نفس نمط `SectionTitle` بشاشة
/// الإعدادات، بس محلي هون تفادياً لتبعية بين المجلدين.
class ReminderSectionTitle extends StatelessWidget {
  const ReminderSectionTitle(this.label, {super.key});
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
