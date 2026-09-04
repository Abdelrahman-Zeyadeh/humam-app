import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/dashboard_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_providers.dart';
import '../../core/data/user/user_repository.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';

/// درجة إنجاز واحدة — من الأدنى للأعلى. أول درجة تُبلَّغ ("لم تبدأ بعد")
/// ليست ضمن هذه القائمة، تُعامَل بشكل منفصل بـ[_TierInfo.forDays].
class _Tier {
  const _Tier(this.minDays, this.label);
  final int minDays;
  final String label;
}

const List<_Tier> _kTiers = [
  _Tier(3, 'بداية قوية'),
  _Tier(7, 'أسبوع كامل'),
  _Tier(30, 'شهر كامل'),
  _Tier(100, 'مئة يوم'),
  _Tier(365, 'سنة كاملة'),
];

class _TierInfo {
  const _TierInfo({
    required this.currentLabel,
    required this.currentIndex,
    required this.nextThreshold,
  });

  /// اسم أعلى درجة وُصلت إليها فعلاً — null لو لسا ما بدأ.
  final String? currentLabel;

  /// فهرس الدرجة الحالية بـ[_kTiers] (-1 لو ما بدأ بعد).
  final int currentIndex;

  /// عتبة الدرجة القادمة — null لو وصل لأعلى درجة أصلاً.
  final int? nextThreshold;

  static _TierInfo forDays(int days) {
    var idx = -1;
    for (var i = 0; i < _kTiers.length; i++) {
      if (days >= _kTiers[i].minDays) idx = i;
    }
    final next = idx + 1 < _kTiers.length ? _kTiers[idx + 1].minDays : null;
    return _TierInfo(
      currentLabel: idx == -1 ? null : _kTiers[idx].label,
      currentIndex: idx,
      nextThreshold: next,
    );
  }
}

/// يحل مفتاح [DashboardStreakItem] (بعض المفاتيح مجازية مثل `prayers_fard`
/// لا عمود مباشر بـ[UserCategories]) لعدد الأيام الفعلي — نفس تعيين
/// `_StreaksRow` بـ`home_screen.dart` حرفياً، كُرِّر هون بدل استيراده لأن
/// ذاك خاص بودجت الداشبورد لا حالة عامة قابلة لإعادة الاستخدام.
int _streakDaysForKey(UserPrefs prefs, String key) {
  switch (key) {
    case 'prayers_fard':
      return prefs.streakDaysFor(UserCategories.fajr);
    case 'daily_quran':
      return prefs.streakDays;
    case 'prayers_rawatib':
      return prefs.streakDaysFor(UserCategories.rawatib);
    default:
      return prefs.streakDaysFor(key);
  }
}

/// شاشة الإنجازات والأوسمة — تجميع بصري لكل سلاسل الاستمرار المستقلة
/// الموجودة أصلاً بالتطبيق (`CategoryStreaks`) + معالم الختمة/الحفظ، بلا
/// أي جدول قاعدة بيانات جديد. الهدف تحفيزي بحت: رؤية كل التزاماتك
/// بمكان واحد بدل مبعثرة بين شاشات الختمة/الحفظ/الأذكار.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoryStreakVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final repo = ref.watch(userRepositoryProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completedKhatmas = repo.khatmaPlans
        .where((p) => p.progress >= 1.0)
        .length;
    final completedHifzPlans = repo.hifzPlans
        .where((p) => p.progress >= 1.0)
        .length;
    final bestStreak = repo.bestCurrentStreakDays();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const GradientAppBar(
          title: 'الإنجازات والأوسمة',
          centerTitle: true,
          colors: [AppColors.blue, AppColors.navy],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // شريط المعالم العامة الثلاثة
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFC0392B),
                    value: '$bestStreak',
                    label: 'أقوى سلسلة نشطة',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.bookmark_rounded,
                    color: const Color(0xFF386892),
                    value: '$completedKhatmas',
                    label: 'ختمات مكتملة',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.sticky_note_2_rounded,
                    color: const Color(0xFF685197),
                    value: '$completedHifzPlans',
                    label: 'خطط حفظ مكتملة',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'أوسمة الاستمرارية',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'كل نشاط له سلسلته الخاصة — استمر فيها لترتقي بدرجتها',
              style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kAvailableDashboardStreaks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, i) {
                final item = kAvailableDashboardStreaks[i];
                final days = _streakDaysForKey(userPrefs, item.key);
                return _BadgeCard(item: item, days: days, isDark: isDark);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.item, required this.days, required this.isDark});

  final DashboardStreakItem item;
  final int days;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final tier = _TierInfo.forDays(days);
    final achieved = tier.currentIndex >= 0;
    final color = achieved ? item.defaultColor : onSurface.withValues(alpha: 0.35);
    final progress = tier.nextThreshold == null
        ? 1.0
        : (days / tier.nextThreshold!).clamp(0.0, 1.0);

    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: achieved ? color.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: item.icon, color: color, tintAlpha: achieved ? 0.15 : 0.08),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            achieved ? tier.currentLabel! : 'لم تبدأ بعد',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            tier.nextThreshold == null
                ? '$days يوماً — أعلى درجة! 🏆'
                : '$days / ${tier.nextThreshold} يوماً',
            style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
