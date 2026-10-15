import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../mushaf/mushaf_screen.dart';
import '../mushaf/mushaf_surah_index_sheet.dart';

Color _textSoft(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkSoftOnDark
    : AppColors.inkSoft;

/// خطط ختمة: يحدّد المستخدم عدد الأيام أو مقدار القراءة اليومي (بوحدات
/// المصحف التقليدية)، ونقطة بداية اختيارية (لا صفحة ١ إلزامياً). **أكثر
/// من خطة بنفس الوقت** (بطلب صاحب المشروع: توحيد سلوك الختمة مع قسم
/// الحفظ) — راجع توثيق `KhatmaPlan` بـ`user_repository.dart`. تقدّم كل
/// خطة **مستقل تماماً** عن القراءة العامة (`plan.currentPage`، يُحدَّث
/// فقط أثناء "تابع القراءة" لهذه الخطة تحديداً — راجع
/// `MushafScreen.khatmaPracticeMode`).
class KhatmaScreen extends ConsumerWidget {
  const KhatmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(khatmaVersionProvider); // يجبر إعادة البناء بعد bump()
    final khatmaPrefs = ref.watch(khatmaPrefsProvider);
    final plans = khatmaPrefs.activePlans;
    final userPrefs = ref.watch(userPrefsProvider);
    final suggestedStartPage = userPrefs.lastReadPage ?? 1;

    return Scaffold(
      // هيدر بتدرّج كحلي مطابق للوحة التصميم المعتمدة (`Plans.dc.html`) —
      // بقي `AppBar` عادياً بلا لمس هيكل الجسم (`body`)، فقط زُيِّن بصرياً
      // (`flexibleSpace` + شكل حواف سفلية دائرية) بدل خلفية بيضاء مسطّحة.
      appBar: const GradientAppBar(
        title: 'خطة الختمة',
        colors: [AppColors.blue, AppColors.navy],
      ),
      body: plans.isEmpty
          ? _StartPlanView(
              initialStartPage: suggestedStartPage,
              onStart: (days, startPage) =>
                  _start(context, ref, days, startPage),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final plan in plans) ...[
                  _ActivePlanView(
                    plan: plan,
                    streakDays: userPrefs.streakDays,
                    onCancel: () => _confirmCancel(context, ref, plan),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('خطة ختمة جديدة'),
                  onPressed: () =>
                      _startNewPlanSheet(context, ref, suggestedStartPage),
                ),
              ],
            ),
    );
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    int days,
    int startPage,
  ) async {
    await ref.read(khatmaPrefsProvider).start(days, startPage: startPage);
    ref.read(khatmaVersionProvider.notifier).bump();
  }

  Future<void> _startNewPlanSheet(
    BuildContext context,
    WidgetRef ref,
    int suggestedStartPage,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _StartPlanView(
            initialStartPage: suggestedStartPage,
            onStart: (days, startPage) async {
              await _start(context, ref, days, startPage);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    KhatmaPlan plan,
  ) async {
    // تأكيد قبل الحذف — بلا تراجع، نفس نمط `hifz_screen.dart._confirmDelete`.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء خطة الختمة؟'),
        content: const Text(
          'لن يمكن التراجع عن هذا — يمكنك بدء خطة جديدة لاحقاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إلغاء الخطة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(khatmaPrefsProvider).cancel(plan.id);
    ref.read(khatmaVersionProvider.notifier).bump();
  }
}

/// طريقتا تحديد خطة الختمة: كم يوم، أو مقدار القراءة اليومي بوحدات المصحف
/// التقليدية — بطلب صاحب المشروع: "شيل كم اية ومقدار القراءة خليه مثلا
/// حزب وربع نص حزب جزء ثلاثة اجزاء وبتحكيله كم صفحة"، ثم "مقدار القراءة
/// مش هيك ثابت خليه اتحكم فيه ازيد وانقص زي عداد" (شرائح ثابتة أولاً، ثم
/// طُلب عدّاد +/- بدلها).
enum _PlanMode { days, unit }

/// وحدة القياس الذرّية "ربع حزب" (٦٠٤ ÷ ٢٤٠) — العدّاد يتحرّك بخطوات
/// ربع-حزب، و[_quarterHizbLabel] يترجم أي عدد أرباع لنص عربي مفهوم
/// (حزب/أحزاب + كسر متبقٍّ). ٢٤٠ ربعاً = المصحف كاملاً كحد أقصى منطقي.
const double _kQuarterHizbPages = 604 / 240;
const int _kMaxQuarters = 240;

const Map<int, String> _kFractionLabel = {1: 'ربع', 2: 'نصف', 3: 'ثلاثة أرباع'};

/// نص العدد الحالي من الأرباع — مثلاً ٤ → "حزب"، ٦ → "حزب ونصف"،
/// ٣ → "ثلاثة أرباع حزب"، **وبطلب صاحب المشروع "احكي كم الجزء... بس يصير
/// حزبان يوضح انه جزء"**: أي مضاعف لـ٨ أرباع (= حزبان = جزء كامل) يُعرَض
/// بوحدة "جزء" مباشرة بدل "حزبان"/"٤ أحزاب" — ٨ → "جزء"، ١٦ → "جزءان"،
/// ٢٤ → "٣ أجزاء". غير مضاعفات ٨ (حزب أو ٣ أحزاب مثلاً) تبقى بوحدة الحزب.
String _quarterHizbLabel(int quarters) {
  if (quarters % 8 == 0) {
    final juz = quarters ~/ 8;
    return switch (juz) {
      1 => 'جزء',
      2 => 'جزءان',
      _ => '$juz أجزاء',
    };
  }
  final hizb = quarters ~/ 4;
  final rest = quarters % 4;
  if (hizb == 0) return '${_kFractionLabel[rest]} حزب';
  final hizbPart = switch (hizb) {
    1 => 'حزب',
    2 => 'حزبان',
    _ => '$hizb أحزاب',
  };
  return rest == 0 ? hizbPart : '$hizbPart و${_kFractionLabel[rest]}';
}

class _StartPlanView extends StatefulWidget {
  const _StartPlanView({required this.initialStartPage, required this.onStart});
  final int initialStartPage;

  /// `(days, startPage)`.
  final void Function(int days, int startPage) onStart;

  @override
  State<_StartPlanView> createState() => _StartPlanViewState();
}

class _StartPlanViewState extends State<_StartPlanView> {
  _PlanMode _mode = _PlanMode.days;
  int _days = 30;
  int _quarters = 4; // افتراضي: حزب واحد يومياً
  late int _startPage = widget.initialStartPage;

  /// عدد الصفحات المتبقّية للختمة من نقطة البداية المختارة — ٦٠٤ لو بدأت
  /// من الصفحة ١.
  int get _totalPagesToRead => 604 - _startPage + 1;

  double get _unitPages => _quarters * _kQuarterHizbPages;

  int get _computedDays => switch (_mode) {
    _PlanMode.days => _days,
    _PlanMode.unit => (_totalPagesToRead / _unitPages).ceil().clamp(1, 604),
  };

  Future<void> _pickStartPage() async {
    final page = await MushafSurahIndexSheet.show(
      context,
      currentPage: _startPage,
    );
    if (page != null && mounted) setState(() => _startPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: themeAccent(context),
            ),
            const SizedBox(height: 16),
            const Text(
              'خطة الختمة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            // نقطة البداية — مقترحة تلقائياً من آخر صفحة مقروءة فعلياً،
            // قابلة للتغيير من فهرس المصحف مباشرة. بطلب صاحب المشروع "ضيف
            // اقتراح مكان بداية الختمة".
            OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_border, size: 18),
              label: Text(
                _startPage == widget.initialStartPage
                    ? 'نقطة البداية: صفحة $_startPage (من حيث توقّفت)'
                    : 'نقطة البداية: صفحة $_startPage',
              ),
              onPressed: _pickStartPage,
            ),
            const SizedBox(height: 20),
            SegmentedButton<_PlanMode>(
              segments: const [
                ButtonSegment(value: _PlanMode.days, label: Text('كم يوم')),
                ButtonSegment(
                  value: _PlanMode.unit,
                  label: Text('مقدار القراءة'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 20),
            switch (_mode) {
              _PlanMode.days => _PresetStepper(
                presets: const [7, 14, 30, 60],
                presetSuffix: 'يوم',
                value: _days,
                min: 1,
                max: 604,
                onChanged: (v) => setState(() => _days = v),
                summary:
                    'الورد اليومي: ${(_totalPagesToRead / _days).ceil()} صفحة تقريباً',
              ),
              // بلا شرائح جاهزة هون — بطلب صاحب المشروع "مقدار القراءة...
              // شيل الثوابت خليه عداد": عدّاد +/- بحت لمقدار القراءة (خلافاً
              // لوضع "كم يوم" الذي أبقى شرائحه، لم يُشتكَ منها).
              _PlanMode.unit => _PresetStepper(
                presets: const [],
                value: _quarters,
                min: 1,
                max: _kMaxQuarters,
                onChanged: (v) => setState(() => _quarters = v),
                labelBuilder: _quarterHizbLabel,
                summary:
                    'كل يوم ~${_unitPages.toStringAsFixed(1)} صفحة — ختمة كل ~$_computedDays يوماً',
              ),
            },
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => widget.onStart(_computedDays, _startPage),
              child: const Text('ابدأ الختمة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// شرائح جاهزة (`presets`) + خطوة يدوية دقيقة (+/-) لقيمة رقمية واحدة —
/// بطلب صاحب المشروع "مقدار القراءة مش هيك ثابت خليه اتحكم فيه ازيد
/// وانقص زي عداد" (كانت شرائح ثابتة بلا +/- بوضع "مقدار القراءة"، صار
/// [_PresetStepper] هذا مستخدَماً بكلا الوضعين الآن). [labelBuilder]
/// اختياري لتنسيق نص غير خطي (مثلاً "حزب ونصف" بدل رقم خام) — لو غاب
/// يُستخدَم `'$value $presetSuffix'` العادي.
class _PresetStepper extends StatelessWidget {
  const _PresetStepper({
    required this.presets,
    this.presetSuffix = '',
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.summary,
    this.labelBuilder,
  });
  final List<int> presets;
  final String presetSuffix;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String summary;
  final String Function(int)? labelBuilder;

  String _label(int v) => labelBuilder?.call(v) ?? '$v $presetSuffix';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // بلا شرائح إطلاقاً لو `presets` فارغة — عدّاد +/- بحت (راجع توثيق
        // موقع الاستدعاء بوضع "مقدار القراءة").
        if (presets.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: presets.map((p) {
              return ChoiceChip(
                label: Text(_label(p)),
                selected: value == p,
                onSelected: (_) => onChanged(p),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 110,
              child: Text(
                _label(value),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          summary,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
        ),
      ],
    );
  }
}

class _ActivePlanView extends StatelessWidget {
  const _ActivePlanView({
    required this.plan,
    required this.streakDays,
    required this.onCancel,
  });
  final KhatmaPlan plan;
  final int streakDays;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final onTrack = plan.currentPage >= plan.expectedPageByNow;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // بطاقة واحدة موحَّدة (بدل بطاقة متداخلة بإطار خارجي مضاعف) — بطلب
    // صاحب المشروع "لو تحسّن شكلها"، بنفس لغة التصميم المعتمدة بباقي
    // الشاشات (حلقة تقدّم دائرية، شبكة إحصاءات مصغّرة، بطاقة حالة ملوّنة).
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: plan.progress.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: themeAccent(
                          context,
                        ).withValues(alpha: 0.13),
                        valueColor: AlwaysStoppedAnimation(
                          themeAccent(context),
                        ),
                      ),
                    ),
                    Text(
                      '${(plan.progress * 100).round()}٪',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: themeAccent(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صفحة ${plan.currentPage} من ٦٠٤',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      onTrack
                          ? 'ملتزم بالورد 👍'
                          : 'متأخّر — الصفحة ${plan.expectedPageByNow} متوقّعة اليوم',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: onTrack
                            ? AppColors.tealDeep
                            : const Color(0xFFB3261E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // --- شريط التقدم اليومي ---
          _DailyProgressBar(plan: plan),
          const SizedBox(height: 14),
          // شبكة إحصاءات مصغّرة (بدل قائمة تسمية/قيمة مسطّحة طويلة).
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.local_fire_department_outlined,
                  label: 'سلسلة القراءة',
                  value: '$streakDays 🔥',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  icon: Icons.menu_book_outlined,
                  label: 'الورد اليومي',
                  value: '${plan.dailyPages} صفحة',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.flag_outlined,
                  label: 'نقطة البداية',
                  value: plan.startPage == 1
                      ? 'صفحة ١'
                      : 'صفحة ${plan.startPage}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  icon: Icons.event_available_outlined,
                  label: 'الانتهاء المتوقّع',
                  value: _formatDate(plan.expectedEndDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  // تابع من موضع **هذه الخطة تحديداً** (`plan.currentPage`)، لا
                  // آخر صفحة قراءة عامة — بطلب صاحب المشروع: "التقدم يكون
                  // مختلف عن التقدم الحالي". راجع `MushafScreen.khatmaPracticeMode`.
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MushafScreen(
                        initialPage: plan.currentPage,
                        khatmaPracticeMode: true,
                        khatmaPlanId: plan.id,
                      ),
                    ),
                  ),
                  child: const Text('تابع القراءة'),
                ),
              ),
              const SizedBox(width: 8),
              // زر "تمت القراءة" — يُسجّل صفحات الورد اليومي بدون فتح المصحف
              // (مفيد لو قرأ المستخدم من مصحف عادي أو بمكان آخر).
              _MarkDoneButton(plan: plan),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'إلغاء الخطة',
                color: _textSoft(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// إحصاء مصغَّر بأيقونة — يعرض تسمية/قيمة داخل صندوق خفيف الصبغة، مطابق
/// لأسلوب "شبكة الإحصاءات" باقي الشاشات المُعاد تصميمها (بدل قائمة
/// تسمية/قيمة نصية طويلة `_InfoRow` سابقاً).
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _textSoft(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9.5, color: _textSoft(context)),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
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

String _formatDate(DateTime d) => '${d.year}/${d.month}/${d.day}';

// ---------------------------------------------------------------------------
// شريط التقدم اليومي
// ---------------------------------------------------------------------------

/// يحسب كم صفحة قرأ المستخدم اليوم لهذه الخطة (الفرق بين `currentPage`
/// وما يجب أن تكون عليه في نهاية أمس) ويرسم شريطاً يوضّح التقدم نحو الورد
/// اليومي الكامل وكم صفحة باقية.
class _DailyProgressBar extends StatelessWidget {
  const _DailyProgressBar({required this.plan});
  final KhatmaPlan plan;

  @override
  Widget build(BuildContext context) {
    final accent = themeAccent(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // الصفحة المتوقَّعة في نهاية أمس = المتوقَّعة اليوم ناقص ورد يوم واحد.
    final expectedYesterday =
        (plan.startPage - 1 + (plan.daysElapsed - 1) * plan.dailyPages)
            .clamp(plan.startPage - 1, 604);
    final readToday = (plan.currentPage - expectedYesterday).clamp(0, plan.dailyPages + 20);
    final dailyTarget = plan.dailyPages;
    final remainingToday = (dailyTarget - readToday).clamp(0, dailyTarget);
    final ratio = dailyTarget > 0
        ? (readToday / dailyTarget).clamp(0.0, 1.0)
        : 1.0;
    final done = readToday >= dailyTarget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.today_outlined,
              size: 14,
              color: done ? AppColors.tealDeep : _textSoft(context),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                done
                    ? 'أتممت ورد اليوم بحمد الله 🎉'
                    : 'ورد اليوم: $readToday من $dailyTarget صفحة (متبقٍّ $remainingToday)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.tealDeep : onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            Text(
              '${(ratio * 100).round()}٪',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: accent.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(done ? AppColors.tealDeep : accent),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// زر "تمت القراءة"
// ---------------------------------------------------------------------------

/// زر إجراء يُتيح تسجيل ورد اليوم يدوياً بدون فتح المصحف (إذا قرأ من مصحف ورقي أو مكان آخر).
class _MarkDoneButton extends ConsumerWidget {
  const _MarkDoneButton({required this.plan});
  final KhatmaPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expectedYesterday =
        (plan.startPage - 1 + (plan.daysElapsed - 1) * plan.dailyPages)
            .clamp(plan.startPage - 1, 604);
    final readToday = (plan.currentPage - expectedYesterday).clamp(0, plan.dailyPages + 20);
    final done = readToday >= plan.dailyPages;

    return Tooltip(
      message: done ? 'أتممت ورد اليوم' : 'تمت القراءة من مصحف آخر',
      child: OutlinedButton.icon(
        icon: Icon(
          done ? Icons.check_circle_rounded : Icons.done_all_rounded,
          size: 16,
          color: done ? AppColors.tealDeep : null,
        ),
        label: Text(
          done ? 'مكتمل' : 'تمت القراءة',
          style: TextStyle(
            fontSize: 12,
            color: done ? AppColors.tealDeep : null,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 36),
          side: done
              ? const BorderSide(color: AppColors.tealDeep, width: 1.3)
              : null,
        ),
        onPressed: done
            ? null
            : () async {
                final newPage = (plan.currentPage + plan.dailyPages).clamp(
                  plan.currentPage,
                  604,
                );
                await ref
                    .read(khatmaPrefsProvider)
                    .updateCurrentPage(plan.id, newPage);
                // تحديث سلسلة القراءة اليومية أيضاً
                await ref.read(userPrefsProvider).bumpStreakIfNewDay();
                ref.read(khatmaVersionProvider.notifier).bump();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'بارك الله فيك، تم احتساب الورد — الصفحة $newPage من ٦٠٤ 📖',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
      ),
    );
  }
}

