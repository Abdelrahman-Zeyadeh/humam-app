import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'azkar_full_repository.dart';
import 'azkar_library_progress.dart';

/// أذكار قسم واحد من مكتبة حصن المسلم — نفس نمط تفاعل بطاقات
/// `AzkarScreen` (ضغطة = إنقاص العدّاد)، بمفتاح تقدّم منفصل تماماً.
class AzkarLibraryCategoryScreen extends ConsumerWidget {
  const AzkarLibraryCategoryScreen({super.key, required this.category});
  final AzkarLibraryCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة ضبط العدّ',
            onPressed: () => ref.read(azkarLibraryProgressProvider.notifier).resetAll(),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        itemCount: category.items.length,
        itemBuilder: (context, i) => _LibraryItemCard(
          categoryId: category.id,
          itemIndex: i,
          item: category.items[i],
          onSurface: onSurface,
        ),
      ),
    );
  }
}

class _LibraryItemCard extends ConsumerWidget {
  const _LibraryItemCard({
    required this.categoryId,
    required this.itemIndex,
    required this.item,
    required this.onSurface,
  });
  final int categoryId;
  final int itemIndex;
  final AzkarLibraryItem item;
  final Color onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = AzkarLibraryProgressNotifier.keyFor(categoryId, itemIndex);
    final remaining = ref.watch(azkarLibraryProgressProvider.select((m) => m[key] ?? item.count));
    final done = remaining <= 0;

    return Card(
      color: done ? AppColors.teal.withValues(alpha: 0.08) : null,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(azkarLibraryProgressProvider.notifier).tap(key, item.count),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: done ? onSurface.withValues(alpha: 0.45) : onSurface, fontSize: 16, height: 1.8),
              ),
              if (item.reference != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.reference!,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 11, height: 1.5),
                ),
              ],
              if (item.count > 1) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: done ? AppColors.teal : AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      done ? 'تمّ' : '$remaining من ${item.count}',
                      style: TextStyle(color: done ? AppColors.teal : AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
