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
          // بطلب صريح "عدل على شكل ظهور الآيات لو تكون بقالب" — بطاقة
          // مستقلة لكل ملاحظة بدل `ListTile` مضغوطة (كانت تقصّ نص الآية
          // بسطرين فقط وتخلط الملاحظة بالنص الفرعي)، بنفس لغة التصميم
          // المعتمَدة بشاشات مشابهة (`mutashabihat_screen.dart._MutashabihCard`).
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: entries.length,
            itemBuilder: (context, index) => _NoteCard(
              entry: entries[index],
              onDelete: () async {
                await ref.read(userPrefsProvider).clearNoteForAyah(entries[index].ayah.id);
                ref.read(ayahNoteVersionProvider.notifier).bump();
              },
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MushafScreen(initialPage: entries[index].ayah.page)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.entry, required this.onDelete, required this.onTap});
  final _NoteEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldDeep.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.surahName} · آية ${entry.ayah.ayah}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.goldDeep),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'صفحة ${entry.ayah.page}',
                      style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      tooltip: 'حذف الملاحظة',
                      visualDensity: VisualDensity.compact,
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // نص الآية كاملاً (لا قصّ بسطرين كالسابق) — راجع توثيق
                // [stripQuranicMarksForDisplay].
                Text(
                  stripQuranicMarksForDisplay(entry.ayah.textUthmani),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 18,
                    height: 2.0,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                // الملاحظة بصندوق مستقل بصرياً — لا تختلط بالنص الفرعي كما
                // كان بالتصميم السابق.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF162232) : const Color(0xFFF9F7F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18, color: onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.note.noteText,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            color: onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
