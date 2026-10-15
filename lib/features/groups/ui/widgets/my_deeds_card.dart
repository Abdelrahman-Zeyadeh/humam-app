import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/faith_group.dart';

/// بطاقة "إنجازك في أعمال اليوم والليلة" بأعلى مركز المجموعات — بتصميم عصري ملهم
/// وشريط تقدم دائري متوهج وشارات توضح إنجاز الفرائض والسنن والأذكار وورد القرآن.
class MyDeedsCard extends StatelessWidget {
  const MyDeedsCard({super.key, required this.deeds, required this.isDark});

  final DailyDeedsProgress deeds;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final score = deeds.scorePercentage;
    final accent = themeAccent(context);

    final String statusText = score >= 80
        ? 'ما شاء الله، همة إيمانية عالية! 🌟'
        : score >= 40
            ? 'خطوة مباركة، واصل إتمام طاعاتك 🌱'
            : 'سارع في الخيرات وابدأ أوراد يومك 🌿';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131F2E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: score >= 80
              ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
              : (isDark ? AppColors.lineDark : AppColors.line),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'اليوم والليلة',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🌟 إنجازك الإيماني اليومي',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: score >= 80
                            ? const Color(0xFF2E7D32)
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // عداد الإنجاز الدائري المتوهج
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 5.5,
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 80 ? const Color(0xFF2E7D32) : accent,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          const SizedBox(height: 14),

          // شارات تفصيل أعمال اليوم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DeedStatus(
                icon: Icons.mosque_outlined,
                label: '${deeds.prayersCompleted}/5 فرائض',
                done: deeds.prayersCompleted == 5,
              ),
              _DeedStatus(
                icon: Icons.wb_sunny_outlined,
                label: '${deeds.sunnahCount} سنن',
                done: deeds.sunnahCount > 0,
              ),
              _DeedStatus(
                icon: Icons.touch_app_outlined,
                label: deeds.morningAzkar && deeds.eveningAzkar
                    ? 'الأذكار كاملة'
                    : 'الأذكار',
                done: deeds.morningAzkar || deeds.eveningAzkar,
              ),
              _DeedStatus(
                icon: Icons.menu_book_outlined,
                label: deeds.quranPages > 0 ? '${deeds.quranPages} ص ورد' : 'الورد',
                done: deeds.quranPages > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeedStatus extends StatelessWidget {
  const _DeedStatus({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: done
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.45)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: done ? const Color(0xFF2E7D32) : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
            if (done)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: done ? FontWeight.bold : FontWeight.w500,
            color: done
                ? (isDark ? Colors.white : AppColors.ink)
                : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ],
    );
  }
}
