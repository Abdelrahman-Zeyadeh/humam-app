import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/dashboard_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_repository.dart' show UserCategories;
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../habits/custom_habits_screen.dart';
import '../../hifz/hifz_screen.dart';
import '../../prayer/prayer_screen.dart' show PrayerChecklistScreen;
import '../../qiyam/qiyam_screen.dart';
import '../../shell/root_shell.dart';
import '../home_style_helpers.dart';

/// شبكة "سلاسل الاستمرار" (عدد الأيام المتتالية لكل عادة مفعَّلة بتخصيص
/// الداشبورد) — استُخرجت من `home_screen.dart` أثناء تفكيك الملف بلا أي
/// تغيير سلوكي.
class StreaksRow extends ConsumerWidget {
  const StreaksRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final activeKeys = ref.watch(dashboardCustomPrefsProvider);

    final allItems = [
      (
        key: 'prayers_fard',
        icon: Icons.mosque_outlined,
        label: 'الصلوات\nالمكتوبة',
        days: userPrefs.streakDaysFor(UserCategories.fajr),
        color: AppColors.navy,
        action: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrayerChecklistScreen()),
        ),
      ),
      (
        key: UserCategories.morningAzkar,
        icon: Icons.wb_sunny_outlined,
        label: 'أذكار\nالصباح',
        days: userPrefs.streakDaysFor(UserCategories.morningAzkar),
        color: AppColors.gold,
        action: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      (
        key: UserCategories.eveningAzkar,
        icon: Icons.wb_twilight,
        label: 'أذكار\nالمساء',
        days: userPrefs.streakDaysFor(UserCategories.eveningAzkar),
        color: AppColors.teal,
        action: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      (
        key: 'daily_quran',
        icon: Icons.menu_book_outlined,
        label: 'الورد\nاليومي',
        days: userPrefs.streakDays,
        color: AppColors.blue,
        action: () => ref.read(rootTabIndexProvider.notifier).select(1),
      ),
      (
        key: UserCategories.hifz,
        icon: Icons.school_outlined,
        label: 'الحفظ',
        days: userPrefs.streakDaysFor(UserCategories.hifz),
        // نفس لون أيقونة "الحفظ والمراجعة" بـhome_goals_group.dart — لا
        // لون عشوائي جديد.
        color: AppColors.purple,
        action: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HifzScreen())),
      ),
      (
        key: UserCategories.nightAzkar,
        icon: Icons.bedtime_outlined,
        label: 'أذكار\nالنوم',
        days: userPrefs.streakDaysFor(UserCategories.nightAzkar),
        color: AppColors.navyDeep,
        action: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      (
        key: UserCategories.qiyam,
        icon: Icons.dark_mode_outlined,
        label: 'قيام\nالليل',
        days: userPrefs.streakDaysFor(UserCategories.qiyam),
        // نفس لون بطاقة قيام الليل بـhome_prayer_leading_cards.dart — لا
        // لون عشوائي جديد.
        color: AppColors.navy,
        action: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const QiyamScreen())),
      ),
      (
        key: 'prayers_rawatib',
        icon: Icons.auto_awesome_outlined,
        label: 'السنن\nالرواتب',
        days: userPrefs.streakDaysFor(UserCategories.rawatib),
        color: AppColors.blue,
        action: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrayerChecklistScreen()),
        ),
      ),
      (
        key: 'tasbih',
        icon: Icons.fingerprint,
        label: 'التسبيح\nوالذكر',
        days: userPrefs.streakDaysFor('tasbih'),
        // نفس لون بطاقة الظهيرة (المسبحة) بـhome_prayer_leading_cards.dart
        // — لا لون عشوائي جديد.
        color: AppColors.gold,
        action: () => ref.read(rootTabIndexProvider.notifier).select(3),
      ),
      (
        key: UserCategories.customHabitsAny,
        icon: Icons.checklist_rtl_outlined,
        label: 'عاداتي',
        days: userPrefs.streakDaysFor(UserCategories.customHabitsAny),
        color: AppColors.purple,
        action: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CustomHabitsScreen())),
      ),
    ];

    final filtered = allItems
        .where((it) => activeKeys.contains(it.key))
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(
          icon: Icons.local_fire_department_outlined,
          label: 'سلاسل الاستمرار',
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: [
            for (final item in filtered)
              _StreakChip(
                icon: item.icon,
                label: item.label,
                days: item.days,
                color: item.color,
                iconColor: switch (item.color) {
                  AppColors.gold => AppColors.goldDeep,
                  AppColors.teal => AppColors.tealDeep,
                  final c => c,
                },
                onTap: item.action,
              ),
          ],
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({
    required this.icon,
    required this.label,
    required this.days,
    required this.color,
    required this.onTap,
    Color? iconColor,
  }) : iconColor = iconColor ?? color;

  final IconData icon;
  final String label;
  final int days;
  final Color color;
  // خلفية الدائرة تبقى بلون [color] بشفافية خفيفة (زخرفة). الأيقونة نفسها
  // تحتاج ٣:١ على الأقل فوق البطاقة البيضاء — [iconColor] يسمح بدرجة أغمق
  // (goldDeep) عند الحاجة بدل [color] مباشرة.
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      onTap: onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(height: 5),
            Text(
              '$days',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: homeTextStrong(context),
              ),
            ),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: homeTextSoft(context),
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
