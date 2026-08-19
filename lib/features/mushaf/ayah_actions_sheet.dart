import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../audio/quran_audio_controller.dart';
import 'ayah_text_view_screen.dart';

final _ayahByIdProvider = FutureProvider.family<Ayah, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahById(ayahId);
});

/// شيت سفلي عند الضغط على كلمة/آية: نسخ، مشاركة، وتبديل علامة مرجعية.
/// النص المنسوخ/المُشارَك دايماً `text_uthmani` من قاعدة البيانات — لا نص
/// مكتوب بالكود.
class AyahActionsSheet extends ConsumerWidget {
  const AyahActionsSheet({super.key, required this.ayahId});
  final int ayahId;

  static Future<void> show(BuildContext context, int ayahId) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => AyahActionsSheet(ayahId: ayahId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(_ayahByIdProvider(ayahId));
    // نراقب bookmarkVersionProvider لإجبار إعادة البناء عند تبديل العلامة —
    // UserPrefs تخزين متزامن بلا Stream خاص به.
    ref.watch(bookmarkVersionProvider);
    final prefs = ref.watch(userPrefsProvider);
    final audio = ref.watch(quranAudioControllerProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: ayahAsync.when(
        loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => const SizedBox(height: 80, child: Center(child: Text('تعذّر تحميل الآية'))),
        data: (ayah) {
          final isBookmarked = prefs.isBookmarked(ayah.id);
          final isThisAyahPlaying = audio.isActive && audio.currentAyahId == ayah.id && audio.isPlaying;
          final isThisSurahPlaying =
              audio.isActive && audio.currentSurah == ayah.surah && audio.fromAyah == null && audio.isPlaying;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 14),
                Text(
                  'السورة ${ayah.surah} · الآية ${ayah.ayah}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  ayah.textUthmani,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: onSurface, fontSize: 20, height: 1.8),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  runSpacing: 8,
                  children: [
                    _ActionButton(
                      icon: isThisAyahPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      label: isThisAyahPlaying ? 'إيقاف' : 'استماع',
                      onTap: () => _toggleAyah(context, ref, ayah, isThisAyahPlaying),
                    ),
                    _ActionButton(
                      icon: isThisSurahPlaying ? Icons.pause_circle_filled : Icons.playlist_play,
                      label: isThisSurahPlaying ? 'إيقاف السورة' : 'تشغيل السورة',
                      onTap: () => _toggleSurah(context, ref, ayah.surah, isThisSurahPlaying),
                    ),
                    _ActionButton(
                      icon: Icons.menu_book_outlined,
                      label: 'التفسير',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AyahTextViewScreen(ayahId: ayah.id, kind: AyahTextViewKind.tafsir),
                        ),
                      ),
                    ),
                    _ActionButton(
                      icon: Icons.translate_outlined,
                      label: 'الترجمة',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AyahTextViewScreen(ayahId: ayah.id, kind: AyahTextViewKind.translation),
                        ),
                      ),
                    ),
                    _ActionButton(
                      icon: Icons.copy_outlined,
                      label: 'نسخ',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: ayah.textUthmani));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخت الآية')));
                        }
                      },
                    ),
                    _ActionButton(
                      icon: Icons.share_outlined,
                      label: 'مشاركة',
                      onTap: () => SharePlus.instance.share(ShareParams(text: ayah.textUthmani)),
                    ),
                    _ActionButton(
                      icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      label: isBookmarked ? 'إزالة العلامة' : 'علامة مرجعية',
                      iconColor: isBookmarked ? AppColors.gold : null,
                      onTap: () async {
                        await prefs.toggleBookmark(ayah.id);
                        ref.read(bookmarkVersionProvider.notifier).bump();
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// يبدّل تشغيل/إيقاف آية واحدة. لو مشغَّلة فعلاً يوقفها مؤقتاً، غير هيك
/// يستبدل أي تشغيل جارٍ (سورة أو آية أخرى) بهذه — مشغّل واحد مشترك بكل
/// التطبيق (راجع `quran_audio_controller.dart`). يعرض رسالة عند فشل
/// الشبكة بدل تجاهل الخطأ صامتاً.
Future<void> _toggleAyah(BuildContext context, WidgetRef ref, Ayah ayah, bool isPlaying) async {
  final controller = ref.read(quranAudioControllerProvider.notifier);
  if (isPlaying) {
    await controller.togglePlayPause();
    return;
  }
  await controller.playAyah(ayah.surah, ayah.ayah);
  if (context.mounted) _showErrorIfAny(context, ref);
}

/// يبدّل تشغيل/إيقاف السورة كاملة من أوّلها.
Future<void> _toggleSurah(BuildContext context, WidgetRef ref, int surahId, bool isPlaying) async {
  final controller = ref.read(quranAudioControllerProvider.notifier);
  if (isPlaying) {
    await controller.togglePlayPause();
    return;
  }
  await controller.playSurahFull(surahId);
  if (context.mounted) _showErrorIfAny(context, ref);
}

void _showErrorIfAny(BuildContext context, WidgetRef ref) {
  final error = ref.read(quranAudioControllerProvider).errorMessage;
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.iconColor});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? onSurface),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
