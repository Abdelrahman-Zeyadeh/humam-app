import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_database.dart';
import '../../core/data/hadith/hadith_providers.dart';
import '../../core/theme/app_colors.dart';
import 'hadith_book_screen.dart';
import 'hadith_search_screen.dart';

final _booksProvider = FutureProvider<List<HadithBook>>((ref) {
  return ref.watch(hadithRepositoryProvider).allBooks();
});

final _bookCountProvider = FutureProvider.family<int, int>((ref, bookId) {
  return ref.watch(hadithRepositoryProvider).countForBook(bookId);
});

/// نقطة الدخول لقسم الأحاديث: صحيح البخاري، صحيح مسلم، الأربعون النووية.
/// راجع `tools/raw/README.md` لمصدر البيانات ورخصته وحدوده (لا تصنيف صحة
/// لكل حديث بهذا المصدر تحديداً).
class HadithBooksScreen extends ConsumerWidget {
  const HadithBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(_booksProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأحاديث'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HadithSearchScreen())),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذّر تحميل الكتب')),
        data: (books) => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: books.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final book = books[i];
            final countAsync = ref.watch(_bookCountProvider(book.id));
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.menu_book_outlined),
                ),
                title: Text(book.nameAr, style: TextStyle(color: onSurface, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  countAsync.value != null ? '${countAsync.value} حديث' : '…',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HadithBookScreen(bookId: book.id, bookNameAr: book.nameAr)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
