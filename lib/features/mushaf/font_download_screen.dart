import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/remote_assets_config.dart';
import '../../core/theme/app_colors.dart';
import 'font_download_service.dart';

/// شاشة تنزيل حزمة خطوط بقية صفحات المصحف (٥١-٦٠٤) دفعة واحدة —
/// الاستئناف بمستوى الملف: يتخطّى أي صفحة منزَّلة أصلاً، فإغلاق التطبيق
/// منتصف التنزيل لا يعيده من الصفر. راجع `font_download_service.dart`.
class FontDownloadScreen extends ConsumerWidget {
  const FontDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fontDownloadControllerProvider);
    final controller = ref.read(fontDownloadControllerProvider.notifier);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final totalPages = kLastDownloadablePage - kFirstDownloadablePage + 1;
    final downloadedCount = state.downloadedPages.length;
    final progress = totalPages == 0 ? 0.0 : downloadedCount / totalPages;
    final allDone = downloadedCount >= totalPages;

    return Scaffold(
      appBar: AppBar(title: const Text('تنزيل بقية صفحات المصحف')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allDone ? Icons.check_circle : Icons.cloud_download_outlined,
              size: 56,
              color: allDone ? AppColors.teal : AppColors.gold,
            ),
            const SizedBox(height: 16),
            Text(
              'أول ٥٠ صفحة مضمَّنة أصلاً بالتطبيق. هون تنزّل الباقي (٥١-٦٠٤) ليصير المصحف كاملاً متاحاً بلا إنترنت لاحقاً.',
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (!isFontsBaseUrlConfigured)
              Text(
                'الاستضافة غير مهيّأة بهذا الإصدار بعد — راجع صاحب التطبيق',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 12),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: AppColors.line),
              ),
              const SizedBox(height: 8),
              Text('$downloadedCount من $totalPages صفحة', style: TextStyle(color: onSurface, fontSize: 13)),
              if (state.currentPage != null)
                Text('يُنزَّل الآن: صفحة ${state.currentPage}', style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 11)),
              const SizedBox(height: 20),
              if (allDone)
                const Text('اكتمل تنزيل المصحف كاملاً 🎉', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700))
              else if (state.isBulkRunning)
                OutlinedButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('إيقاف'),
                  onPressed: controller.cancelBulk,
                )
              else
                FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('بدء التنزيل'),
                  onPressed: controller.downloadRemaining,
                ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(state.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
