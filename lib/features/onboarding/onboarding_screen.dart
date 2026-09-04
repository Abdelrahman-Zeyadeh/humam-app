import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../mushaf/mushaf_settings.dart' show mushafChromeVisibleProvider;
import '../shell/root_shell.dart';
import 'onboarding_target_keys.dart';

/// مفتاح SharedPreferences لتسجيل إتمام الجولة التعريفية
const String kOnboardingSeenKey = 'onboarding_seen_v5';

/// مزود للتحكم في ظهور أو إخفاء الجولة التعريفية من أي مكان بالتطبيق
class TourActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void start() => state = true;
  void dismiss() => state = false;
}

final tourActiveProvider = NotifierProvider<TourActiveNotifier, bool>(
  TourActiveNotifier.new,
);

/// بيانات خطوة الجولة التعريفية والكتالوج
class _TourStep {
  const _TourStep({
    required this.tabIndex,
    required this.title,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.shortDescription,
    this.targetKey,
    this.isCircle = false,
  });

  final int tabIndex;
  final String title;
  final String badge;
  final IconData icon;
  final Color accentColor;
  final String shortDescription;
  final GlobalKey? targetKey;
  final bool isCircle;
}

final List<_TourStep> _kTourSteps = [
  // 1. الرئيسية - الورد وسلاسل الاستمرار
  _TourStep(
    tabIndex: 0,
    targetKey: homeStreakWirdKey,
    title: 'سلاسل الاستمرار والورد',
    badge: 'الرئيسية',
    icon: Icons.local_fire_department_rounded,
    accentColor: const Color(0xFF2A85FF),
    shortDescription:
        'تابع انتظامك اليومي في الطاعات، واستأنف قراءة الورد من آخر صفحة بنقرة واحدة.',
  ),

  // 2. الرئيسية - تخصيص الواجهة
  _TourStep(
    tabIndex: 0,
    targetKey: dashboardCustomizeButtonKey,
    title: 'تخصيص الواجهة',
    badge: 'تحكم بالداشبورد',
    icon: Icons.dashboard_customize_rounded,
    accentColor: const Color(0xFF00B4D8),
    shortDescription:
        'اضغط هنا لإعادة ترتيب البطاقات بالسحب، وإخفاء أو إظهار ما يناسبك.',
  ),

  // 3. المصحف - القراءة مع التفسير
  _TourStep(
    tabIndex: 1,
    targetKey: mushafTafsirReadingButtonKey,
    isCircle: true,
    title: 'القراءة مع التفسير',
    badge: 'المصحف',
    icon: Icons.menu_book_rounded,
    accentColor: AppColors.goldDeep,
    shortDescription:
        'تصفح الآيات مع تفسير فوري متصل تحت كل آية، أو اضغط مطولاً لشرح الغريب.',
  ),

  // 4. المصحف - التلاوات الصوتية
  _TourStep(
    tabIndex: 1,
    targetKey: mushafAudioBarKey,
    title: 'التلاوات وكبار القرّاء',
    badge: 'المصحف',
    icon: Icons.audiotrack_rounded,
    accentColor: const Color(0xFFD4AF37),
    shortDescription:
        'استمع لأكثر من ١٠ قرّاء مع تكرار الآيات والتحكم بالسرعة والتظليل المتزامن.',
  ),

  // 5. الصلاة - بوصلة القبلة
  _TourStep(
    tabIndex: 2,
    targetKey: qiblaButtonKey,
    isCircle: true,
    title: 'بوصلة القبلة 3D',
    badge: 'الصلاة',
    icon: Icons.explore_rounded,
    accentColor: const Color(0xFF00A86B),
    shortDescription:
        'تحديد دقيق لاتجاه الكعبة المشرفة بمستشعرات البوصلة وبدون الحاجة لإنترنت.',
  ),

  // 6. الصلاة - مواقيت الصلاة والعد التنازلي
  _TourStep(
    tabIndex: 2,
    targetKey: firstPrayerRowKey,
    title: 'مواقيت الصلاة والتنبيهات',
    badge: 'الصلاة',
    icon: Icons.access_time_filled_rounded,
    accentColor: const Color(0xFF2E8071),
    shortDescription:
        'حساب دقيق لمواقيت الصلوات مع عداد تنازلي، واضغط على أي صلاة لضبط تنبيهاتها.',
  ),

  // 7. الصلاة - اختيار المؤذن
  _TourStep(
    tabIndex: 2,
    targetKey: adhanVoiceCardKey,
    title: 'صوت المؤذن والأذان',
    badge: 'الصلاة',
    icon: Icons.record_voice_over_rounded,
    accentColor: const Color(0xFFE07A5F),
    shortDescription:
        'اختر مؤذنك المفضل (الحرمين، مصر، القدس) مع معاينة فورية وتخصيص لكل صلاة.',
  ),

  // 8. الأذكار - المسبحة الإلكترونية
  _TourStep(
    tabIndex: 3,
    targetKey: azkarTasbihButtonKey,
    isCircle: true,
    title: 'المسبحة الإلكترونية الذكية',
    badge: 'الأذكار',
    icon: Icons.fingerprint_rounded,
    accentColor: const Color(0xFF20B2AA),
    shortDescription:
        'شاشة تسبيح تفاعلية مع عدادات مرنة وردود فعل حسية (اهتزاز) عند كل تسبيحة.',
  ),

  // 9. الأذكار - أذكار الصباح والمساء
  _TourStep(
    tabIndex: 3,
    targetKey: azkarQuickCardsKey,
    title: 'أذكار الصباح والمساء وحصن المسلم',
    badge: 'الأذكار',
    icon: Icons.spa_rounded,
    accentColor: const Color(0xFF1ABC9C),
    shortDescription:
        'وصول سريع للأذكار اليومية بعداد ذكي، ومكتبة حصن المسلم الكاملة (١٣١ قسماً).',
  ),

  // 10. أدواتي - الختمات والمجموعات والأحاديث
  _TourStep(
    tabIndex: 4,
    targetKey: toolsKhatmaCardKey,
    title: 'الختمات والمجموعات والأحاديث',
    badge: 'أدواتي',
    icon: Icons.grid_view_rounded,
    accentColor: const Color(0xFF9D4EDD),
    shortDescription:
        'خطط ختم القرآن وحفظه، مجموعات التنافس مع الأصدقاء، وموسوعة الأحاديث النبوية.',
  ),
];

/// غلاف الجولة التعريفية التفاعلية المدمجة وغير المحجبة للشاشة
class OnboardingTourOverlay extends ConsumerStatefulWidget {
  const OnboardingTourOverlay({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  ConsumerState<OnboardingTourOverlay> createState() =>
      _OnboardingTourOverlayState();
}

class _OnboardingTourOverlayState extends ConsumerState<OnboardingTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  Rect? _targetRect;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyStepTab(_kTourSteps[0]);
      _measureAndFocus();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _applyStepTab(_TourStep step) {
    ref.read(rootTabIndexProvider.notifier).select(step.tabIndex);
    if (step.tabIndex == 1) {
      final isChromeVisible = ref.read(mushafChromeVisibleProvider);
      if (!isChromeVisible) {
        ref.read(mushafChromeVisibleProvider.notifier).toggle();
      }
    }
  }

  void _measureAndFocus() {
    final step = _kTourSteps[_currentStep];
    final key = step.targetKey;
    if (key == null) {
      if (mounted) setState(() => _targetRect = null);
      return;
    }

    void tryFocus() {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx == null || !ctx.mounted) return;

      // 1. التمرير التلقائي للعنصر إذا كان داخل قائمة قابلة للتمرير (كزر التخصيص بالأسفل)
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        alignment: 0.5,
      ).then((_) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final renderBox = ctx.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize && renderBox.attached) {
            final offset = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;
            setState(() {
              _targetRect = offset & size;
            });
          }
        });
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryFocus();
      // محاولة ثانية للتأكيد في حال أخذ بناء الشاشة بضعة أجزاء من الثانية
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _targetRect == null) {
          tryFocus();
        }
      });
    });
  }

  void _goToStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= _kTourSteps.length) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentStep = stepIndex;
      _targetRect = null;
    });
    final nextStep = _kTourSteps[stepIndex];
    _applyStepTab(nextStep);
    _measureAndFocus();
  }

  Future<void> _finishTour() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingSeenKey, true);
    ref.read(tourActiveProvider.notifier).dismiss();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final step = _kTourSteps[_currentStep];
    final isLast = _currentStep == _kTourSteps.length - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    // تموضع ذكي: في الأعلى إذا كان العنصر في النصف السفلي، وفي الأسفل إذا كان بالأعلى
    final target = _targetRect;
    final bool placeCardAtTop =
        target != null && target.center.dy > (screenSize.height * 0.45);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 1. قناع العتمة ودائرة التركيز المضيئة المتوهجة
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: _targetRect,
                    pulseProgress: _pulseController.value,
                    accentColor: step.accentColor,
                    isCircle: step.isCircle,
                  ),
                );
              },
            ),
          ),

          // 2. منطقة لمس سريعة للانتقال
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (isLast) {
                  _finishTour();
                } else {
                  _goToStep(_currentStep + 1);
                }
              },
            ),
          ),

          // 3. بطاقة الشرح المدمجة والذكية (غير حاجبة للشاشة)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: 14,
            right: 14,
            top: placeCardAtTop ? safePadding.top + 10 : null,
            bottom: placeCardAtTop ? null : safePadding.bottom + 62,
            child: SafeArea(
              top: placeCardAtTop,
              bottom: !placeCardAtTop,
              child: Material(
                color: isDark
                    ? const Color(0xFF131F30).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.97),
                elevation: 16,
                shadowColor: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: step.accentColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // الصف العلوي: أيقونة + عنوان + شارة + رقم الخطوة + إغلاق
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: step.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              step.icon,
                              size: 18,
                              color: step.accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    step.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          isDark ? Colors.white : AppColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: step.accentColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    step.badge,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: step.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_currentStep + 1}/${_kTourSteps.length}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: _finishTour,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            color: isDark ? Colors.white54 : Colors.black45,
                            tooltip: 'تخطّي الجولة',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // النص التوضيحي المدمج والواضح
                      Text(
                        step.shortDescription,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.88)
                              : AppColors.ink.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // الصف السفلي: الأزرار ومؤشرات الخطوات
                      Row(
                        children: [
                          if (_currentStep > 0) ...[
                            InkWell(
                              onTap: () => _goToStep(_currentStep - 1),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'السابق',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // مؤشرات الخطوات
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_kTourSteps.length, (idx) {
                                final isSelected = idx == _currentStep;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1.5),
                                  height: 3.5,
                                  width: isSelected ? 12 : 3.5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? step.accentColor
                                        : (isDark
                                            ? Colors.white24
                                            : Colors.black12),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ),

                          const SizedBox(width: 6),

                          ElevatedButton(
                            onPressed: () {
                              if (isLast) {
                                _finishTour();
                              } else {
                                _goToStep(_currentStep + 1);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: step.accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLast ? 'ابدأ الآن' : 'التالي',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  isLast
                                      ? Icons.check_rounded
                                      : Icons.arrow_back_rounded,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// رسام دائرة التركيز المتوهجة والمتحركة
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.targetRect,
    required this.pulseProgress,
    required this.accentColor,
    required this.isCircle,
  });

  final Rect? targetRect;
  final double pulseProgress;
  final Color accentColor;
  final bool isCircle;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);

    if (targetRect == null) {
      canvas.drawRect(fullRect, bgPaint);
      return;
    }

    final target = targetRect!;
    final pad = isCircle ? 6.0 : 8.0;
    final inflated = target.inflate(pad);

    final Path holePath = Path();
    if (isCircle ||
        (inflated.width - inflated.height).abs() < 12 &&
            inflated.width < 80) {
      final center = inflated.center;
      final radius = math.max(inflated.width, inflated.height) / 2;
      holePath.addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      holePath.addRRect(
        RRect.fromRectAndRadius(
          inflated,
          Radius.circular(math.min(18.0, inflated.height / 2)),
        ),
      );
    }

    // رسم العتمة مع استثناء فتحة العنصر
    final scrimPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(fullRect),
      holePath,
    );
    canvas.drawPath(scrimPath, bgPaint);

    // 1. الإطار المضيء الثابت حول العنصر
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = accentColor;
    canvas.drawPath(holePath, borderPaint);

    // 2. موجة النبض الإشعاعية الأولى المتوسعة
    final t1 = pulseProgress;
    final ripple1Rect = inflated.inflate(4.0 + (12.0 * t1));
    final ripple1Paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1.0 - t1)
      ..color = accentColor.withValues(alpha: (1.0 - t1) * 0.75);

    if (isCircle ||
        (inflated.width - inflated.height).abs() < 12 &&
            inflated.width < 80) {
      final center = ripple1Rect.center;
      final radius = math.max(ripple1Rect.width, ripple1Rect.height) / 2;
      canvas.drawCircle(center, radius, ripple1Paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          ripple1Rect,
          Radius.circular(math.min(20.0, ripple1Rect.height / 2)),
        ),
        ripple1Paint,
      );
    }

    // 3. موجة النبض الإشعاعية الثانية المتتابعة
    final t2 = (pulseProgress + 0.5) % 1.0;
    final ripple2Rect = inflated.inflate(4.0 + (16.0 * t2));
    final ripple2Paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * (1.0 - t2)
      ..color = accentColor.withValues(alpha: (1.0 - t2) * 0.45);

    if (isCircle ||
        (inflated.width - inflated.height).abs() < 12 &&
            inflated.width < 80) {
      final center = ripple2Rect.center;
      final radius = math.max(ripple2Rect.width, ripple2Rect.height) / 2;
      canvas.drawCircle(center, radius, ripple2Paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          ripple2Rect,
          Radius.circular(math.min(22.0, ripple2Rect.height / 2)),
        ),
        ripple2Paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isCircle != isCircle;
  }
}

/// غلاف OnboardingScreen للتوافق العكسي
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RootShell(startTour: true);
  }
}


