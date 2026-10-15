import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/user_repository.dart' show KhatmaPlan, HifzPlan, UserCategories;
import '../../../core/data/user/khatma_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../hifz/hifz_screen.dart';
import '../../mushaf/mushaf_screen.dart' show MushafScreen;
import '../../shell/root_shell.dart';
import '../home_style_helpers.dart';

/// ورد اليوم لخطة ختمة — إعادة حساب **حيّة** حسب التقدّم الفعلي الحالي
/// (لا الوتيرة الأصلية الثابتة `plan.dailyPages` المحسوبة عند بدء الخطة
/// فقط): الصفحات المتبقّية ÷ الأيام المتبقّية من مدّة الخطة الأصلية. لو
/// انتهت المدّة الأصلية ولم تكتمل الختمة بعد، "حساب جديد تلقائياً" — نرجع
/// لنفس وتيرة الخطة الأصلية بدل قسمة كل الصفحات المتبقّية على يوم واحد
/// (رقم غير معقول بصفحة واحدة قد يعني ٢٠٠+ صفحة). استُخرجت من
/// `home_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
int wirdPagesForToday(KhatmaPlan plan) {
  final pagesRemaining = 604 - plan.currentPage;
  if (pagesRemaining <= 0) return 0;

  // **لا** نستخدم `plan.daysElapsed` هون — مُقيَّد عمداً بحد أقصى
  // `targetDays` (لعرض "الصفحة المتوقَّعة اليوم" بمكان آخر)، فـ"الأيام
  // المتبقّية" المحسوبة منه لا تقل عن ١ أبداً حتى لو تجاوزت الخطة مدّتها
  // الأصلية فعلياً بأسابيع — يمنع اكتشاف "انتهت المدّة" كلياً. نحسب هون
  // عدد الأيام الحقيقي المنقضي (بلا تقييد) للكشف الصحيح عن انتهاء المدّة.
  final rawDaysElapsed = DateTime.now().difference(plan.startDate).inDays + 1;
  final expired = rawDaysElapsed > plan.targetDays;
  if (expired) {
    // "حساب جديد تلقائياً" — وتيرة الخطة الأصلية بدل قسمة كل الصفحات
    // المتبقّية على يوم واحد فقط (رقم غير معقول).
    return plan.dailyPages.clamp(1, pagesRemaining);
  }

  final daysRemaining = plan.targetDays - rawDaysElapsed + 1;
  return (pagesRemaining / daysRemaining).ceil().clamp(1, pagesRemaining);
}

/// بطاقة "أهدافي اليوم" المجمَّعة — تحل محل ٣ بطاقات منفصلة (ختمة/حفظ/
/// متابعة قراءة) كانت متطابقة الشكل تقريباً (نفس الحد/الظل/الاستدارة)
/// ومتكدّسة تباعاً، بشكوى صريحة "سيل بطاقات متطابقة". كل صف يستخدم حلقة
/// تقدّم دائرية (`CircularProgressIndicator`) بدل الشريط المسطّح — نفس
/// تدرّج اللون الدلالي الأصلي (أزرق للختمة، بنفسجي للحفظ) بلا تغيير.
/// استُخرجت من `home_screen.dart` أثناء تفكيك الملف بلا أي تغيير سلوكي.
class GoalsGroupCard extends ConsumerWidget {
  const GoalsGroupCard({
    super.key,
    this.khatmaPlan,
    this.hifzPlan,
    this.continueReadingSurah,
  });

  final KhatmaPlan? khatmaPlan;
  final HifzPlan? hifzPlan;
  final String? continueReadingSurah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <Widget>[
      if (khatmaPlan != null) _KhatmaGoalRow(plan: khatmaPlan!),
      if (hifzPlan != null) _HifzGoalRow(plan: hifzPlan!),
      if (continueReadingSurah != null)
        _ContinueReadingGoalRow(
          surahName: continueReadingSurah!,
          onTap: () => ref.read(rootTabIndexProvider.notifier).select(1),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            icon: Icons.auto_awesome_outlined,
            label: 'أهدافي اليوم',
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: homeCardBorder(context)),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalDonut extends StatelessWidget {
  const _GoalDonut({
    required this.size,
    required this.progress,
    required this.color,
    this.fontSize = 11,
  });
  final double size;
  final double progress;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: size >= 50 ? 6 : 5,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '${(progress * 100).round()}٪',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _KhatmaGoalRow extends ConsumerWidget {
  const _KhatmaGoalRow({required this.plan});
  final KhatmaPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = (plan.expectedPageByNow / 604).clamp(0.0, 1.0);
    final wirdPages = wirdPagesForToday(plan);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          _GoalDonut(size: 52, progress: progress, color: AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ختمة القرآن',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: homeTextStrong(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wirdPages > 0
                      ? 'ورد اليوم: $wirdPages صفحة'
                      : 'أتممت وردك بالكامل اليوم ✨',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: homeTextSoft(context)),
                ),
              ],
            ),
          ),
          if (wirdPages > 0) ...[
            const SizedBox(width: 6),
            // زر "تمّ" السريع — للمستخدم الذي قرأ ورده خارج التطبيق
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: AppColors.blue, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final newPage = (plan.currentPage + wirdPages).clamp(1, 604);
                await ref.read(khatmaPrefsProvider).updateCurrentPage(plan.id, newPage);
                await ref.read(userPrefsProvider).bumpCategoryStreakIfNewDay(UserCategories.dailyWird);
                ref.read(categoryStreakVersionProvider.notifier).bump();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('مبارك! تمّ تسجيل ورد اليوم حتى صفحة $newPage 📖✨'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('تمّ ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blue)),
            ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MushafScreen(
                    initialPage: plan.currentPage,
                    khatmaPracticeMode: true,
                    khatmaPlanId: plan.id,
                    wirdTargetPage: (plan.currentPage + wirdPages - 1).clamp(1, 604),
                  ),
                ),
              ),
              child: const Text('ابدأ وردي', style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ],
      ),
    );
  }
}

class _HifzGoalRow extends ConsumerWidget {
  const _HifzGoalRow({required this.plan});
  final HifzPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          _GoalDonut(
            size: 44,
            progress: plan.progress,
            color: AppColors.purple,
            fontSize: 9.5,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HifzScreen())),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الحفظ والمراجعة',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: homeTextStrong(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(plan.progress * 100).round()}٪ من الخطة الحالية',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: homeTextSoft(context)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // زر "تمّ" السريع للحفظ — إذا راجع ورده خارج التطبيق
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppColors.purple, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await ref.read(userPrefsProvider).bumpCategoryStreakIfNewDay(UserCategories.hifz);
              ref.read(categoryStreakVersionProvider.notifier).bump();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('بارك الله فيك! تمّ تسجيل ورد الحفظ والمراجعة لليوم 🧠✨'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('تمّ ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.purple)),
          ),
          Icon(Icons.chevron_left, color: homeTextSoft(context), size: 18),
        ],
      ),
    );
  }
}

class _ContinueReadingGoalRow extends StatelessWidget {
  const _ContinueReadingGoalRow({required this.surahName, required this.onTap});
  final String surahName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: homeCardBorder(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.menu_book_outlined,
                color: homeTextStrong(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متابعة القراءة',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: homeTextStrong(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'آخر قراءة: $surahName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: homeTextSoft(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: homeTextSoft(context), size: 18),
          ],
        ),
      ),
    );
  }
}
