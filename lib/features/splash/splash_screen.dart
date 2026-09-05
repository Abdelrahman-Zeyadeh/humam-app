import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/root_shell.dart';

/// شاشة الترحيب — تُعرض لحظات عند الإقلاع ثم تنتقل للجولة التعريفية (أول
/// فتح فقط، راجع `kOnboardingSeenKey`) أو مباشرة للقشرة الرئيسية. الأيقونة
/// النهائية (`assets/icon/icon.png`) هي الشعار — فيها اسم "هُمَام" مكتوباً
/// بالذهبي أصلاً، فلا نص إضافي منفصل هون.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // الأيقونة تُفكّ ترميزها (decode) بشكل غير متزامن حتى لو بُنيت مع النص
  // بنفس الفريم — فبدون هالتحميل المسبق، ممكن يظهر النص أولاً ثم "تقفز"
  // الأيقونة بعده بفريم أو اثنين (بالضبط الملاحظة: "الصورة بتظهر بعدين
  // الاسم" أو العكس، حسب سرعة الجهاز). نحمّلها هون وما نبني المحتوى إلا
  // لما تخلص، فيظهران معاً بنفس اللحظة دايماً.
  bool _iconReady = false;
  bool _precacheStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `precacheImage` بحاجة `context` مربوط بالكامل بالشجرة (لقراءة
    // MediaQuery/DefaultAssetBundle) — `didChangeDependencies` هو المكان
    // الموصى فيه رسمياً لهيك نداء، لا `initState`. الحارس تحت يمنع تكراره
    // لو استُدعيت هالدالة أكتر من مرة.
    if (_precacheStarted) return;
    _precacheStarted = true;
    precacheImage(const AssetImage('assets/icon/icon.png'), context).then((
      _,
    ) {
      if (mounted) setState(() => _iconReady = true);
    });
  }

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
      // بدون الأيقونة الجاهزة، الخلفية الكحلية لحالها مطابقة تمامًا لخلفية
      // شاشة الإقلاع الأصلية بأندرويد (راجع
      // `android/.../drawable/launch_background.xml`) — فالانتقال من نظام
      // التشغيل لفلاتر بلا أي ومضة، وما إن تجهز الأيقونة يظهر المحتوى
      // كاملاً (أيقونة + اسم) دفعة واحدة بدل ما يتباينان بينهما.
      // لا نص "هُمَام" منفصل هون عمداً — الأيقونة نفسها فيها الاسم مكتوباً
      // بالذهبي جوّاها أصلاً (راجع `assets/icon/icon.png`)، فنص أبيض إضافي
      // بالأسفل كان يكرّر نفس الاسم مرّتين بلون مختلف بلا داعٍ.
      body: _iconReady
          ? Center(
              // `assets/icon/icon.png` ملف JPEG فعلياً (لا يدعم شفافية) —
              // الشكل المدوّر (squircle) الكحلي مرسوم فوق خلفية **بيضاء
              // صريحة** بزوايا القماشة المربعة حوله. `ClipRRect` بنصف قطر
              // أكبر شوي من انحناء الشكل نفسه يقصّ هالزوايا البيضاء
              // بالكامل، فيبقى الكحلي متّصل بخلفية الشاشة الكحلية بلا أي
              // حافة بيضاء ظاهرة (الشكل بالصورة أصلاً نفس درجة
              // `AppColors.navy`).
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            )
          : null,
    );
  }
}
