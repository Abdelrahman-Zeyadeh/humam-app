import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';
import 'audio_download_service.dart';
import 'quran_audio_controller.dart';
import 'reciters.dart';

final _allSurahsProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).allSurahs();
});

/// شاشة "تنزيل التلاوات للاستماع بلا إنترنت" — قائمة ١١٤ سورة لقارئ واحد
/// مختار، كل سورة بزر تنزيل/حذف مستقل، مع تنزيل جماعي وحذف جماعي. راجع
/// توثيق `AudioDownloadController` لتفاصيل التخزين والاستئناف.
class AudioDownloadsScreen extends ConsumerWidget {
  const AudioDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioDownloadControllerProvider);
    final controller = ref.read(audioDownloadControllerProvider.notifier);
    final surahsAsync = ref.watch(_allSurahsProvider);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final liveListen = ref.watch(
      quranAudioControllerProvider.select((s) => s.liveListenEnabled),
    );

    ref.listen(audioDownloadControllerProvider.select((s) => s.errorMessage), (
      prev,
      next,
    ) {
      if (next != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('تنزيل التلاوات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: state.reciterId,
                    decoration: const InputDecoration(
                      labelText: 'القارئ',
                      isDense: true,
                    ),
                    items: [
                      for (final r in kReciters)
                        DropdownMenuItem(value: r.id, child: Text(r.nameAr)),
                    ],
                    onChanged: (id) {
                      if (id != null) controller.switchReciter(id);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('سماع مباشر (بلا تنزيل)', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                'يبثّ الصوت من الإنترنت دائماً، حتى لو كانت السورة منزَّلة',
                style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
              ),
              value: liveListen,
              onChanged: (value) => ref
                  .read(quranAudioControllerProvider.notifier)
                  .setLiveListenEnabled(value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${state.downloadedSurahs.length} من ١١٤ سورة منزَّلة',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (state.isBulkRunning)
                  // "إيقاف مؤقت" لا "إلغاء" — استئناف حقيقي بمستوى البايت
                  // (`downloadResumable`)، الضغط على "تنزيل الكل" لاحقاً
                  // يكمل من حيث توقّف بالضبط لا يعيد من الصفر.
                  TextButton(
                    onPressed: controller.cancelBulk,
                    child: const Text('إيقاف مؤقت'),
                  )
                else ...[
                  TextButton(
                    onPressed: state.downloadedSurahs.length == 114
                        ? null
                        : controller.downloadAll,
                    child: const Text('تنزيل الكل'),
                  ),
                  TextButton(
                    onPressed: state.downloadedSurahs.isEmpty
                        ? null
                        : () => _confirmDeleteAll(context, controller),
                    child: const Text('حذف الكل'),
                  ),
                ],
              ],
            ),
          ),
          if (state.isBulkRunning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: state.bulkTotal == 0
                          ? null
                          : state.bulkCompleted / state.bulkTotal,
                      minHeight: 6,
                      backgroundColor: AppColors.line,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'جارٍ التنزيل: ${state.bulkCompleted}/${state.bulkTotal}'
                    '${state.currentSurah != null ? " — سورة ${state.currentSurah}" : ""}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: surahsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text('تعذّر تحميل قائمة السور')),
              data: (surahs) => ListView.builder(
                itemCount: surahs.length,
                itemBuilder: (context, i) {
                  final s = surahs[i];
                  final downloaded = state.downloadedSurahs.contains(s.id);
                  final downloading =
                      state.isBulkRunning && state.currentSurah == s.id;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: themeAccent(context).withValues(alpha: 0.15),
                      child: Text(
                        '${s.id}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: themeAccent(context),
                        ),
                      ),
                    ),
                    title: Text(s.nameAr),
                    subtitle: Text(
                      '${s.ayahCount} آية',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: downloading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: Icon(
                              downloaded
                                  ? Icons.download_done
                                  : Icons.download_outlined,
                              color: downloaded
                                  ? AppColors.tealDeep
                                  : onSurface.withValues(alpha: 0.6),
                            ),
                            tooltip: downloaded ? 'حذف التنزيل' : 'تنزيل',
                            onPressed: () => downloaded
                                ? controller.deleteSurah(s.id)
                                : controller.downloadSurah(s.id),
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll(
    BuildContext context,
    AudioDownloadController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف كل التنزيلات؟'),
        content: const Text(
          'سيُحذَف صوت كل السور المنزَّلة لهذا القارئ من الجهاز — يمكنك تنزيلها مجدداً لاحقاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteAll();
  }
}
