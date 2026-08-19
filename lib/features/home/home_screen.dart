import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// شاشة الرئيسية — هيكل مبدئي فقط لهذه المرحلة (المرحلة ١: الأساس).
/// الداشبورد الكامل (بطاقة الصدارة الديناميكية، شريط التقدم، آية اليوم،
/// البطاقات القابلة لإعادة الترتيب) يُبنى في مرحلة الداشبورد المخصصة،
/// بعد جاهزية طبقة البيانات. راجع تصميم هُمَام الأولي (الكانفاس المعتمد)
/// لتفاصيل التصميم النهائي المستهدف لهذه الشاشة.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.navy, AppColors.navyDeep],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'السلام عليكم',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'أهلاً بك في هُمَام',
                    style: TextStyle(color: AppColors.goldSoft, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'الداشبورد الكامل قيد الإنشاء —\nسيظهر هنا في مرحلة لاحقة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
