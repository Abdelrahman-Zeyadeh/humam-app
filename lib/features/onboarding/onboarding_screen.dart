import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';

/// مفتاح SharedPreferences لتسجيل إتمام الجولة التعريفية الجديدة
const String kOnboardingSeenKey = 'onboarding_seen_v6';

/// مزود للتحكم في ظهور أو إخفاء كتالوج التطبيق والجولة التعريفية
class TourActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void start() => state = true;
  void dismiss() => state = false;
}

final tourActiveProvider = NotifierProvider<TourActiveNotifier, bool>(
  TourActiveNotifier.new,
);

class _CatalogSlideData {
  const _CatalogSlideData({
    required this.title,
    required this.badge,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.features,
  });

  final String title;
  final String badge;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<String> features;
}

const List<_CatalogSlideData> _kCatalogSlides = [
  _CatalogSlideData(
    title: 'المصحف الشريف والتلاوات',
    badge: 'كتاب الله',
    description: 'تجربة قراءة وتدبر قرآنية مريحة تعينك على وردك اليومي بثقة وطمأنينة.',
    icon: Icons.menu_book_rounded,
    accentColor: AppColors.goldDeep,
    features: [
      'مصحف بالرسم العثماني المعتمد مع وضوح تام',
      'تفسير فوري متصل تحت كل آية (الميسر والسعدي)',
      'استماع لأكثر من ١٠ من كبار القرّاء مع تكرار الآيات',
      'فهرس سريع وبحث فوري في نص وسور القرآن',
    ],
  ),
  _CatalogSlideData(
    title: 'مواقيت الصلاة وبوصلة القبلة',
    badge: 'عماد الدين',
    description: 'صلواتك في وقتها بدقة تامة بلا إنترنت أينما كنت حول العالم.',
    icon: Icons.access_time_filled_rounded,
    accentColor: Color(0xFF2E8071),
    features: [
      'حساب دقيق للمواقيت محلياً دون الحاجة لاتصال شبكة',
      'أصوات أذان متنوعة (الحرمين الشريفين، مصر، القدس)',
      'بوصلة ثلاثية الأبعاد تفاعلية لتحديد اتجاه القبلة',
      'عداد تنازلي للصلوات وتنبيهات أذكار ما بعد الصلاة',
    ],
  ),
  _CatalogSlideData(
    title: 'الأذكار والمسبحة وحصن المسلم',
    badge: 'ألا بذكر الله',
    description: 'حصنك اليومي من الأذكار النبوية والمسبحة الذكية لتعمير يومك بالذكر.',
    icon: Icons.fingerprint_rounded,
    accentColor: Color(0xFF1ABC9C),
    features: [
      'أذكار الصباح والمساء بعداد لمسي ذكي وواضح',
      'مسبحة إلكترونية مع اهتزاز تفاعلي يحاكي الواقع',
      'مكتبة حصن المسلم الكاملة (أكثر من ١٣٠ قسماً)',
      'تنبيهات لطيفة تذكرك بالورد في أوقاتك المفضلة',
    ],
  ),
  _CatalogSlideData(
    title: 'الصحبة والتنافس الإيماني',
    badge: 'وتعاونوا على البر',
    description: 'بيئة إيمانية تجمعك مع أهلك وأصحابك للمسارعة في الخيرات والطاعات.',
    icon: Icons.people_alt_rounded,
    accentColor: Color(0xFF2A85FF),
    features: [
      'إنشاء مجموعات خاصة أو الانضمام برمز ورابط مباشر',
      'لوحة تنافس يومية لأعمال اليوم والليلة والسنن',
      'تشجيع متبادل وتواصٍ بالحق وإرسال أدعية بلمسة',
      'خطط ختمة القرآن ومتابعة سلاسل الاستمرار',
    ],
  ),
];

/// غلاف كتالوج التطبيق الخفيف واللطيف — بطاقة عصرية قصيرة وجميلة
/// تعرض أقسام التطبيق وتوصل فكرته دون أي قناع معتم أو حركات مؤذية للعين.
class OnboardingTourOverlay extends StatefulWidget {
  const OnboardingTourOverlay({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  State<OnboardingTourOverlay> createState() => _OnboardingTourOverlayState();
}

class _OnboardingTourOverlayState extends State<OnboardingTourOverlay> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeTour() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingSeenKey, true);
    widget.onDismiss();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _kCatalogSlides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeTour();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slide = _kCatalogSlides[_currentIndex];
    final isLast = _currentIndex == _kCatalogSlides.length - 1;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // خلفية ضبابية خفيفة وهادئة ومريحة
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.40),
              ),
            ),
          ),

          // منطقة النقر للإغلاق السريع خارج البطاقة
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _completeTour,
            ),
          ),

          // البطاقة المركزية الأنيقة والمنسقة
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131F2E) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: slide.accentColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: slide.accentColor.withValues(alpha: 0.15),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الشريط العلوي: زر التخطي ورقم الشريحة وزر الإغلاق
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: _completeTour,
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: isDark ? Colors.white60 : Colors.black45,
                                ),
                                child: const Text(
                                  'تخطي الدليل',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: slide.accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_currentIndex + 1} من ${_kCatalogSlides.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: slide.accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: _completeTour,
                                icon: const Icon(Icons.close_rounded, size: 20),
                                visualDensity: VisualDensity.compact,
                                tooltip: 'إغلاق',
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ],
                          ),
                        ),

                        // محتوى الشرائح القابل للتمرير الأفقي السلس
                        Flexible(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _kCatalogSlides.length,
                            onPageChanged: (idx) {
                              HapticFeedback.selectionClick();
                              setState(() => _currentIndex = idx);
                            },
                            itemBuilder: (context, index) {
                              final item = _kCatalogSlides[index];
                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // أيقونة القسم الكبيرة والمميزة
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: item.accentColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: item.accentColor.withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 34,
                                        color: item.accentColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // شارة وتصنيف
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.accentColor.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        item.badge,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: item.accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // العنوان الرئيسي
                                    Text(
                                      item.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // الوصف التوضيحي اللطيف
                                    Text(
                                      item.description,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.45,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // قائمة المزايا الأربع الأساسية للقسم
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.04)
                                            : Colors.black.withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? Colors.white10 : Colors.black12,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          for (final feat in item.features)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 3.5),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 3),
                                                    child: Icon(
                                                      Icons.check_circle_rounded,
                                                      size: 14,
                                                      color: item.accentColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      feat,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        height: 1.35,
                                                        color: isDark ? Colors.white : Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // شريط المؤشرات وأزرار الانتقال السفلية
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // مؤشر النقاط (Page Indicator Dots)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _kCatalogSlides.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _currentIndex == i ? 22 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _currentIndex == i
                                          ? slide.accentColor
                                          : (isDark ? Colors.white24 : Colors.black12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // زر التالي / ابدأ رحلتك
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _nextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: slide.accentColor,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isLast ? 'ابدأ رحلتك مع هُمَام 🌿' : 'التالي',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isLast ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
