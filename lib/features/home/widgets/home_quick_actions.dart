import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../prayer/qibla_screen.dart';
import '../../shell/root_shell.dart';

/// صف أدوات الوصول السريع الموحّد لنمط تطبيق «منار» (القبلة، المساجد، الأذكار، المزيد)
/// تصميم أزرار مربعة مستديرة بخلفية عاجية هادئة وإطار دافئ وأيقونات برونزية.
class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _QuickActionItem(
        icon: Icons.explore_outlined,
        title: 'القبلة',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QiblaScreen()),
        ),
      ),
      _QuickActionItem(
        icon: Icons.mosque_outlined,
        title: 'المساجد',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QiblaScreen()),
        ),
      ),
      _QuickActionItem(
        icon: Icons.wb_sunny_outlined,
        title: 'الأذكار',
        onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      _QuickActionItem(
        icon: Icons.grid_view_rounded,
        title: 'المزيد',
        onTap: () => ref.read(rootTabIndexProvider.notifier).select(4),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) {
          return Expanded(
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2630) : const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E3A4A) : const Color(0xFFEADBCA),
                          width: 1.2,
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: const Color(0xFF8C6B45).withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        size: 28,
                        color: isDark ? const Color(0xFFD4AF67) : const Color(0xFF8C6B45),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF5A4833),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}
