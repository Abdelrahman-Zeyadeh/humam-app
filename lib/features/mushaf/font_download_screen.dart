import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'font_download_service.dart';
import 'mushaf_settings.dart' show MushafFontEdition;

/// شاشة تنزيل حزمة خطوط بقية صفحات المصحف دفعة واحدة، **لأي طبعة من
/// الثلاث** (V1/V2/V4 Tajweed — راجع [downloadableRangeFor]؛ V2 وحدها
/// فيها ٥٠ صفحة مضمَّنة أصلاً فتبدأ من ٥١، الباقيتان بلا تضمين فتبدآن من
/// ١). الاستئناف بمستويين معاً (ملف/طابور — راجع توثيق
/// `FontDownloadController`)، فزر "إيقاف" هون **إيقاف مؤقت حقيقي لا
/// إلغاء**: "بدء التنزيل" التالي يكمل من حيث توقّف بالضبط.
class FontDownloadScreen extends ConsumerStatefulWidget {
  const FontDownloadScreen({super.key, this.edition = MushafFontEdition.v2});
  final MushafFontEdition edition;

  @override
  ConsumerState<FontDownloadScreen> createState() => _FontDownloadScreenState();
}

class _FontDownloadScreenState extends ConsumerState<FontDownloadScreen> {
  @override
  void initState() {
    super.initState();
    // مسح ملفات الطبعة المطلوبة محلياً — بعد `initState` مباشرة (لا أثناءه)
    // تفادياً لتعديل حالة Notifier وقت بناء الودجت الأولي.
    Future.microtask(
      () => ref.read(fontDownloadControllerProvider.notifier).switchEdition(widget.edition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final edition = widget.edition;
    final state = ref.watch(fontDownloadControllerProvider);
    final controller = ref.read(fontDownloadControllerProvider.notifier);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // الحالة قد توصف طبعة أخرى لحظياً (لسا ما خلص `switchEdition` أو تبديل
    // شاشات) — نتجاهل الأرقام حتى تتطابق مع الطبعة المطلوبة، بدل عرض تقدّم
    // طبعة غلط لجزء ثانية.
    final matchesEdition = state.activeEdition == edition;
    final (first, last) = downloadableRangeFor(edition);
    final totalPages = last - first + 1;
    final downloadedCount = matchesEdition ? state.downloadedPages.length : 0;
    final progress = totalPages == 0 ? 0.0 : downloadedCount / totalPages;
    final allDone = matchesEdition && downloadedCount >= totalPages;
    final isBulkRunning = matchesEdition && state.isBulkRunning;

    return Scaffold(
      appBar: AppBar(title: Text('تنزيل خطوط ${edition.label}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allDone ? Icons.check_circle : Icons.cloud_download_outlined,
              size: 56,
              color: allDone ? AppColors.tealDeep : themeAccent(context),
            ),
            const SizedBox(height: 16),
            Text(
              first == 1
                  ? 'هذه الطبعة بلا صفحات مضمَّنة بالتطبيق — هون تنزّل الـ$totalPages صفحة كلها ليصير المصحف متاحاً بلا إنترنت لاحقاً.'
                  : 'أول ٥٠ صفحة مضمَّنة أصلاً بالتطبيق. هون تنزّل الباقي ($first-$last) ليصير المصحف كاملاً متاحاً بلا إنترنت لاحقاً.',
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: AppColors.line),
            ),
            const SizedBox(height: 8),
            Text('$downloadedCount من $totalPages صفحة', style: TextStyle(color: onSurface, fontSize: 13)),
            if (matchesEdition && state.currentPage != null)
              Text(
                'يُنزَّل الآن: صفحة ${state.currentPage}',
                style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 11),
              ),
            const SizedBox(height: 20),
            if (allDone)
              const Text('اكتمل تنزيل المصحف كاملاً 🎉', style: TextStyle(color: AppColors.tealDeep, fontWeight: FontWeight.w700))
            else if (isBulkRunning)
              OutlinedButton.icon(
                icon: const Icon(Icons.pause_circle_outlined),
                label: const Text('إيقاف مؤقت'),
                onPressed: controller.cancelBulk,
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.download),
                label: Text(downloadedCount > 0 ? 'متابعة التنزيل' : 'بدء التنزيل'),
                onPressed: () => controller.downloadRemaining(edition),
              ),
            if (matchesEdition && state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(state.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
