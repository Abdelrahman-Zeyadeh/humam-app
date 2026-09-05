import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart' show Ayah, Surah;
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/hifz_prefs.dart';
import '../../core/text/arabic_normalizer.dart'
    show stripQuranicMarksForDisplay;
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/smart_reminder_sync.dart';

final _reviewAyahProvider = FutureProvider.family<Ayah, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahById(ayahId);
});

final _reviewSurahProvider = FutureProvider.family<Surah, int>((ref, surahId) {
  return ref.watch(quranRepositoryProvider).surahById(surahId);
});

/// شاشة مراجعة وتثبيت الحفظ:
/// - استعراض آيات الخطة مع زر مباشر "تمت المراجعة بنجاح ✓"
class HifzReviewScreen extends ConsumerStatefulWidget {
  const HifzReviewScreen({super.key, required this.planId});
  final int planId;

  @override
  ConsumerState<HifzReviewScreen> createState() => _HifzReviewScreenState();
}

class _HifzReviewScreenState extends ConsumerState<HifzReviewScreen> {
  List<int>? _queue;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hifzPrefs = ref.read(hifzPrefsProvider);
    var ids = await hifzPrefs.dueReviewAyahIds(widget.planId);
    if (ids.isEmpty) {
      final plans = hifzPrefs.plans;
      if (plans.isNotEmpty) {
        final plan = plans.firstWhere(
          (p) => p.id == widget.planId,
          orElse: () => plans.first,
        );
        ids = List.generate(
          plan.currentAyahId - plan.fromAyahId + 1,
          (i) => plan.fromAyahId + i,
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _queue = ids;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;

    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة وتثبيت الحفظ')),
      body: SafeArea(
        child: queue == null
            ? const Center(child: CircularProgressIndicator())
            : queue.isEmpty || _index >= queue.length
            ? _DoneState(total: queue.length)
            : _ReviewCard(
                ayahId: queue[_index],
                progressLabel: 'الآية ${_index + 1} من ${queue.length}',
                onGrade: _grade,
              ),
      ),
    );
  }

  Future<void> _grade(int quality) async {
    final queue = _queue;
    if (queue == null || _index >= queue.length) return;
    final ayahId = queue[_index];
    final hifzPrefs = ref.read(hifzPrefsProvider);
    await hifzPrefs.gradeReview(widget.planId, ayahId, quality);
    // إلغاء فوري لتذكير الحفظ اليوم لو صار عندنا مراجعة واحدة على الأقل —
    // بلا انتظار الإقلاع التالي (راجع توثيق `syncHifzReminder`).
    unawaited(syncHifzReminder(hifzPrefs));
    if (!mounted) return;
    setState(() {
      _index++;
    });
  }
}

class _DoneState extends StatelessWidget {
  const _DoneState({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 56,
              color: themeAccent(context),
            ),
            const SizedBox(height: 16),
            Text(
              total == 0 ? 'تم تثبيت ومراجعة الحفظ بنجاح 🎉' : 'أنهيت مراجعة وتثبيت كل الآيات 🎉',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تقبّل الله طاعتك وثبّت القرآن في صدرك',
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'العودة لخطة الحفظ',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.ayahId,
    required this.progressLabel,
    required this.onGrade,
  });

  final int ayahId;
  final String progressLabel;
  final ValueChanged<int> onGrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);
    final ayahAsync = ref.watch(_reviewAyahProvider(ayahId));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              progressLabel,
              style: TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ayahAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const Text('تعذّر تحميل الآية'),
                    data: (ayah) => SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final surahAsync = ref.watch(_reviewSurahProvider(ayah.surah));
                              final surahName = surahAsync.value?.nameArPlain ?? 'سورة ${ayah.surah}';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: onSurface.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$surahName · الآية ${ayah.ayah}',
                                  style: TextStyle(
                                    color: onSurface.withValues(alpha: 0.7),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            stripQuranicMarksForDisplay(ayah.textUthmani),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 22,
                              fontFamily: 'AmiriQuran',
                              height: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppPrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'تمت المراجعة بنجاح ✓',
                  onPressed: () => onGrade(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('إعادة لاحقاً', style: TextStyle(fontSize: 12)),
                  onPressed: () => onGrade(0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
