import 'package:flutter/material.dart';

import '../../../core/data/names_of_allah/names_of_allah_data.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../hadith/daily_hadith_screen.dart';
import '../../names_of_allah/names_of_allah_screen.dart';
import '../home_style_helpers.dart';

/// بطاقة "حديث اليوم واسم من أسماء الله الحسنى" — تختار عنصراً واحداً
/// حتمياً (بيوم السنة `DateTime.now()`، لا عشوائي) من كل قائمة فتبقى
/// **نفس** الحديث/الاسم طول اليوم بغض النظر عن كم مرة يُفتح التطبيق أو
/// تُعاد بناء الشاشة، ويتغيّران تلقائياً غداً — نفس فكرة "آية الفترة"
/// (راجع `home_period_verse.dart`) لكن ليومياً لا لفترة اليوم. بطلب صاحب
/// المشروع: "حديث اليوم... يظهر في الشاشة عند فتح التطبيق واسماء الله
/// الحسنى كذلك". استُخرجت من `home_screen.dart` أثناء تفكيك الملف بلا أي
/// تغيير سلوكي.
class HomeDailyHadithNameCard extends StatelessWidget {
  const HomeDailyHadithNameCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final hadith =
        kCuratedDailyHadiths[dayOfYear % kCuratedDailyHadiths.length];
    final name =
        NamesOfAllahData.items[dayOfYear % NamesOfAllahData.items.length];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DailyHadithScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 13,
                        color: AppColors.tealDeep,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'حديث اليوم',
                        style: TextStyle(
                          color: homeTextSoft(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_left,
                        size: 13,
                        color: homeTextSoft(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hadith.matn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: homeTextStrong(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: homeCardBorder(context), height: 1),
          InkWell(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(18),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NamesOfAllahScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 13,
                    color: AppColors.goldDeep,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name.name,
                    style: const TextStyle(
                      color: AppColors.goldDeep,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name.meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: homeTextStrong(context).withValues(alpha: 0.85),
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
      ),
    );
  }
}
