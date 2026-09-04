import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/tasbih_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';

const List<String> _kDefaultPhrases = [
  'سُبْحَانَ اللَّهِ',
  'الْحَمْدُ لِلَّهِ',
  'لَا إِلَهَ إِلَّا اللَّهُ',
  'اللَّهُ أَكْبَرُ',
  'أَسْتَغْفِرُ اللَّهَ',
  'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
  'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
  'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
];

/// مكتبة سبحات/أذكار جاهزة بعدد مستهدف ثابت (راجع `TasbihLog` بـ
/// `user_tables.dart`) — اختيار إحداها يضبط النص/الهدف تلقائياً ويُسجَّل
/// إتمامها بسجل مستقل لعرض "آخر مرة" لاحقاً، بخلاف العدّ الحر/المخصَّص
/// (لا `azkarKey` ثابتاً له فلا يُسجَّل).
class _TasbihLibraryItem {
  const _TasbihLibraryItem({
    required this.key,
    required this.label,
    required this.phrase,
    required this.target,
  });
  final String key;
  final String label;
  final String phrase;
  final int target;
}

const List<_TasbihLibraryItem> _kTasbihLibrary = [
  _TasbihLibraryItem(
    key: 'morning_tasbih',
    label: 'تسبيحة الصباح',
    phrase: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    target: 100,
  ),
  _TasbihLibraryItem(
    key: 'after_prayer_subhan',
    label: 'بعد الصلاة (٣٣ تسبيحة)',
    phrase: 'سُبْحَانَ اللَّهِ',
    target: 33,
  ),
  _TasbihLibraryItem(
    key: 'after_prayer_hamd',
    label: 'بعد الصلاة (٣٣ تحميدة)',
    phrase: 'الْحَمْدُ لِلَّهِ',
    target: 33,
  ),
  _TasbihLibraryItem(
    key: 'after_prayer_takbir',
    label: 'بعد الصلاة (٣٤ تكبيرة)',
    phrase: 'اللَّهُ أَكْبَرُ',
    target: 34,
  ),
  _TasbihLibraryItem(
    key: 'istighfar_100',
    label: 'الاستغفار (١٠٠)',
    phrase: 'أَسْتَغْفِرُ اللَّهَ',
    target: 100,
  ),
  _TasbihLibraryItem(
    key: 'salawat_100',
    label: 'الصلاة على النبي ﷺ (١٠٠)',
    phrase: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    target: 100,
  ),
  _TasbihLibraryItem(
    key: 'tahlil_100',
    label: 'التهليل (١٠٠)',
    phrase: 'لَا إِلَهَ إِلَّا اللَّهُ',
    target: 100,
  ),
];

/// نص "آخر مرة" (اليوم/البارحة/تاريخ) لعرضه ببطاقة سبحة بالمكتبة —
/// `null` يعني لم تكتمل هذه السبحة قط بعد.
String _lastCompletedLabel(DateTime? completedAt) {
  if (completedAt == null) return 'لم تكتمل بعد';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(completedAt.year, completedAt.month, completedAt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'آخر مرة: اليوم';
  if (diff == 1) return 'آخر مرة: البارحة';
  if (diff > 1 && diff < 30) return 'آخر مرة: قبل $diff يوم';
  return 'آخر مرة: ${completedAt.year}/${completedAt.month}/${completedAt.day}';
}

/// شاشة المسبحة الإلكترونية التفاعلية المتقدمة:
/// - لمس بملء الشاشة مع اهتزاز لمسي ذكي (Haptic Feedback) متدرج.
/// - أهداف مخصصة (33، 100، مفتوح) مع مؤشر تقدم دائري ناعم.
/// - حساب الدورات المكتملة والإجمالي التراكمي المحفوظ.
/// - تبديل سريع بين الأذكار المأثورة.
class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen>
    with SingleTickerProviderStateMixin {
  late int _count;
  late int _targetGoal;
  late int _completedCycles;
  late int _totalCount;
  late String _selectedPhrase;
  late bool _vibrationEnabled;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  // --- مكتبة السبحات الجاهزة (راجع _kTasbihLibrary/TasbihLog) ---
  String? _activeLibraryKey;
  final Map<String, DateTime?> _lastCompletedByKey = {};

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(tasbihPrefsProvider);
    _count = prefs.count;
    _targetGoal = prefs.targetGoal;
    _completedCycles = prefs.completedCycles;
    _totalCount = prefs.totalCount;
    _selectedPhrase = prefs.selectedPhrase;
    _vibrationEnabled = prefs.vibrationEnabled;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    unawaited(_loadLastCompletions());
  }

  /// يحمّل "آخر إتمام" لكل سبحات المكتبة دفعة واحدة (استعلامات مستقلة
  /// متوازية) — لا تحميل تسلسلي بطيء لسبع سبحات.
  Future<void> _loadLastCompletions() async {
    final prefs = ref.read(userPrefsProvider);
    final entries = await Future.wait(
      _kTasbihLibrary.map((item) async {
        final last = await prefs.getTasbihLastCompleted(item.key);
        return MapEntry(item.key, last);
      }),
    );
    if (!mounted) return;
    setState(() => _lastCompletedByKey.addEntries(entries));
  }

  /// يختار سبحة جاهزة من المكتبة — يضبط النص/الهدف ويصفّر العدّاد الحالي،
  /// ويربط الجلسة الحالية بمفتاح هذه السبحة (`azkarKey`) لتسجيلها عند
  /// الاكتمال.
  void _selectLibraryItem(_TasbihLibraryItem item) {
    if (_vibrationEnabled) HapticFeedback.selectionClick();
    setState(() {
      _activeLibraryKey = item.key;
      _selectedPhrase = item.phrase;
      _targetGoal = item.target;
      _count = 0;
    });
    final prefs = ref.read(tasbihPrefsProvider);
    prefs.setSelectedPhrase(item.phrase);
    prefs.setTargetGoal(item.target);
    prefs.setCount(0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapIncrement() {
    _animController.forward().then((_) => _animController.reverse());
    final prefs = ref.read(tasbihPrefsProvider);
    var justCompletedLibraryKey = false;

    setState(() {
      _count++;
      _totalCount++;

      if (_vibrationEnabled) {
        HapticFeedback.lightImpact();
      }

      // التحقق من اكتمال الدورة (33 أو 100)
      if (_targetGoal > 0 && _count >= _targetGoal) {
        _completedCycles++;
        _count = 0;
        if (_vibrationEnabled) {
          // اهتزاز تأكيدي مميز ومضاعف عند إتمام الدورة
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 140), () {
            HapticFeedback.heavyImpact();
          });
        }
        if (_activeLibraryKey != null) {
          justCompletedLibraryKey = true;
          _lastCompletedByKey[_activeLibraryKey!] = DateTime.now();
        }
      }
    });

    prefs.setCount(_count);
    prefs.setCompletedCycles(_completedCycles);
    prefs.setTotalCount(_totalCount);

    // تسجيل إتمام سبحة المكتبة بـ`tasbih_log` — العدّ الحر/المخصَّص (بلا
    // مفتاح مكتبة) لا يُسجَّل، راجع توثيق [_TasbihLibraryItem].
    if (justCompletedLibraryKey) {
      final key = _activeLibraryKey!;
      ref.read(userPrefsProvider).logTasbihCompletion(key, _targetGoal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أتممت ${_kTasbihLibrary.firstWhere((i) => i.key == key).label} 🌿',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _decrement() {
    if (_count <= 0 && _totalCount <= 0) return;
    final prefs = ref.read(tasbihPrefsProvider);
    setState(() {
      if (_count > 0) _count--;
      if (_totalCount > 0) _totalCount--;
    });
    if (_vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
    prefs.setCount(_count);
    prefs.setTotalCount(_totalCount);
  }

  void _setGoal(int goal) {
    if (_targetGoal == goal) return;
    setState(() {
      _targetGoal = goal;
      _count = 0;
      _activeLibraryKey = null; // تبديل يدوي = خروج من وضع سبحة المكتبة
    });
    if (_vibrationEnabled) HapticFeedback.selectionClick();
    ref.read(tasbihPrefsProvider).setTargetGoal(goal);
    ref.read(tasbihPrefsProvider).setCount(0);
  }

  void _selectPhrase(String phrase) {
    setState(() {
      _selectedPhrase = phrase;
      _activeLibraryKey = null; // تبديل يدوي = خروج من وضع سبحة المكتبة
    });
    if (_vibrationEnabled) HapticFeedback.selectionClick();
    ref.read(tasbihPrefsProvider).setSelectedPhrase(phrase);
  }

  void _toggleVibration() {
    setState(() => _vibrationEnabled = !_vibrationEnabled);
    if (_vibrationEnabled) HapticFeedback.mediumImpact();
    ref.read(tasbihPrefsProvider).setVibrationEnabled(_vibrationEnabled);
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'إعادة ضبط المسبحة',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'هل ترغب في تصفير عداد الدورة الحالية أم تصفير الإجمالي بالكامل؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _count = 0;
              });
              ref.read(tasbihPrefsProvider).setCount(0);
              if (_vibrationEnabled) HapticFeedback.heavyImpact();
            },
            child: const Text('تصفير الدورة'),
          ),
          AppPrimaryButton(
            label: 'تصفير الكل',
            color: Theme.of(context).colorScheme.error,
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _count = 0;
                _completedCycles = 0;
                _totalCount = 0;
              });
              final prefs = ref.read(tasbihPrefsProvider);
              prefs.setCount(0);
              prefs.setCompletedCycles(0);
              prefs.setTotalCount(0);
              if (_vibrationEnabled) HapticFeedback.heavyImpact();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCustomDhikrDialog() async {
    final phraseCtrl = TextEditingController();
    final goalCtrl = TextEditingController(text: '100');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'إضافة ذكر خاص ➕',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phraseCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'صيغة الذكر (مثلاً: أستغفر الله العظيم)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'العدد المستهدف (مثلاً: 100 أو 33)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          AppPrimaryButton(
            label: 'إضافة والبدء',
            onPressed: () async {
              final phrase = phraseCtrl.text.trim();
              final goal = int.tryParse(goalCtrl.text.trim()) ?? 100;
              if (phrase.isNotEmpty) {
                final prefs = ref.read(tasbihPrefsProvider);
                await prefs.addCustomPhrase(phrase);
                setState(() {
                  _selectedPhrase = phrase;
                  _targetGoal = goal;
                  _count = 0;
                  _activeLibraryKey = null;
                });
                prefs.setSelectedPhrase(phrase);
                prefs.setTargetGoal(goal);
                prefs.setCount(0);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  /// شيت اختيار الذكر — يجمع "سبحات جاهزة" (بهدف وسجل آخر إتمام) و"أذكار
  /// سريعة" (بلا هدف مسجَّل) بمكان واحد خلف ضغطة، بدل عرضهما دائماً
  /// كشريطين أفقيين فوق العداد (راجع توثيق زر الاختيار بـ`build`).
  Future<void> _showPhrasePicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final fg = isDark ? AppColors.inkOnDark : AppColors.navy;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.lineDark : AppColors.line;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'سبحات جاهزة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final item in _kTasbihLibrary)
                  _LibraryItemTile(
                    item: item,
                    isSelected: _activeLibraryKey == item.key,
                    lastLabel: _lastCompletedLabel(
                      _lastCompletedByKey[item.key],
                    ),
                    accent: accent,
                    surface: surface,
                    border: border,
                    fg: fg,
                    onTap: () {
                      _selectLibraryItem(item);
                      Navigator.of(ctx).pop();
                    },
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'أذكار سريعة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final phrase in _kDefaultPhrases)
                      ChoiceChip(
                        label: Text(phrase),
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _selectedPhrase == phrase
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedPhrase == phrase ? Colors.white : fg,
                        ),
                        selected: _selectedPhrase == phrase,
                        selectedColor: accent,
                        backgroundColor: surface,
                        side: BorderSide(
                          color: _selectedPhrase == phrase ? accent : border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (_) {
                          _selectPhrase(phrase);
                          Navigator.of(ctx).pop();
                        },
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final fg = isDark ? AppColors.inkOnDark : AppColors.navy;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.lineDark : AppColors.line;
    final progress = _targetGoal > 0
        ? (_count / _targetGoal).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      // هيدر بتدرّج مطابق لأسلوب لوحة التصميم المعتمدة — `AppBar` عادي
      // بلا لمس هيكل الجسم، فقط زُيِّن بصرياً (`flexibleSpace`).
      appBar: GradientAppBar(
        title: 'المسبحة الإلكترونية',
        centerTitle: true,
        colors: const [AppColors.blue, AppColors.navy],
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة ذكر خاص ➕',
            onPressed: _showAddCustomDhikrDialog,
          ),
          IconButton(
            icon: Icon(
              _vibrationEnabled ? Icons.vibration : Icons.mobile_off_outlined,
              // بلون أبيض معتَّم بدل `fg` (كان يعتمد لون النص العادي —
              // كحلي غامق يختفي فوق هيدر التدرّج الكحلي الجديد).
              color: _vibrationEnabled
                  ? AppColors.gold
                  : Colors.white.withValues(alpha: 0.5),
            ),
            tooltip: _vibrationEnabled ? 'الاهتزاز مفعل' : 'الاهتزاز معطل',
            onPressed: _toggleVibration,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'تصفير',
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // شريط الإحصائيات (الإجمالي والدورات المكتملة)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatBadge(
                      label: 'الدورات المكتملة',
                      value: '$_completedCycles',
                      icon: Icons.loop,
                      accent: accent,
                      surface: surface,
                      border: border,
                      fg: fg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBadge(
                      label: 'إجمالي التسبيحات',
                      value: '$_totalCount',
                      icon: Icons.auto_awesome,
                      accent: accent,
                      surface: surface,
                      border: border,
                      fg: fg,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // شريط اختيار الهدف (33 / 100 / مفتوح)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _GoalTab(
                      label: '٣٣ تسبيحة',
                      selected: _targetGoal == 33,
                      accent: accent,
                      onTap: () => _setGoal(33),
                    ),
                    _GoalTab(
                      label: '١٠٠ تسبيحة',
                      selected: _targetGoal == 100,
                      accent: accent,
                      onTap: () => _setGoal(100),
                    ),
                    _GoalTab(
                      label: 'عدّ حر (مفتوح)',
                      selected: _targetGoal == 0,
                      accent: accent,
                      onTap: () => _setGoal(0),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // زر واحد مدمَج يفتح شيت اختيار الذكر (سبحات جاهزة + أذكار
            // سريعة معاً) — بطلب صاحب المشروع "معجوقة، كثير عناصر بنفس
            // الوقت": كانت هذه الشاشة تعرض شريطين أفقيين كاملين (٧ سبحات +
            // ١٠ أذكار) ظاهرين دائماً فوق العداد، فصار الاختيار خلف زر واحد
            // مضغوط والعداد الرئيسي يظهر مباشرة بلا تمرير عين إضافي.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showPhrasePicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 17, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedPhrase,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.unfold_more_rounded,
                        size: 18,
                        color: fg.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // منطقة اللمس والعداد الرئيسي التفاعلي بملء الشاشة
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTapIncrement,
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            surface,
                            Color.lerp(surface, accent, isDark ? 0.06 : 0.03)!,
                          ],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.16),
                            blurRadius: 40,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // حلقة التقدم الدائرية الناعمة
                          if (_targetGoal > 0)
                            SizedBox(
                              width: 254,
                              height: 254,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                                backgroundColor: accent.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accent,
                                ),
                              ),
                            ),
                          // المحتوى الداخلي للعداد
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // نص الذكر المختار
                                Text(
                                  _selectedPhrase,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // رقم العداد الكبير
                                Text(
                                  '$_count',
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo',
                                    color: fg,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // الهدف
                                Text(
                                  _targetGoal > 0
                                      ? 'الهدف: $_targetGoal'
                                      : 'عدّ مفتوح',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: fg.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w600,
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

            // شريط الإجراء السفلي (تراجع خطوة وتوجيه اللمس)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // زر تراجع خطوة
                  IconButton.filledTonal(
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: 'إنقاص واحدة',
                    onPressed: _count > 0 || _totalCount > 0
                        ? _decrement
                        : null,
                  ),
                  // نص إرشادي
                  Expanded(
                    child: Text(
                      'المس الدائرة أو أي مكان للشاشة للعدّ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: fg.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // زر تصفير سريع للدورة
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'تصفير الدورة',
                    onPressed: _count > 0
                        ? () {
                            setState(() => _count = 0);
                            ref.read(tasbihPrefsProvider).setCount(0);
                            if (_vibrationEnabled)
                              HapticFeedback.mediumImpact();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صف سبحة واحدة بشيت الاختيار [_TasbihScreenState._showPhrasePicker] —
/// عرض عمودي كامل العرض (بدل بطاقة ضيقة ١٥٥ بيكسل بالشريط الأفقي القديم)
/// فيه مساحة كافية لعرض النص والهدف وآخر إتمام معاً بلا اقتطاع.
class _LibraryItemTile extends StatelessWidget {
  const _LibraryItemTile({
    required this.item,
    required this.isSelected,
    required this.lastLabel,
    required this.accent,
    required this.surface,
    required this.border,
    required this.fg,
    required this.onTap,
  });

  final _TasbihLibraryItem item;
  final bool isSelected;
  final String lastLabel;
  final Color accent;
  final Color surface;
  final Color border;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.12) : surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent : border,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: isSelected ? accent : fg.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? accent : fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: fg.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'الهدف ${item.target}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.surface,
    required this.border,
    required this.fg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color surface;
  final Color border;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: fg.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTab extends StatelessWidget {
  const _GoalTab({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
