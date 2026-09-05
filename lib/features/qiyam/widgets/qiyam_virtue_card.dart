import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/hadith/hadith_database.dart' show Hadith;
import '../../../core/data/hadith/hadith_providers.dart';
import '../../../core/data/hadith/hadith_repository.dart' show hadithMatnOnly;
import '../../../core/theme/app_colors.dart';

/// حديث "فضل قيام الليل" — يُجلَب حياً من `hadith.db` المرخّصة بمرجعه
/// (كتاب/رقم)، لا نص ثابت بالكود (راجع توثيق `HadithRepository.
/// hadithByBookAndNumber`). صحيح البخاري ١١٤٥ (ومسلم ١٧٧٢ بنفس المتن):
/// حديث نزول الله تبارك وتعالى بالثلث الأخير من الليل.
final _qiyamVirtueHadithProvider = FutureProvider<Hadith?>((ref) {
  return ref.watch(hadithRepositoryProvider).hadithByBookAndNumber(1, 1145);
});

/// "فضل قيام الليل" — حديث حقيقي مجلوب حياً من `hadith.db` المرخّصة (راجع
/// `_qiyamVirtueHadithProvider` أعلى الملف)، لا نص مؤلَّف بالكود.
class QiyamVirtueCard extends ConsumerWidget {
  const QiyamVirtueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hadithAsync = ref.watch(_qiyamVirtueHadithProvider);
    final hadith = hadithAsync.value;
    if (hadith == null) return const SizedBox.shrink();

    return Card(
      color: themeAccent(context).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: themeAccent(context),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'فضل قيام الليل',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // سند مختصَر بطلب صاحب المشروع "اختصر السند اجعله فقط الراوي
            // عن رسول الله ﷺ والحديث" — راوي هذا الحديث (أبو هريرة رضي
            // الله عنه) موثَّق حرفياً بنص الحديث الكامل بـ`hadith.db` (راجع
            // توثيق [hadithMatnOnly])، المتن نفسه مجلوب حياً بلا تعديل.
            Text(
              'عَنْ أَبِي هُرَيْرَةَ رضى الله عنه، أَنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم:\n${hadithMatnOnly(hadith.content)}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.85),
                fontSize: 13.5,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'رواه البخاري (١١٤٥) ومسلم (١٧٧٢)',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
