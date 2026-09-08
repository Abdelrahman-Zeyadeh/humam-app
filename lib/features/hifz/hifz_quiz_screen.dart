import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';

enum QuizQuestionType {
  nextAyah,
  prevAyah,
  completeAyah,
}

/// نطاق مصدر أسئلة الاختبار — سورة كاملة، جزء كامل، أو نطاق آيات مخصّص
/// ضمن سورة واحدة (من آية إلى آية). بطلب صريح: "خلّي المستخدم يختار
/// السورة أو الجزء أو النطاق" — قبل هذا كانت الشاشة تقتصر على سورة واحدة
/// فقط (`initialSurahId`/منتقي السور) بلا خيار الجزء أو نطاق مخصّص.
enum _ScopeType { surah, juz, range }

/// اتجاه سؤال "الآية التالية/السابقة" — بطلب صريح: "يحدد الاختبار آية
/// قبل أو آية بعد أو الجهتين مع بعض". لا علاقة له بنوع سؤال "أكمل الآية"
/// (يبقى ممكناً دائماً بغض النظر عن هذا الاختيار — سؤال مستقل تماماً عن
/// اتجاه التالي/السابق).
enum _DirectionMode { next, prev, both }

class HifzQuizScreen extends ConsumerStatefulWidget {
  final int? initialSurahId;

  const HifzQuizScreen({super.key, this.initialSurahId});

  @override
  ConsumerState<HifzQuizScreen> createState() => _HifzQuizScreenState();
}

class _HifzQuizScreenState extends ConsumerState<HifzQuizScreen> {
  // --- نطاق واتجاه الاختبار الحاليَّين (راجع توثيق [_ScopeType]/[_DirectionMode]) ---
  _ScopeType _scopeType = _ScopeType.surah;
  _DirectionMode _directionMode = _DirectionMode.both;
  Surah? _selectedSurah; // نطاق `surah`/`range`
  int _selectedJuz = 1; // نطاق `juz`
  int _rangeFrom = 1;
  int _rangeTo = 1;
  String _scopeLabel = '';

  bool _isLoading = false;
  List<Ayah> _scopeAyahs = [];

  /// اسم كل سورة بمعرّفها — يُحمَّل مرّة واحدة (راجع `initState`) لعرضه
  /// بجانب رقم الآية/الصفحة/الجزء بكل سؤال، بلا استعلام DB لكل سؤال.
  Map<int, String> _surahNames = {};

  // بيانات السؤال الحالي
  int _questionIndex = 0;
  // عدد الأسئلة — قابل للتعديل من ورقة النطاق (بطلب صريح "التحكم بعدد
  // الأسئلة")، بدل ٥ ثابتة دائماً.
  int _totalQuestions = 5;
  int _score = 0;
  bool _quizFinished = false;

  Ayah? _targetAyah;
  String _questionPrompt = '';
  String _promptSnippet = '';
  List<String> _options = [];
  int _correctOptionIndex = 0;
  int? _userSelectedOption;
  bool _answered = false;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    ref.read(allSurahsProvider.future).then((surahs) {
      if (!mounted) return;
      setState(() => _surahNames = {for (final s in surahs) s.id: s.nameAr});
    });
    if (widget.initialSurahId != null) {
      _scopeType = _ScopeType.surah;
      _loadSurahById(widget.initialSurahId!);
    } else {
      _loadSurahById(1); // الفاتحة افتراضياً
    }
  }

  Future<void> _loadSurahById(int surahId) async {
    setState(() => _isLoading = true);
    final surah = await ref.read(quranRepositoryProvider).surahById(surahId);
    final ayahs = await ref.read(quranRepositoryProvider).ayahsForSurah(surahId);
    if (!mounted) return;
    setState(() {
      _selectedSurah = surah;
      _rangeFrom = 1;
      _rangeTo = surah.ayahCount;
      _scopeAyahs = ayahs;
      _scopeLabel = surah.nameAr;
      _isLoading = false;
      _startQuiz();
    });
  }

  Future<void> _loadJuz(int juz) async {
    setState(() => _isLoading = true);
    final ayahs = await ref.read(quranRepositoryProvider).ayahsForJuz(juz);
    if (!mounted) return;
    setState(() {
      _scopeType = _ScopeType.juz;
      _selectedJuz = juz;
      _scopeAyahs = ayahs;
      _scopeLabel = 'الجزء $juz';
      _isLoading = false;
      _startQuiz();
    });
  }

  Future<void> _loadRange(Surah surah, int from, int to) async {
    setState(() => _isLoading = true);
    final all = await ref.read(quranRepositoryProvider).ayahsForSurah(surah.id);
    if (!mounted) return;
    final ayahs = all.where((a) => a.ayah >= from && a.ayah <= to).toList();
    setState(() {
      _scopeType = _ScopeType.range;
      _selectedSurah = surah;
      _rangeFrom = from;
      _rangeTo = to;
      _scopeAyahs = ayahs;
      _scopeLabel = '${surah.nameAr} ($from-$to)';
      _isLoading = false;
      _startQuiz();
    });
  }

  void _startQuiz() {
    _questionIndex = 0;
    _score = 0;
    _quizFinished = false;
    _generateNextQuestion();
  }

  void _generateNextQuestion() {
    if (_scopeAyahs.isEmpty) {
      setState(() => _quizFinished = true);
      return;
    }

    _answered = false;
    _userSelectedOption = null;

    // أنواع الأسئلة المؤهَّلة: "أكمل الآية" ممكن دائماً (يحتاج آية واحدة
    // فقط)، بينما "التالية/السابقة" يحتاجان نطاقاً بآيتين على الأقل
    // وتُفلتران حسب [_directionMode] المختار.
    final types = <QuizQuestionType>[QuizQuestionType.completeAyah];
    if (_scopeAyahs.length >= 2) {
      if (_directionMode != _DirectionMode.prev) types.add(QuizQuestionType.nextAyah);
      if (_directionMode != _DirectionMode.next) types.add(QuizQuestionType.prevAyah);
    }
    final qType = types[_rng.nextInt(types.length)];

    int targetIdx;
    if (qType == QuizQuestionType.nextAyah) {
      targetIdx = _rng.nextInt(_scopeAyahs.length - 1); // لا نختار الأخيرة لأننا نسأل عن التالية
      _targetAyah = _scopeAyahs[targetIdx];
      final nextAyah = _scopeAyahs[targetIdx + 1];
      _questionPrompt = 'ما هي الآية التالية لقوله تعالى:';
      _promptSnippet = _targetAyah!.textUthmani;
      _buildOptions(correctText: nextAyah.textUthmani);
    } else if (qType == QuizQuestionType.prevAyah) {
      targetIdx = 1 + _rng.nextInt(_scopeAyahs.length - 1); // لا نختار الأولى لأننا نسأل عن السابقة
      _targetAyah = _scopeAyahs[targetIdx];
      final prevAyah = _scopeAyahs[targetIdx - 1];
      _questionPrompt = 'ما هي الآية السابقة لقوله تعالى:';
      _promptSnippet = _targetAyah!.textUthmani;
      _buildOptions(correctText: prevAyah.textUthmani);
    } else {
      targetIdx = _rng.nextInt(_scopeAyahs.length);
      _targetAyah = _scopeAyahs[targetIdx];
      final words = _targetAyah!.textUthmani.split(' ');
      if (words.length > 4) {
        final half = words.length ~/ 2;
        _promptSnippet = '${words.take(half).join(' ')} ...';
        final remainder = words.skip(half).join(' ');
        _questionPrompt = 'أكمل قوله تعالى:';
        _buildOptions(correctText: remainder);
      } else {
        // إذا الآية قصيرة جداً نسأل عن الآية نفسها
        _questionPrompt = 'ما الآية رقم (${_targetAyah!.ayah}) في سورة ${_targetAyah!.surah}؟';
        _promptSnippet = 'آية رقم ${_targetAyah!.ayah}';
        _buildOptions(correctText: _targetAyah!.textUthmani);
      }
    }

    setState(() {});
  }

  void _buildOptions({required String correctText}) {
    final otherOptions = <String>{};
    // نجمع خيارات عشوائية من باقي آيات النطاق الحالي (سورة/جزء/نطاق مخصّص)
    final shuffled = List<Ayah>.from(_scopeAyahs)..shuffle(_rng);
    for (final a in shuffled) {
      if (a.textUthmani != correctText && a.textUthmani != _promptSnippet) {
        otherOptions.add(a.textUthmani);
        if (otherOptions.length >= 3) break;
      }
    }

    final opts = [correctText, ...otherOptions];
    opts.shuffle(_rng);
    _options = opts;
    _correctOptionIndex = _options.indexOf(correctText);
  }

  void _handleOptionSelected(int index) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _userSelectedOption = index;
      if (index == _correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextOrFinish() {
    if (_questionIndex + 1 >= _totalQuestions) {
      setState(() => _quizFinished = true);
    } else {
      _questionIndex++;
      _generateNextQuestion();
    }
  }

  Future<void> _showScopeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ScopeAndModeSheet(
        initialScopeType: _scopeType,
        initialDirectionMode: _directionMode,
        initialSurah: _selectedSurah,
        initialJuz: _selectedJuz,
        initialRangeFrom: _rangeFrom,
        initialRangeTo: _rangeTo,
        initialTotalQuestions: _totalQuestions,
        onApply: (scopeType, directionMode, surah, juz, from, to, totalQuestions) {
          Navigator.pop(ctx);
          setState(() {
            _directionMode = directionMode;
            _totalQuestions = totalQuestions;
          });
          switch (scopeType) {
            case _ScopeType.surah:
              if (surah != null) _loadSurahById(surah.id);
            case _ScopeType.juz:
              _loadJuz(juz);
            case _ScopeType.range:
              if (surah != null) _loadRange(surah, from, to);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إختبر حفظك 🎯'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'نطاق واتجاه الاختبار',
              onPressed: _showScopeSheet,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _quizFinished
                ? _buildResultView(context, isDark)
                : _buildQuizView(context, isDark, accent),
      ),
    );
  }

  Widget _buildQuizView(BuildContext context, bool isDark, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط التقدم والنتيجة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال ${_questionIndex + 1} من $_totalQuestions',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              InkWell(
                onTap: _showScopeSheet,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _scopeLabel.isNotEmpty ? _scopeLabel : 'اختر النطاق',
                        style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.tune_rounded, color: AppColors.purple, size: 15),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_questionIndex + 1) / _totalQuestions,
              minHeight: 8,
              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.purple),
            ),
          ),
          const SizedBox(height: 24),

          // بطاقة السؤال
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _questionPrompt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                  ),
                ),
                if (_targetAyah != null) ...[
                  const SizedBox(height: 6),
                  // موقع الآية المعروضة — سورة/رقم آية/صفحة/جزء — بطلب
                  // صريح: "إضافة الآية والصفحة وفي أي جزء للآية المعروضة".
                  Text(
                    '${_surahNames[_targetAyah!.surah] ?? 'سورة ${_targetAyah!.surah}'} '
                    '• آية ${_targetAyah!.ayah} • صفحة ${_targetAyah!.page} • الجزء ${_targetAyah!.juz}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purple.withValues(alpha: isDark ? 0.9 : 0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black26 : const Color(0xFFF9F7F2)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8DECF)),
                  ),
                  child: Text(
                    '﴿ $_promptSnippet ﴾',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 19,
                      height: 2.1,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2216),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // قائمة الخيارات
          for (int i = 0; i < _options.length; i++) ...[
            _buildOptionButton(i, isDark, accent),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 14),
          if (_answered)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(_questionIndex + 1 >= _totalQuestions ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded),
              label: Text(
                _questionIndex + 1 >= _totalQuestions ? 'عرض النتيجة النهائية' : 'السؤال التالي',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: _nextOrFinish,
            ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, bool isDark, Color accent) {
    Color? borderCol;
    Color? bgCol;
    Widget? trailingIcon;

    if (_answered) {
      if (index == _correctOptionIndex) {
        borderCol = const Color(0xFF2E7D32);
        bgCol = const Color(0xFF2E7D32).withValues(alpha: 0.12);
        trailingIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 22);
      } else if (index == _userSelectedOption) {
        borderCol = const Color(0xFFC62828);
        bgCol = const Color(0xFFC62828).withValues(alpha: 0.1);
        trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFC62828), size: 22);
      }
    }

    return InkWell(
      onTap: () => _handleOptionSelected(index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgCol ?? (isDark ? const Color(0xFF1E2836) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderCol ?? (isDark ? AppColors.lineDark : AppColors.line),
            width: borderCol != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _options[index],
                style: const TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 15,
                  height: 1.8,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 10),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(BuildContext context, bool isDark) {
    final percent = ((_score / _totalQuestions) * 100).round();
    final bool passed = percent >= 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (passed ? const Color(0xFF2E7D32) : const Color(0xFFF57C00)).withValues(alpha: 0.15),
              ),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.auto_awesome,
                size: 48,
                color: passed ? const Color(0xFF2E7D32) : const Color(0xFFF57C00),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              passed ? 'بارك الله فيك! حفظ متقن 🌟' : 'أحسنت المحاولة! واصل التثبيت والمراجعة 📖',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'أجبت على $_score من $_totalQuestions أسئلة بشكل صحيح ($percent٪)',
              style: TextStyle(
                fontSize: 14,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة الاختبار'),
                    onPressed: _startQuiz,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('نطاق آخر'),
                    onPressed: _showScopeSheet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ورقة سفلية موحّدة لاختيار (١) نطاق مصدر الأسئلة — سورة/جزء/نطاق مخصّص
/// — و(٢) اتجاه سؤال التالي/السابق. بديل صريح لمنتقي السور القديم
/// (`_showSurahPicker`) الذي كان يحصر الاختبار بسورة واحدة فقط بلا أي
/// تحكّم باتجاه السؤال — راجع توثيق [_ScopeType]/[_DirectionMode].
class _ScopeAndModeSheet extends ConsumerStatefulWidget {
  const _ScopeAndModeSheet({
    required this.initialScopeType,
    required this.initialDirectionMode,
    required this.initialSurah,
    required this.initialJuz,
    required this.initialRangeFrom,
    required this.initialRangeTo,
    required this.initialTotalQuestions,
    required this.onApply,
  });

  final _ScopeType initialScopeType;
  final _DirectionMode initialDirectionMode;
  final Surah? initialSurah;
  final int initialJuz;
  final int initialRangeFrom;
  final int initialRangeTo;
  final int initialTotalQuestions;
  final void Function(
    _ScopeType scopeType,
    _DirectionMode directionMode,
    Surah? surah,
    int juz,
    int from,
    int to,
    int totalQuestions,
  ) onApply;

  @override
  ConsumerState<_ScopeAndModeSheet> createState() => _ScopeAndModeSheetState();
}

class _ScopeAndModeSheetState extends ConsumerState<_ScopeAndModeSheet> {
  late _ScopeType _scopeType = widget.initialScopeType;
  late _DirectionMode _directionMode = widget.initialDirectionMode;
  Surah? _surah;
  late int _juz = widget.initialJuz;
  late int _from = widget.initialRangeFrom;
  late int _to = widget.initialRangeTo;
  late int _totalQuestions = widget.initialTotalQuestions;

  @override
  void initState() {
    super.initState();
    _surah = widget.initialSurah;
  }

  Future<void> _pickSurah() async {
    final surahs = await ref.read(allSurahsProvider.future);
    if (!mounted) return;
    // بحث باسم السورة — بطلب صريح ("إضافة البحث عن اسم السورة")، بدل
    // التمرير اليدوي بقائمة الـ١١٤ سورة كاملة.
    final picked = await showModalBottomSheet<Surah>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _SurahSearchList(surahs: surahs, onPicked: (s) => Navigator.pop(ctx, s)),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _surah = picked;
        _from = 1;
        _to = picked.ayahCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final canApply = _scopeType == _ScopeType.juz || _surah != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('نطاق الاختبار', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: onSurface)),
              const SizedBox(height: 10),
              _SegmentedChips<_ScopeType>(
                value: _scopeType,
                options: const {
                  _ScopeType.surah: 'سورة',
                  _ScopeType.juz: 'جزء',
                  _ScopeType.range: 'نطاق مخصّص',
                },
                onChanged: (v) => setState(() => _scopeType = v),
              ),
              const SizedBox(height: 14),
              if (_scopeType == _ScopeType.surah || _scopeType == _ScopeType.range)
                _SurahPickerTile(surah: _surah, onTap: _pickSurah),
              if (_scopeType == _ScopeType.juz) _JuzPickerRow(value: _juz, onChanged: (v) => setState(() => _juz = v)),
              if (_scopeType == _ScopeType.range && _surah != null) ...[
                const SizedBox(height: 12),
                _RangeFields(
                  surah: _surah!,
                  from: _from,
                  to: _to,
                  onChanged: (from, to) => setState(() {
                    _from = from;
                    _to = to;
                  }),
                ),
              ],
              const SizedBox(height: 22),
              Text('اتجاه سؤال "التالية/السابقة"', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: onSurface)),
              const SizedBox(height: 4),
              Text(
                'سؤال "أكمل الآية" يبقى ممكناً دائماً بغض النظر عن هذا الاختيار.',
                style: TextStyle(fontSize: 11.5, color: onSurface.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 10),
              _SegmentedChips<_DirectionMode>(
                value: _directionMode,
                options: const {
                  _DirectionMode.next: 'آية بعد',
                  _DirectionMode.prev: 'آية قبل',
                  _DirectionMode.both: 'الجهتين معاً',
                },
                onChanged: (v) => setState(() => _directionMode = v),
              ),
              const SizedBox(height: 22),
              // عدد الأسئلة — بطلب صريح "التحكم بعدد الأسئلة أو إضافة عدد
              // أكبر"، بدل ٥ ثابتة دائماً.
              Text('عدد الأسئلة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: onSurface)),
              const SizedBox(height: 10),
              _SegmentedChips<int>(
                value: _totalQuestions,
                options: const {5: '5', 10: '10', 15: '15', 20: '20'},
                onChanged: (v) => setState(() => _totalQuestions = v),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: canApply
                      ? () => widget.onApply(_scopeType, _directionMode, _surah, _juz, _from, _to, _totalQuestions)
                      : null,
                  child: const Text('بدء الاختبار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedChips<T> extends StatelessWidget {
  const _SegmentedChips({required this.value, required this.options, required this.onChanged});
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final selected = e.key == value;
        return ChoiceChip(
          label: Text(e.value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          selected: selected,
          selectedColor: AppColors.purple.withValues(alpha: 0.85),
          labelStyle: TextStyle(color: selected ? Colors.white : null),
          onSelected: (_) => onChanged(e.key),
        );
      }).toList(),
    );
  }
}

/// قائمة سور قابلة للبحث بالاسم — تُستخدَم بورقة اختيار سورة الاختبار.
class _SurahSearchList extends StatefulWidget {
  const _SurahSearchList({required this.surahs, required this.onPicked});
  final List<Surah> surahs;
  final ValueChanged<Surah> onPicked;

  @override
  State<_SurahSearchList> createState() => _SurahSearchListState();
}

class _SurahSearchListState extends State<_SurahSearchList> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final filtered = q.isEmpty
        ? widget.surahs
        : widget.surahs.where((s) => s.nameAr.contains(q) || s.nameArPlain.contains(q)).toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        const Text('اختر السورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'ابحث باسم السورة...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('لا توجد سورة بهذا الاسم'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final s = filtered[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.purple.withValues(alpha: 0.15),
                        child: Text('${s.id}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple)),
                      ),
                      title: Text(s.nameAr, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.ayahCount} آية', style: const TextStyle(fontSize: 11)),
                      onTap: () => widget.onPicked(s),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SurahPickerTile extends StatelessWidget {
  const _SurahPickerTile({required this.surah, required this.onTap});
  final Surah? surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.purple),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                surah?.nameAr ?? 'اختر السورة',
                style: TextStyle(fontWeight: FontWeight.w700, color: onSurface),
              ),
            ),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}

class _JuzPickerRow extends StatelessWidget {
  const _JuzPickerRow({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 30,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final juz = i + 1;
          final selected = juz == value;
          return ChoiceChip(
            label: Text('$juz', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            selected: selected,
            selectedColor: AppColors.purple.withValues(alpha: 0.85),
            labelStyle: TextStyle(color: selected ? Colors.white : null),
            onSelected: (_) => onChanged(juz),
          );
        },
      ),
    );
  }
}

class _RangeFields extends StatelessWidget {
  const _RangeFields({required this.surah, required this.from, required this.to, required this.onChanged});
  final Surah surah;
  final int from;
  final int to;
  final void Function(int from, int to) onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'من آية',
                value: from,
                min: 1,
                max: surah.ayahCount,
                onChanged: (v) => onChanged(v > to ? to : v, to),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _NumberField(
                label: 'إلى آية',
                value: to,
                min: 1,
                max: surah.ayahCount,
                onChanged: (v) => onChanged(from, v < from ? from : v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('${to - from + 1} آية مختارة', style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12)),
      ],
    );
  }
}

/// حقل رقم بعدّاد +/- وكتابة مباشرة — نفس أسلوب `hifz_range_picker_sheet.dart`.
class _NumberField extends StatefulWidget {
  const _NumberField({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller = TextEditingController(text: '${widget.value}');
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _submit(_controller.text);
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final text = '${widget.value}';
      if (_controller.text != text) _controller.text = text;
    }
  }

  void _submit(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) {
      _controller.text = '${widget.value}';
      return;
    }
    final clamped = parsed.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
    if (clamped != parsed) _controller.text = '$clamped';
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Text(widget.label, style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: widget.value > widget.min ? () => widget.onChanged(widget.value - 1) : null),
            SizedBox(
              width: 56,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                onSubmitted: _submit,
              ),
            ),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: widget.value < widget.max ? () => widget.onChanged(widget.value + 1) : null),
          ],
        ),
      ],
    );
  }
}
