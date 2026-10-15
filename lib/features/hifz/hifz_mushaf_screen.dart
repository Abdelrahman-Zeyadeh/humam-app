import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../../core/text/arabic_normalizer.dart'
    show stripQuranicMarksForDisplay, surahShortName;
import '../mushaf/widgets/ayah_share_format.dart' show toArabicDigits;
import '../../core/theme/app_colors.dart';
import '../../core/theme/mushaf_palettes.dart';
import '../mushaf/mushaf_page_widget.dart';
import '../mushaf/mushaf_screen.dart' show kMushafPageCount;
import '../mushaf/mushaf_settings.dart';
import '../mushaf/mushaf_surah_index_sheet.dart';
import '../mushaf/widgets/mushaf_chrome_bars.dart' show PageIdentityBar;
import 'hifz_heatmap_screen.dart';

/// أنماط مصحف الحفظ والتثبيت
enum HifzMushafMode {
  /// وضع التثبيت والمراجعة — تصفح المصحف بنصوصه العثمانية مع إخفاء الآيات وتثبيتها
  review,

  /// وضع اختبار الحفظ — أسئلة استحضار وإكمال واختبار الآيات على صفحة المصحف مباشرة
  quiz,
}

/// نطاق الاختبار داخل المصحف
enum HifzQuizScopeType {
  /// الصفحة المفتوحة حالياً بالمصحف
  currentPage,

  /// سورة كاملة
  surah,

  /// جزء كامل
  juz,

  /// نطاق خطة الحفظ
  plan,
}

/// مصحف الحفظ والتثبيت والاختبار المخصص:
/// يوفر تجربة قرآنية أصيلة وتفاعلية مباشرة على صفحات المصحف الحقيقية:
/// ١. وضع التثبيت والمراجعة: حجب الآيات وكشفها باللمس، وتثبيت الصفحة بضغطة زر.
/// ٢. وضع اختبار الحفظ: استحضار الآيات واختبارها مع القفز التلقائي لصفحة الآية بالمصحف.
class HifzMushafScreen extends ConsumerStatefulWidget {
  const HifzMushafScreen({
    super.key,
    this.initialPage,
    this.initialMode = HifzMushafMode.review,
    this.planId,
    this.initialSurahId,
    this.initialJuz,
  });

  final int? initialPage;
  final HifzMushafMode initialMode;
  final int? planId;
  final int? initialSurahId;
  final int? initialJuz;

  @override
  ConsumerState<HifzMushafScreen> createState() => _HifzMushafScreenState();
}

class _HifzMushafScreenState extends ConsumerState<HifzMushafScreen> {
  late final PageController _pageController;
  late int _currentPage;
  late HifzMushafMode _currentMode;

  // --- حالة التثبيت ---
  List<Ayah> _currentPageAyahs = [];
  Map<int, String> _masteryMap = {};

  // --- حالة الاختبار ---
  HifzQuizScopeType _quizScopeType = HifzQuizScopeType.currentPage;
  int _quizSurahId = 1;
  int _quizJuz = 1;
  bool _quizActive = false;
  List<Ayah> _quizAyahsPool = [];
  int _quizTotalQuestions = 5;
  int _quizCurrentQuestionIndex = 0;
  int _quizScore = 0;
  Ayah? _quizCurrentAyah;
  String _quizPrompt = '';
  List<String> _quizOptions = [];
  int _quizCorrectOptionIndex = 0;
  int? _quizSelectedOption;
  bool _quizAnswered = false;
  bool _quizAyahRevealedOnMushaf = false;
  final Random _rng = Random();

  late final MemorizationModeNotifier _memNotifier;
  late final RevealedAyahsNotifier _revealedNotifier;

  @override
  void initState() {
    super.initState();
    _memNotifier = ref.read(memorizationModeProvider.notifier);
    _revealedNotifier = ref.read(revealedAyahsProvider.notifier);
    _currentMode = widget.initialMode;
    _currentPage = (widget.initialPage ?? 1).clamp(1, kMushafPageCount);
    _pageController = PageController(initialPage: _currentPage - 1);

    if (widget.initialSurahId != null) {
      _quizSurahId = widget.initialSurahId!;
      _quizScopeType = HifzQuizScopeType.surah;
    } else if (widget.initialJuz != null) {
      _quizJuz = widget.initialJuz!;
      _quizScopeType = HifzQuizScopeType.juz;
    } else if (widget.planId != null) {
      _quizScopeType = HifzQuizScopeType.plan;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // تفعيل وضع الحفظ تلقائياً في مصحف التثبيت
      _memNotifier.set(true);
      _loadPageData(_currentPage);
      if (_currentMode == HifzMushafMode.quiz) {
        _startQuiz();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPageData(int page) async {
    final quran = ref.read(quranRepositoryProvider);
    final hifz = ref.read(hifzPrefsProvider);

    final ayahs = await quran.ayahsForPage(page);
    final mastery = await hifz.allMasteryMap();

    if (!mounted) return;
    setState(() {
      _currentPageAyahs = ayahs;
      _masteryMap = mastery;
    });

    // تحديث خطة الحفظ النشطة عند التقليب إن وجدت
    if (widget.planId != null && ayahs.isNotEmpty) {
      unawaited(hifz.updateCurrentAyah(widget.planId!, ayahs.first.id));
      ref.read(hifzVersionProvider.notifier).bump();
    }
  }

  void _onPageChanged(int index) {
    final newPage = index + 1;
    setState(() => _currentPage = newPage);
    _loadPageData(newPage);
  }

  void _jumpToPage(int page) {
    final clamped = page.clamp(1, kMushafPageCount);
    _pageController.jumpToPage(clamped - 1);
    setState(() => _currentPage = clamped);
    _loadPageData(clamped);
  }

  // --- إجراءات التثبيت ---

  Future<void> _masterCurrentPage() async {
    if (_currentPageAyahs.isEmpty) return;
    final ids = _currentPageAyahs.map((a) => a.id).toList();
    final hifz = ref.read(hifzPrefsProvider);

    await hifz.setMultipleAyahsMasteryStatus(ids, 'mastered');
    await ref
        .read(userPrefsProvider)
        .bumpCategoryStreakIfNewDay(UserCategories.hifz);
    ref.read(categoryStreakVersionProvider.notifier).bump();
    ref.read(hifzVersionProvider.notifier).bump();

    await _loadPageData(_currentPage);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تم تثبيت صفحة $_currentPage كاملة بنجاح (${ids.length} آية متقنة) ⭐',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _revealAllOnPage() {
    if (_currentPageAyahs.isEmpty) return;
    final ids = _currentPageAyahs.map((a) => a.id);
    ref.read(revealedAyahsProvider.notifier).revealAll(ids);
  }

  void _hideAllOnPage() {
    ref.read(revealedAyahsProvider.notifier).hideAll();
  }

  void _toggleMemorizationShading() {
    ref.read(memorizationModeProvider.notifier).toggle();
  }

  // --- إجراءات الاختبار ---

  Future<void> _startQuiz() async {
    final quran = ref.read(quranRepositoryProvider);
    List<Ayah> pool = [];

    switch (_quizScopeType) {
      case HifzQuizScopeType.currentPage:
        pool = await quran.ayahsForPage(_currentPage);
        break;
      case HifzQuizScopeType.surah:
        pool = await quran.ayahsForSurah(_quizSurahId);
        break;
      case HifzQuizScopeType.juz:
        pool = await quran.ayahsForJuz(_quizJuz);
        break;
      case HifzQuizScopeType.plan:
        if (widget.planId != null) {
          final plans = ref.read(hifzPrefsProvider).plans;
          final currentPlan = plans.cast<HifzPlan?>().firstWhere(
            (p) => p?.id == widget.planId,
            orElse: () => null,
          );
          if (currentPlan != null) {
            pool = await quran.ayahsInIdRange(
              currentPlan.fromAyahId,
              currentPlan.toAyahId,
            );
          }
        }
        if (pool.isEmpty) {
          pool = await quran.ayahsForPage(_currentPage);
        }
        break;
    }

    if (pool.isEmpty) return;

    setState(() {
      _quizAyahsPool = pool;
      _quizTotalQuestions = min(5, pool.length);
      _quizCurrentQuestionIndex = 0;
      _quizScore = 0;
      _quizActive = true;
      _currentMode = HifzMushafMode.quiz;
    });

    _generateNextQuizQuestion();
  }

  Future<void> _generateNextQuizQuestion() async {
    if (_quizAyahsPool.isEmpty) return;

    final target = _quizAyahsPool[_rng.nextInt(_quizAyahsPool.length)];
    final quran = ref.read(quranRepositoryProvider);
    final surah = await quran.surahById(target.surah);

    // القفز التلقائي لصفحة الآية في المصحف
    if (target.page != _currentPage) {
      _jumpToPage(target.page);
    }

    // إخفاء الآية بالمصحف للاختبار
    ref.read(revealedAyahsProvider.notifier).hide(target.id);
    ref.read(memorizationModeProvider.notifier).set(true);

    final isNextAyahTest = _rng.nextBool();
    String prompt;
    String correctAnswer;
    List<String> distractors = [];

    if (isNextAyahTest) {
      prompt = 'ما هي الآية التالية لقوله تعالى في سورة ${surahShortName(surah.nameAr)}؟';
      correctAnswer = stripQuranicMarksForDisplay(target.textUthmani);

      // جمع مشتتات من نفس السورة أو النطاق
      final others = _quizAyahsPool.where((a) => a.id != target.id).toList()
        ..shuffle(_rng);
      for (final o in others) {
        final text = stripQuranicMarksForDisplay(o.textUthmani);
        if (text != correctAnswer && !distractors.contains(text)) {
          distractors.add(text);
          if (distractors.length >= 3) break;
        }
      }
      while (distractors.length < 3) {
        distractors.add('﴿ إِنَّ اللَّهَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ ﴾');
      }
    } else {
      // إكمال شطر الآية
      final cleanTargetText = stripQuranicMarksForDisplay(target.textUthmani);
      final words = cleanTargetText.trim().split(RegExp(r'\s+'));
      if (words.length > 3) {
        final cut = (words.length * 0.4).ceil().clamp(1, words.length - 1);
        final startSnippet = words.take(cut).join(' ');
        prompt =
            'أكمل قوله تعالى في سورة ${surahShortName(surah.nameAr)} (آية ${target.ayah}):\n« $startSnippet ... »';
        correctAnswer = words.skip(cut).join(' ');

        final others = _quizAyahsPool.where((a) => a.id != target.id).toList()
          ..shuffle(_rng);
        for (final o in others) {
          final cleanOther = stripQuranicMarksForDisplay(o.textUthmani);
          final oWords = cleanOther.trim().split(RegExp(r'\s+'));
          if (oWords.length > 2) {
            final dText = oWords.skip(1).join(' ');
            if (dText != correctAnswer && !distractors.contains(dText)) {
              distractors.add(dText);
              if (distractors.length >= 3) break;
            }
          }
        }
        while (distractors.length < 3) {
          distractors.add('وَكَانَ اللَّهُ غَفُورًا رَّحِيمًا');
        }
      } else {
        prompt =
            'استحضر وتأكد من قراءة الآية الكريمة (${target.ayah}) من سورة ${surahShortName(surah.nameAr)}:';
        correctAnswer = cleanTargetText;
        distractors = [
          'صحيحة تماماً',
          'تحتاج مراجعة',
          'غير مكتملة',
        ];
      }
    }

    final allOptions = [correctAnswer, ...distractors]..shuffle(_rng);

    if (!mounted) return;
    setState(() {
      _quizCurrentAyah = target;
      _quizPrompt = prompt;
      _quizOptions = allOptions;
      _quizCorrectOptionIndex = allOptions.indexOf(correctAnswer);
      _quizSelectedOption = null;
      _quizAnswered = false;
      _quizAyahRevealedOnMushaf = false;
    });
  }

  void _submitQuizAnswer(int selectedIndex) {
    if (_quizAnswered) return;
    final isCorrect = selectedIndex == _quizCorrectOptionIndex;

    setState(() {
      _quizAnswered = true;
      _quizSelectedOption = selectedIndex;
      if (isCorrect) {
        _quizScore++;
        if (_quizCurrentAyah != null) {
          ref
              .read(hifzPrefsProvider)
              .setAyahMasteryStatus(_quizCurrentAyah!.id, 'mastered');
          ref.read(hifzVersionProvider.notifier).bump();
        }
      }
    });

    // كشف الآية تلقائياً على المصحف للتحقق
    _revealQuizAyahOnMushaf();
  }

  void _revealQuizAyahOnMushaf() {
    if (_quizCurrentAyah == null) return;
    ref.read(revealedAyahsProvider.notifier).reveal(_quizCurrentAyah!.id);
    setState(() => _quizAyahRevealedOnMushaf = true);
  }

  void _handleSelfEvaluation({required bool isMastered}) {
    if (_quizAnswered) return;
    setState(() {
      _quizAnswered = true;
      if (isMastered) {
        _quizScore++;
        if (_quizCurrentAyah != null) {
          ref
              .read(hifzPrefsProvider)
              .setAyahMasteryStatus(_quizCurrentAyah!.id, 'mastered');
          ref.read(hifzVersionProvider.notifier).bump();
        }
      }
    });
    _revealQuizAyahOnMushaf();
  }

  void _goToNextQuizQuestionOrFinish() {
    if (_quizCurrentQuestionIndex + 1 < _quizTotalQuestions) {
      setState(() => _quizCurrentQuestionIndex++);
      _generateNextQuizQuestion();
    } else {
      _showQuizSummaryDialog();
    }
  }

  Future<void> _showQuizSummaryDialog() async {
    // زيادة سلسلة الحفظ عند إتمام الاختبار
    await ref
        .read(userPrefsProvider)
        .bumpCategoryStreakIfNewDay(UserCategories.hifz);
    ref.read(categoryStreakVersionProvider.notifier).bump();

    if (!mounted) return;
    final percentage = ((_quizScore / _quizTotalQuestions) * 100).round();
    final isExcellent = percentage >= 80;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isExcellent ? Icons.emoji_events_rounded : Icons.psychology_rounded,
              color: isExcellent ? Colors.amber : AppColors.teal,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'نتيجة اختبار الحفظ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_quizScore / $_quizTotalQuestions',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isExcellent ? AppColors.teal : AppColors.purple,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$percentage٪ إتقان',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isExcellent
                ? 'ما شاء الله تبارك الله! حفظ متقن ومثبت، بارك الله في صدرك ونفع بك.'
                : 'أحسنت المحاولة! التكرار مفتاح التثبيت الراسخ، داوم على المراجعة.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _quizActive = false;
                _currentMode = HifzMushafMode.review;
              });
            },
            child: const Text('العودة للمصحف والتثبيت'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة الاختبار'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _startQuiz();
            },
          ),
        ],
      ),
    );
  }

  void _showScopePickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر نطاق الاختبار بالمصحف',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.teal),
                title: Text('الصفحة الحالية (ص $_currentPage)'),
                subtitle: const Text('اختبار الآيات في الصفحة المعروضة فقط'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  setState(() => _quizScopeType = HifzQuizScopeType.currentPage);
                  _startQuiz();
                },
              ),
              if (widget.planId != null)
                ListTile(
                  leading: const Icon(Icons.bookmark_outline, color: AppColors.purple),
                  title: const Text('نطاق خطة الحفظ النشطة'),
                  subtitle: const Text('اختبار الآيات المحفوظة ضمن خطتك'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    setState(() => _quizScopeType = HifzQuizScopeType.plan);
                    _startQuiz();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined, color: AppColors.blue),
                title: const Text('سورة من المصحف'),
                subtitle: const Text('اختيار سورة كاملة لاختبار حفظها'),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final picked = await MushafSurahIndexSheet.show(context, currentPage: _currentPage);
                  if (picked != null) {
                    _jumpToPage(picked);
                    setState(() => _quizScopeType = HifzQuizScopeType.currentPage);
                    _startQuiz();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(mushafPaletteVersionProvider);
    ref.watch(accentColorVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final palette = mushafPaletteById(
      userPrefs.mushafPaletteId,
      accentId: userPrefs.accentColorId,
    );
    final bg = palette.bg(isDark);
    final fg = palette.fg(isDark);
    final textSize = ref.watch(mushafTextSizeProvider);
    final isMemorizationOn = ref.watch(memorizationModeProvider);

    // حساب إحصائية إتقان الصفحة الحالية
    final pageAyahIds = _currentPageAyahs.map((a) => a.id).toSet();
    final masteredOnPageCount = pageAyahIds.where((id) => _masteryMap[id] == 'mastered').length;
    final totalOnPageCount = _currentPageAyahs.length;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _memNotifier.set(false);
          _revealedNotifier.hideAll();
        }
      },
      child: Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.navy],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const BackButton(color: Colors.white),
                  Expanded(
                    child: Center(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeTab(
                              title: 'تثبيت ومراجعة',
                              icon: Icons.menu_book_rounded,
                              isActive: _currentMode == HifzMushafMode.review,
                              onTap: () {
                                setState(() {
                                  _currentMode = HifzMushafMode.review;
                                  _quizActive = false;
                                });
                                ref.read(memorizationModeProvider.notifier).set(true);
                              },
                            ),
                            _buildModeTab(
                              title: 'إختبار الحفظ',
                              icon: Icons.psychology_rounded,
                              isActive: _currentMode == HifzMushafMode.quiz,
                              onTap: () {
                                setState(() => _currentMode = HifzMushafMode.quiz);
                                _startQuiz();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_on_rounded, color: Colors.white, size: 20),
                    tooltip: 'خريطة إتقان الحفظ',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HifzHeatmapScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // شريط هوية الصفحة (السورة، الجزء، الحزب)
          PageIdentityBar(
            bg: bg,
            fg: fg,
            page: _currentPage,
            onSurahTap: () async {
              final picked = await MushafSurahIndexSheet.show(context, currentPage: _currentPage);
              if (picked != null) _jumpToPage(picked);
            },
            onJuzTap: () async {
              final picked = await MushafSurahIndexSheet.show(
                context,
                currentPage: _currentPage,
                openJuzTab: true,
              );
              if (picked != null) _jumpToPage(picked);
            },
          ),

          // شريط تنبيه الحفظ الذكي
          _buildHifzStatusStrip(
            isDark: isDark,
            isMemorizationOn: isMemorizationOn,
            masteredCount: masteredOnPageCount,
            totalCount: totalOnPageCount,
          ),

          // عرض صفحة المصحف الحقيقية
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: kMushafPageCount,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final page = index + 1;
                    return RepaintBoundary(
                      key: ValueKey('hifz_mushaf_page_${page}_${textSize.name}'),
                      child: MediaQuery.withNoTextScaling(
                        child: MushafPageWidget(page: page),
                      ),
                    );
                  },
                ),

                // بطاقة الاختبار التفاعلية العائمة بأسفل المصحف
                if (_currentMode == HifzMushafMode.quiz && _quizActive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: _buildQuizDockCard(isDark: isDark),
                  ),
              ],
            ),
          ),

          // لوحة أدوات تثبيت الحفظ (في وضع المراجعة)
          if (_currentMode == HifzMushafMode.review)
            _buildReviewToolbar(
              isDark: isDark,
              isMemorizationOn: isMemorizationOn,
              masteredCount: masteredOnPageCount,
              totalCount: totalOnPageCount,
            ),

          // رقم الصفحة بالأسفل
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Center(
              child: Text(
                toArabicDigits(_currentPage),
                style: TextStyle(
                  color: fg.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? AppColors.navy : Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? AppColors.navy : Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHifzStatusStrip({
    required bool isDark,
    required bool isMemorizationOn,
    required int masteredCount,
    required int totalCount,
  }) {
    final accent = themeAccent(context);
    final isMasteredAll = totalCount > 0 && masteredCount == totalCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: isDark ? const Color(0xFF1E222A) : const Color(0xFFF0F4F8),
      child: Row(
        children: [
          Icon(
            isMasteredAll ? Icons.verified_rounded : Icons.psychology_outlined,
            size: 16,
            color: isMasteredAll ? const Color(0xFF2E7D32) : accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _currentMode == HifzMushafMode.review
                  ? (isMasteredAll
                      ? 'الصفحة مثبتة ومتقنة بالكامل ⭐'
                      : 'اضغط على أي آية محجوبة لكشفها والتحقق من حفظك')
                  : 'اختبر حفظك: استحضر الآية ثم اكشفها على المصحف',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isMasteredAll ? const Color(0xFF2E7D32) : accent).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isMasteredAll ? const Color(0xFF2E7D32) : accent).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                '$masteredCount / $totalCount متقنة',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isMasteredAll ? const Color(0xFF2E7D32) : accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewToolbar({
    required bool isDark,
    required bool isMemorizationOn,
    required int masteredCount,
    required int totalCount,
  }) {
    final isMasteredAll = totalCount > 0 && masteredCount == totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // زر تثبيت الصفحة كاملة
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                icon: Icon(
                  isMasteredAll ? Icons.check_circle_rounded : Icons.star_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  isMasteredAll ? 'صفحة متقنة ⭐' : 'تثبيت الصفحة كاملة ⭐',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isMasteredAll ? const Color(0xFF2E7D32) : AppColors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _masterCurrentPage,
              ),
            ),
            const SizedBox(width: 8),

            // زر إخفاء / كشف الكل
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                icon: Icon(
                  isMemorizationOn ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 16,
                ),
                label: Text(
                  isMemorizationOn ? 'كشف الكل' : 'إخفاء الكل',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (isMemorizationOn) {
                    _revealAllOnPage();
                  } else {
                    _hideAllOnPage();
                  }
                  _toggleMemorizationShading();
                },
              ),
            ),
            const SizedBox(width: 8),

            // زر اختبار سريع للصفحة
            IconButton.filledTonal(
              tooltip: 'اختبر حفظ هذه الصفحة',
              icon: const Icon(Icons.quiz_outlined, size: 20),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _quizScopeType = HifzQuizScopeType.currentPage;
                  _currentMode = HifzMushafMode.quiz;
                });
                _startQuiz();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizDockCard({required bool isDark}) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      constraints: BoxConstraints(maxHeight: screenH * 0.52),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط رأس الاختبار المصغر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'سؤال ${_quizCurrentQuestionIndex + 1} من $_quizTotalQuestions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'النقاط: $_quizScore',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showScopePickerSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'تغيير النطاق',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'إغلاق الاختبار',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _quizActive = false;
                      _currentMode = HifzMushafMode.review;
                    });
                  },
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // نص السؤال
                Text(
                  _quizPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                // خيارات الإجابة
                for (var i = 0; i < _quizOptions.length; i++) ...[
                  _buildQuizOptionButton(i, isDark: isDark),
                  const SizedBox(height: 6),
                ],

                const SizedBox(height: 4),

                // زر كشف الآية في المصحف أو زر التالي
                Row(
                  children: [
                    if (!_quizAyahRevealedOnMushaf)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('اكشف الآية بالمصحف'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _revealQuizAyahOnMushaf,
                        ),
                      ),
                    if (_quizAyahRevealedOnMushaf && !_quizAnswered) ...[
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('أتقنتها ⭐'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _handleSelfEvaluation(isMastered: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.replay_rounded, size: 16),
                          label: const Text('تحتاج تثبيت 🔁'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _handleSelfEvaluation(isMastered: false),
                        ),
                      ),
                    ],
                    if (_quizAnswered)
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: Text(
                            _quizCurrentQuestionIndex + 1 < _quizTotalQuestions
                                ? 'السؤال التالي'
                                : 'عرض النتيجة النهائية 🎉',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _goToNextQuizQuestionOrFinish,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizOptionButton(int index, {required bool isDark}) {
    final optionText = _quizOptions[index];
    Color? bgColor;
    Color? textColor;
    BorderSide borderSide = BorderSide(color: Colors.grey.withValues(alpha: 0.3));

    if (_quizAnswered) {
      if (index == _quizCorrectOptionIndex) {
        bgColor = const Color(0xFF2E7D32).withValues(alpha: 0.18);
        borderSide = const BorderSide(color: Color(0xFF2E7D32), width: 1.5);
        textColor = const Color(0xFF2E7D32);
      } else if (index == _quizSelectedOption) {
        bgColor = Colors.red.withValues(alpha: 0.15);
        borderSide = const BorderSide(color: Colors.red, width: 1.5);
        textColor = Colors.red;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _quizAnswered ? null : () => _submitQuizAnswer(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(10),
          border: Border.fromBorderSide(borderSide),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                optionText,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 14.5,
                  height: 1.6,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            if (_quizAnswered && index == _quizCorrectOptionIndex)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16)
            else if (_quizAnswered && index == _quizSelectedOption)
              const Icon(Icons.cancel_rounded, color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }
}
