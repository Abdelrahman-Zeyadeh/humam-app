import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/text/arabic_normalizer.dart'
    show stripQuranicMarksForDisplay;
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/smart_reminder_sync.dart';

/// مزود خريطة إتقان الحفظ
final _hifzCenterMasteryProvider = FutureProvider<Map<int, String>>((ref) {
  ref.watch(hifzVersionProvider);
  return ref.watch(hifzPrefsProvider).allMasteryMap();
});

/// أنماط تثبيت الحفظ داخل الصفحة
enum HifzReviewMode {
  /// تثبيت ومراجعة كامل الصفحة بنص قرآني متصل
  memorize,

  /// كلمات ناقصة لاختبار الاستحضار
  missingWords,

  /// إكمال الآيات (مطلع الآية ظاهر وباقيها محجوب)
  completeAyah,
}

/// مركز الحفظ والمراجعة الشامل والذكي
/// يجمع:
/// ١. تثبيت ومراجعة الحفظ (صفحة بصفحة بنص مصحفي موصول وكلمات ناقصة تفاعلية)
/// ٢. اختبر حفظك (اختبار مرن يتيح اختيار الصفحة أو السورة أو الجزء)
/// ٣. خريطة إتقان الحفظ (مع إمكانية تحديد السورة أو الجزء كاملاً بنقرة واحدة)
class HifzCenterScreen extends ConsumerStatefulWidget {
  const HifzCenterScreen({
    super.key,
    this.initialTab = 0,
    this.planId,
    this.initialPage,
    this.initialSurahId,
  });

  final int initialTab;
  final int? planId;
  final int? initialPage;
  final int? initialSurahId;

  @override
  ConsumerState<HifzCenterScreen> createState() => _HifzCenterScreenState();
}

class _HifzCenterScreenState extends ConsumerState<HifzCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- حالة التبويب ١: تثبيت ومراجعة الحفظ ---
  int _currentPage = 1;
  bool _pageLoading = true;
  List<Ayah> _pageAyahs = [];
  Map<int, Surah> _surahMap = {};
  HifzReviewMode _reviewMode = HifzReviewMode.memorize;
  int _missingInterval = 3; // كل 3 كلمات
  final Map<int, Set<int>> _revealedWordIndices = {};
  final Set<int> _revealedAyahIds = {};
  final Set<int> _markedAyahIds = {};

  // --- حالة التبويب ٢: اختبر حفظك ---
  bool _quizActive = false;
  String _quizScopeTitle = '';
  List<Ayah> _quizScopeAyahs = [];
  int _quizQuestionCount = 5;
  int _quizCurrentIndex = 0;
  int _quizScore = 0;
  bool _quizFinished = false;
  Ayah? _quizTargetAyah;
  String _quizPrompt = '';
  String _quizSnippet = '';
  List<String> _quizOptions = [];
  int _quizCorrectOptionIndex = 0;
  int? _quizSelectedOption;
  bool _quizAnswered = false;
  final Random _rng = Random();

  // خيارات إعداد الاختبار
  int _quizScopeSelection = 0; // 0: الصفحة الحالية, 1: سورة, 2: جزء
  int _quizSelectedSurahId = 1;
  int _quizSelectedJuz = 1;

  // --- حالة التبويب ٣: خريطة إتقان الحفظ ---
  int _heatmapViewMode = 0; // 0: سور, 1: أجزاء
  String _heatmapSearchQuery = '';
  int? _heatmapExpandedSurahId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _currentPage = widget.initialPage ?? 1;
    if (_currentPage < 1) _currentPage = 1;
    if (_currentPage > 604) _currentPage = 604;

    if (widget.initialSurahId != null) {
      _quizSelectedSurahId = widget.initialSurahId!;
      _quizScopeSelection = 1;
    }

    _loadSurahsAndPage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahsAndPage() async {
    final repo = ref.read(quranRepositoryProvider);
    final surahs = await repo.allSurahs();
    if (!mounted) return;
    _surahMap = {for (final s in surahs) s.id: s};

    // إن كان هنالك خطة محددة، نبدأ بآخر صفحة فيها
    if (widget.initialPage == null && widget.planId != null) {
      final plans = ref.read(hifzPrefsProvider).plans;
      final plan = plans.where((p) => p.id == widget.planId).firstOrNull;
      if (plan != null) {
        try {
          final targetAyah = await repo.ayahById(plan.currentAyahId);
          _currentPage = targetAyah.page;
        } catch (_) {}
      }
    }

    await _loadPage(_currentPage);
  }

  Future<void> _loadPage(int page) async {
    if (page < 1 || page > 604) return;
    setState(() => _pageLoading = true);
    final repo = ref.read(quranRepositoryProvider);
    final ayahs = await repo.ayahsForPage(page);

    if (!mounted) return;
    setState(() {
      _currentPage = page;
      _pageAyahs = ayahs;
      _pageLoading = false;
      _revealedWordIndices.clear();
      _revealedAyahIds.clear();
      _markedAyahIds.clear();
    });
  }

  // ==========================================
  // منطق تثبيت ومراجعة الحفظ
  // ==========================================

  List<String> _splitWords(Ayah ayah) {
    final clean = stripQuranicMarksForDisplay(ayah.textUthmani).trim();
    if (clean.isEmpty) return const [];
    return clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  bool _isWordMasked(int ayahId, int wordIndex, int totalWords) {
    if (totalWords <= 2) return false;
    if (wordIndex == 0) return false; // لا نحجب الكلمة الأولى لتبقى مفتاحاً
    return (wordIndex + 1) % _missingInterval == 0;
  }

  Future<void> _markEntirePageAsMastered() async {
    if (_pageAyahs.isEmpty) return;
    final ids = _pageAyahs.map((a) => a.id).toList();
    final hifzPrefs = ref.read(hifzPrefsProvider);
    await hifzPrefs.setMultipleAyahsMasteryStatus(ids, 'mastered');

    if (widget.planId != null) {
      for (final a in _pageAyahs) {
        await hifzPrefs.gradeReview(widget.planId!, a.id, 2);
      }
      unawaited(syncHifzReminder(hifzPrefs));
    }

    ref.read(hifzVersionProvider.notifier).bump();

    if (!mounted) return;
    setState(() {
      _markedAyahIds.addAll(ids);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تثبيت وإتقان صفحة $_currentPage بالكامل بنجاح ⭐'),
        backgroundColor: const Color(0xFF1B8A72),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startQuizForCurrentPage() {
    _startQuizWithAyahs(
      ayahs: _pageAyahs,
      title: 'صفحة $_currentPage',
    );
    _tabController.animateTo(1);
  }

  // ==========================================
  // منطق اختبر حفظك
  // ==========================================

  void _startQuizWithAyahs({
    required List<Ayah> ayahs,
    required String title,
  }) {
    if (ayahs.isEmpty) return;
    setState(() {
      _quizScopeTitle = title;
      _quizScopeAyahs = List<Ayah>.from(ayahs);
      _quizActive = true;
      _quizCurrentIndex = 0;
      _quizScore = 0;
      _quizFinished = false;
      _generateQuizQuestion();
    });
  }

  Future<void> _startConfiguredQuiz() async {
    setState(() => _pageLoading = true);
    final repo = ref.read(quranRepositoryProvider);
    List<Ayah> ayahs = [];
    String title = '';

    if (_quizScopeSelection == 0) {
      ayahs = await repo.ayahsForPage(_currentPage);
      title = 'صفحة $_currentPage';
    } else if (_quizScopeSelection == 1) {
      ayahs = await repo.ayahsForSurah(_quizSelectedSurahId);
      final surah = _surahMap[_quizSelectedSurahId];
      title = surah?.nameAr ?? 'سورة $_quizSelectedSurahId';
    } else {
      ayahs = await repo.ayahsForJuz(_quizSelectedJuz);
      title = 'الجزء $_quizSelectedJuz';
    }

    if (!mounted) return;
    setState(() => _pageLoading = false);

    if (ayahs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد آيات كافية في هذا النطاق.')),
      );
      return;
    }

    _startQuizWithAyahs(ayahs: ayahs, title: title);
  }

  void _generateQuizQuestion() {
    if (_quizScopeAyahs.isEmpty || _quizCurrentIndex >= _quizQuestionCount) {
      setState(() => _quizFinished = true);
      return;
    }

    _quizAnswered = false;
    _quizSelectedOption = null;

    final target = _quizScopeAyahs[_rng.nextInt(_quizScopeAyahs.length)];
    _quizTargetAyah = target;

    // نوع السؤال: إكمال الآية أو الآية التالية
    final questionType = _rng.nextInt(2); // 0: الآية التالية, 1: إكمال الآية
    final surahName = _surahMap[target.surah]?.nameAr ?? 'سورة ${target.surah}';

    if (questionType == 0) {
      // ما هي الآية التالية؟
      _quizPrompt = 'ما هي الآية التالية في $surahName بعد الآية الكريمة:';
      _quizSnippet = stripQuranicMarksForDisplay(target.textUthmani);

      // نبحث عن الآية التالية الفعلية
      final nextAyahIndex = _quizScopeAyahs.indexWhere(
        (a) => a.surah == target.surah && a.ayah == target.ayah + 1,
      );

      String correctAnswer;
      if (nextAyahIndex != -1) {
        correctAnswer = stripQuranicMarksForDisplay(_quizScopeAyahs[nextAyahIndex].textUthmani);
      } else {
        correctAnswer = '﴿ نهاية السورة الكريمة ﴾';
      }

      // خيارات مشتتة
      final distractors = <String>[];
      final shuffled = List<Ayah>.from(_quizScopeAyahs)..shuffle(_rng);
      for (final a in shuffled) {
        if (a.id != target.id && distractors.length < 3) {
          final text = stripQuranicMarksForDisplay(a.textUthmani);
          if (text != correctAnswer && !distractors.contains(text)) {
            distractors.add(text);
          }
        }
      }

      while (distractors.length < 3) {
        distractors.add('﴿ إِنَّ اللَّهَ غَفُورٌ رَّحِيمٌ ﴾');
      }

      final allOptions = [correctAnswer, ...distractors]..shuffle(_rng);
      _quizOptions = allOptions;
      _quizCorrectOptionIndex = allOptions.indexOf(correctAnswer);
    } else {
      // إكمال الآية
      _quizPrompt = 'أكمل قوله تعالى في $surahName (الآية ${target.ayah}):';
      final words = _splitWords(target);
      if (words.length > 3) {
        final startCount = (words.length * 0.4).ceil().clamp(1, words.length - 1);
        _quizSnippet = '${words.take(startCount).join(' ')} ...';
        final correctAnswer = words.skip(startCount).join(' ');

        // خيارات مشتتة
        final distractors = <String>[];
        final shuffled = List<Ayah>.from(_quizScopeAyahs)..shuffle(_rng);
        for (final a in shuffled) {
          if (a.id != target.id && distractors.length < 3) {
            final w = _splitWords(a);
            if (w.length > 2) {
              final dText = w.skip(1).join(' ');
              if (dText != correctAnswer && !distractors.contains(dText)) {
                distractors.add(dText);
              }
            }
          }
        }
        while (distractors.length < 3) {
          distractors.add('وَاللَّهُ عَلِيمٌ حَكِيمٌ');
        }

        final allOptions = [correctAnswer, ...distractors]..shuffle(_rng);
        _quizOptions = allOptions;
        _quizCorrectOptionIndex = allOptions.indexOf(correctAnswer);
      } else {
        _quizSnippet = stripQuranicMarksForDisplay(target.textUthmani);
        _quizOptions = ['صحيحة تماماً', 'مكررة', 'منسوخة', 'غير دقيقة'];
        _quizCorrectOptionIndex = 0;
      }
    }

    setState(() {});
  }

  void _submitQuizAnswer(int selectedIndex) {
    if (_quizAnswered) return;
    final isCorrect = selectedIndex == _quizCorrectOptionIndex;

    setState(() {
      _quizAnswered = true;
      _quizSelectedOption = selectedIndex;
      if (isCorrect) {
        _quizScore++;
        // تحديث آية الحفظ في خريطة الإتقان تلقائياً عند الإجابة الصحيحة!
        if (_quizTargetAyah != null) {
          ref.read(hifzPrefsProvider).setAyahMasteryStatus(_quizTargetAyah!.id, 'mastered');
          ref.read(hifzVersionProvider.notifier).bump();
        }
      }
    });
  }

  void _nextQuizQuestion() {
    setState(() {
      _quizCurrentIndex++;
      _generateQuizQuestion();
    });
  }

  // ==========================================
  // منطق خريطة إتقان الحفظ مع التحديد الجماعي
  // ==========================================

  Future<void> _setSurahMastery(Surah surah, String status) async {
    final repo = ref.read(quranRepositoryProvider);
    final ayahs = await repo.ayahsForSurah(surah.id);
    final ids = ayahs.map((a) => a.id).toList();

    await ref.read(hifzPrefsProvider).setMultipleAyahsMasteryStatus(ids, status);
    ref.read(hifzVersionProvider.notifier).bump();

    if (!mounted) return;
    final msg = status == 'mastered'
        ? 'تم تحديد سورة ${surah.nameAr} كاملة كمتقنة ⭐'
        : status == 'needsReview'
            ? 'تم تحديد سورة ${surah.nameAr} للمراجعة ⏳'
            : 'تم إلغاء تحديد سورة ${surah.nameAr}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: status == 'mastered'
            ? const Color(0xFF2E7D32)
            : status == 'needsReview'
                ? const Color(0xFFF57F17)
                : Colors.grey.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _setJuzMastery(int juzNumber, String status) async {
    final repo = ref.read(quranRepositoryProvider);
    final ayahs = await repo.ayahsForJuz(juzNumber);
    final ids = ayahs.map((a) => a.id).toList();

    await ref.read(hifzPrefsProvider).setMultipleAyahsMasteryStatus(ids, status);
    ref.read(hifzVersionProvider.notifier).bump();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تحديث إتقان الجزء $juzNumber بالكامل بنجاح ⭐'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _setAyahQuickToggle(int ayahId, String? currentStatus) async {
    String nextStatus;
    if (currentStatus == null || currentStatus == 'unmemorized') {
      nextStatus = 'mastered';
    } else if (currentStatus == 'mastered') {
      nextStatus = 'needsReview';
    } else {
      nextStatus = 'unmemorized';
    }

    await ref.read(hifzPrefsProvider).setAyahMasteryStatus(ayahId, nextStatus);
    ref.read(hifzVersionProvider.notifier).bump();
  }

  // ==========================================
  // بناء الواجهة الرئيسية
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مركز الحفظ والمراجعة الذكي',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accent,
          indicatorWeight: 3,
          labelColor: accent,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded, size: 20), text: 'تثبيت ومراجعة'),
            Tab(icon: Icon(Icons.fact_check_rounded, size: 20), text: 'اختبر حفظك'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'خريطة الإتقان'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewTab(accent, isDark),
          _buildQuizTab(accent, isDark),
          _buildHeatmapTab(accent, isDark),
        ],
      ),
    );
  }

  // ==========================================
  // التبويب ١: تثبيت ومراجعة الحفظ (المعاد تصميمه)
  // ==========================================

  Widget _buildReviewTab(Color accent, bool isDark) {
    final surahNames = _pageAyahs
        .map((a) => _surahMap[a.surah]?.nameArPlain ?? 'سورة ${a.surah}')
        .toSet()
        .join(' · ');
    final juzNumber = _pageAyahs.isNotEmpty ? _pageAyahs.first.juz : 1;

    return Column(
      children: [
        // ١. ترويسة الصفحة والتنقل السريع
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B232E) : Colors.white,
            border: Border(bottom: BorderSide(color: (isDark ? Colors.white12 : Colors.black12))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                tooltip: 'الصفحة السابقة',
                onPressed: _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
              ),
              Expanded(
                child: InkWell(
                  onTap: _showPageJumpModal,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'صفحة $_currentPage من 604',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الجزء $juzNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded, size: 18),
                            ],
                          ),
                        ),
                        if (surahNames.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              surahNames,
                              style: TextStyle(
                                fontSize: 11,
                                color: accent.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                tooltip: 'الصفحة التالية',
                onPressed: _currentPage < 604 ? () => _loadPage(_currentPage + 1) : null,
              ),
            ],
          ),
        ),

        // ٢. محدد الأنماط الثلاثة
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: SegmentedButton<HifzReviewMode>(
            segments: const [
              ButtonSegment(
                value: HifzReviewMode.memorize,
                label: Text('تثبيت ومراجعة', style: TextStyle(fontSize: 11.5)),
                icon: Icon(Icons.auto_stories_rounded, size: 16),
              ),
              ButtonSegment(
                value: HifzReviewMode.missingWords,
                label: Text('كلمات ناقصة', style: TextStyle(fontSize: 11.5)),
                icon: Icon(Icons.extension_rounded, size: 16),
              ),
              ButtonSegment(
                value: HifzReviewMode.completeAyah,
                label: Text('إكمال الآية', style: TextStyle(fontSize: 11.5)),
                icon: Icon(Icons.visibility_off_rounded, size: 16),
              ),
            ],
            selected: {_reviewMode},
            onSelectionChanged: (set) => setState(() {
              _reviewMode = set.first;
              _revealedWordIndices.clear();
              _revealedAyahIds.clear();
            }),
          ),
        ),

        // ٣. شريط تحكم فرعي مخصص للنمط
        if (_reviewMode == HifzReviewMode.missingWords)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    'نسبة الإخفاء:',
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('سهل', style: TextStyle(fontSize: 11)),
                    selected: _missingInterval == 4,
                    onSelected: (_) => setState(() {
                      _missingInterval = 4;
                      _revealedWordIndices.clear();
                    }),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('متوسط', style: TextStyle(fontSize: 11)),
                    selected: _missingInterval == 3,
                    onSelected: (_) => setState(() {
                      _missingInterval = 3;
                      _revealedWordIndices.clear();
                    }),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('متقدم', style: TextStyle(fontSize: 11)),
                    selected: _missingInterval == 2,
                    onSelected: (_) => setState(() {
                      _missingInterval = 2;
                      _revealedWordIndices.clear();
                    }),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (final a in _pageAyahs) {
                          final words = _splitWords(a);
                          final set = <int>{};
                          for (var i = 0; i < words.length; i++) {
                            set.add(i);
                          }
                          _revealedWordIndices[a.id] = set;
                        }
                      });
                    },
                    child: const Text('كشف الكل', style: TextStyle(fontSize: 11.5)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _revealedWordIndices.clear()),
                    child: const Text('إخفاء', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
            ),
          )
        else if (_reviewMode == HifzReviewMode.completeAyah)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    'انقر على الآية لإظهار باقيها من حفظك:',
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => setState(() => _revealedAyahIds.addAll(_pageAyahs.map((a) => a.id))),
                    child: const Text('كشف الكل', style: TextStyle(fontSize: 11.5)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _revealedAyahIds.clear()),
                    child: const Text('إخفاء الكل', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
            ),
          ),

        // ٤. متن الصفحة القرآنية بنص مصحفي موصول وانسيابي
        Expanded(
          child: _pageLoading
              ? const Center(child: CircularProgressIndicator())
              : _pageAyahs.isEmpty
                  ? const Center(child: Text('لا توجد آيات في هذه الصفحة'))
                  : Container(
                      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E28) : const Color(0xFFFAF7F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildFlowingMushafPage(accent, isDark),
                      ),
                    ),
        ),

        // ٥. شريط الأزرار التفاعلية أسفل التثبيت
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B232E) : Colors.white,
            border: Border(top: BorderSide(color: (isDark ? Colors.white12 : Colors.black12))),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('تثبيت وإتقان الصفحة كاملة ⭐'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A72),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _markEntirePageAsMastered,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.quiz_rounded, size: 17),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('اختبر هذه الصفحة'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _startQuizForCurrentPage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// النص القرآني المتصل الأنيق بدلاً من البطاقات المجزأة المنفصلة
  Widget _buildFlowingMushafPage(Color accent, bool isDark) {
    final spans = <InlineSpan>[];

    for (final ayah in _pageAyahs) {
      final isMarked = _markedAyahIds.contains(ayah.id);
      final isSurahStart = ayah.ayah == 1;
      final surah = _surahMap[ayah.surah];

      // ترويسة بداية السورة إن كانت أول آية
      if (isSurahStart && surah != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                'سُورَةُ ${surah.nameAr}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ),
        );
      }

      if (_reviewMode == HifzReviewMode.memorize) {
        // نمط التثبيت المفتوح
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                setState(() {
                  if (isMarked) {
                    _markedAyahIds.remove(ayah.id);
                  } else {
                    _markedAyahIds.add(ayah.id);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: isMarked ? const Color(0xFF2E7D32).withValues(alpha: 0.16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stripQuranicMarksForDisplay(ayah.textUthmani),
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 21,
                    height: 2.1,
                    color: isMarked
                        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20))
                        : (isDark ? Colors.white : const Color(0xFF1C2733)),
                    fontWeight: isMarked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (_reviewMode == HifzReviewMode.missingWords) {
        // نمط الكلمات الناقصة
        final words = _splitWords(ayah);
        final revealedSet = _revealedWordIndices[ayah.id] ?? const <int>{};

        for (var i = 0; i < words.length; i++) {
          final word = words[i];
          final isMasked = _isWordMasked(ayah.id, i, words.length);

          if (isMasked) {
            final isRevealed = revealedSet.contains(i);
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      final set = _revealedWordIndices.putIfAbsent(ayah.id, () => <int>{});
                      if (isRevealed) {
                        set.remove(i);
                      } else {
                        set.add(i);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isRevealed
                          ? const Color(0xFF1B8A72).withValues(alpha: 0.18)
                          : accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isRevealed ? const Color(0xFF1B8A72) : accent.withValues(alpha: 0.6),
                        width: 1.1,
                      ),
                    ),
                    child: Text(
                      isRevealed ? word : ' ⋯⋯ ',
                      style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isRevealed ? const Color(0xFF1B8A72) : accent,
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            spans.add(
              TextSpan(
                text: ' $word ',
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 21,
                  height: 2.1,
                  color: isDark ? Colors.white : const Color(0xFF1C2733),
                ),
              ),
            );
          }
        }
      } else {
        // نمط إكمال الآية
        final words = _splitWords(ayah);
        final isRevealed = _revealedAyahIds.contains(ayah.id);
        final startCount = (words.length * 0.35).ceil().clamp(1, words.length);
        final visiblePart = words.take(startCount).join(' ');
        final hiddenPart = words.skip(startCount).join(' ');

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isRevealed) {
                    _revealedAyahIds.remove(ayah.id);
                  } else {
                    _revealedAyahIds.add(ayah.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isRevealed ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$visiblePart ',
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      if (hiddenPart.isNotEmpty)
                        TextSpan(
                          text: isRevealed ? hiddenPart : ' [اضغط لإكمال الآية] ',
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: isRevealed ? 21 : 16,
                            color: isRevealed
                                ? (isDark ? Colors.white : const Color(0xFF1C2733))
                                : (isDark ? Colors.white38 : Colors.black38),
                            fontStyle: isRevealed ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
        );
      }

      // رقم الآية وزخرفتها
      spans.add(
        TextSpan(
          text: ' ﴿${ayah.ayah}﴾ ',
          style: TextStyle(
            fontFamily: 'AmiriQuran',
            fontSize: 18,
            color: accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }

  void _showPageJumpModal() {
    final pageCtrl = TextEditingController(text: '$_currentPage');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'الانتقال إلى صفحة في المصحف',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pageCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'أدخل رقم الصفحة (1 - 604)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  final p = int.tryParse(pageCtrl.text.trim());
                  if (p != null && p >= 1 && p <= 604) {
                    Navigator.of(ctx).pop();
                    _loadPage(p);
                  }
                },
                child: const Text('انتقال'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // التبويب ٢: اختبر حفظك (مع لوحة الإعداد المرنة)
  // ==========================================

  Widget _buildQuizTab(Color accent, bool isDark) {
    if (_quizActive) {
      return _buildActiveQuizView(accent, isDark);
    }

    // شاشة إعداد الاختبار الذكية (لا تفوت فوراً على الفاتحة!)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // بطاقة الترحيب التوجيهية
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1B2A26), const Color(0xFF14201D)]
                    : [const Color(0xFFE8F5F1), const Color(0xFFD7EDE6)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.quiz_rounded, color: accent, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختبارات الحفظ الذكية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0E4D40),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اختر نطاق السورة أو الصفحة أو الجزء وسنختبر حفظك بالآيات التالية وإكمال الكلمات بدقة.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // تحديد نطاق الاختبار
          const Text('١. نطاق الاختبار:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text('صفحة $_currentPage', style: const TextStyle(fontSize: 12)),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
              ),
              const ButtonSegment(
                value: 1,
                label: Text('سورة محددة', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.bookmark_border_rounded, size: 16),
              ),
              const ButtonSegment(
                value: 2,
                label: Text('جزء كامل', style: TextStyle(fontSize: 12)),
                icon: Icon(Icons.view_week_rounded, size: 16),
              ),
            ],
            selected: {_quizScopeSelection},
            onSelectionChanged: (set) => setState(() => _quizScopeSelection = set.first),
          ),
          const SizedBox(height: 14),

          // خيار اختيار السورة إذا تم اختيار "سورة محددة"
          if (_quizScopeSelection == 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B232E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _quizSelectedSurahId,
                  items: _surahMap.values.map((s) {
                    return DropdownMenuItem<int>(
                      value: s.id,
                      child: Text('${s.id}. سورة ${s.nameAr} (${s.ayahCount} آية)'),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) setState(() => _quizSelectedSurahId = id);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
          ] else if (_quizScopeSelection == 2) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B232E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _quizSelectedJuz,
                  items: List.generate(30, (i) => i + 1).map((j) {
                    return DropdownMenuItem<int>(
                      value: j,
                      child: Text('الجزء $j من القرآن الكريم'),
                    );
                  }).toList(),
                  onChanged: (j) {
                    if (j != null) setState(() => _quizSelectedJuz = j);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // عدد الأسئلة
          const Text('٢. عدد الأسئلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [5, 10, 15].map((count) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$count أسئلة'),
                    selected: _quizQuestionCount == count,
                    onSelected: (_) => setState(() => _quizQuestionCount = count),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // زر بدء الاختبار الفخم
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text('ابدأ الاختبار الآن 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
            ),
            onPressed: _startConfiguredQuiz,
          ),
        ],
      ),
    );
  }

  /// واجهة الاختبار الجارية
  Widget _buildActiveQuizView(Color accent, bool isDark) {
    if (_quizFinished) {
      final percent = ((_quizScore / _quizQuestionCount) * 100).round();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                percent >= 80 ? Icons.emoji_events_rounded : Icons.check_circle_rounded,
                color: percent >= 80 ? Colors.amber : accent,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                percent >= 80 ? 'ما شاء الله! حفظ متقن 🌟' : 'أحسنت! واصل المراجعة والتعاهد 👍',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'أجبت على $_quizScore من أصل $_quizQuestionCount سؤال بنجاح ($percent٪)',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة الاختبار'),
                onPressed: () => setState(() => _quizActive = false),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط التقدم ونطاق الاختبار
          Row(
            children: [
              Text(
                'السؤال ${_quizCurrentIndex + 1} من $_quizQuestionCount',
                style: TextStyle(fontWeight: FontWeight.bold, color: accent),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _quizScopeTitle,
                  style: TextStyle(fontSize: 11.5, color: accent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_quizCurrentIndex + 1) / _quizQuestionCount,
              color: accent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),

          // بطاقة السؤال
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _quizPrompt,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF9F7F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    _quizSnippet,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 22,
                      height: 2.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B3022),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // الخيارات
          for (var i = 0; i < _quizOptions.length; i++) ...[
            Builder(
              builder: (context) {
                final optionText = _quizOptions[i];
                final isSelected = _quizSelectedOption == i;
                final isCorrect = i == _quizCorrectOptionIndex;

                Color borderColor = Colors.grey.withValues(alpha: 0.3);
                Color bgColor = isDark ? const Color(0xFF1B232E) : Colors.white;

                if (_quizAnswered) {
                  if (isCorrect) {
                    borderColor = Colors.green;
                    bgColor = Colors.green.withValues(alpha: 0.15);
                  } else if (isSelected) {
                    borderColor = Colors.red;
                    bgColor = Colors.red.withValues(alpha: 0.15);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _submitQuizAnswer(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              optionText,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'AmiriQuran',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1C2733),
                              ),
                            ),
                          ),
                          if (_quizAnswered) ...[
                            if (isCorrect)
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22)
                            else if (isSelected)
                              const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          if (_quizAnswered) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _nextQuizQuestion,
              child: Text(
                _quizCurrentIndex + 1 >= _quizQuestionCount ? 'عرض النتيجة النهائية 🏆' : 'السؤال التالي ⬅',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // التبويب ٣: خريطة إتقان الحفظ (مع التحديد الجماعي السهل)
  // ==========================================

  Widget _buildHeatmapTab(Color accent, bool isDark) {
    final masteryAsync = ref.watch(_hifzCenterMasteryProvider);
    final surahsAsync = ref.watch(allSurahsProvider);

    return masteryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('تعذّر تحميل البيانات: $e')),
      data: (masteryMap) {
        final totalMastered = masteryMap.values.where((v) => v == 'mastered').length;
        final totalNeedsReview = masteryMap.values.where((v) => v == 'needsReview').length;
        final totalSaved = totalMastered + totalNeedsReview;
        final percent = (totalSaved / 6236 * 100).toStringAsFixed(1);

        return surahsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('تعذّر تحميل السور: $e')),
          data: (surahs) {
            return Column(
              children: [
                // بطاقة الإحصائيات الشاملة
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B232E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: (isDark ? Colors.white12 : Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalSaved / ٦٢٣٦ آية',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent),
                            ),
                            const SizedBox(height: 2),
                            Text('نسبة الإنجاز: $percent٪', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: const Color(0xFF2E7D32)),
                                const SizedBox(width: 4),
                                Text('متقن: $totalMastered', style: const TextStyle(fontSize: 11)),
                                const SizedBox(width: 12),
                                Icon(Icons.access_time_filled_rounded, size: 14, color: const Color(0xFFF57F17)),
                                const SizedBox(width: 4),
                                Text('مراجعة: $totalNeedsReview', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                          border: Border.all(color: accent, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '$percent٪',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // شريط التبديل بين السور والأجزاء
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('حسب السور (١١٤)')),
                            ButtonSegment(value: 1, label: Text('حسب الأجزاء (٣٠)')),
                          ],
                          selected: {_heatmapViewMode},
                          onSelectionChanged: (set) => setState(() => _heatmapViewMode = set.first),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_heatmapViewMode == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      onChanged: (q) => setState(() => _heatmapSearchQuery = q.trim()),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم السورة أو رقمها...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                // محتوى السور أو الأجزاء
                Expanded(
                  child: _heatmapViewMode == 0
                      ? Builder(
                          builder: (context) {
                            final filtered = surahs.where((s) {
                              if (_heatmapSearchQuery.isEmpty) return true;
                              return s.nameAr.contains(_heatmapSearchQuery) ||
                                  s.id.toString() == _heatmapSearchQuery;
                            }).toList();
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final surah = filtered[i];
                                final isExpanded = _heatmapExpandedSurahId == surah.id;
                                return _buildSurahMasteryTile(surah, masteryMap, isExpanded, accent, isDark);
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: 30,
                          itemBuilder: (context, i) {
                            final juz = i + 1;
                            return _buildJuzMasteryTile(juz, masteryMap, accent, isDark);
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// عنصر سورة مع أزرار التحديد السريع الجماعية (الحل الجذري لمعاناة التحديد الفردي)
  Widget _buildSurahMasteryTile(
    Surah surah,
    Map<int, String> masteryMap,
    bool isExpanded,
    Color accent,
    bool isDark,
  ) {
    final ayahsAsync = ref.watch(_surahAyahsProvider(surah.id));

    return ayahsAsync.when(
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox.shrink(),
      data: (ayahs) {
        int mastered = 0;
        int needsReview = 0;
        for (final a in ayahs) {
          final st = masteryMap[a.id];
          if (st == 'mastered') mastered++;
          if (st == 'needsReview') needsReview++;
        }
        final total = mastered + needsReview;
        final ratio = ayahs.isEmpty ? 0.0 : total / ayahs.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B232E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ratio == 1.0
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.6)
                  : (isDark ? Colors.white12 : Colors.black12),
            ),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _heatmapExpandedSurahId = isExpanded ? null : surah.id;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ratio == 1.0
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                              : accent.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            '${surah.id}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ratio == 1.0 ? const Color(0xFF2E7D32) : accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.nameAr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            Text(
                              '${ayahs.length} آية · $mastered متقن · $needsReview مراجعة',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(ratio * 100).toInt()}٪',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ratio > 0 ? const Color(0xFF2E7D32) : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              // منطقة التحديد الجماعي السريع عند التوسيع
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // أزرار التحديد الجماعي السريع للسورة
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.star_rounded, size: 16),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('إتقان كامل السورة ⭐', style: TextStyle(fontSize: 11.5)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _setSurahMastery(surah, 'mastered'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.access_time_rounded, size: 15),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('تحتاج مراجعة ⏳', style: TextStyle(fontSize: 11.5)),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFF57F17),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _setSurahMastery(surah, 'needsReview'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                            tooltip: 'إلغاء حفظ السورة',
                            onPressed: () => _setSurahMastery(surah, 'unmemorized'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // شبكة الآيات السريعة (النقر المباشر يقلب الحالة فوراً دون نوافذ منبثقة!)
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: ayahs.map((a) {
                          final st = masteryMap[a.id];
                          Color blockColor;
                          Color textColor;

                          if (st == 'mastered') {
                            blockColor = const Color(0xFF2E7D32);
                            textColor = Colors.white;
                          } else if (st == 'needsReview') {
                            blockColor = const Color(0xFFF57F17);
                            textColor = Colors.white;
                          } else {
                            blockColor = isDark ? Colors.white10 : const Color(0xFFEEEEEE);
                            textColor = isDark ? Colors.white70 : Colors.black87;
                          }

                          return InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _setAyahQuickToggle(a.id, st),
                            child: Tooltip(
                              message: 'الآية ${a.ayah}: ${st == 'mastered' ? 'متقن' : st == 'needsReview' ? 'مراجعة' : 'غير محفوظ'}',
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: blockColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${a.ayah}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// عنصر الجزء مع زر الإتقان الكامل
  Widget _buildJuzMasteryTile(
    int juzNumber,
    Map<int, String> masteryMap,
    Color accent,
    bool isDark,
  ) {
    final ayahsAsync = ref.watch(_juzAyahsProvider(juzNumber));

    return ayahsAsync.when(
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox.shrink(),
      data: (ayahs) {
        int mastered = 0;
        int needsReview = 0;
        for (final a in ayahs) {
          final st = masteryMap[a.id];
          if (st == 'mastered') mastered++;
          if (st == 'needsReview') needsReview++;
        }
        final total = mastered + needsReview;
        final ratio = ayahs.isEmpty ? 0.0 : total / ayahs.length;
        final percent = (ratio * 100).toInt();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B232E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (isDark ? Colors.white12 : Colors.black12)),
          ),
          child: Row(
            children: [
              Text('الجزء $juzNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '(${ayahs.length} آية · $mastered متقن · $percent٪)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.star_rounded, size: 14),
                label: const Text('إتقان ⭐', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _setJuzMastery(juzNumber, 'mastered'),
              ),
            ],
          ),
        );
      },
    );
  }
}

final _surahAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, surahId) {
  return ref.watch(quranRepositoryProvider).ayahsForSurah(surahId);
});

final _juzAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, juz) {
  return ref.watch(quranRepositoryProvider).ayahsForJuz(juz);
});
