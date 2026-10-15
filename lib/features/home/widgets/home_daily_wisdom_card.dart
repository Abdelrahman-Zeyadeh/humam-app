import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/data/names_of_allah/names_of_allah_data.dart';
import '../../audio/reciters.dart' show ayahAudioUrl;
import '../../hadith/daily_hadith_screen.dart';
import '../../mushaf/mushaf_settings.dart' show mushafJumpRequestProvider;
import '../../names_of_allah/names_of_allah_screen.dart';
import '../../shell/root_shell.dart';
import '../../story_maker/models/story_content.dart';
import '../../story_maker/ui/ayah_story_maker_screen.dart';
import '../home_dashboard_data.dart';

/// بطاقة «قبس اليوم» التفاعلية بنظام السحب والتصفح (Swipeable Carousel) —
/// تعرض أولاً «آية اليوم» منفردة بتصميم ملكي ملون غير أبيض، وعند السحب لليمين
/// تنتقل بانسيابية إلى «حديث اليوم» ثم «اسم من أسماء الله الحسنى»، مع زر مشاركة كبطاقة ستوري.
class HomeDailyWisdomCard extends ConsumerStatefulWidget {
  const HomeDailyWisdomCard({super.key, required this.data});
  final HomeDashboardData data;

  @override
  ConsumerState<HomeDailyWisdomCard> createState() =>
      _HomeDailyWisdomCardState();
}

class _HomeDailyWisdomCardState extends ConsumerState<HomeDailyWisdomCard> {
  late final PageController _pageController;
  int _currentPage = 0; // 0: آية اليوم, 1: حديث اليوم, 2: اسم الله الحسنى
  AudioPlayer? _ayahPlayer;
  StreamSubscription<PlayerState>? _playerSub;
  bool _isAyahPlaying = false;
  bool _isAyahLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _ayahPlayer?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayAyah(int surah, int ayahNumber) async {
    if (_isAyahPlaying) {
      await _ayahPlayer?.pause();
      if (mounted) setState(() => _isAyahPlaying = false);
      return;
    }

    _ayahPlayer ??= AudioPlayer();
    _playerSub ??= _ayahPlayer!.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isAyahPlaying = false;
          _isAyahLoading = false;
        });
      }
    });

    setState(() => _isAyahLoading = true);
    try {
      final url = ayahAudioUrl('ghamadi', surah, ayahNumber);
      await _ayahPlayer!.setUrl(url);
      await _ayahPlayer!.play();
      if (mounted) {
        setState(() {
          _isAyahLoading = false;
          _isAyahPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Ayah audio play error: $e');
      if (mounted) {
        setState(() {
          _isAyahLoading = false;
          _isAyahPlaying = false;
        });
      }
    }
  }

  void _goToPage(int index) {
    final target = index % 3;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final hadith = kCuratedDailyHadiths[dayOfYear % kCuratedDailyHadiths.length];
    final nameItem =
        NamesOfAllahData.items[dayOfYear % NamesOfAllahData.items.length];
    final ayah = widget.data.ayahOfDay;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 198,
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            if (mounted) {
              setState(() => _currentPage = index);
            }
          },
          children: [
            // الصفحة ٠: آية اليوم (تظهر أولاً لحالها بلون زمردي ملكي فاخر)
            _buildAyahSlide(context, ayah, hadith, nameItem),
            // الصفحة ١: حديث اليوم (تظهر عند السحب بلون فيروزي ياقوتي)
            _buildHadithSlide(context, ayah, hadith, nameItem),
            // الصفحة ٢: اسم من أسماء الله الحسنى (تظهر عند السحب بلون عنبري ذهبي)
            _buildNameSlide(context, ayah, hadith, nameItem),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahSlide(
    BuildContext context,
    dynamic ayah,
    dynamic hadith,
    dynamic nameItem,
  ) {
    final surahLabel = widget.data.ayahOfDaySurah.startsWith('سورة')
        ? widget.data.ayahOfDaySurah
        : 'سورة ${widget.data.ayahOfDaySurah}';

    return _WisdomSlideContainer(
      gradientColors: const [
        Color(0xFF0E4D40),
        Color(0xFF156956),
        Color(0xFF09352B),
      ],
      borderColor: const Color(0xFFD4AF67).withValues(alpha: 0.5),
      shadowColor: const Color(0xFF0E4D40).withValues(alpha: 0.28),
      onCardTap: () {
        ref.read(mushafJumpRequestProvider.notifier).request(
              page: ayah.page,
              ayahId: ayah.id,
            );
        ref.read(rootTabIndexProvider.notifier).select(1);
      },
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF67).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF67).withValues(alpha: 0.45),
                width: 0.9,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: Color(0xFFF5D78E),
                ),
                SizedBox(width: 5),
                Text(
                  'آية اليوم',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF5D78E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$surahLabel • آية ${ayah.ayah}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          const Spacer(),
          _AyahAudioListenChip(
            isPlaying: _isAyahPlaying,
            isLoading: _isAyahLoading,
            onTap: () => _togglePlayAyah(ayah.surah, ayah.ayah),
          ),
          const SizedBox(width: 6),
          _StoryShareChip(
            onTap: () => _openStoryMaker(context, 0, ayah, hadith, nameItem),
          ),
        ],
      ),
      body: Center(
        child: Text(
          '﴿ ${ayah.textUthmani} ﴾',
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'AmiriQuran',
            fontSize: 17,
            height: 1.75,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFBF2),
          ),
        ),
      ),
      footer: _SlideFooterBar(
        currentPage: _currentPage,
        onDotTap: _goToPage,
        actionLabel: 'افتح في المصحف',
        onActionTap: () {
          ref.read(mushafJumpRequestProvider.notifier).request(
                page: ayah.page,
                ayahId: ayah.id,
              );
          ref.read(rootTabIndexProvider.notifier).select(1);
        },
        nextSwipeLabel: 'اسحب لحديث اليوم',
        onNextTap: () => _goToPage(1),
      ),
    );
  }

  Widget _buildHadithSlide(
    BuildContext context,
    dynamic ayah,
    dynamic hadith,
    dynamic nameItem,
  ) {
    return _WisdomSlideContainer(
      gradientColors: const [
        Color(0xFF124559),
        Color(0xFF1A617A),
        Color(0xFF0C2E3D),
      ],
      borderColor: const Color(0xFFD4AF67).withValues(alpha: 0.45),
      shadowColor: const Color(0xFF124559).withValues(alpha: 0.28),
      onCardTap: () {
        final hadithIndex = kCuratedDailyHadiths.indexOf(hadith);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DailyHadithScreen(
              initialIndex: hadithIndex != -1 ? hadithIndex : null,
              initialHadithId: hadith.id,
              scrollToFawaid: true,
            ),
          ),
        );
      },
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5D78E).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF5D78E).withValues(alpha: 0.45),
                width: 0.9,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 14,
                  color: Color(0xFFF5D78E),
                ),
                SizedBox(width: 5),
                Text(
                  'حديث اليوم',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF5D78E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${hadith.source} • ${hadith.narrator}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
          const Spacer(),
          _StoryShareChip(
            onTap: () => _openStoryMaker(context, 1, ayah, hadith, nameItem),
          ),
        ],
      ),
      body: Center(
        child: Text(
          '«${hadith.matn}»',
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFBF2),
          ),
        ),
      ),
      footer: _SlideFooterBar(
        currentPage: _currentPage,
        onDotTap: _goToPage,
        actionLabel: 'الفوائد والشرح',
        onActionTap: () {
          final hadithIndex = kCuratedDailyHadiths.indexOf(hadith);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DailyHadithScreen(
                initialIndex: hadithIndex != -1 ? hadithIndex : null,
                initialHadithId: hadith.id,
                scrollToFawaid: true,
              ),
            ),
          );
        },
        nextSwipeLabel: 'اسحب لاسم الله',
        onNextTap: () => _goToPage(2),
      ),
    );
  }

  Widget _buildNameSlide(
    BuildContext context,
    dynamic ayah,
    dynamic hadith,
    dynamic nameItem,
  ) {
    return _WisdomSlideContainer(
      gradientColors: const [
        Color(0xFF4A3319),
        Color(0xFF6B4A24),
        Color(0xFF332210),
      ],
      borderColor: const Color(0xFFD4AF67).withValues(alpha: 0.55),
      shadowColor: const Color(0xFF4A3319).withValues(alpha: 0.28),
      onCardTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NamesOfAllahScreen()),
      ),
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5D78E).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF5D78E).withValues(alpha: 0.45),
                width: 0.9,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 13.5,
                  color: Color(0xFFF5D78E),
                ),
                SizedBox(width: 5),
                Text(
                  'من أسماء الله الحسنى',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF5D78E),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _StoryShareChip(
            onTap: () => _openStoryMaker(context, 2, ayah, hadith, nameItem),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nameItem.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 24,
                height: 1.25,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5D78E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nameItem.meaning,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      footer: _SlideFooterBar(
        currentPage: _currentPage,
        onDotTap: _goToPage,
        actionLabel: 'كافة الأسماء الحسنى',
        onActionTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NamesOfAllahScreen()),
        ),
        nextSwipeLabel: 'آية اليوم',
        onNextTap: () => _goToPage(0),
      ),
    );
  }

  void _openStoryMaker(
    BuildContext context,
    int tabIndex,
    dynamic ayah,
    dynamic hadith,
    dynamic nameItem,
  ) {
    final StoryContent content;
    switch (tabIndex) {
      case 0:
        content = AyahContent(
          ayahId: ayah.id,
          text: ayah.textUthmani,
          surahName: widget.data.ayahOfDaySurah,
          ayahNumber: ayah.ayah,
        );
        break;
      case 1:
        content = HadithContent(
          hadithText: hadith.matn,
          narrator: hadith.narrator,
          sourceBook: '${hadith.source} (${hadith.grade})',
          explanation: hadith.fawaid.isNotEmpty ? hadith.fawaid.first : null,
        );
        break;
      case 2:
      default:
        content = NameOfAllahContent(
          name: nameItem.name,
          meaning: nameItem.meaning,
          tadabbur: nameItem.tadabbur,
          dua: nameItem.dua,
        );
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahStoryMakerScreen(initialContent: content),
      ),
    );
  }
}

class _WisdomSlideContainer extends StatelessWidget {
  const _WisdomSlideContainer({
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    required this.onCardTap,
    required this.header,
    required this.body,
    required this.footer,
  });

  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final VoidCallback onCardTap;
  final Widget header;
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap,
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _WisdomOrnamentPainter(
                    color: const Color(0xFFD4AF67).withValues(alpha: 0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 6),
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: body,
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 6),
                    footer,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryShareChip extends StatelessWidget {
  const _StoryShareChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFF5D78E).withValues(alpha: 0.45),
            width: 0.9,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette_outlined, size: 12.5, color: Color(0xFFF5D78E)),
            SizedBox(width: 4),
            Text(
              'بطاقة',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF5D78E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahAudioListenChip extends StatelessWidget {
  const _AyahAudioListenChip({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = isPlaying
        ? const Color(0xFF55E6C1)
        : const Color(0xFFF5D78E);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFF55E6C1).withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activeColor.withValues(alpha: isPlaying ? 0.8 : 0.45),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                ),
              )
            else
              Icon(
                isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                size: 13,
                color: activeColor,
              ),
            const SizedBox(width: 4),
            Text(
              isPlaying ? 'إيقاف' : 'استمع',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideFooterBar extends StatelessWidget {
  const _SlideFooterBar({
    required this.currentPage,
    required this.onDotTap,
    required this.actionLabel,
    this.onActionTap,
    required this.nextSwipeLabel,
    required this.onNextTap,
  });

  final int currentPage;
  final ValueChanged<int> onDotTap;
  final String actionLabel;
  final VoidCallback? onActionTap;
  final String nextSwipeLabel;
  final VoidCallback onNextTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // يمين التذييل: رابط فتح التفاصيل
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // مؤشر النقاط التفاعلي للصفحات الثلاث
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final active = currentPage == index;
            return GestureDetector(
              onTap: () => onDotTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFF5D78E)
                      : Colors.white.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 6),
        // يسار التذييل: تلميح السحب/التصفح التفاعلي
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: InkWell(
              onTap: onNextTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.swipe_rounded,
                      size: 12,
                      color: Color(0xFFF5D78E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nextSwipeLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5D78E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WisdomOrnamentPainter extends CustomPainter {
  const _WisdomOrnamentPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final w = size.width;
    final h = size.height;

    // زخرفة هندسية ناعمة على الزاويتين
    final centerLeft = Offset(w * 0.12, h * 0.5);
    const radius = 36.0;
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      final petal = Offset(
        centerLeft.dx + (radius * 0.5) * math.cos(angle),
        centerLeft.dy + (radius * 0.5) * math.sin(angle),
      );
      canvas.drawCircle(petal, radius * 0.42, paint);
    }

    final arch = Path()
      ..moveTo(w * 0.04, h)
      ..lineTo(w * 0.04, h * 0.3)
      ..quadraticBezierTo(w * 0.04, h * 0.05, w * 0.5, h * 0.03)
      ..quadraticBezierTo(w * 0.96, h * 0.05, w * 0.96, h * 0.3)
      ..lineTo(w * 0.96, h);
    canvas.drawPath(arch, paint);
  }

  @override
  bool shouldRepaint(covariant _WisdomOrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}
