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
import '../../core/data/user/hifz_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../audio/quran_audio_controller.dart'
    show RepeatOption, quranAudioControllerProvider;
import '../audio/ui/detailed_audio_sheet.dart';
import '../shell/root_shell.dart' show rootTabIndexProvider;
import '../story_maker/models/story_content.dart';
import '../story_maker/ui/ayah_story_maker_screen.dart';
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

final _ayahMasteryProvider = FutureProvider.family<String?, int>((ref, ayahId) async {
  ref.watch(hifzVersionProvider);
  final map = await ref.watch(hifzPrefsProvider).allMasteryMap();
  return map[ayahId];
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
    final masteryStatusAsync = ref.watch(_ayahMasteryProvider(_currentAyahId));
    final masteryStatus = masteryStatusAsync.value;

    final cardBg = isDark ? const Color(0xFF1B232E) : Colors.white;

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
          final colorTags = prefs.colorTagsForAyah(ayah.id);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  // مقبض السحب
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. بطاقة معاينة الآية والسورة ورقم الصفحة
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF131A22)
                                  : const Color(0xFFF9F7F1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (isDark ? AppColors.lineDark : AppColors.line)
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeAccent(context).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        surah != null
                                            ? '${surah.nameAr} · الآية ${ayah.ayah}'
                                            : 'الآية ${ayah.ayah}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: themeAccent(context),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'صفحة ${ayah.page}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: onSurface.withValues(alpha: 0.55),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '﴿ ${stripQuranicMarksForDisplay(ayah.textUthmani)} ﴾',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'AmiriQuran',
                                    fontSize: 16,
                                    height: 1.7,
                                    color: onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2. شريط حالة إتقان ومراجعة الآية
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2836).withValues(alpha: 0.6)
                                  : Colors.grey.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (isDark ? AppColors.lineDark : AppColors.line)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 16,
                                    color: themeAccent(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'إتقان الحفظ:',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: onSurface.withValues(alpha: 0.75),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _MasteryChip(
                                    label: 'متمكن',
                                    color: const Color(0xFF2E7D32),
                                    isSelected: masteryStatus == 'mastered',
                                    onTap: () async {
                                      await ref
                                          .read(hifzPrefsProvider)
                                          .setAyahMasteryStatus(ayah.id, 'mastered');
                                      ref.read(hifzVersionProvider.notifier).bump();
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  _MasteryChip(
                                    label: 'تثبيت',
                                    color: const Color(0xFFE65100),
                                    isSelected: masteryStatus == 'needsReview',
                                    onTap: () async {
                                      await ref
                                          .read(hifzPrefsProvider)
                                          .setAyahMasteryStatus(ayah.id, 'needsReview');
                                      ref.read(hifzVersionProvider.notifier).bump();
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  _MasteryChip(
                                    label: 'لم يُحفظ',
                                    color: Colors.grey,
                                    isSelected: masteryStatus == null ||
                                        masteryStatus == 'unmemorized',
                                    onTap: () async {
                                      await ref
                                          .read(hifzPrefsProvider)
                                          .setAyahMasteryStatus(ayah.id, 'unmemorized');
                                      ref.read(hifzVersionProvider.notifier).bump();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. صفوف الإجراءات السريعة (Quick Action Cards)
                          Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'استماع',
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
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.repeat_rounded,
                                  label: 'كرر الآية',
                                  onTap: () {
                                    if (surah != null) {
                                      Navigator.of(context).pop();
                                      ref
                                          .read(quranAudioControllerProvider.notifier)
                                          .setRepeat(RepeatOption.infinite);
                                      ref
                                          .read(quranAudioControllerProvider.notifier)
                                          .playAyah(surah.id, ayah.ayah);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'تم تكرار الآية (${ayah.ayah}) من سورة ${surah.nameAr}',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.palette_outlined,
                                  label: colorTags.isEmpty
                                      ? 'تلوين'
                                      : 'تلوين (${colorTags.length})',
                                  isActive: colorTags.isNotEmpty,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _pickColorTags(context, ref, ayah.id);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.bookmark_add_outlined,
                                  label: 'فاصلة',
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _pickBookmarkMarker(context, ref, ayah.id);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  icon: hasNote
                                      ? Icons.edit_note
                                      : Icons.edit_note_outlined,
                                  label: hasNote ? 'ملاحظتي' : 'ملاحظة',
                                  isActive: hasNote,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _NoteSheet.show(
                                      context,
                                      ayah.id,
                                      noteAsync.value,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.copy_outlined,
                                  label: 'نسخ',
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: ayah.textUthmani),
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'تم نسخ نص الآية الشريفة بنجاح',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.image_outlined,
                                  label: 'بطاقة',
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    AyahShareSheet.show(context, ayah.id);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 4. عنوان قسم التفسير والعلوم
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 1,
                                color: (isDark ? AppColors.lineDark : AppColors.line)
                                    .withValues(alpha: 0.6),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.auto_stories_rounded,
                                      size: 15,
                                      color: themeAccent(context),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'التفسير والترجمات والعلوم',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: onSurface.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 1,
                                color: (isDark ? AppColors.lineDark : AppColors.line)
                                    .withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 5. شبكة البطاقات المعرفية المتطورة
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.3,
                            children: [
                              _CategoryKnowledgeCard(
                                title: 'التفسير والترجمات',
                                icon: Icons.menu_book_rounded,
                                iconColor: const Color(0xFFD48B28),
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
                              _CategoryKnowledgeCard(
                                title: 'المتشابهات اللفظية',
                                icon: Icons.compare_arrows_rounded,
                                iconColor: const Color(0xFFC0392B),
                                badgeCount: similarAyahs.length,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _SimilarAyahsSheet.show(context, similarAyahs);
                                },
                              ),
                              _CategoryKnowledgeCard(
                                title: 'كلمات غريب القرآن',
                                icon: Icons.spellcheck_rounded,
                                iconColor: AppColors.purple,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  GharibWordsSheet.show(context, ayah.id);
                                },
                              ),
                              _CategoryKnowledgeCard(
                                title: 'صانع بطاقات فَذَكِّرْ',
                                icon: Icons.style_rounded,
                                iconColor: AppColors.tealDeep,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AyahStoryMakerScreen(
                                        initialContent: AyahContent(
                                          ayahId: ayah.id,
                                          text: ayah.textUthmani,
                                          surahName: surah?.nameAr ?? '',
                                          ayahNumber: ayah.ayah,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),

                  // 6. الشريط السفلي: التنقل السريع بين الآيات
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B232E)
                          : const Color(0xFFF9FAFB),
                      border: Border(
                        top: BorderSide(
                          color: (isDark ? AppColors.lineDark : AppColors.line)
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          tooltip: 'الآية السابقة',
                          onPressed: _currentAyahId > 1 ? () => _stepAyah(-1) : null,
                        ),
                        Text(
                          surah != null
                              ? '${surah.nameAr} · آية ${ayah.ayah} من ${surah.ayahCount}'
                              : 'الآية ${ayah.ayah}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                          tooltip: 'الآية التالية',
                          onPressed: _currentAyahId < 6236 ? () => _stepAyah(1) : null,
                        ),
                      ],
                    ),
                  ),
                ],
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

class _MasteryChip extends StatelessWidget {
  const _MasteryChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.35),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isActive
          ? themeAccent(context).withValues(alpha: 0.15)
          : (isDark ? const Color(0xFF1E2836) : Colors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? themeAccent(context)
                  : (isDark ? AppColors.lineDark : AppColors.line).withValues(
                      alpha: 0.7,
                    ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? themeAccent(context)
                    : onSurface.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? themeAccent(context) : onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryKnowledgeCard extends StatelessWidget {
  const _CategoryKnowledgeCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.badgeCount,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E2836) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? AppColors.lineDark : AppColors.line).withValues(
                alpha: 0.7,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ),
              if (badgeCount != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
