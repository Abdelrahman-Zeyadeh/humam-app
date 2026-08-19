import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/khatma_prefs.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../mushaf/mushaf_screen.dart';

/// خطة ختمة بسيطة: يحدّد المستخدم عدد الأيام، ونحسب الورد اليومي والتقدّم
/// المتوقّع مقارنة بآخر صفحة قرأها فعلياً (`UserPrefs.lastReadPage`).
/// لا نتتبّع "صفحات اليوم" بجلسة منفصلة بعد — التقدّم تقريبي بمقارنة
/// الصفحة الحالية بالمتوقّعة، لا سجلّ قراءة يومي حقيقي.
class KhatmaScreen extends ConsumerWidget {
  const KhatmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(khatmaVersionProvider); // يجبر إعادة البناء بعد bump()
    final khatmaPrefs = ref.watch(khatmaPrefsProvider);
    final plan = khatmaPrefs.activePlan;
    final userPrefs = ref.watch(userPrefsProvider);
    final currentPage = userPrefs.lastReadPage ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text('خطة الختمة')),
      body: plan == null
          ? _StartPlanView(onStart: (days) async {
              await khatmaPrefs.start(days);
              ref.read(khatmaVersionProvider.notifier).bump();
            })
          : _ActivePlanView(
              plan: plan,
              currentPage: currentPage,
              streakDays: userPrefs.streakDays,
              onCancel: () async {
                await khatmaPrefs.cancel();
                ref.read(khatmaVersionProvider.notifier).bump();
              },
            ),
    );
  }
}

class _StartPlanView extends StatefulWidget {
  const _StartPlanView({required this.onStart});
  final ValueChanged<int> onStart;

  @override
  State<_StartPlanView> createState() => _StartPlanViewState();
}

class _StartPlanViewState extends State<_StartPlanView> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.gold),
            const SizedBox(height: 16),
            const Text('حدّد عدد الأيام لختم المصحف', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('الورد اليومي: ${(604 / _days).ceil()} صفحة', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            const SizedBox(height: 20),
            Slider(
              value: _days.toDouble(),
              min: 7,
              max: 604,
              divisions: 100,
              label: '$_days يوماً',
              onChanged: (v) => setState(() => _days = v.round()),
            ),
            Wrap(
              spacing: 8,
              children: [7, 30, 60, 604].map((d) {
                return ChoiceChip(
                  label: Text(d == 604 ? 'يوم بيوم (604)' : '$d يوماً'),
                  selected: _days == d,
                  onSelected: (_) => setState(() => _days = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => widget.onStart(_days), child: const Text('ابدأ الختمة')),
          ],
        ),
      ),
    );
  }
}

class _ActivePlanView extends StatelessWidget {
  const _ActivePlanView({required this.plan, required this.currentPage, required this.streakDays, required this.onCancel});
  final KhatmaPlan plan;
  final int currentPage;
  final int streakDays;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final progress = (currentPage / 604).clamp(0.0, 1.0);
    final onTrack = currentPage >= plan.expectedPageByNow;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('${(progress * 100).round()}٪', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.gold)),
                  const SizedBox(height: 4),
                  Text('صفحة $currentPage من 604', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: AppColors.line),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'سلسلة أيام القراءة', value: '$streakDays 🔥'),
          _InfoRow(label: 'الورد اليومي', value: '${plan.dailyPages} صفحة'),
          _InfoRow(label: 'تاريخ البدء', value: _formatDate(plan.startDate)),
          _InfoRow(label: 'الانتهاء المتوقّع', value: _formatDate(plan.expectedEndDate)),
          _InfoRow(
            label: 'الحالة',
            value: onTrack ? 'ملتزم بالورد 👍' : 'متأخّر عن الورد — الصفحة ${plan.expectedPageByNow} متوقّعة اليوم',
            valueColor: onTrack ? AppColors.teal : const Color(0xFFB3261E),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MushafScreen())),
            child: const Text('تابع القراءة'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onCancel, child: const Text('إلغاء الخطة')),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) => '${d.year}/${d.month}/${d.day}';
