import 'package:flutter/material.dart';

import '../reciters.dart';

/// ودجت أيقونة/صورة القارئ الدائرية
/// تعرض الصورة الشخصية المعتمدة للقارئ من assets/images/reciters
/// مع الرجوع التلقائي لحرف القارئ الأول في حال حدوث أي خطأ أو تعذر تحميل.
class ReciterAvatar extends StatelessWidget {
  const ReciterAvatar({
    super.key,
    required this.reciter,
    this.radius = 18,
    this.backgroundColor,
  });

  final Reciter reciter;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hue = (reciter.id.hashCode.abs() * 7) % 360;
    final fallbackBg = backgroundColor ??
        HSLColor.fromAHSL(
          1,
          hue.toDouble(),
          0.5,
          isDark ? 0.32 : 0.45,
        ).toColor();

    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackBg,
      child: ClipOval(
        child: Image.asset(
          reciter.imageAsset,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              reciter.nameAr.characters.first,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.85,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
