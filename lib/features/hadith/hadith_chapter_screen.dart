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
class HadithChapterScreen extends ConsumerStatefulWidget {
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
  ConsumerState<HadithChapterScreen> createState() => _HadithChapterScreenState();
}

class _HadithChapterScreenState extends ConsumerState<HadithChapterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hadithsAsync = ref.watch(_hadithsForChapterProvider((widget.bookId, widget.chapterId)));
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GradientAppBar(
          title: widget.chapterTitle,
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
                    hintText: 'ابحث في أحاديث هذا الباب...',
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
              child: hadithsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('تعذّر تحميل أحاديث الباب')),
                data: (hadiths) {
                  final filtered = hadiths.where((h) {
                    if (_filter.isEmpty) return true;
                    return h.content.contains(_filter);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد أحاديث مطابقة',
                        style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final h = filtered[i];
                      return AppCard(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HadithDetailScreen(
                              bookId: widget.bookId,
                              hadithId: h.id,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: themeAccent(context).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'حديث رقم ${h.hadithNumber}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: themeAccent(context),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_left,
                                  color: onSurface.withValues(alpha: 0.4),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              h.content,
                              textAlign: TextAlign.justify,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: onSurface,
                                height: 1.8,
                                fontSize: 14,
                              ),
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
