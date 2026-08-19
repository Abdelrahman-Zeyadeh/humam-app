import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';
import '../audio/quran_audio_controller.dart';
import '../audio/reciters.dart';

const List<double> _kSpeedSteps = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

final _barSurahProvider = FutureProvider.family<Surah, int>((ref, id) {
  return ref.watch(quranRepositoryProvider).surahById(id);
});

final _barAyahProvider = FutureProvider.family<Ayah, int>((ref, id) {
  return ref.watch(quranRepositoryProvider).ayahById(id);
});

/// شريط تشغيل ثابت أسفل شاشة المصحف، يظهر فقط أثناء تشغيل صوتي جارٍ.
/// يعرض القارئ والموضع الحالي، ويحكم بالتشغيل/التنقّل/التكرار/السرعة —
/// راجع `QuranAudioController` لمنطق التشغيل الفعلي.
class QuranAudioBar extends ConsumerWidget {
  const QuranAudioBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(quranAudioControllerProvider);
    if (!audio.isActive) return const SizedBox.shrink();

    final controller = ref.read(quranAudioControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.cream;
    final fg = isDark ? AppColors.inkOnDark : AppColors.ink;
    final reciter = reciterById(audio.reciterId);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line)),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, -2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'إيقاف',
              color: fg.withValues(alpha: 0.6),
              onPressed: controller.stop,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showReciterPicker(context, ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AudioBarLabel(audio: audio, fg: fg),
                    Text(
                      reciter.nameAr,
                      style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
            _SmallTextButton(
              label: audio.repeat.labelAr,
              onTap: () => controller.setRepeat(audio.repeat.nextOption),
              fg: fg,
            ),
            _SmallTextButton(
              label: '${audio.speed}x'.replaceAll('.0x', 'x'),
              onTap: () {
                final i = _kSpeedSteps.indexOf(audio.speed);
                final next = _kSpeedSteps[(i < 0 ? 0 : i + 1) % _kSpeedSteps.length];
                controller.setSpeed(next);
              },
              fg: fg,
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous),
              color: fg,
              onPressed: controller.previous,
            ),
            IconButton(
              icon: Icon(audio.isLoading
                  ? Icons.hourglass_empty
                  : (audio.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled)),
              iconSize: 34,
              color: AppColors.gold,
              onPressed: audio.isLoading ? null : controller.togglePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              color: fg,
              onPressed: controller.next,
            ),
          ],
        ),
      ),
    );
  }

  void _showReciterPicker(BuildContext context, WidgetRef ref) {
    final audio = ref.read(quranAudioControllerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('القارئ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: onSurface)),
              for (final r in kReciters)
                ListTile(
                  leading: Icon(
                    r.id == audio.reciterId ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: r.id == audio.reciterId ? AppColors.gold : onSurface.withValues(alpha: 0.5),
                  ),
                  title: Text(r.nameAr, style: TextStyle(color: onSurface)),
                  subtitle: r.mode == ReciterAudioMode.perSurahOnly
                      ? const Text('تشغيل السورة كاملة فقط — لا تظليل متزامن', style: TextStyle(fontSize: 11))
                      : null,
                  onTap: () {
                    ref.read(quranAudioControllerProvider.notifier).setReciter(r.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _AudioBarLabel extends ConsumerWidget {
  const _AudioBarLabel({required this.audio, required this.fg});
  final QuranAudioState audio;
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahId = audio.currentSurah;
    if (surahId == null) {
      return Text('—', style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700));
    }
    final surahAsync = ref.watch(_barSurahProvider(surahId));
    final surahName = surahAsync.value?.nameAr ?? '…';

    final ayahId = audio.currentAyahId;
    if (ayahId == null) {
      return Text(surahName, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700));
    }
    final ayahAsync = ref.watch(_barAyahProvider(ayahId));
    final ayahNo = ayahAsync.value?.ayah;
    return Text(
      ayahNo == null ? surahName : '$surahName · آية $ayahNo',
      style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SmallTextButton extends StatelessWidget {
  const _SmallTextButton({required this.label, required this.onTap, required this.fg});
  final String label;
  final VoidCallback onTap;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(label, style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.75), fontWeight: FontWeight.w600)),
      ),
    );
  }
}
