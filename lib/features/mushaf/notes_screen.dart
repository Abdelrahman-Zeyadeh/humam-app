import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/user_database.dart' show AyahNote;
import '../../core/data/user/user_prefs.dart';
import '../../core/text/arabic_normalizer.dart' show stripQuranicMarksForDisplay;
import '../../core/theme/app_colors.dart';
import 'mushaf_screen.dart';

class _NoteEntry {
  const _NoteEntry({required this.note, required this.ayah, required this.surahName});
  final AyahNote note;
  final Ayah ayah;
  final String surahName;
}

/// كل الملاحظات + آيتها/اسم سورتها (لعرض نص الآية بدل رقمها فقط) — راجع
/// `UserRepository.allNotes` و`mushaf_page_widget.dart._notedAyahIdsProvider`
/// (نفس مصدر البيانات، عرض مختلف: قائمة كاملة هون بدل علامة على الصفحة).
final _allNotesProvider = FutureProvider<List<_NoteEntry>>((ref) async {
  ref.watch(ayahNoteVersionProvider);
  final notes = await ref.watch(userPrefsProvider).allNotes();
  final repo = ref.watch(quranRepositoryProvider);
  return Future.wait(
    notes.map((n) async {
      final ayah = await repo.ayahById(n.ayahId);
      final surah = await repo.surahById(ayah.surah);
      return _NoteEntry(note: n, ayah: ayah, surahName: surah.nameArPlain);
    }),
  );
});

/// شاشة "ملاحظاتي" — كل ملاحظات التدبر المكتوبة على آيات المصحف بمكان
/// واحد، الأحدث تعديلاً أولاً. بطلب صاحب المشروع: الملاحظة كانت لا تظهر
/// إلا بالضغط على آيتها بالمصحف مباشرة؛ هذه الشاشة (+ علامة صغيرة على
/// الآية نفسها بصفحة المصحف) تحلّان ذلك معاً. نفس هيكل `BookmarksScreen`.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(_allNotesProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('ملاحظاتي')),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذّر تحميل الملاحظات')),
        data: (entries) {
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'ما في ملاحظات بعد — اضغط مطوّلاً على أي كلمة بالمصحف واختر '
                  '"ملاحظة" لتدوين تدبراتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                title: Text(
                  // راجع توثيق [stripQuranicMarksForDisplay].
                  stripQuranicMarksForDisplay(entry.ayah.textUthmani),
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface, fontSize: 15, height: 1.6),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.note.noteText,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.surahName} · آية ${entry.ayah.ayah} · صفحة ${entry.ayah.page}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'حذف الملاحظة',
                  onPressed: () async {
                    await ref.read(userPrefsProvider).clearNoteForAyah(entry.ayah.id);
                    ref.read(ayahNoteVersionProvider.notifier).bump();
                  },
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MushafScreen(initialPage: entry.ayah.page)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
