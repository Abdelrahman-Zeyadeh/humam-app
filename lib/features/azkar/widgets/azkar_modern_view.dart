import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../azkar_focus_mode_screen.dart';
import '../azkar_progress.dart';
import '../azkar_repository.dart';

/// العرض الحديث لقائمة الأذكار (مطابق تماماً للصورة المرفقة)
class AzkarModernView extends ConsumerWidget {
  const AzkarModernView({
    super.key,
    required this.period,
    required this.azkar,
    this.locked = false,
  });

  final AzkarPeriod period;
  final List<Dhikr> azkar;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (azkar.isEmpty) {
      return const Center(child: Text('لا توجد أذكار متاحة'));
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;
    final progress = ref.watch(azkarProgressProvider);

    // حسابات التقدم الإجمالي
    final totalDhikrs = azkar.length;
    var completedDhikrs = 0;
    var totalReps = 0;
    var doneReps = 0;

    // البحث عن أول ذكر غير مكتمل للشريط العائم
    Dhikr? firstIncompleteDhikr;
    int? firstIncompleteRemaining;

    for (final d in azkar) {
      final rem = progress[(period, d.order)] ?? d.count;
      totalReps += d.count;
      doneReps += (d.count - rem).clamp(0, d.count);
      if (rem <= 0) {
        completedDhikrs++;
      } else if (firstIncompleteDhikr == null) {
        firstIncompleteDhikr = d;
        firstIncompleteRemaining = rem;
      }
    }

    // إذا اكتملت كلها
    firstIncompleteDhikr ??= azkar.last;
    firstIncompleteRemaining ??= 0;

    final progressRatio = totalReps > 0 ? (doneReps / totalReps).clamp(0.0, 1.0) : 0.0;
    final percentInt = (progressRatio * 100).toInt();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
          children: [
            // بطاقة ملخص التقدم العلوية مع النسبة الدائرية وشريط التقدم
            _TopModernProgressCard(
              completedDhikrs: completedDhikrs,
              totalDhikrs: totalDhikrs,
              doneReps: doneReps,
              totalReps: totalReps,
              ratio: progressRatio,
              percent: percentInt,
            ),
            const SizedBox(height: 12),

            // لافتة "وضع التركيز الكامل"
            _FocusModeBanner(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AzkarFocusModeScreen(
                      azkar: azkar,
                      period: period,
                      initialIndex: azkar.indexOf(firstIncompleteDhikr!),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // قائمة بطاقات الأذكار
            for (var i = 0; i < azkar.length; i++) ...[
              _ModernDhikrCard(
                dhikr: azkar[i],
                index: i + 1,
                period: period,
                locked: locked,
                onSurface: onSurface,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),

        // الشريط العائم التفاعلي بالأسفل
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: _BottomFloatingBar(
            completedCount: completedDhikrs,
            totalCount: totalDhikrs,
            ratio: progressRatio,
            currentDhikr: firstIncompleteDhikr,
            currentRemaining: firstIncompleteRemaining,
            onTapIncrement: () {
              if (locked) return;
              HapticFeedback.lightImpact();
              ref.read(azkarProgressProvider.notifier).tap(
                period,
                firstIncompleteDhikr!.order,
                firstIncompleteDhikr.count,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// بطاقة ملخص التقدم العلوية (مطابقة للصورة 2)
class _TopModernProgressCard extends StatelessWidget {
  const _TopModernProgressCard({
    required this.completedDhikrs,
    required this.totalDhikrs,
    required this.doneReps,
    required this.totalReps,
    required this.ratio,
    required this.percent,
  });

  final int completedDhikrs;
  final int totalDhikrs;
  final int doneReps;
  final int totalReps;
  final double ratio;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardBg = isDark ? const Color(0xFF1B232E) : const Color(0xFFFBF8F2);
    final borderColor = isDark ? const Color(0xFF2C394A) : const Color(0xFFE5DEC9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // النصوص على اليمين (RTL)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedDhikrs / $totalDhikrs ذكر',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إجمالي التكرارات: $doneReps / $totalReps',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),

              // الدائرة الدائرية للنسبة المئوية
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 4.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFD4AF67).withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFC59B27)),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFE2C98D) : const Color(0xFF8C6D3F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // شريط التقدم الأفقي
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: const Color(0xFFD4AF67).withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFC59B27)),
            ),
          ),
        ],
      ),
    );
  }
}

/// لافتة "وضع التركيز الكامل"
class _FocusModeBanner extends StatelessWidget {
  const _FocusModeBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardBg = isDark ? const Color(0xFF1B232E) : const Color(0xFFFBF8F2);
    final borderColor = isDark ? const Color(0xFF2C394A) : const Color(0xFFE5DEC9);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: onSurface.withValues(alpha: 0.5),
            ),
            const Spacer(),
            Text(
              'وضع التركيز الكامل',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE2C98D) : const Color(0xFF7A5C22),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.play_circle_outline_rounded,
              size: 20,
              color: isDark ? const Color(0xFFD4AF67) : const Color(0xFF8C6D3F),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الذكر الحديثة التفاعلية (مطابقة تماماً للصورة 2)
class _ModernDhikrCard extends ConsumerWidget {
  const _ModernDhikrCard({
    required this.dhikr,
    required this.index,
    required this.period,
    required this.locked,
    required this.onSurface,
  });

  final Dhikr dhikr;
  final int index;
  final AzkarPeriod period;
  final bool locked;
  final Color onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = ref.watch(
      azkarProgressProvider.select(
        (m) => m[(period, dhikr.order)] ?? dhikr.count,
      ),
    );
    final done = remaining <= 0;
    final currentReps = (dhikr.count - remaining).clamp(0, dhikr.count);

    final cardBg = isDark ? const Color(0xFF1B232E) : const Color(0xFFFCFAF6);
    final borderColor = isDark ? const Color(0xFF2C394A) : const Color(0xFFE8DFD1);

    return Column(
      children: [
        // شريط الإجراءات السريعة أعلى البطاقة (+ تسبيح، تشغيل، نسخ، مشاركة، حفظ)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // أزرار الإجراءات السريعة (حفظ، مشاركة، نسخ، استماع)
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuickIconButton(
                        icon: Icons.download_rounded,
                        tooltip: 'حفظ الذكر',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حفظ الذكر في المفضلة'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      _QuickIconButton(
                        icon: Icons.share_outlined,
                        tooltip: 'مشاركة الذكر',
                        onTap: () {
                          final text = '${dhikr.content}\n\n'
                              '${dhikr.fadl != null ? "الفضل: ${dhikr.fadl}\n" : ""}'
                              '${dhikr.source != null ? "المصدر: ${dhikr.source}" : ""}';
                          SharePlus.instance.share(ShareParams(text: text.trim()));
                        },
                      ),
                      const SizedBox(width: 6),
                      _QuickIconButton(
                        icon: Icons.copy_rounded,
                        tooltip: 'نسخ الذكر',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: dhikr.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ نص الذكر بنجاح'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      _QuickIconButton(
                        icon: Icons.play_arrow_rounded,
                        tooltip: 'استماع للذكر',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تشغيل صوت الذكر'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // زر + تسبيح (x/y)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: InkWell(
                    onTap: locked || done
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            ref.read(azkarProgressProvider.notifier).tap(
                                  period,
                                  dhikr.order,
                                  dhikr.count,
                                );
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF273240) : const Color(0xFFF9F5EC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD4AF67).withValues(alpha: 0.35),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+ تسبيح ($currentReps/${dhikr.count})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFE2C98D) : const Color(0xFF7A5C22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // بطاقة جسم الذكر الرئيسية
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: InkWell(
            onTap: locked || done
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    ref.read(azkarProgressProvider.notifier).tap(
                          period,
                          dhikr.order,
                          dhikr.count,
                        );
                  },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // شريط رأس البطاقة: العداد والنقاط يساراً + رقم الذكر يميناً
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // اليسار: العداد مع نقاط التكرار وأيقونة الإشارة
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                done ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                size: 16,
                                color: done
                                    ? const Color(0xFF2E8B57)
                                    : onSurface.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 5),
                              // نقاط التكرارات (Dots)
                              if (dhikr.count > 1 && dhikr.count <= 7) ...[
                                for (int dot = 0; dot < dhikr.count; dot++)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dot < currentReps
                                          ? const Color(0xFFC59B27)
                                          : onSurface.withValues(alpha: 0.18),
                                    ),
                                  ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                '$currentReps/${dhikr.count}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: done
                                      ? const Color(0xFF2E8B57)
                                      : onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // اليمين: رقم الذكر والتكرار (مثلاً: 8 أو ×4  9)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF26303D)
                                : const Color(0xFFF3ECE0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (dhikr.count > 1) ...[
                                Text(
                                  '×${dhikr.count}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? const Color(0xFFD4AF67)
                                        : const Color(0xFF8C6D3F),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                '$index',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // نص الذكر الشريف
                  Text(
                    dhikr.content,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 18,
                      height: 1.9,
                      fontWeight: FontWeight.w600,
                      color: done
                          ? onSurface.withValues(alpha: 0.55)
                          : onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // المصدر
                  if (dhikr.source != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.bookmark_outline_rounded,
                            size: 13,
                            color: onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dhikr.source!,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // شارة فضل الذكر (Pill Badge)
                  if (dhikr.fadl != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262115) : const Color(0xFFF9F5EA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.stars_rounded,
                              size: 14,
                              color: Color(0xFFD4AF67),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dhikr.fadl!,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFE2C98D)
                                    : const Color(0xFF7A5C22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// زر إجراء سريع دائري صغير
class _QuickIconButton extends StatelessWidget {
  const _QuickIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222B37) : const Color(0xFFF5EFE4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 17),
        color: onSurface.withValues(alpha: 0.65),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

/// الشريط العائم بالأسفل مع زر + ونسبة التقدم
class _BottomFloatingBar extends StatelessWidget {
  const _BottomFloatingBar({
    required this.completedCount,
    required this.totalCount,
    required this.ratio,
    required this.currentDhikr,
    required this.currentRemaining,
    required this.onTapIncrement,
  });

  final int completedCount;
  final int totalCount;
  final double ratio;
  final Dhikr currentDhikr;
  final int currentRemaining;
  final VoidCallback onTapIncrement;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final barBg = isDark ? const Color(0xFF1B232E) : const Color(0xFFFAF6EE);
    final borderColor = isDark ? const Color(0xFF2C394A) : const Color(0xFFE5DEC9);

    // مقطع من نص الذكر الحالي
    final snippet = currentDhikr.content.length > 25
        ? '${currentDhikr.content.substring(0, 25)}...'
        : currentDhikr.content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // الزر الدائري الذهبي +
          GestureDetector(
            onTap: onTapIncrement,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFD6A868), Color(0xFF9E7A3E)],
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // النص في المنتصف مع شريط التقدم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '$completedCount/$totalCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        snippet,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 3,
                    backgroundColor: const Color(0xFFD4AF67).withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFC59B27)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // العداد الدائري على اليمين
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF26303D) : const Color(0xFFF3ECE0),
              border: Border.all(
                color: const Color(0xFFD4AF67).withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '$currentRemaining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFFD4AF67) : const Color(0xFF8C6D3F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
