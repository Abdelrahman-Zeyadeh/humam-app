import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_chapter_arabic_map.dart';
import '../../core/data/hadith/hadith_providers.dart';
import '../../core/data/hadith/hadith_repository.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import 'hadith_chapter_screen.dart';

final _chaptersForBookProvider = FutureProvider.family<List<HadithChapterWithCount>, int>((ref, bookId) {
  return ref.watch(hadithRepositoryProvider).chaptersForBook(bookId);
});

/// أبواب كتاب واحد (مثلاً كتاب الإيمان، كتاب الصلاة...) — كل حديث تحت
/// بابه بدل قائمة مسطّحة. راجع `hadith_chapter_names_ar.py` لمصدر
/// الأسماء العربية (ترجمة/معرفة عامة موثَّقة، وليست من ملف بيانات مصدر).
class HadithBookScreen extends ConsumerWidget {
  const HadithBookScreen({super.key, required this.bookId, required this.bookNameAr});
  final int bookId;
  final String bookNameAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(_chaptersForBookProvider(bookId));
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(bookNameAr)),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e is HadithBookNotDownloadedException ? e.toString() : 'تعذّر تحميل الأبواب'),
        ),
        data: (chapters) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          itemCount: chapters.length,
          itemBuilder: (context, i) {
            final c = chapters[i];
            return AppCard(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () {
                final title = HadithChapterArabicMap.resolveChapterName(
                  c.chapter.nameAr,
                  c.chapter.nameEn,
                  c.chapter.chapterNumber,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HadithChapterScreen(
                      bookId: bookId,
                      chapterId: c.chapter.id,
                      chapterTitle: title,
                    ),
                  ),
                );
              },
              child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: themeAccent(context).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${c.hadithCount}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: themeAccent(context))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            HadithChapterArabicMap.resolveChapterName(
                              c.chapter.nameAr,
                              c.chapter.nameEn,
                              c.chapter.chapterNumber,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, fontSize: 14.5),
                          ),
                        ),
                        Icon(Icons.chevron_left, color: onSurface.withValues(alpha: 0.5)),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
