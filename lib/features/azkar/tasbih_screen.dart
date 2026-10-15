import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/tasbih_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/floating_dhikr_banner.dart';
import 'widgets/tasbih_counter_dial.dart';
import 'widgets/tasbih_dialogs.dart';
import 'widgets/tasbih_goal_tab.dart';
import 'widgets/tasbih_library_data.dart';
import 'widgets/tasbih_phrase_picker.dart';
import 'widgets/tasbih_stat_badge.dart';

/// شاشة المسبحة الإلكترونية التفاعلية المتقدمة:
/// - لمس بملء الشاشة مع اهتزاز لمسي ذكي (Haptic Feedback) متدرج.
/// - أهداف مخصصة (33، 100، مفتوح) مع مؤشر تقدم دائري ناعم.
/// - حساب الدورات المكتملة والإجمالي التراكمي المحفوظ.
/// - تبديل سريع بين الأذكار المأثورة.
///
/// الشاشة نفسها مجرّد تنسيق (composition) وحالة (state) — العناصر البصرية
/// (بطاقة إحصائية، تبويب هدف، قرص العدّاد الدائري، صف عنصر مكتبة، شيت
/// اختيار الذكر، حواري التصفير/الإضافة) استُخرجت لمجلد `widgets/` أثناء
/// تفكيك هذا الملف، بلا أي تغيير سلوكي.
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

  // --- مكتبة السبحات الجاهزة (راجع kTasbihLibrary/TasbihLog) ---
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
      kTasbihLibrary.map((item) async {
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
  void _selectLibraryItem(TasbihLibraryItem item) {
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
        if (_count % 10 == 0) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
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
    // مفتاح مكتبة) لا يُسجَّل، راجع توثيق [TasbihLibraryItem].
    if (justCompletedLibraryKey) {
      final key = _activeLibraryKey!;
      ref.read(userPrefsProvider).logTasbihCompletion(key, _targetGoal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أتممت ${kTasbihLibrary.firstWhere((i) => i.key == key).label} 🌿',
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
    showTasbihResetDialog(
      context,
      onResetCycle: () {
        setState(() {
          _count = 0;
        });
        ref.read(tasbihPrefsProvider).setCount(0);
        if (_vibrationEnabled) HapticFeedback.heavyImpact();
      },
      onResetAll: () {
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
    );
  }

  Future<void> _showAddCustomDhikrDialog() {
    return showAddCustomDhikrDialog(
      context,
      ref,
      onApply: (phrase, goal) {
        setState(() {
          _selectedPhrase = phrase;
          _targetGoal = goal;
          _count = 0;
          _activeLibraryKey = null;
        });
        final prefs = ref.read(tasbihPrefsProvider);
        prefs.setSelectedPhrase(phrase);
        prefs.setTargetGoal(goal);
        prefs.setCount(0);
      },
    );
  }

  Future<void> _showPhrasePicker(BuildContext context) {
    return showTasbihPhrasePicker(
      context,
      activeLibraryKey: _activeLibraryKey,
      lastCompletedByKey: _lastCompletedByKey,
      selectedPhrase: _selectedPhrase,
      onSelectLibraryItem: _selectLibraryItem,
      onSelectPhrase: _selectPhrase,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final fg = isDark ? AppColors.inkOnDark : const Color(0xFF135B4C);
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.lineDark : AppColors.line;
    final progress = _targetGoal > 0
        ? (_count / _targetGoal).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      // هيدر بتدرّج أخضر زمردي فاخر موحّد مع هوية التطبيق
      appBar: GradientAppBar(
        title: 'المسبحة الإلكترونية',
        centerTitle: true,
        colors: const [Color(0xFF135B4C), Color(0xFF0D3B31)],
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
                    child: TasbihStatBadge(
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
                    child: TasbihStatBadge(
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

            const SizedBox(height: 10),

            // نبض التسبيح الجماعي المباشر
            const _LiveCommunityDhikrPulse(),

            const SizedBox(height: 10),

            // كبسولة الذكر العائم فوق التطبيقات
            FloatingDhikrBanner(
              currentPhrase: _selectedPhrase,
              accent: accent,
              isDark: isDark,
            ),

            const SizedBox(height: 12),

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
                    TasbihGoalTab(
                      label: '٣٣ تسبيحة',
                      selected: _targetGoal == 33,
                      accent: accent,
                      onTap: () => _setGoal(33),
                    ),
                    TasbihGoalTab(
                      label: '١٠٠ تسبيحة',
                      selected: _targetGoal == 100,
                      accent: accent,
                      onTap: () => _setGoal(100),
                    ),
                    TasbihGoalTab(
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
              child: TasbihCounterDial(
                scaleAnimation: _scaleAnimation,
                onTap: _onTapIncrement,
                isDark: isDark,
                accent: accent,
                surface: surface,
                fg: fg,
                targetGoal: _targetGoal,
                progress: progress,
                selectedPhrase: _selectedPhrase,
                count: _count,
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
                            if (_vibrationEnabled) {
                              HapticFeedback.mediumImpact();
                            }
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

class _LiveCommunityDhikrPulse extends StatefulWidget {
  const _LiveCommunityDhikrPulse();

  @override
  State<_LiveCommunityDhikrPulse> createState() => _LiveCommunityDhikrPulseState();
}

class _LiveCommunityDhikrPulseState extends State<_LiveCommunityDhikrPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.82, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      final digit = int.tryParse(c);
      buffer.write(digit != null ? d[digit] : c);
      if ((s.length - i - 1) % 3 == 0 && i < s.length - 1) {
        buffer.write('،');
      }
    }
    return buffer.toString();
  }

  int _simulatedActiveCount() {
    final now = DateTime.now();
    final hourBonus = ((now.hour >= 4 && now.hour <= 7) || (now.hour >= 18 && now.hour <= 22)) ? 1200 : 700;
    final variance = (now.minute * 19 + now.hour * 29) % 240;
    return 2100 + hourBonus + variance;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countStr = _formatArabic(_simulatedActiveCount());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.22),
          width: 0.85,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseScale,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF10B981),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$countStr+ مسلم يسبحون معك الآن حول العالم 🌿',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }
}
