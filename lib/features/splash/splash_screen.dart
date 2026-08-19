import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../shell/root_shell.dart';

/// شاشة الترحيب — تُعرض لحظات عند الإقلاع ثم تنتقل للقشرة الرئيسية.
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
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 52),
            SizedBox(height: 14),
            Text(
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
