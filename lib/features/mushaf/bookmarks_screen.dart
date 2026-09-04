import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show BookmarkTypes;
import '../../core/text/arabic_normalizer.dart' show stripQuranicMarksForDisplay;
import '../../core/theme/app_colors.dart';
import 'ayah_actions_sheet.dart' show kMarkerMeta;
import 'mushaf_screen.dart';

final _bookmarkedAyahsProvider = FutureProvider<List<Ayah>>((ref) async {
  ref.watch(bookmarkVersionProvider);
  final ids = ref.watch(userPrefsProvider).bookmarkedAyahIds;
  final repo = ref.watch(quranRepositoryProvider);
  final ayahs = await Future.wait(ids.map(repo.ayahById));
  ayahs.sort((a, b) => a.id.compareTo(b.id));
  return ayahs;
});

/// آية + اسم سورتها لفاصلة نوع واحد (`null` لو ما ضُبطت بعد) — راجع
/// `BookmarkTypes`.
final _markerAyahProvider = FutureProvider.family<({Ayah ayah, String surahName})?, String>((ref, type) async {
  ref.watch(activityBookmarkVersionProvider);
  final ayahId = ref.watch(userPrefsProvider).activityBookmarkAyah(type);
  if (ayahId == null) return null;
  final repo = ref.watch(quranRepositoryProvider);
  final ayah = await repo.ayahById(ayahId);
  final surah = await repo.surahById(ayah.surah);
  return (ayah: ayah, surahName: surah.nameArPlain);
});

/// شاشتان بشاشة واحدة: **الفواصل** (٤ فتحات أحادية — راجع [BookmarkTypes]،
/// كل نوع فاصلة واحدة فقط بأي لحظة، تُضبَط من شيت إجراءات الآية) فوق
/// **العلامات المرجعية** الحرّة القديمة (عدد غير محدود). بطلب صاحب المشروع
/// "اضافة فواصل وعلامات حفظ للمصحف زي اللي بالصورة".
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahsAsync = ref.watch(_bookmarkedAyahsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('العلامات المرجعية')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('الفواصل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: onSurface.withValues(alpha: 0.6))),
            ),
          ),
          for (final type in BookmarkTypes.all) _MarkerRow(type: type),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('العلامات المرجعية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
            ),
          ),
          ayahsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('تعذّر تحميل العلامات')),
            ),
            data: (ayahs) {
              if (ayahs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'ما في علامات مرجعية بعد — اضغط مطوّلاً على أي كلمة بالمصحف لإضافتها',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final a in ayahs) ...[
                    ListTile(
                      title: Text(
                        // راجع توثيق [stripQuranicMarksForDisplay].
                        stripQuranicMarksForDisplay(a.textUthmani),
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
                    ),
                    const Divider(height: 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// صف فاصلة نوع واحد — شارة ملوَّنة + "السورة : الآية" لو مضبوطة، أو
/// "غير مضبوطة" رمادية لو لا. الضغط على الصف ينقل لصفحتها بالمصحف، وزر
/// الحذف (×) يمسحها (يظهر فقط لو مضبوطة فعلاً).
class _MarkerRow extends ConsumerWidget {
  const _MarkerRow({required this.type});
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markerAsync = ref.watch(_markerAyahProvider(type));
    final meta = kMarkerMeta[type]!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return markerAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (marker) {
        return ListTile(
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: meta.color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(meta.icon, size: 18, color: meta.color),
          ),
          title: Text('فاصلة ${meta.label}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
            marker != null ? '${marker.surahName} : ${marker.ayah.ayah}' : 'غير مضبوطة بعد',
            style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.55)),
          ),
          trailing: marker == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  tooltip: 'مسح الفاصلة',
                  onPressed: () async {
                    await ref.read(userPrefsProvider).clearActivityBookmark(type);
                    ref.read(activityBookmarkVersionProvider.notifier).bump();
                  },
                ),
          onTap: marker == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MushafScreen(initialPage: marker.ayah.page)),
                  ),
        );
      },
    );
  }
}
