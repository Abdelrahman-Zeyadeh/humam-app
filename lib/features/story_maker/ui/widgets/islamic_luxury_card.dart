import 'dart:io';
import 'package:flutter/material.dart';

/// بطاقة إسلامية ملكية فاخرة مطابقة لنمط "خلفيات فذكّر" واستوديو بطاقات هُمَام
/// بخلفيات متدرجة ملكية، وتطريز ذهبي دقيق، وزوايا زخرفية، وتيبوغرافيا عربية متناسقة
/// بلا أي تقطيع في الحروف أو فيضان في النصوص الطويلة.
class IslamicLuxuryCard extends StatelessWidget {
  const IslamicLuxuryCard({
    super.key,
    required this.mainText,
    this.badgeText = 'كرر تؤجر',
    this.topTitle = 'فَذَكِّرْ',
    this.footerText = 'ذكّر غيرك',
    this.footerIcon = Icons.repeat_rounded,
    this.gradientColors = const [
      Color(0xFF1A0E07),
      Color(0xFF351D0E),
      Color(0xFF140A04),
    ],
    this.textColor = const Color(0xFFE5C378),
    this.accentGold = const Color(0xFFD4AF37),
    this.fontSize = 24.0,
    this.width = 280,
    this.height = 490,
    this.fontFamily = 'Cairo',
    this.subText,
    this.customImagePath,
    this.overlayDarkness = 0.60,
    this.showDecorativeFrame = true,
  });

  final String mainText;
  final String badgeText;
  final String topTitle;
  final String footerText;
  final IconData footerIcon;
  final List<Color> gradientColors;
  final Color textColor;
  final Color accentGold;
  final double fontSize;
  final double width;
  final double height;
  final String fontFamily;
  final String? subText;
  final String? customImagePath;
  final double overlayDarkness;
  final bool showDecorativeFrame;

  /// حساب الحجم الأمثل للنص تلقائياً بناءً على طوله لتفادي أي قطع أو فيضان
  double _calculateDynamicFontSize(String text, double baseSize) {
    final clean = text.trim();
    final len = clean.length;
    final scale = (baseSize / 24.0);

    if (len < 35) {
      return (26.0 * scale).clamp(20.0, 32.0);
    } else if (len < 80) {
      return (21.0 * scale).clamp(16.0, 25.0);
    } else if (len < 160) {
      return (17.0 * scale).clamp(13.5, 20.0);
    } else if (len < 260) {
      return (14.5 * scale).clamp(11.5, 17.0);
    } else {
      return (12.5 * scale).clamp(10.0, 14.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomBg = customImagePath != null && File(customImagePath!).existsSync();
    final isAmiri = fontFamily == 'AmiriQuran';
    final computedFontSize = _calculateDynamicFontSize(mainText, fontSize);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: hasCustomBg
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
          border: Border.all(
            color: accentGold.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // صورة الخلفية المخصصة إن اختار المستخدم من جهازه
            if (hasCustomBg) ...[
              Positioned.fill(
                child: Image.file(
                  File(customImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: overlayDarkness),
                ),
              ),
            ],

            // إضاءة شعاعية دافئة خفيفة في منتصف وأعلى البطاقة
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.85,
                    colors: [
                      accentGold.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // إطار زخرفي داخلي رقيق يعطي فخامة إسلامية استثنائية للبطاقة
            if (showDecorativeFrame)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.20),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ),

            // المحتوى الداخلي الرأسي المتناسق والمحمي من الفيضان
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. الترويسة العلوية المزخرفة ("فَذَكِّرْ" أو اسم التطبيق)
                  if (topTitle.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '۞',
                          style: TextStyle(
                            fontSize: 11,
                            color: accentGold.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          topTitle,
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            // إزالة letterSpacing لحماية الحروف العربية من الانفصال
                            color: accentGold,
                            shadows: [
                              Shadow(
                                color: accentGold.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '۞',
                          style: TextStyle(
                            fontSize: 11,
                            color: accentGold.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 2. إطار التصنيف / البادج المستطيل المذهب ("كرر تؤجر" أو رقم الآية/السورة)
                  if (badgeText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentGold.withValues(alpha: 0.5),
                          width: 1.1,
                        ),
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          // إزالة letterSpacing للحفاظ على اتصال الحروف
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3. النص الرئيسي المتكيف ذكياً بدون قطع في الحروف أو اختناق
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: width - 44,
                            maxHeight: height - 150,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mainText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: computedFontSize,
                                  // استخدام وزن مناسب لـ AmiriQuran (بدون synthetic bold المشوه للحركات)
                                  fontWeight: isAmiri ? FontWeight.w600 : FontWeight.w800,
                                  // تباعد أسطر مريح يتنفس فيه التشكيل والرسم العثماني
                                  height: isAmiri ? 1.85 : 1.58,
                                  color: textColor,
                                  // بدون letterSpacing إطلاقاً — اتصال الحروف العربية مقدس
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                              if (subText != null && subText!.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  subText!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: (computedFontSize * 0.55).clamp(10.0, 13.0),
                                    color: accentGold.withValues(alpha: 0.90),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. الخط الفاصل الذهبي الرقيق مع زخرفة مركزية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              accentGold.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.circle,
                          size: 4,
                          color: accentGold.withValues(alpha: 0.6),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentGold.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 5. زر الإشارة والتذييل السفلي ("ذكّر غيرك" مع الأيقونة)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        footerIcon,
                        size: 13,
                        color: accentGold.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        footerText,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: accentGold.withValues(alpha: 0.90),
                          // إزالة letterSpacing
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
