import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';

/// نافذة سفلية بفهرس السور الـ١١٤ (بترتيب المصحف). تُرجع رقم الصفحة
/// (`startPage`) عند اختيار سورة — الاستدعاء يقفز إليها بالمصحف.
class MushafSurahIndexSheet extends ConsumerWidget {
  const MushafSurahIndexSheet({super.key});

  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const MushafSurahIndexSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(_allSurahsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('فهرس السور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface)),
            const Divider(height: 24),
            Expanded(
              child: surahsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('تعذّر تحميل فهرس السور')),
                data: (surahs) => ListView.separated(
                  itemCount: surahs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) {
                    final s = surahs[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                        foregroundColor: AppColors.gold,
                        child: Text('${s.id}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(s.nameAr, style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${s.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'} · ${s.ayahCount} آية',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      ),
                      trailing: Text('ص ${s.startPage}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                      onTap: () => Navigator.of(context).pop(s.startPage),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _allSurahsProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).allSurahs();
});
