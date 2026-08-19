import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/hadith/hadith_database.dart';
import '../../core/data/hadith/hadith_providers.dart';

final _hadithByIdProvider = FutureProvider.family<Hadith, int>((ref, id) {
  return ref.watch(hadithRepositoryProvider).hadithById(id);
});

final _hadithBookProvider = FutureProvider.family<HadithBook, int>((ref, id) {
  return ref.watch(hadithRepositoryProvider).bookById(id);
});

/// عرض حديث واحد كاملاً — النص حرفياً من `hadith.db` (مصدر Unlicense
/// موثّق، راجع tools/raw/README.md)، بلا أي صياغة أو تلخيص من الكود.
class HadithDetailScreen extends ConsumerWidget {
  const HadithDetailScreen({super.key, required this.hadithId});
  final int hadithId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadithAsync = ref.watch(_hadithByIdProvider(hadithId));
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('الحديث')),
      body: hadithAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذّر تحميل الحديث')),
        data: (hadith) {
          final bookAsync = ref.watch(_hadithBookProvider(hadith.bookId));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${bookAsync.value?.nameAr ?? ''} · حديث ${hadith.hadithNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                hadith.content,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: onSurface, fontSize: 18, height: 2),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('نسخ'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: hadith.content));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخ الحديث')));
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('مشاركة'),
                    onPressed: () => SharePlus.instance.share(ShareParams(text: hadith.content)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'لا تصنيف صحّة لكل حديث بهذا المصدر — البخاري ومسلم "صحيحان" بمجملهما باتفاق العلماء',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }
}
