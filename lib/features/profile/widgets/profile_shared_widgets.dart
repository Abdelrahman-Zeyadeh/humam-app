import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// عنوان قسم مصغّر (شريط لوني + نص) يُستخدم في أعلى كل قسم بشاشة الملف
/// الشخصي والإحصائيات.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: themeAccent(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// بطاقة إحصائية صغيرة (قيمة + عنوان + أيقونة) تُستخدم بقسمي "إحصائيات
/// اليوم" و"الإجمالي الكلي".
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final accent = themeAccent(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// قيمة رقمية مع تسمية أسفلها، تُستخدم بصف مقاييس الانتظام اليومي.
class StreakMetric extends StatelessWidget {
  const StreakMetric({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE67E22),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// صف تقدّم نحو هدف (نسبة + شريط تقدّم)، يُستخدم بقسم "تحليل التقدم".
class ProgressGoalRow extends StatelessWidget {
  const ProgressGoalRow({
    super.key,
    required this.label,
    required this.current,
    required this.total,
    required this.icon,
  });

  final String label;
  final int current;
  final int total;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percent = (current / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current/$total',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: themeAccent(context)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(themeAccent(context)),
          ),
        ),
      ],
    );
  }
}

/// شارة إنجاز مفردة (أيقونة دائرية + تسمية) بشبكة "شارات الإنجاز".
class BadgeItem extends StatelessWidget {
  const BadgeItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isUnlocked,
  });

  final IconData icon;
  final String label;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? themeAccent(context).withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            border: Border.all(
              color: isUnlocked
                  ? themeAccent(context)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: isUnlocked
                ? themeAccent(context)
                : Colors.grey.withValues(alpha: 0.4),
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
            color: isUnlocked ? onSurface : onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
