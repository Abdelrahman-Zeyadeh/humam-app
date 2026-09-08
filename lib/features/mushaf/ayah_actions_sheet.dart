import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart' show SimilarAyahResult;
import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show BookmarkTypes;
import '../../core/text/arabic_normalizer.dart'
    show stripQuranicMarksForDisplay;
import '../../core/theme/app_colors.dart';
import '../audio/quran_audio_controller.dart'
    show QuranAudioController, RepeatOption, quranAudioControllerProvider;
import '../audio/ui/detailed_audio_sheet.dart';
import '../shell/root_shell.dart' show rootTabIndexProvider;
import 'ayah_share_sheet.dart';
import 'ayah_text_view_screen.dart';
import 'gharib_words_sheet.dart';
import 'mushaf_settings.dart' show mushafJumpRequestProvider;

const Map<String, ({String label, Color color, IconData icon})> kMarkerMeta = {
  BookmarkTypes.reading: (
    label: 'تلاوة',
    color: AppColors.blue,
    icon: Icons.menu_book_outlined,
  ),
  BookmarkTypes.hifz: (
    label: 'حفظ',
    color: AppColors.purple,
    icon: Icons.school_outlined,
  ),
  BookmarkTypes.review: (
    label: 'مراجعة',
    color: AppColors.tealDeep,
    icon: Icons.refresh,
  ),
  BookmarkTypes.tadabbur: (
    label: 'تدبر',
    color: AppColors.goldDeep,
    icon: Icons.auto_stories_outlined,
  ),
};

final _ayahByIdProvider = FutureProvider.family<Ayah, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahById(ayahId);
});

final _surahByIdProvider = FutureProvider.family<Surah, int>((ref, surahId) {
  return ref.watch(quranRepositoryProvider).surahById(surahId);
});

final _similarAyahsProvider =
    FutureProvider.family<List<SimilarAyahResult>, int>((ref, ayahId) {
      return ref.watch(quranRepositoryProvider).similarAyahsFor(ayahId);
    });

final _noteProvider = FutureProvider.family<String?, int>((ref, ayahId) {
  ref.watch(ayahNoteVersionProvider);
  return ref.watch(userPrefsProvider).noteForAyah(ayahId);
});

/// شيت سفلي متطور لخدمات الآية (مطابق لصور التصميم الحديثة)
class AyahActionsSheet extends ConsumerStatefulWidget {
  const AyahActionsSheet({super.key, required this.ayahId});
  final int ayahId;

  static Future<void> show(BuildContext context, int ayahId) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AyahActionsSheet(ayahId: ayahId),
    );
  }

  @override
  ConsumerState<AyahActionsSheet> createState() => _AyahActionsSheetState();
}

class _AyahActionsSheetState extends ConsumerState<AyahActionsSheet> {
  late int _currentAyahId = widget.ayahId;

  void _stepAyah(int delta) {
    final nextId = _currentAyahId + delta;
    if (nextId >= 1 && nextId <= 6236) {
      setState(() => _currentAyahId = nextId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ayahAsync = ref.watch(_ayahByIdProvider(_currentAyahId));
    ref.watch(bookmarkVersionProvider);
    ref.watch(activityBookmarkVersionProvider);
    ref.watch(ayahColorTagVersionProvider);
    final prefs = ref.watch(userPrefsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final similarAyahsAsync = ref.watch(_similarAyahsProvider(_currentAyahId));
    final similarAyahs = similarAyahsAsync.value ?? const <SimilarAyahResult>[];
    final noteAsync = ref.watch(_noteProvider(_currentAyahId));
    final hasNote = (noteAsync.value ?? '').isNotEmpty;

    final cardBg = isDark ? const Color(0xFF1B232E) : Colors.white;
    final dividerColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 100) {
            // سحب لليمين -> الآية التالية
            if (_currentAyahId < 6236) _stepAyah(1);
          } else if (details.primaryVelocity! < -100) {
            // سحب لليسار -> الآية السابقة
            if (_currentAyahId > 1) _stepAyah(-1);
          }
        }
      },
      child: ayahAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذّر تحميل الآية: $e')),
        data: (ayah) {
          final surahAsync = ref.watch(_surahByIdProvider(ayah.surah));
          final surah = surahAsync.value;
          final isBookmarked = prefs.isBookmarked(ayah.id);
          final colorTags = prefs.colorTagsForAyah(ayah.id);

          return Center(
            child: Container(
              width: 260,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.lineDark : const Color(0xFFE8E8E8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Material(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. تشغيل إلى نهاية الجزء
                        _MenuItemTile(
                          icon: Icons.play_arrow_rounded,
                          titleBold: 'تشغيل',
                          titleRest: ' إلى نهاية الجزء',
                          onTap: () {
                            if (surah != null) {
                              Navigator.of(context).pop();
                              AyahAudioQuickSheet.show(
                                context,
                                ayah: ayah,
                                surah: surah,
                              );
                            }
                          },
                        ),
                        Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),

                        // 2. كرر الآية المختارة
                        _MenuItemTile(
                          icon: Icons.repeat_rounded,
                          titleBold: 'كرر',
                          titleRest: ' الآية المختارة',
                          onTap: () {
                            if (surah != null) {
                              Navigator.of(context).pop();
                              ref.read(quranAudioControllerProvider.notifier).setRepeat(RepeatOption.infinite);
                              ref.read(quranAudioControllerProvider.notifier).playAyah(surah.id, ayah.ayah);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم بدء تكرار الآية (${ayah.ayah}) من ${surah.nameAr}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),

                        // 3. تصنيف/تلوين الآية — بطلب صريح: "تحديد لون
                        // التمييز" القديم كان يميّز آية واحدة فقط بلون
                        // ثابت مؤقّت (نفس آلية القفز بمتشابهات/بحث،
                        // `highlightedAyahProvider` تُصفَّر تلقائياً)، بلا
                        // أي معنى دائم أو اختيار لون حقيقي. الآن: تصنيف
                        // **دائم متعدّد الآيات لكل نوع** (حفظ/تلاوة/
                        // مراجعة/تدبر)، بلون كل نوع الخاص، يظهر بخلفية
                        // الآية بكل مرة تُفتح فيها الصفحة — راجع
                        // AyahColorTags و_ColorTagPickerSheet.
                        _MenuItemTile(
                          icon: Icons.palette_outlined,
                          titleBold: colorTags.isEmpty
                              ? 'تصنيف وتلوين الآية'
                              : 'تصنيف الآية (${colorTags.length})',
                          isActive: colorTags.isNotEmpty,
                          onTap: () {
                            Navigator.of(context).pop();
                            _pickColorTags(context, ref, ayah.id);
                          },
                        ),
                        Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),

                        // 4. إضافة فاصلة
                        _MenuItemTile(
                          icon: Icons.bookmark_add_outlined,
                          titleBold: 'إضافة فاصلة',
                          onTap: () {
                            Navigator.of(context).pop();
                            _pickBookmarkMarker(context, ref, ayah.id);
                          },
                        ),
                        Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),

                        // 5. التفاسير والتراجم
                        _MenuItemTile(
                          icon: Icons.menu_book_outlined,
                          titleBold: 'التفاسير والتراجم',
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AyahTextViewScreen(
                                  ayahId: ayah.id,
                                  kind: AyahTextViewKind.tafsir,
                                  initialTab: MainTafsirTab.tafasir,
                                ),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),

                        // 6. نسخ
                        _MenuItemTile(
                          icon: Icons.copy_outlined,
                          titleBold: 'نسخ',
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(text: ayah.textUthmani),
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ نص الآية الشريفة بنجاح'),
                                ),
                              );
                            }
                          },
                        ),
                        Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),

                        // 7. حفظ الآية كصورة
                        _MenuItemTile(
                          icon: Icons.image_outlined,
                          titleBold: 'حفظ الآية كصورة',
                          onTap: () {
                            Navigator.of(context).pop();
                            AyahShareSheet.show(context, ayah.id);
                          },
                        ),
                        Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),

                        // 8. المتشابهات اللفظية
                        _MenuItemTile(
                          icon: Icons.compare_arrows_rounded,
                          titleBold: 'المتشابهات اللفظية',
                          trailingBadge: similarAyahs.isNotEmpty
                              ? '${similarAyahs.length}'
                              : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            _SimilarAyahsSheet.show(context, similarAyahs);
                          },
                        ),
                        Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),

                        // 9. تدبر وملاحظة
                        _MenuItemTile(
                          icon: hasNote ? Icons.edit_note : Icons.edit_note_outlined,
                          titleBold: hasNote ? 'ملاحظتي على الآية' : 'تدبر وملاحظة',
                          isActive: hasNote,
                          onTap: () {
                            Navigator.of(context).pop();
                            _NoteSheet.show(context, ayah.id, noteAsync.value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _pickBookmarkMarker(BuildContext context, WidgetRef ref, int ayahId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookmarkPickerSheet(ayahId: ayahId),
    );
  }

  void _pickColorTags(BuildContext context, WidgetRef ref, int ayahId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ColorTagPickerSheet(ayahId: ayahId),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.icon,
    required this.titleBold,
    this.titleRest,
    required this.onTap,
    this.isActive = false,
    this.trailingBadge,
  });

  final IconData icon;
  final String titleBold;
  final String? titleRest;
  final VoidCallback onTap;
  final bool isActive;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
        child: Row(
          children: [
            // أيقونة البند بحجم أنيق
            Icon(
              icon,
              size: 20,
              color: isActive ? accent : onSurface.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 12),
            // النص العريض والمكمل على سطر واحد
            Expanded(
              child: RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: titleBold,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        color: isActive ? accent : onSurface,
                      ),
                    ),
                    if (titleRest != null)
                      TextSpan(
                        text: titleRest!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Cairo',
                          color: onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (trailingBadge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingBadge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _BookmarkPickerSheet extends ConsumerWidget {
  const _BookmarkPickerSheet({required this.ayahId});
  final int ayahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final markers = [
      (
        type: BookmarkTypes.reading,
        label: 'فاصلة التلاوة',
        color: AppColors.blue,
        icon: Icons.menu_book,
      ),
      (
        type: BookmarkTypes.hifz,
        label: 'فاصلة الحفظ',
        color: AppColors.purple,
        icon: Icons.school,
      ),
      (
        type: BookmarkTypes.review,
        label: 'فاصلة المراجعة',
        color: AppColors.tealDeep,
        icon: Icons.refresh,
      ),
      (
        type: BookmarkTypes.tadabbur,
        label: 'فاصلة التدبر',
        color: AppColors.goldDeep,
        icon: Icons.auto_stories,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B232E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تعيين فاصلة لهذه الآية',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            for (final m in markers) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(m.icon, color: m.color, size: 20),
                ),
                title: Text(
                  m.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: prefs.activityBookmarkAyah(m.type) == ayahId
                    ? const Icon(Icons.check_circle, color: Color(0xFF1B8A72))
                    : null,
                onTap: () async {
                  await prefs.setActivityBookmark(m.type, ayahId);
                  ref.read(activityBookmarkVersionProvider.notifier).bump();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

/// شيت تصنيف/تلوين الآية — **متعدّد الاختيار** (checkboxes)، بخلاف
/// [_BookmarkPickerSheet] (اختيار واحد يستبدل السابق): نفس الأربعة أنواع
/// (`kMarkerMeta`)، لكن أي عدد منها يمكن تفعيله معاً لنفس الآية، وكل نوع
/// يسع أي عدد من الآيات (`AyahColorTags`، راجع توثيقها). بطلب صريح: "زي
/// نظام العلامات المرجعية بس أكثر من لون وكل لون بيسع أكثر من آية".
class _ColorTagPickerSheet extends ConsumerWidget {
  const _ColorTagPickerSheet({required this.ayahId});
  final int ayahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);
    ref.watch(ayahColorTagVersionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTags = prefs.colorTagsForAyah(ayahId);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B232E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تصنيف وتلوين الآية',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر أكثر من تصنيف لنفس الآية — كل تصنيف يسع أي عدد من الآيات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            for (final entry in kMarkerMeta.entries) ...[
              CheckboxListTile(
                value: activeTags.contains(entry.key),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: entry.value.color,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: entry.value.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(entry.value.icon, color: entry.value.color, size: 20),
                ),
                title: Text(entry.value.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                onChanged: (_) async {
                  await prefs.toggleAyahColorTag(entry.key, ayahId);
                  ref.read(ayahColorTagVersionProvider.notifier).bump();
                },
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _SimilarAyahsSheet extends ConsumerWidget {
  const _SimilarAyahsSheet(this.similarList);
  final List<SimilarAyahResult> similarList;

  static void show(BuildContext context, List<SimilarAyahResult> list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SimilarAyahsSheet(list),
    );
  }

  /// يقفز للمصحف عند موضع المتشابهة ويظلّلها لحظياً — بلا حاجة تصفّح يدوي.
  /// `popUntil(isFirst)` يغلق هذا الشيت وشيت الإجراءات تحته معاً، **وأي
  /// شاشة مدفوعة فوق `RootShell`** (هذا الشيت يُفتح إمّا من داخل المصحف
  /// نفسه أو من `TafsirReadingScreen` المدفوعة فوقه — راجع استدعاءات
  /// `AyahActionsSheet.show`)، فيعمل من الحالتين معاً. ثم [mushafJumpRequestProvider]
  /// (نفس آلية "آية الفترة" بالداشبورد) ينفّذ القفز الفعلي + تظليلاً مؤقتاً.
  void _goToAyah(BuildContext context, WidgetRef ref, Ayah ayah) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref
        .read(mushafJumpRequestProvider.notifier)
        .request(page: ayah.page, ayahId: ayah.id);
    ref.read(rootTabIndexProvider.notifier).select(1); // تبويب المصحف
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // بطلب صاحب المشروع (٢٠٢٦-٠٩-٠١، جولة ثانية: "اللون بعده زهري") — حدّ
    // البطاقة صار محايداً تماماً (`AppColors.line`/`lineDark`، بلا أي صبغة
    // لونية إطلاقاً) فلا مجال لأي انطباع "زهري" أياً كانت الإضاءة. اللون
    // بقي فقط بنص/خلفية شارة "سورة · آية" الصغيرة (وضوح دون طغيان). لون
    // أيقونة الزر بالشبكة أعلاه (`0xFFC0392B`) يبقى كما هو — تصنيف لوني
    // للفئات هناك مقصود ولم يُشتكَ منه.
    const accent = AppColors.teal;
    final borderColor = isDark ? AppColors.lineDark : AppColors.line;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B232E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  'المتشابهات اللفظية',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          if (similarList.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'اضغط على أي آية متشابهة للانتقال إليها بالمصحف مباشرة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: similarList.isEmpty
                ? const Center(child: Text('لا توجد متشابهات مسجلة لهذه الآية'))
                : ListView.separated(
                    itemCount: similarList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = similarList[index];
                      return Material(
                        color: isDark
                            ? const Color(0xFF1E2836)
                            : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _goToAyah(context, ref, item.ayah),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        // بطلب صاحب المشروع: علامة وقف عثمانية
                                        // طافية كانت تُرسَم منفصلة/معلَّقة فوق
                                        // السطر بخط AmiriQuran العادي (غير
                                        // مصمَّم لتكديسها بدقّة زي خط الصفحة
                                        // QCF المخصَّص) — نفس التنظيف المستخدَم
                                        // بقوائم الملاحظات/المفضّلة.
                                        stripQuranicMarksForDisplay(
                                          item.ayah.textUthmani,
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'AmiriQuran',
                                          fontSize: 17,
                                          height: 1.7,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.13),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          // `item.surahNameAr` من `surahs.name_ar`
                                          // بقاعدة البيانات — يتضمّن بادئة
                                          // "سورة" أصلاً (راجع `surahShortName`
                                          // بـ`arabic_normalizer.dart`)، فإضافتها
                                          // هون ثانية كانت تكرّرها ("سورة سورة
                                          // المائدة") — بطلب صاحب المشروع.
                                          '${item.surahNameAr} · آية ${item.ayah.ayah}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_left_rounded,
                                  color: onSurface.withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.ayahId, this.initialText});
  final int ayahId;
  final String? initialText;

  static void show(BuildContext context, int ayahId, String? initialText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NoteSheet(ayahId: ayahId, initialText: initialText),
    );
  }

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialText ?? '',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer(
      builder: (context, ref, _) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B232E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تدوين ملاحظة وتدبر للآية',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اكتب تدبراتك وملاحظاتك حول هذه الآية...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(userPrefsProvider)
                      .setNoteForAyah(widget.ayahId, _ctrl.text.trim());
                  ref.read(ayahNoteVersionProvider.notifier).bump();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('حفظ الملاحظة'),
              ),
            ],
          ),
        );
      },
    );
  }
}
