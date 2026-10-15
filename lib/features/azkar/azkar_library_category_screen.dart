import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import 'azkar_dhikr_frame.dart';
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
      // هيدر بتدرّج أخضر زمردي فاخر موحّد مع هوية التطبيق
      appBar: GradientAppBar(
        title: category.title,
        colors: const [Color(0xFF135B4C), Color(0xFF0D3B31)],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة ضبط العدّ',
            onPressed: () =>
                ref.read(azkarLibraryProgressProvider.notifier).resetAll(),
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
    final remaining = ref.watch(
      azkarLibraryProgressProvider.select((m) => m[key] ?? item.count),
    );
    final done = remaining <= 0;

    // نفس تصميم بطاقة `_DhikrCard` بـ`azkar_screen.dart` (بلا إطار داخلي
    // حول النص، شارة حالة بأسفل البطاقة) — توحيد شكل كل شاشات الأذكار.
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      onTap: () =>
          ref.read(azkarLibraryProgressProvider.notifier).tap(key, item.count),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                // إطار أنيق موحَّد لكل شاشات الأذكار — راجع `DhikrTextFrame`.
                DhikrTextFrame(text: item.text, done: done),
                if (item.reference != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.reference!,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.55),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
                if (item.count > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        done ? 'تمّ' : '$remaining من ${item.count} مرة',
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.5),
                          fontSize: 10.5,
                        ),
                      ),
                      if (done)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check,
                            size: 15,
                            color: Colors.white,
                          ),
                        )
                      else
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: ((item.count - remaining) / item.count)
                                      .clamp(0.0, 1.0),
                                  strokeWidth: 3.5,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: themeAccent(
                                    context,
                                  ).withValues(alpha: 0.15),
                                  valueColor: AlwaysStoppedAnimation(
                                    themeAccent(context),
                                  ),
                                ),
                              ),
                              Text(
                                '$remaining',
                                style: TextStyle(
                                  color: themeAccent(context),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

}
