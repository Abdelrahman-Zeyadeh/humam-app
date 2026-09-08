import 'package:flutter/material.dart';

import 'app_colors.dart';

/// بطاقة المحتوى الرئيسية الموحّدة — تجمّع منطق اللون/الحدود/الظل الذي
/// كان مكرَّراً كدوال خاصة (`_cardSurface`/`_cardBorder`/`_cardShadow`) في
/// أكثر من عشرة ملفات، بنفس القيم تماماً، مع تثبيت نصف قطر الحواف على
/// ١٨ (مطابق لـ`AppTheme.cardTheme` الافتراضي) بدل التذبذب بين ١٤/١٦/٢٠/٢٤.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderColor,
    this.borderRadius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  /// لتجاوز لون الحدّ الافتراضي (مثلاً تمييز بطاقة "محقَّقة" بلون الإنجاز).
  final Color? borderColor;
  final double borderRadius;

  static Color surface(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white;

  static Color border(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? AppColors.lineDark : AppColors.line;

  static List<BoxShadow> shadow(BuildContext c) => [
    BoxShadow(
      color: (Theme.of(c).brightness == Brightness.dark ? Colors.black : AppColors.navy)
          .withValues(alpha: Theme.of(c).brightness == Brightness.dark ? 0.32 : 0.06),
      blurRadius: 16,
      offset: const Offset(0, 5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: surface(context),
        borderRadius: radius,
        border: Border.all(color: borderColor ?? border(context)),
        boxShadow: shadow(context),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: radius),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: surface(context),
              borderRadius: radius,
              border: Border.all(color: borderColor ?? border(context)),
              boxShadow: shadow(context),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// شريط علوي بتدرّج (Navy gradient) للشاشات "الخاصة" (مداخل/إحصاءات) —
/// نفس النمط المكرَّر بأكثر من ١٢ شاشة: عنوان أبيض، حواف سفلية دائرية،
/// و`flexibleSpace` بتدرّج لوني.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    required this.title,
    this.colors = const [AppColors.blue, AppColors.navy],
    this.centerTitle = false,
    this.actions,
    this.leading,
    this.bottomRadius = 24,
    this.titleWidget,
    this.bottom,
  });

  /// نص العنوان — يُتجاهَل لو مُرِّر [titleWidget].
  final String title;
  final Widget? titleWidget;
  final List<Color> colors;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double bottomRadius;

  /// عنصر أسفل الشريط (مثلاً `TabBar`) — اختياري.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          titleWidget ??
          // **باج حقيقي مُصلَح هون**: عناوين طويلة (مثلاً "مجموعات الصحبة
          // والتنافس الإيماني") كانت تُقتَص بعلامة "..." لأن `Text` بلا
          // أي تصغير تلقائي بعرض شريط العنوان المحدود — خصوصاً وسط
          // `centerTitle: false` (افتراضي هون) يلي بيحاذي العنوان يمين
          // الشاشة فيقلّل المساحة المتاحة أكتر. `FittedBox` بيصغّر الخط
          // تلقائياً بس لو النص أطول من المساحة، بلا أي تغيير للعناوين
          // القصيرة العادية.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: centerTitle ? Alignment.center : AlignmentDirectional.centerStart,
            child: Text(
              title,
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors),
        ),
      ),
      actions: actions,
      leading: leading,
      bottom: bottom,
    );
  }
}

/// زر الإجراء الرئيسي الموحَّد — نصف قطر ١٤ ثابت بكل مكان، ولون تعبئة
/// افتراضي هو لون التمييز الحالي للثيم ([themeAccent])، مع إمكانية تمرير
/// [color] لتجاوزه بالحالات المتعمَّدة (إجراء إتلاف، لون فرع/هدف ديناميكي...).
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foregroundColor,
    this.expanded = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foregroundColor;
  final bool expanded;

  /// لو true، يُستبدَل النص/الأيقونة بمؤشّر تحميل صغير (نفس لون النص) —
  /// لأزرار الإجراءات غير المتزامنة (إنشاء/انضمام...).
  final bool loading;

  static const double radius = 14;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: color ?? themeAccent(context),
      foregroundColor: foregroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    );

    if (loading) {
      final button = FilledButton(
        onPressed: null,
        style: style,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: foregroundColor ?? Colors.white,
          ),
        ),
      );
      return expanded ? SizedBox(width: double.infinity, child: button) : button;
    }

    final button = icon != null
        ? FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: Text(label),
          )
        : FilledButton(onPressed: onPressed, style: style, child: Text(label));

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// شارة أيقونة دائرية بخلفية ملوَّنة خفيفة الشفافية — بدرجتين: صغيرة
/// (قوائم) وكبيرة (بطاقات مميَّزة/أبطال).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.large = false,
    this.iconColor,
    this.tintAlpha,
  });

  final IconData icon;
  final Color color;
  final bool large;

  /// لتمييز الأيقونة عن لون الخلفية (درجة أغمق لضمان تباين كافٍ).
  final Color? iconColor;

  /// لتجاوز شفافية الخلفية الافتراضية للدرجة (مثلاً تمييز حالة "محقَّق").
  final double? tintAlpha;

  double get _size => large ? 44 : 32;
  double get _iconSize => large ? 22 : 17;
  double get _defaultAlpha => large ? 0.15 : 0.12;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: tintAlpha ?? _defaultAlpha),
      ),
      child: Icon(icon, size: _iconSize, color: iconColor ?? color),
    );
  }
}

/// حالة "لا يوجد محتوى" الموحَّدة — أيقونة خافتة فوق رسالة، بنفس الأسلوب
/// المستخدَم أصلاً بـ`qibla_screen.dart`/`mushaf_search_screen.dart`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.iconSize = 48,
    this.color,
    this.padding = const EdgeInsets.all(24),
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final double iconSize;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: color ?? onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withValues(alpha: 0.65), fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
