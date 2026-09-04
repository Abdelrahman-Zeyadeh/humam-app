import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_database.dart';
import '../../core/data/hadith/hadith_providers.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import 'hadith_detail_screen.dart';

final _hadithsForChapterProvider = FutureProvider.family<List<Hadith>, (int bookId, int chapterId)>((ref, args) {
  return ref.watch(hadithRepositoryProvider).hadithsForChapter(args.$1, args.$2);
});

/// أحاديث باب واحد — أكبر باب فعلياً ~٥٨٠ حديثاً، تحميل دفعة وحدة كافٍ
/// (خلافاً لكتاب كامل الذي يحتاج ترقيماً تدريجياً، راجع `hadith_books_screen.dart`).
class HadithChapterScreen extends ConsumerWidget {
  const HadithChapterScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
    required this.chapterTitle,
  });
  final int bookId;
  final int chapterId;
  final String chapterTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadithsAsync = ref.watch(_hadithsForChapterProvider((bookId, chapterId)));
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(chapterTitle)),
      body: hadithsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذّر تحميل أحاديث الباب')),
        data: (hadiths) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: hadiths.length,
          itemBuilder: (context, i) {
            final h = hadiths[i];
            return AppCard(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HadithDetailScreen(bookId: bookId, hadithId: h.id)),
              ),
              child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: themeAccent(context).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${h.hadithNumber}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: themeAccent(context))),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_left, color: onSurface.withValues(alpha: 0.5), size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          h.content,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: onSurface, height: 1.8),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
