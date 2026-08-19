import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_colors.dart';
import 'mushaf_screen.dart';

final _bookmarkedAyahsProvider = FutureProvider<List<Ayah>>((ref) async {
  ref.watch(bookmarkVersionProvider);
  final ids = ref.watch(userPrefsProvider).bookmarkedAyahIds;
  final repo = ref.watch(quranRepositoryProvider);
  final ayahs = await Future.wait(ids.map(repo.ayahById));
  ayahs.sort((a, b) => a.id.compareTo(b.id));
  return ayahs;
});

/// قائمة كل الآيات المعلَّم عليها (`UserPrefs.bookmarkedAyahIds`)، بالضغط
/// على أي منها ينتقل للمصحف عند صفحتها.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahsAsync = ref.watch(_bookmarkedAyahsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('العلامات المرجعية')),
      body: ayahsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذّر تحميل العلامات')),
        data: (ayahs) {
          if (ayahs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'ما في علامات مرجعية بعد — اضغط على أي كلمة بالمصحف لإضافتها',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: ayahs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = ayahs[i];
              return ListTile(
                title: Text(
                  a.textUthmani,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface, fontSize: 16, height: 1.6),
                ),
                subtitle: Text('سورة ${a.surah} · آية ${a.ayah} · صفحة ${a.page}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                trailing: IconButton(
                  icon: const Icon(Icons.bookmark_remove_outlined),
                  tooltip: 'إزالة',
                  onPressed: () async {
                    await ref.read(userPrefsProvider).toggleBookmark(a.id);
                    ref.read(bookmarkVersionProvider.notifier).bump();
                  },
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MushafScreen(initialPage: a.page)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
