import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/dashboard_prefs.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';

/// نافذة سفلية متطورة لتخصيص بطاقات وسلاسل الواجهة الرئيسية
class DashboardCustomizeSheet extends ConsumerStatefulWidget {
  const DashboardCustomizeSheet({super.key});

  @override
  ConsumerState<DashboardCustomizeSheet> createState() => _DashboardCustomizeSheetState();
}

class _DashboardCustomizeSheetState extends ConsumerState<DashboardCustomizeSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeStreaks = ref.watch(dashboardCustomPrefsProvider);
    final activeCards = ref.watch(dashboardCardsPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // مؤشر السحب
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // العنوان وزر الاستعادة
            Row(
              children: [
                Icon(Icons.dashboard_customize_outlined, color: themeAccent(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تخصيص الواجهة الرئيسية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(dashboardCustomPrefsProvider.notifier).resetToDefaults();
                    ref.read(dashboardCardsPrefsProvider.notifier).resetToDefaults();
                  },
                  child: const Text('استعادة الافتراضي', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // تبويبات التخصيص
            Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? const Color(0xFF1E2836) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: themeAccent(context),
                unselectedLabelColor: onSurface.withValues(alpha: 0.6),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'البطاقات الرئيسية'),
                  Tab(text: 'سلاسل الاستمرار'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // محتوى التبويبات
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. تبويب البطاقات الرئيسية
                  ListView.separated(
                    itemCount: kAvailableDashboardCards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final card = kAvailableDashboardCards[index];
                      final isEnabled = activeCards.contains(card.key);

                      return SwitchListTile.adaptive(
                        value: isEnabled,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                        activeThumbColor: themeAccent(context),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeAccent(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(card.icon, color: themeAccent(context), size: 20),
                        ),
                        title: Text(
                          card.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: onSurface,
                          ),
                        ),
                        subtitle: Text(
                          card.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        onChanged: (_) =>
                            ref.read(dashboardCardsPrefsProvider.notifier).toggle(card.key),
                      );
                    },
                  ),

                  // 2. تبويب سلاسل الاستمرار
                  ListView.separated(
                    itemCount: kAvailableDashboardStreaks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final streak = kAvailableDashboardStreaks[index];
                      final isEnabled = activeStreaks.contains(streak.key);

                      return SwitchListTile.adaptive(
                        value: isEnabled,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                        activeThumbColor: streak.defaultColor,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: streak.defaultColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(streak.icon, color: streak.defaultColor, size: 20),
                        ),
                        title: Text(
                          streak.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: onSurface,
                          ),
                        ),
                        subtitle: Text(
                          streak.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        onChanged: (_) =>
                            ref.read(dashboardCustomPrefsProvider.notifier).toggle(streak.key),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // زر الحفظ
            AppPrimaryButton(
              label: 'حفظ التفضيلات',
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
