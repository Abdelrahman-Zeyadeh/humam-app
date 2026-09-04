import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'mushaf_image_download_service.dart';
import 'mushaf_settings.dart';

/// شاشة تنزيل الطبعات المصورة (سكان مجمع الملك فهد) — قائمة الثلاث نسخ
/// (`normal`/`jawamie`/`premium`)، كل واحدة بحجمها التقريبي وزر تنزيل/حذف
/// + شريط تقدّم مستقل. الاستئناف بمستوى الملف: يتخطّى أي صفحة منزَّلة
/// أصلاً، فإغلاق التطبيق منتصف التنزيل لا يعيده من الصفر. راجع
/// `mushaf_image_download_service.dart`.
///
/// [initialEdition] لو مُمرَّرة (مثلاً من الإعدادات عند اختيار نسخة غير
/// منزَّلة) تُفتح بطاقتها موسَّعة تلقائياً — بقية النسخ تبقى مطوية.
class MushafImageDownloadScreen extends ConsumerStatefulWidget {
  const MushafImageDownloadScreen({super.key, this.initialEdition});

  final RasterMushafEdition? initialEdition;

  @override
  ConsumerState<MushafImageDownloadScreen> createState() => _MushafImageDownloadScreenState();
}

class _MushafImageDownloadScreenState extends ConsumerState<MushafImageDownloadScreen> {
  late String _expandedEditionId = (widget.initialEdition ?? RasterMushafEdition.normal).id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنزيل الطبعات المصورة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'نسخ مصورة (سكان) رسمية من مجمع الملك فهد لطباعة المصحف الشريف — '
            'بلا تلوين تجويد، الضغط على آية والحفظ متاحان بكل نسخة. تُنزَّل عند '
            'الطلب لضخامة حجمها ولا تُضمَّن بالتطبيق.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          for (final edition in RasterMushafEdition.values) ...[
            _EditionDownloadCard(
              edition: edition,
              expanded: _expandedEditionId == edition.id,
              onTap: () => setState(() => _expandedEditionId = edition.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _EditionDownloadCard extends ConsumerWidget {
  const _EditionDownloadCard({required this.edition, required this.expanded, required this.onTap});

  final RasterMushafEdition edition;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allState = ref.watch(mushafImageDownloadControllerProvider);
    final controller = ref.read(mushafImageDownloadControllerProvider.notifier);
    final state = allState.forEdition(edition.id);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final totalPages = kMushafImageTotalPages;
    final downloadedCount = state.downloadedPages.length;
    final progress = totalPages == 0 ? 0.0 : downloadedCount / totalPages;
    final allDone = downloadedCount >= totalPages;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: onTap,
            leading: Icon(
              allDone ? Icons.check_circle : Icons.image_outlined,
              color: allDone ? AppColors.tealDeep : themeAccent(context),
            ),
            title: Text(edition.label),
            subtitle: Text(
              allDone
                  ? 'مكتملة (~${edition.approxSizeMb} م.ب)'
                  : '$downloadedCount من $totalPages صفحة — تقريباً ${edition.approxSizeMb} م.ب كاملة',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: AppColors.line),
                  ),
                  const SizedBox(height: 8),
                  if (state.currentPage != null)
                    Text(
                      'يُنزَّل الآن: صفحة ${state.currentPage}',
                      style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 11),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (allDone)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('حذف النسخة'),
                            onPressed: () => controller.deleteEdition(edition.id),
                          ),
                        )
                      else if (state.isBulkRunning)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.pause_circle_outlined),
                            label: const Text('إيقاف مؤقت'),
                            onPressed: () => controller.cancelBulk(edition.id),
                          ),
                        )
                      else ...[
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('تنزيل'),
                            onPressed: () => controller.downloadRemaining(edition.id),
                          ),
                        ),
                        if (downloadedCount > 0) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'حذف الجزء المنزَّل',
                            onPressed: () => controller.deleteEdition(edition.id),
                          ),
                        ],
                      ],
                    ],
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
