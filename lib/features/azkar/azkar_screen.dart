import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../../core/theme/app_colors.dart';
import '../qiyam/qiyam_screen.dart';
import 'azkar_full_repository.dart';
import 'azkar_library_progress.dart';
import 'azkar_progress.dart';
import 'azkar_repository.dart';
import 'streak_status_row.dart';
import 'tasbih_screen.dart';

/// خانة الأذكار المعروضة بشاشة `AzkarScreen` الرئيسية — منفصلة عن
/// `AzkarPeriod` (نموذج بيانات الصباح/المساء فقط بـ`azkar_repository.dart`)
/// لأن "النوم" مصدرها مختلف (قسم من مكتبة حصن المسلم الكاملة، لا ملف
/// azkar.json المخصَّص). كل خانة مربوطة بفئة سلسلة استمرار مستقلة
/// (`UserCategories`).
enum _Segment {
  morning(UserCategories.morningAzkar),
  evening(UserCategories.eveningAzkar),
  night(UserCategories.nightAzkar);

  const _Segment(this.category);
  final String category;
}

class _SegmentNotifier extends Notifier<_Segment> {
  @override
  _Segment build() => _Segment.morning;

  void set(_Segment s) => state = s;
}

final _segmentProvider = NotifierProvider<_SegmentNotifier, _Segment>(_SegmentNotifier.new);

/// أذكار الصباح والمساء والنوم: قائمة قابلة للضغط، كل ذكر يُعدّ تنازلياً
/// بالضغط عليه — نفس نمط تطبيقات الأذكار المعروفة. إكمال كل أذكار خانة
/// بيوم تقويمي واحد يزيد سلسلة استمرارها (`UserRepository.
/// bumpCategoryStreakIfNewDay`) — معروضة أعلى القائمة وبالداشبورد. راجع
/// `azkar_repository.dart`/`azkar_full_repository.dart` لمصدر البيانات وقيوده.
class AzkarScreen extends ConsumerWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(_segmentProvider);
    final userPrefs = ref.watch(userPrefsProvider);

    // إكمال أذكار الصباح/المساء (`azkarProgressProvider` بمفاتيح `order`
    // رقمية من azkar.json) — نستمع بدل نحسب أثناء البناء لتفادي كتابة
    // بقاعدة البيانات كجزء من عملية بناء الودجت نفسها.
    ref.listen<Map<int, int>>(azkarProgressProvider, (prev, next) {
      if (segment == _Segment.night) return;
      final list = ref.read(azkarListProvider).value;
      if (list == null) return;
      final relevant = list.where((d) => d.appliesTo(segment == _Segment.morning ? AzkarPeriod.morning : AzkarPeriod.evening));
      if (relevant.isEmpty) return;
      final allDone = relevant.every((d) => (next[d.order] ?? d.count) <= 0);
      if (allDone) {
        userPrefs.bumpCategoryStreakIfNewDay(segment.category).then((_) {
          ref.read(categoryStreakVersionProvider.notifier).bump();
        });
      }
    });

    // إكمال أذكار النوم (`azkarLibraryProgressProvider` بمفاتيح نصية
    // `categoryId:itemIndex` من مكتبة حصن المسلم — قسم ٢٨ فقط هون).
    ref.listen<Map<String, int>>(azkarLibraryProgressProvider, (prev, next) {
      if (segment != _Segment.night) return;
      final category = ref.read(sleepAzkarProvider).value;
      if (category == null) return;
      final allDone = category.items.asMap().entries.every((e) {
        final key = AzkarLibraryProgressNotifier.keyFor(category.id, e.key);
        return (next[key] ?? e.value.count) <= 0;
      });
      if (allDone) {
        userPrefs.bumpCategoryStreakIfNewDay(segment.category).then((_) {
          ref.read(categoryStreakVersionProvider.notifier).bump();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('أذكار الصباح والمساء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories_outlined),
            tooltip: 'مكتبة الأذكار الكاملة',
            // تُفتح دائماً بالدفع من مكتبة الأذكار (تبويب "الأذكار" الرئيسي)
            // الآن — رجوع بدل دفع نسخة ثانية فوقها.
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة ضبط العدّ',
            onPressed: () {
              if (segment == _Segment.night) {
                ref.read(azkarLibraryProgressProvider.notifier).resetAll();
              } else {
                ref.read(azkarProgressProvider.notifier).resetAll();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.fingerprint),
            tooltip: 'المسبحة',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasbihScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            tooltip: 'قيام الليل',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiyamScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SegmentedButton<_Segment>(
              segments: const [
                ButtonSegment(value: _Segment.morning, label: Text('الصباح'), icon: Icon(Icons.wb_sunny_outlined)),
                ButtonSegment(value: _Segment.evening, label: Text('المساء'), icon: Icon(Icons.nights_stay_outlined)),
                ButtonSegment(value: _Segment.night, label: Text('النوم'), icon: Icon(Icons.bedtime_outlined)),
              ],
              selected: {segment},
              onSelectionChanged: (s) => ref.read(_segmentProvider.notifier).set(s.first),
            ),
          ),
          StreakStatusRow(category: segment.category),
          Expanded(
            child: segment == _Segment.night ? const _NightAzkarList() : _PeriodAzkarList(segment: segment),
          ),
        ],
      ),
    );
  }
}

class _PeriodAzkarList extends ConsumerWidget {
  const _PeriodAzkarList({required this.segment});
  final _Segment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final azkarAsync = ref.watch(azkarListProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final period = segment == _Segment.morning ? AzkarPeriod.morning : AzkarPeriod.evening;

    return azkarAsync.when(
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
    );
  }
}

class _NightAzkarList extends ConsumerWidget {
  const _NightAzkarList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(sleepAzkarProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return categoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('تعذّر تحميل أذكار النوم')),
      data: (category) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount: category.items.length,
        itemBuilder: (context, i) => _LibraryDhikrCard(categoryId: category.id, itemIndex: i, item: category.items[i], onSurface: onSurface),
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

/// نفس نمط `_DhikrCard` لكن فوق `AzkarLibraryItem`/`azkarLibraryProgressProvider`
/// (مصدر بيانات مختلف — راجع `_NightAzkarList`).
class _LibraryDhikrCard extends ConsumerWidget {
  const _LibraryDhikrCard({required this.categoryId, required this.itemIndex, required this.item, required this.onSurface});
  final int categoryId;
  final int itemIndex;
  final AzkarLibraryItem item;
  final Color onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = AzkarLibraryProgressNotifier.keyFor(categoryId, itemIndex);
    final remaining = ref.watch(azkarLibraryProgressProvider.select((m) => m[key] ?? item.count));
    final done = remaining <= 0;

    return Card(
      color: done ? AppColors.teal.withValues(alpha: 0.08) : null,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(azkarLibraryProgressProvider.notifier).tap(key, item.count),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: done ? onSurface.withValues(alpha: 0.45) : onSurface, fontSize: 16, height: 1.8),
              ),
              if (item.reference != null) ...[
                const SizedBox(height: 8),
                Text(item.reference!, textDirection: TextDirection.rtl, style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 11, height: 1.5)),
              ],
              if (item.count > 1) ...[
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
                      done ? 'تمّ' : '$remaining من ${item.count}',
                      style: TextStyle(color: done ? AppColors.teal : AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
