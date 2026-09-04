import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../models/wrapped_data.dart';

class FaithWrappedScreen extends ConsumerStatefulWidget {
  const FaithWrappedScreen({super.key});

  @override
  ConsumerState<FaithWrappedScreen> createState() => _FaithWrappedScreenState();
}

class _FaithWrappedScreenState extends ConsumerState<FaithWrappedScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSlides = 5;
  int _currentSlide = 0;
  late AnimationController _animCtrl;
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextSlide();
        }
      });
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentSlide < _totalSlides - 1) {
      setState(() {
        _currentSlide++;
      });
      _animCtrl.forward(from: 0.0);
    } else {
      _animCtrl.stop();
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() {
        _currentSlide--;
      });
      _animCtrl.forward(from: 0.0);
    } else {
      _animCtrl.forward(from: 0.0);
    }
  }

  void _pause() => _animCtrl.stop();
  void _resume() => _animCtrl.forward();

  Future<void> _shareSummaryCard(FaithWrappedData data) async {
    setState(() => _isSharing = true);
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/humam_weekly_wrapped_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: '✨ حصادي الإيماني لهذا الأسبوع على تطبيق هُمَام:\n'
              '🏆 الوسام: ${data.spiritualBadgeTitle}\n'
              '🕌 الصلوات: ${data.totalPrayers} صلاة\n'
              '📖 القرآن الكريم: ${data.totalQuranPages} صفحة\n'
              '📿 الأذكار: ${data.azkarCompletedDays} أيام',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر مشاركة البطاقة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPrefsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF091118),
      body: FutureBuilder<FaithWrappedData>(
        future: FaithWrappedData.compute(prefs),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'تعذّر تجهيز التقرير: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!;

          return SafeArea(
            child: Stack(
              children: [
                // المحتوى التفاعلي للشريحة الحالية
                GestureDetector(
                  onTapDown: (_) => _pause(),
                  onTapUp: (details) {
                    _resume();
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (details.globalPosition.dx < screenWidth * 0.35) {
                      _prevSlide(); // في الاتجاه العربي اليمين هو التقدم واليسار هو العودة
                    } else {
                      _nextSlide();
                    }
                  },
                  onLongPressStart: (_) => _pause(),
                  onLongPressEnd: (_) => _resume(),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                    child: _buildSlideContent(data),
                  ),
                ),

                // شريط المؤشرات العلوي للقصة (Story Progress Bars)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(_totalSlides, (index) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
                              child: AnimatedBuilder(
                                animation: _animCtrl,
                                builder: (ctx, _) {
                                  double val = 0.0;
                                  if (index < _currentSlide) {
                                    val = 1.0;
                                  } else if (index == _currentSlide) {
                                    val = _animCtrl.value;
                                  }
                                  return LinearProgressIndicator(
                                    value: val,
                                    minHeight: 3.5,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                                    borderRadius: BorderRadius.circular(2),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.auto_awesome, size: 13, color: AppColors.gold),
                                    SizedBox(width: 4),
                                    Text(
                                      'حصاد هُمَام الأسبوعي',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlideContent(FaithWrappedData data) {
    switch (_currentSlide) {
      case 0:
        return _buildIntroSlide(data);
      case 1:
        return _buildQuranSlide(data);
      case 2:
        return _buildPrayersSlide(data);
      case 3:
        return _buildAzkarSlide(data);
      case 4:
      default:
        return _buildGoldenCardSlide(data);
    }
  }

  Widget _buildIntroSlide(FaithWrappedData data) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: const Icon(Icons.stars_rounded, size: 48, color: AppColors.gold),
          ),
          const SizedBox(height: 28),
          Text(
            'مرحباً بك يا ${data.userName} ✨',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'أسبوعٌ مضى في طاعة الله.. تعال نستعرض معاً حصادك الإيماني ونبارك لك ثباتك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.gold),
                const SizedBox(width: 8),
                Text(
                  'انقر للشريحة التالية',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranSlide(FaithWrappedData data) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF04291D), Color(0xFF0A4432), Color(0xFF13684D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF81C784).withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.menu_book_rounded, size: 42, color: Color(0xFF81C784)),
          ),
          const SizedBox(height: 24),
          const Text(
            'نور القرآن الكريم 📖',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            '${data.totalQuranPages}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Color(0xFFA5D6A7),
              height: 1,
            ),
          ),
          const Text(
            'صفحة قرأتها وتدبرتها هذا الأسبوع',
            style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.3)),
            ),
            child: const Text(
              '«اقْرَؤُوا القُرْآنَ فإنَّه يَأْتي يَومَ القِيامَةِ شَفِيعًا لأَصْحابِهِ»',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFFE8F5E9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayersSlide(FaithWrappedData data) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A3A), Color(0xFF272757), Color(0xFF3B3B82)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.mosque_rounded, size: 42, color: Color(0xFFFFD54F)),
          ),
          const SizedBox(height: 24),
          const Text(
            'الصلوات المكتوبة والسنن 🕌',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            '${data.totalPrayers}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFE082),
              height: 1,
            ),
          ),
          const Text(
            'صلاة فرض حافظت عليها في وقتها',
            style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            '+ ${data.totalSunnahs} ركعة سنة ورواتب أحييت بها يومك',
            style: const TextStyle(fontSize: 13.5, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildAzkarSlide(FaithWrappedData data) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2B1B17), Color(0xFF4A2C25), Color(0xFF6B3F35)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFAB91).withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.nights_stay_rounded, size: 42, color: Color(0xFFFFAB91)),
          ),
          const SizedBox(height: 24),
          const Text(
            'الأذكار وقيام الليل 📿',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            '${data.azkarCompletedDays}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFCCBC),
              height: 1,
            ),
          ),
          const Text(
            'أيام اكتملت فيها أذكارك الصباحية والمسائية',
            style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          if (data.qiyamNights > 0) ...[
            const SizedBox(height: 14),
            Text(
              'وقمت الليل في ${data.qiyamNights} ليالٍ مباركة 🌙',
              style: const TextStyle(fontSize: 14, color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoldenCardSlide(FaithWrappedData data) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // بطاقة التلخيص الذهبية
          RepaintBoundary(
            key: _shareCardKey,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1708), Color(0xFF2D260D), Color(0xFF3D3212)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.gold, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(data.spiritualBadgeIcon, size: 28, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text(
                        data.spiritualBadgeTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.spiritualBadgeQuote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatPill('🕌 الصلوات', '${data.totalPrayers}'),
                      _buildStatPill('📖 القرآن', '${data.totalQuranPages} ص'),
                      _buildStatPill('📿 الأذكار', '${data.azkarCompletedDays} أيام'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تطبيق هُمَام • حصاد الأسبوع المبارك ✨',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // زر مشاركة البطاقة
          AppPrimaryButton(
            label: _isSharing ? 'جارٍ التجهيز...' : 'مشاركة بطاقة الإنجاز 🚀',
            icon: Icons.share_rounded,
            color: AppColors.gold,
            foregroundColor: Colors.black,
            loading: _isSharing,
            onPressed: _isSharing ? null : () => _shareSummaryCard(data),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ],
    );
  }
}
