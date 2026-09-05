import 'package:flutter/material.dart';

import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';

/// أدوات ألوان/ظلال مشتركة بين بطاقات الشاشة الرئيسية (`home_screen.dart`
/// وودجتاتها الفرعية بـ`widgets/`) — استُخرجت من `home_screen.dart` أثناء
/// تفكيك الملف (كان ~٢١٠٠ سطر بكل شي بملف واحد)، بلا أي تغيير سلوكي.
Color homeCardSurface(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark
    ? AppColors.surfaceDark
    : Colors.white;

Color homeCardBorder(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.lineDark
    : AppColors.line;

Color homeTextStrong(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkOnDark
    : AppColors.navy;

Color homeTextSoft(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkSoftOnDark
    : AppColors.inkSoft;

List<BoxShadow> homeCardShadow(BuildContext c) => [
  BoxShadow(
    color:
        (Theme.of(c).brightness == Brightness.dark
                ? Colors.black
                : AppColors.navy)
            .withValues(
              alpha: Theme.of(c).brightness == Brightness.dark ? 0.32 : 0.06,
            ),
    blurRadius: 14,
    offset: const Offset(0, 4),
  ),
];

/// عنوان قسم صغير (أيقونة برُقعة + نص) — يُستخدَم فوق البطاقات المجمَّعة
/// (الأهداف، سلاسل الاستمرار) بنفس أسلوب لوحة التصميم المعتمدة، بدل
/// قفز مباشر من بطاقة لبطاقة بلا عنوان يفصلها.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: homeCardBorder(context),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 13, color: homeTextStrong(context)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: homeTextStrong(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة أيقونة بخلفية دائرية مصبوغة بلون خفيف — يُستخدَم بمعظم بطاقات
/// الرئيسية القيادية (الليل/الأذكار/الظهيرة) وبطاقة "ابدأ خطة".
class TintedIconBadge extends StatelessWidget {
  const TintedIconBadge({
    super.key,
    required this.icon,
    required this.color,
    Color? iconColor,
  }) : iconColor = iconColor ?? color;
  final IconData icon;
  final Color color;
  // خلفية الدائرة تبقى بلون [color] الأصلي بشفافية خفيفة (زخرفة، لا حاجة
  // لتباين). الأيقونة نفسها تحتاج ٣:١ على الأقل فوق البطاقة البيضاء —
  // [iconColor] يسمح بتمرير درجة أغمق (goldDeep) بدل [color] عند الحاجة.
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return IconBadge(icon: icon, color: color, iconColor: iconColor);
  }
}
