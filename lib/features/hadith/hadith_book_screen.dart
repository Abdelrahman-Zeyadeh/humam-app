import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_providers.dart';
import '../../core/data/hadith/hadith_repository.dart';
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
        error: (e, _) => const Center(child: Text('تعذّر تحميل الأبواب')),
        data: (chapters) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chapters.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = chapters[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                foregroundColor: AppColors.gold,
                child: Text('${c.hadithCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              title: Text(
                c.chapter.nameAr ?? c.chapter.nameEn,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HadithChapterScreen(
                    chapterId: c.chapter.id,
                    chapterTitle: c.chapter.nameAr ?? c.chapter.nameEn,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
