import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_database.dart';
import '../../core/data/hadith/hadith_providers.dart';
import '../../core/theme/app_colors.dart';
import 'hadith_detail_screen.dart';

final _hadithsForChapterProvider = FutureProvider.family<List<Hadith>, int>((ref, chapterId) {
  return ref.watch(hadithRepositoryProvider).hadithsForChapter(chapterId);
});

/// أحاديث باب واحد — أكبر باب فعلياً ~٥٨٠ حديثاً، تحميل دفعة وحدة كافٍ
/// (خلافاً لكتاب كامل الذي يحتاج ترقيماً تدريجياً، راجع `hadith_books_screen.dart`).
class HadithChapterScreen extends ConsumerWidget {
  const HadithChapterScreen({super.key, required this.chapterId, required this.chapterTitle});
  final int chapterId;
  final String chapterTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadithsAsync = ref.watch(_hadithsForChapterProvider(chapterId));
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(chapterTitle)),
      body: hadithsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذّر تحميل أحاديث الباب')),
        data: (hadiths) => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: hadiths.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final h = hadiths[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                foregroundColor: AppColors.gold,
                child: Text('${h.hadithNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              title: Text(
                h.content,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: onSurface, height: 1.7),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HadithDetailScreen(hadithId: h.id)),
              ),
            );
          },
        ),
      ),
    );
  }
}
