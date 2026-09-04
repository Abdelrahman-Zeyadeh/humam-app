import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../duroos/duroos_audio_providers.dart';
import '../duroos/duroos_screen.dart';
import 'quran_radio_screen.dart';
import 'radio_audio_providers.dart';

/// خيارات مدة مؤقّت النوم — يوقف البث/المحاضرة تلقائياً بعد المدة
/// المختارة بدل ترك الصوت يشتغل طول الليل بلا داعٍ.
const List<int> _kSleepTimerMinutes = [10, 20, 30, 45, 60, 90];

/// مدخل واحد موحَّد لـ"الإذاعة" و"الدروس" — كانتا بطاقتين منفصلتين بشاشة
/// "أدواتي" (بطلب صاحب المشروع دمجهما لتقليل الزحمة، نفس هدف تنظيف تلك
/// الشاشة الأسبق من ٢١→١٥ عنصراً). **دمج بمستوى التنقّل فقط، لا خلط
/// محتوى** — نموذجا التفاعل مختلفان جوهرياً (بث حي بلا تقديم/ترجيع مقابل
/// أرشيف محاضرات بشريط تقدّم كامل)، فكل تبويب يستضيف شاشته الأصلية كاملة
/// بلا أي تعديل بمنطقها الداخلي، فقط أُزيل الـ`AppBar`/`Scaffold` الخاص
/// بكل واحدة (راجع التعليق أعلى كل من `QuranRadioScreen`/`DuroosScreen`)
/// لتفادي شريط عنوان مزدوج.
///
/// **مؤقّت النوم**: مشترك بين التبويبين عمداً (زر واحد بالـ`AppBar` لا
/// اثنان) — وقت الاستماع الليلي لا يهم غالباً أي تبويب كان مفتوحاً وقت
/// الضغط، فبدل تخمين "أي مشغّل يقصد المستخدم"، المؤقّت يوقف (`pause`)
/// أي مشغّل يشتغل فعلياً على [radioAudioPlayerProvider]/
/// [duroosAudioPlayerProvider] معاً عند انتهاء المدة — تشغيل الاثنين
/// معاً أصلاً حالة نادرة جداً (لا واجهة تشجّع عليها).
class RadioAndDuroosScreen extends ConsumerStatefulWidget {
  const RadioAndDuroosScreen({super.key});

  @override
  ConsumerState<RadioAndDuroosScreen> createState() =>
      _RadioAndDuroosScreenState();
}

class _RadioAndDuroosScreenState extends ConsumerState<RadioAndDuroosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _sleepFireTimer;
  Timer? _sleepTickTimer;
  DateTime? _sleepEndsAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sleepFireTimer?.cancel();
    _sleepTickTimer?.cancel();
    super.dispose();
  }

  void _startSleepTimer(int minutes) {
    _sleepFireTimer?.cancel();
    _sleepTickTimer?.cancel();
    setState(() => _sleepEndsAt = DateTime.now().add(Duration(minutes: minutes)));

    _sleepFireTimer = Timer(Duration(minutes: minutes), () {
      // يوقف مؤقتاً (لا يصفّر التقدّم) — نفس سلوك "مؤقّت نوم" بأي تطبيق
      // موسيقى معروف، يسمح باستئناف الاستماع من نفس النقطة لاحقاً.
      ref.read(radioAudioPlayerProvider).pause();
      ref.read(duroosAudioPlayerProvider).pause();
      if (mounted) setState(() => _sleepEndsAt = null);
    });

    // عدّاد تنازلي بصري فقط بالـ`AppBar` — يعيد البناء كل دقيقة، لا حمل
    // فعلي على الأداء.
    _sleepTickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _cancelSleepTimer() {
    _sleepFireTimer?.cancel();
    _sleepTickTimer?.cancel();
    setState(() => _sleepEndsAt = null);
  }

  void _showSleepTimerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        final onSurface = Theme.of(sheetCtx).colorScheme.onSurface;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bedtime_outlined, color: themeAccent(sheetCtx)),
                    const SizedBox(width: 10),
                    Text(
                      'مؤقّت النوم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'يوقف الاستماع تلقائياً بعد المدة المختارة',
                  style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in _kSleepTimerMinutes)
                      ChoiceChip(
                        label: Text('$m د'),
                        selected: false,
                        onSelected: (_) {
                          _startSleepTimer(m);
                          Navigator.of(sheetCtx).pop();
                        },
                      ),
                  ],
                ),
                if (_sleepEndsAt != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      _cancelSleepTimer();
                      Navigator.of(sheetCtx).pop();
                    },
                    icon: const Icon(Icons.timer_off_outlined, size: 18),
                    label: const Text('إلغاء المؤقّت الحالي'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                      side: const BorderSide(color: Color(0xFFC0392B)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _sleepEndsAt?.difference(DateTime.now());
    final remainingMinutes = remaining == null
        ? null
        : (remaining.inSeconds / 60).ceil().clamp(0, 999);

    return Scaffold(
      // هيدر بتدرّج مطابق لأسلوب لوحة التصميم المعتمدة — `AppBar` عادي
      // بلا لمس هيكل الجسم، فقط زُيِّن بصرياً (`flexibleSpace`).
      appBar: GradientAppBar(
        title: 'الإذاعة والدروس الصوتية',
        colors: const [AppColors.blue, AppColors.navy],
        actions: [
          IconButton(
            tooltip: 'مؤقّت النوم',
            onPressed: _showSleepTimerSheet,
            icon: remainingMinutes == null
                ? const Icon(Icons.bedtime_outlined)
                : Badge(
                    label: Text('$remainingMinutes'),
                    backgroundColor: AppColors.gold,
                    child: const Icon(Icons.bedtime),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: '🔴 بث مباشر'),
            Tab(text: '🎓 دروس مسجّلة'),
          ],
        ),
      ),
      // `TabBarView` يبني التبويبين معاً ويبقيهما بالذاكرة طول عمر هالشاشة
      // (بعكس `Navigator.push` المؤقّت) — يعني تبديل التبويب لا يقطع بث
      // الراديو ولا يفقد حالة البحث/التصنيف المختار بتبويب الإذاعة.
      body: TabBarView(
        controller: _tabController,
        children: const [QuranRadioScreen(), DuroosScreen()],
      ),
    );
  }
}
