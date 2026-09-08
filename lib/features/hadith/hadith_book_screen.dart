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
class HadithBookScreen extends ConsumerStatefulWidget {
  const HadithBookScreen({super.key, required this.bookId, required this.bookNameAr});
  final int bookId;
  final String bookNameAr;

  @override
  ConsumerState<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends ConsumerState<HadithBookScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(_chaptersForBookProvider(widget.bookId));
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GradientAppBar(
          title: widget.bookNameAr,
          colors: const [AppColors.blue, AppColors.navy],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navyDeep : const Color(0xFFF4EFE6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _filter = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'ابحث في أبواب الكتاب...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _filter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filter = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: chaptersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(e is HadithBookNotDownloadedException ? e.toString() : 'تعذّر تحميل الأبواب'),
                ),
                data: (chapters) {
                  final filtered = chapters.where((c) {
                    if (_filter.isEmpty) return true;
                    final title = HadithChapterArabicMap.resolveChapterName(
                      c.chapter.nameAr,
                      c.chapter.nameEn,
                      c.chapter.chapterNumber,
                    );
                    return title.contains(_filter);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد أبواب مطابقة',
                        style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final title = HadithChapterArabicMap.resolveChapterName(
                        c.chapter.nameAr,
                        c.chapter.nameEn,
                        c.chapter.chapterNumber,
                      );
                      return AppCard(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HadithChapterScreen(
                                bookId: widget.bookId,
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
                              child: Text(
                                '${c.hadithCount} حديث',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: themeAccent(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_left,
                              color: onSurface.withValues(alpha: 0.4),
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
