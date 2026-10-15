import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/quran/quran_database.dart';
import '../../../core/data/quran/quran_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../duroos/duroos_audio_providers.dart';
import '../../duroos/duroos_screen.dart';
import '../../radio/quran_radio_screen.dart';
import '../../radio/radio_audio_providers.dart';
import '../../shell/root_shell.dart' show rootTabIndexProvider;
import '../quran_audio_controller.dart';
import '../reciters.dart';

final _miniBarSurahProvider = FutureProvider.family<Surah?, int?>((ref, id) {
  if (id == null) return Future.value(null);
  return ref.watch(quranRepositoryProvider).surahById(id);
});

/// شريط المشغل الصوتي المصغر العائم العام (Persistent Mini Audio Player Bar)
/// يعمل باستمرار في أسفل التطبيق فوق شريط التنقل لأي تشغيل صوتي نشط (قرآن، دروس، أو إذاعة).
class GlobalMiniAudioPlayerBar extends ConsumerWidget {
  const GlobalMiniAudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(rootTabIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);

    // 1. فحص الإذاعة
    final activeStation = ref.watch(activeRadioStationProvider);
    final radioPlayer = ref.watch(radioAudioPlayerProvider);

    // 2. فحص الدروس والمحاضرات
    final activeLecture = ref.watch(activeDuroosLectureProvider);
    final duroosPlayer = ref.watch(duroosAudioPlayerProvider);

    // 3. فحص تلاوة القرآن
    final quranAudio = ref.watch(quranAudioControllerProvider);

    // إذا كانت شاشة المصحف مفتوحة (تبويب 1) والصوت الجاري قرآن، لا نظهره هنا لأن المصحف له شريطه الخاص
    final isQuranOnMushafScreen = currentTab == 1 && quranAudio.isActive;

    if (activeStation != null) {
      return _buildBar(
        context: context,
        isDark: isDark,
        accent: accent,
        title: activeStation.name,
        subtitle: 'إذاعة القرآن الكريم المباشرة 📻',
        icon: Icons.radio_rounded,
        iconColor: const Color(0xFFE5A93C),
        isPlaying: radioPlayer.playing,
        onTogglePlay: () {
          if (radioPlayer.playing) {
            radioPlayer.pause();
          } else {
            radioPlayer.play();
          }
        },
        onClose: () {
          radioPlayer.stop();
          ref.read(activeRadioStationProvider.notifier).set(null);
        },
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuranRadioScreen()),
          );
        },
      );
    }

    if (activeLecture != null) {
      return _buildBar(
        context: context,
        isDark: isDark,
        accent: accent,
        title: activeLecture.title,
        subtitle: 'دروس ومحاضرات إسلامية',
        icon: Icons.school_rounded,
        iconColor: AppColors.tealDeep,
        isPlaying: duroosPlayer.playing,
        onTogglePlay: () {
          if (duroosPlayer.playing) {
            duroosPlayer.pause();
          } else {
            duroosPlayer.play();
          }
        },
        onClose: () {
          duroosPlayer.stop();
          ref.read(activeDuroosLectureProvider.notifier).set(null);
        },
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DuroosScreen()),
          );
        },
      );
    }

    if (quranAudio.isActive && !isQuranOnMushafScreen) {
      final reciter = reciterById(quranAudio.reciterId);
      final surahAsync = ref.watch(_miniBarSurahProvider(quranAudio.currentSurah));
      final surahName = surahAsync.value?.nameAr ?? 'سورة';
      final ayahStr = quranAudio.fromAyah != null ? ' · آية ${quranAudio.fromAyah}' : '';

      return _buildBar(
        context: context,
        isDark: isDark,
        accent: accent,
        title: '$surahName$ayahStr',
        subtitle: reciter.nameAr,
        icon: Icons.menu_book_rounded,
        iconColor: AppColors.blue,
        isPlaying: quranAudio.isPlaying,
        onTogglePlay: () {
          ref.read(quranAudioControllerProvider.notifier).togglePlayPause();
        },
        onClose: () {
          ref.read(quranAudioControllerProvider.notifier).stop();
        },
        onTap: () {
          ref.read(rootTabIndexProvider.notifier).select(1);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBar({
    required BuildContext context,
    required bool isDark,
    required Color accent,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isPlaying,
    required VoidCallback onTogglePlay,
    required VoidCallback onClose,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // زر الإغلاق
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  tooltip: 'إيقاف وإغلاق المشغل',
                  onPressed: onClose,
                ),
                const SizedBox(width: 4),

                // زر التشغيل والإيقاف المؤقت
                Material(
                  color: isPlaying ? accent : accent.withValues(alpha: 0.15),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTogglePlay,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 20,
                        color: isPlaying ? Colors.white : accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // العنوان والمعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // أيقونة المشغل الدائرية
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, size: 18, color: iconColor),
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
