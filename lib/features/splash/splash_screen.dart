import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/root_shell.dart';

/// شاشة الترحيب — تُعرض لحظات عند الإقلاع ثم تنتقل للجولة التعريفية (أول
/// فتح فقط، راجع `kOnboardingSeenKey`) أو مباشرة للقشرة الرئيسية.
/// شعار نصي مؤقت فقط؛ الشعار والأيقونة النهائيان يُحسمان في مرحلة التجهيز للنشر.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ٩٠٠ملث الأصلية كانت تأخيراً ثابتاً بالكامل فوق وقت التحميل الفعلي
    // (`UserRepository.preload` يخلص كلياً قبل ما `runApp`/هالشاشة حتى
    // تُرسَم — راجع `main.dart`)، فتُضاف صراحة لوقت الإقلاع المُدرَك بلا
    // أي فائدة وظيفية. أُبقيت "لحظة شعار" قصيرة لا تُلغى كلياً (لمسة
    // هوية مقصودة)، بس مخفَّضة لأقل مدة تبقى محسوسة كلمحة لا كتأخير.
    Future.delayed(const Duration(milliseconds: 60), () async {
      // `SharedPreferences.getInstance()` يرجع نفس النسخة المحمَّلة أصلاً
      // بـ`main.dart` قبل `runApp` (Singleton داخلي بالحزمة) — لا تحميل
      // مضاعف فعلي، مجرّد قراءة فورية من الذاكرة.
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool(kOnboardingSeenKey) ?? false;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RootShell(startTour: !seenOnboarding),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 14),
            const Text(
              'هُمَام',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
