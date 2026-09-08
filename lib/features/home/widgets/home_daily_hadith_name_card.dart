import 'package:flutter/material.dart';

import '../../../core/data/names_of_allah/names_of_allah_data.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../hadith/daily_hadith_screen.dart';
import '../../names_of_allah/names_of_allah_screen.dart';
import '../../story_maker/models/story_content.dart';
import '../../story_maker/ui/ayah_story_maker_screen.dart';
import '../home_style_helpers.dart';

/// بطاقة "حديث اليوم واسم من أسماء الله الحسنى" مع أزرار المشاركة المباشرة كبطاقات ستوري
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
          // حديث اليوم
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
                        size: 14,
                        color: AppColors.tealDeep,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'حديث اليوم',
                        style: TextStyle(
                          color: homeTextSoft(context),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // زر تصميم ومشاركة كبطاقة
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AyahStoryMakerScreen(
                                initialContent: HadithContent(
                                  hadithText: hadith.matn,
                                  narrator: hadith.narrator,
                                  sourceBook: '${hadith.source} (${hadith.grade})',
                                  explanation: hadith.fawaid.isNotEmpty
                                      ? hadith.fawaid.first
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tealDeep.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.palette_outlined, size: 12, color: AppColors.tealDeep),
                              SizedBox(width: 4),
                              Text(
                                'بطاقة',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.tealDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_left,
                        size: 14,
                        color: homeTextSoft(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hadith.matn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
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

          // اسم اليوم من أسماء الله الحسنى
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
                    size: 14,
                    color: AppColors.goldDeep,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name.name,
                    style: const TextStyle(
                      color: AppColors.goldDeep,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 6),
                  // زر تصميم بطاقة الاسم
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AyahStoryMakerScreen(
                            initialContent: NameOfAllahContent(
                              name: name.name,
                              meaning: name.meaning,
                              tadabbur: name.tadabbur,
                              dua: name.dua,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldDeep.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.palette_outlined, size: 12, color: AppColors.goldDeep),
                          SizedBox(width: 4),
                          Text(
                            'بطاقة',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_left,
                    size: 14,
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
