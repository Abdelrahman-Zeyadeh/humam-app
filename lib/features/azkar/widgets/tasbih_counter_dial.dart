import 'package:flutter/material.dart';

/// منطقة اللمس والعداد الرئيسي التفاعلي بملء الشاشة (الدائرة، حلقة التقدم،
/// نص الذكر، الرقم الكبير، والهدف) — استُخرجت من `tasbih_screen.dart` أثناء
/// تفكيكه بلا أي تغيير سلوكي. تبقى حركة الضغط (`scaleAnimation`) والحالة
/// (العدّ/الهدف) مُدارة بالشاشة الأمّ وتُمرَّر هون فقط للعرض.
class TasbihCounterDial extends StatelessWidget {
  const TasbihCounterDial({
    super.key,
    required this.scaleAnimation,
    required this.onTap,
    required this.isDark,
    required this.accent,
    required this.surface,
    required this.fg,
    required this.targetGoal,
    required this.progress,
    required this.selectedPhrase,
    required this.count,
  });

  final Animation<double> scaleAnimation;
  final VoidCallback onTap;
  final bool isDark;
  final Color accent;
  final Color surface;
  final Color fg;
  final int targetGoal;
  final double progress;
  final String selectedPhrase;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  surface,
                  Color.lerp(surface, accent, isDark ? 0.06 : 0.03)!,
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // حلقة التقدم الدائرية الناعمة
                if (targetGoal > 0)
                  SizedBox(
                    width: 254,
                    height: 254,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                // المحتوى الداخلي للعداد
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // نص الذكر المختار
                      Text(
                        selectedPhrase,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // رقم العداد الكبير
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: fg,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // الهدف
                      Text(
                        targetGoal > 0 ? 'الهدف: $targetGoal' : 'عدّ مفتوح',
                        style: TextStyle(
                          fontSize: 12,
                          color: fg.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
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
    );
  }
}
