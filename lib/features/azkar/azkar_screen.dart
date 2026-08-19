import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'azkar_progress.dart';
import 'azkar_repository.dart';
import 'tasbih_screen.dart';

class _PeriodNotifier extends Notifier<AzkarPeriod> {
  @override
  AzkarPeriod build() => AzkarPeriod.morning;

  void set(AzkarPeriod p) => state = p;
}

final _periodProvider = NotifierProvider<_PeriodNotifier, AzkarPeriod>(_PeriodNotifier.new);

/// أذكار الصباح والمساء: قائمة قابلة للضغط، كل ذكر يُعدّ تنازلياً بالضغط
/// عليه — نفس نمط تطبيقات الأذكار المعروفة. راجع `azkar_repository.dart`
/// لمصدر البيانات وقيوده.
class AzkarScreen extends ConsumerWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final azkarAsync = ref.watch(azkarListProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة ضبط العدّ',
            onPressed: () => ref.read(azkarProgressProvider.notifier).resetAll(),
          ),
          IconButton(
            icon: const Icon(Icons.fingerprint),
            tooltip: 'المسبحة',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasbihScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<AzkarPeriod>(
              segments: const [
                ButtonSegment(value: AzkarPeriod.morning, label: Text('الصباح'), icon: Icon(Icons.wb_sunny_outlined)),
                ButtonSegment(value: AzkarPeriod.evening, label: Text('المساء'), icon: Icon(Icons.nights_stay_outlined)),
              ],
              selected: {period},
              onSelectionChanged: (s) => ref.read(_periodProvider.notifier).set(s.first),
            ),
          ),
          Expanded(
            child: azkarAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('تعذّر تحميل الأذكار')),
              data: (all) {
                final list = all.where((d) => d.appliesTo(period)).toList();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _DhikrCard(dhikr: list[i], onSurface: onSurface),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DhikrCard extends ConsumerWidget {
  const _DhikrCard({required this.dhikr, required this.onSurface});
  final Dhikr dhikr;
  final Color onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(azkarProgressProvider.select((m) => m[dhikr.order] ?? dhikr.count));
    final done = remaining <= 0;

    return Card(
      color: done ? AppColors.teal.withValues(alpha: 0.08) : null,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(azkarProgressProvider.notifier).tap(dhikr.order, dhikr.count),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                dhikr.content,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: done ? onSurface.withValues(alpha: 0.45) : onSurface, fontSize: 16, height: 1.8),
              ),
              if (dhikr.fadl != null) ...[
                const SizedBox(height: 8),
                Text(dhikr.fadl!, style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 12, height: 1.6)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: done ? AppColors.teal : AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    done ? 'تمّ' : '$remaining من ${dhikr.count}',
                    style: TextStyle(color: done ? AppColors.teal : AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
