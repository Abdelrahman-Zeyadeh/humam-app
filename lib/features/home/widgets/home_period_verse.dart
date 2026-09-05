import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/text/arabic_normalizer.dart' show formatAyahForWidgetDisplay;
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../mushaf/mushaf_settings.dart' show mushafJumpRequestProvider;
import '../../shell/root_shell.dart';
import '../home_dashboard_data.dart';
import '../home_style_helpers.dart';

/// بطاقة آية الفترة مع الذكر — مع إمكانية القفز للآية بالمصحف وفتح
/// الأذكار. استُخرجت من `home_screen.dart` أثناء تفكيك الملف بلا أي تغيير
/// سلوكي. راجع أيضاً [PeriodVerseFooter] (نفس المحتوى، هوية بصرية مختلفة
/// لعرضه كتذييل داخل [PrayerCountdownCard]/`_NoLocationPrayerCard`).
class PeriodVerseCard extends ConsumerWidget {
  const PeriodVerseCard({super.key, required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // آية الفترة — النقر عليها يفتح المصحف عند الصفحة المحددة مع تظليل الآية
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref
                  .read(mushafJumpRequestProvider.notifier)
                  .request(
                    page: data.ayahOfDay.page,
                    ayahId: data.ayahOfDay.id,
                  );
              ref.read(rootTabIndexProvider.notifier).select(1);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_outlined,
                        size: 13,
                        color: AppColors.goldDeep,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'آية الفترة',
                        style: TextStyle(
                          color: homeTextSoft(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${data.ayahOfDaySurah} · ${data.ayahOfDay.ayah}',
                        style: const TextStyle(
                          color: AppColors.goldDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.chevron_left,
                        size: 13,
                        color: homeTextSoft(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatAyahForWidgetDisplay(data.ayahOfDay.textUthmani),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: homeTextStrong(context),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (data.dhikrOfDay.isNotEmpty) ...[
            const SizedBox(height: 6),
            Divider(color: homeCardBorder(context), height: 1),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '📿 ذكر الفترة:',
                      style: TextStyle(
                        color: homeTextSoft(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.dhikrOfDay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: homeTextStrong(context).withValues(alpha: 0.95),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_left,
                      size: 13,
                      color: homeTextSoft(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// نفس محتوى [PeriodVerseCard] لكن كتذييل بألوان بيضاء/ذهبية فاتحة داخل
/// بطاقة تدرّج ملوّنة (`PrayerCountdownCard`/`_NoLocationPrayerCard`) —
/// راجع توثيق ذاك الملف. استُخرجت من `home_screen.dart` أثناء تفكيك الملف
/// بلا أي تغيير سلوكي.
class PeriodVerseFooter extends ConsumerWidget {
  const PeriodVerseFooter({super.key, required this.data});
  final HomeDashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // آية الفترة — النقر عليها يفتح المصحف عند الصفحة المحددة مع تظليل الآية
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ref
                .read(mushafJumpRequestProvider.notifier)
                .request(page: data.ayahOfDay.page, ayahId: data.ayahOfDay.id);
            ref.read(rootTabIndexProvider.notifier).select(1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      size: 13,
                      color: AppColors.goldSoft,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'آية الفترة',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${data.ayahOfDaySurah} · ${data.ayahOfDay.ayah}',
                      style: const TextStyle(
                        color: AppColors.goldSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_left,
                      size: 13,
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  formatAyahForWidgetDisplay(data.ayahOfDay.textUthmani),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (data.dhikrOfDay.isNotEmpty) ...[
          const SizedBox(height: 6),
          Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => ref.read(rootTabIndexProvider.notifier).select(3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                children: [
                  const Text(
                    '📿 ذكر الفترة:',
                    style: TextStyle(
                      color: AppColors.goldSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.dhikrOfDay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_left,
                    size: 13,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
