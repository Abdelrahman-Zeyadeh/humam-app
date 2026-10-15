import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/location_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../prayer/prayer_times_service.dart'
    show PrayerMoment, hasMomentArrivedToday;
import 'azkar_dhikr_frame.dart';
import 'azkar_progress.dart';
import 'azkar_repository.dart';
import 'streak_status_row.dart';

Color _cardBorder(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.lineDark
    : AppColors.line;

/// شاشة أذكار الصباح والمساء بتصميم هادئ ومريح مع دعم وضع التركيز وزر "تمّ" السريع.
class AzkarScreen extends ConsumerWidget {
  const AzkarScreen({super.key, required this.period});
  final AzkarPeriod period;

  String get _title =>
      period == AzkarPeriod.morning ? 'أذكار الصباح' : 'أذكار المساء';
  String get _category => period == AzkarPeriod.morning
      ? UserCategories.morningAzkar
      : UserCategories.eveningAzkar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPrefs = ref.watch(userPrefsProvider);
    final category = _category;

    // متابعة إتمام أذكار الفترة لتسجيل السلسلة اليومية
    ref.listen(azkarProgressProvider, (prev, next) {
      final list = ref.read(azkarListProvider).value;
      if (list == null) return;
      final relevant = list.where((d) => d.appliesTo(period));
      if (relevant.isEmpty) return;
      final allDone = relevant.every(
        (d) => (next[(period, d.order)] ?? d.count) <= 0,
      );
      if (allDone) {
        userPrefs.bumpCategoryStreakIfNewDay(category).then((_) {
          ref.read(categoryStreakVersionProvider.notifier).bump();
        });
      }
    });

    final azkarAsync = ref.watch(azkarListProvider);

    return Scaffold(
      body: azkarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذّر تحميل الأذكار: $e')),
        data: (all) {
          final list = all.where((d) => d.appliesTo(period)).toList();

          return Column(
            children: [
              _AzkarHeader(
                title: _title,
                period: period,
                azkarList: list,
              ),
              StreakStatusRow(category: category),
              _ProgressSummaryCard(period: period),
              Expanded(child: _PeriodAzkarList(period: period)),
            ],
          );
        },
      ),
    );
  }
}

/// هيدر موحَّد بتدرّج زمردي فاخر مع وصول مباشر لوضع التركيز وإعادة الضبط
class _AzkarHeader extends ConsumerWidget {
  const _AzkarHeader({
    required this.title,
    required this.period,
    required this.azkarList,
  });

  final String title;
  final AzkarPeriod period;
  final List<Dhikr> azkarList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 14,
          16,
          18,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF135B4C), Color(0xFF0D3B31)],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // زر إتمام جميع أذكار الفترة دفعة واحدة
            IconButton(
              tooltip: 'إتمام الكل',
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              onPressed: () {
                final orders = azkarList.map((d) => d.order).toList();
                ref.read(azkarProgressProvider.notifier).completePeriod(period, orders);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تسجيل إتمام جميع أذكار هذه الفترة ✓'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),

            // زر إعادة الضبط
            InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () {
                ref.read(azkarProgressProvider.notifier).resetPeriod(period);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إعادة ضبط عداد الأذكار')),
                );
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.refresh, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة ملخّص التقدّم أعلى القائمة — حلقة دائرية + "أتممت X من Y أذكار"،
/// مطابقة لبطاقة "progress summary" بلوحة التصميم المعتمدة.
class _ProgressSummaryCard extends ConsumerWidget {
  const _ProgressSummaryCard({required this.period});
  final AzkarPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final azkarAsync = ref.watch(azkarListProvider);
    final progress = ref.watch(azkarProgressProvider);

    return azkarAsync.maybeWhen(
      data: (all) {
        final list = all.where((d) => d.appliesTo(period)).toList();
        if (list.isEmpty) return const SizedBox.shrink();
        final total = list.length;
        final done = list
            .where((d) => (progress[(period, d.order)] ?? d.count) <= 0)
            .length;
        final ratio = total > 0 ? done / total : 0.0;

        return AppCard(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 4.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.gold.withValues(alpha: 0.16),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.goldDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.first.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _textStrong(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'أتممت $done من $total أذكار هذه الفترة',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: _textSoft(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

Color _textStrong(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkOnDark
    : const Color(0xFF135B4C);
Color _textSoft(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkSoftOnDark
    : AppColors.inkSoft;

class _SunnahGuidanceBanner extends StatefulWidget {
  const _SunnahGuidanceBanner();

  @override
  State<_SunnahGuidanceBanner> createState() => _SunnahGuidanceBannerState();
}

class _SunnahGuidanceBannerState extends State<_SunnahGuidanceBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF132F27).withValues(alpha: 0.85)
        : const Color(0xFFF0F9F5);
    final border = isDark
        ? const Color(0xFF1E5B4B)
        : const Color(0xFFBCE3D7);
    final titleColor = isDark
        ? const Color(0xFF6EE7B7)
        : const Color(0xFF0F5132);
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF1B4332);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.spa_outlined, size: 20, color: titleColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تيسير ورخصة من السنّة النبوية',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                      color: titleColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _expanded
                      ? 'هذه الأذكار المباركة صحّت عن رسول الله ﷺ في أحوال وأوقات متفرقة، ولم يكن يجمعها كلها في كل يوم تيسيراً ورحمةً بأمته؛ فبإمكانك أن تقرأ ما تيسّر لك منها بيقين وحضور قلب دون مشقة أو حرج، وإن قرأتها كاملة فذلك خير عظيم وأجر مضاعف بإذن الله.'
                      : 'اقرأ ما تيسّر لك بيقين؛ فقد نوّع النبي ﷺ أذكاره رحمةً وتيسيراً بأمته...',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: textColor,
                  ),
                ),
                if (!_expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'اضغط للتفصيل',
                      style: TextStyle(
                        fontSize: 11,
                        color: titleColor.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodAzkarList extends ConsumerWidget {
  const _PeriodAzkarList({required this.period});
  final AzkarPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final azkarAsync = ref.watch(azkarListProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final loc = ref.watch(locationPrefsProvider);
    // بطلب صاحب المشروع: "اذكار المسا عليها قفل... مش الصبح" — الصباح
    // يُفتح بدخول وقت الفجر، المساء بدخول وقت العصر (بداية "المساء"
    // تقليدياً بجدول أوقات المسلمين، لا الغروب). راجع `hasMomentArrivedToday`.
    final locked = !hasMomentArrivedToday(
      lat: loc.lat,
      lon: loc.lon,
      methodKey: loc.calculationMethod,
      moment: period == AzkarPeriod.morning
          ? PrayerMoment.fajr
          : PrayerMoment.asr,
    );

    return azkarAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('تعذّر تحميل الأذكار')),
      data: (all) {
        final list = all.where((d) => d.appliesTo(period)).toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return const _SunnahGuidanceBanner();
            }
            return _DhikrCard(
              dhikr: list[i - 1],
              period: period,
              onSurface: onSurface,
              locked: locked,
            );
          },
        );
      },
    );
  }
}

class _DhikrCard extends ConsumerWidget {
  const _DhikrCard({
    required this.dhikr,
    required this.period,
    required this.onSurface,
    this.locked = false,
  });
  final Dhikr dhikr;
  final AzkarPeriod period;
  final Color onSurface;

  /// `true` = لسا ما جا وقت هذه الفترة (صباح/مساء) — بطلب صاحب المشروع
  /// "اذكار المسا عليها قفل ما بقدر احط تم غير ليجي وقتها". يمنع الضغط،
  /// لا يخفي المحتوى (يبقى المستخدم يقرأ الذكر، فقط لا يُعدّ "منجَز").
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(
      azkarProgressProvider.select(
        (m) => m[(period, dhikr.order)] ?? dhikr.count,
      ),
    );
    final done = remaining <= 0;
    final notStarted = remaining == dhikr.count;

    final String countLabel = dhikr.count <= 1
        ? 'مرة واحدة'
        : notStarted
        ? '${dhikr.count} مرات'
        : '$remaining من ${dhikr.count} مرة';

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      onTap: locked && !done
          ? null
          : () => ref
                .read(azkarProgressProvider.notifier)
                .tap(period, dhikr.order, dhikr.count),
      child: Opacity(
        opacity: locked && !done ? 0.55 : (notStarted ? 0.9 : 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // نص الذكر بإطار داخلي أنيق ومحاذاة وسط — بطلب صاحب
            // المشروع "النص مكانه بالنص وبطاقات الأذكار تكون باطار
            // جميل وأنيق".
            DhikrTextFrame(text: dhikr.content, done: done),
            if (dhikr.fadl != null) ...[
              const SizedBox(height: 8),
              Text(
                dhikr.fadl!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.55),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    locked && !done ? 'لسا ما جا وقت هذه الفترة' : countLabel,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.5),
                      fontSize: 10.5,
                    ),
                  ),
                ),
                if (locked && !done)
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: onSurface.withValues(alpha: 0.4),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!done) ...[
                        InkWell(
                          onTap: () => ref
                              .read(azkarProgressProvider.notifier)
                              .complete(period, dhikr.order),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.35),
                                width: 0.9,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.done_all_rounded,
                                  size: 14,
                                  color: AppColors.teal,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'تمّ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _CountBadge(
                        done: done,
                        remaining: remaining,
                        total: dhikr.count,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة حالة الذكر — ثلاث حالات مطابقة للوحة التصميم المعتمدة: دائرة
/// خضراء بعلامة صح (اكتمل)، حلقة تقدّم ملوّنة بالمتبقّي بمركزها (جارٍ)،
/// أو دائرة بحدّ فارغة (لم يبدأ بعد).
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.done,
    required this.remaining,
    required this.total,
  });
  final bool done;
  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.teal,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check, size: 15, color: Colors.white),
      );
    }

    final notStarted = remaining == total;
    if (notStarted) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _cardBorder(context).withValues(alpha: 0.9),
            width: 1.6,
          ),
        ),
      );
    }

    final color = themeAccent(context);
    final progress = total > 0
        ? ((total - remaining) / total).clamp(0.0, 1.0)
        : 0.0;
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3.5,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '$remaining',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
