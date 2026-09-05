import 'package:flutter/material.dart';

/// عنوان قسم رئيسي بشاشة الإعدادات (فوق البطاقة مباشرة) — مستخدَم عبر كل
/// أقسام `settings_screen.dart` الأربعة، فبقي بملف مشترك بدل تكراره.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.label, {super.key});
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

/// عنوان فرعي صغير جوّا بطاقة قسم — مستخدَم بأكثر من قسم (المظهر، إلخ).
class SubHeader extends StatelessWidget {
  const SubHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
