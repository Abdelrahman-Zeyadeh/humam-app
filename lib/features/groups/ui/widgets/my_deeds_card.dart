import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/faith_group.dart';

/// بطاقة "إنجازك في أعمال اليوم والليلة" بأعلى مركز المجموعات — تُحدَّث
/// تلقائياً بجميع مجموعات المستخدم.
class MyDeedsCard extends StatelessWidget {
  const MyDeedsCard({super.key, required this.deeds, required this.isDark});

  final DailyDeedsProgress deeds;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final score = deeds.scorePercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    const Text(
                      '🌟 إنجازك في أعمال اليوم والليلة',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يتم تحديث إنجازك تلقائياً في جميع مجموعاتك',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 5,
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 80 ? const Color(0xFF2E7D32) : AppColors.goldDeep,
                      ),
                    ),
                  ),
                  Text(
                    '$score%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
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
                label: deeds.quranPages > 0 ? 'ورد القرآن' : 'الورد',
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
    final accent = themeAccent(context);
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done
                ? accent.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? accent.withValues(alpha: 0.5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 18, color: done ? accent : Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: done ? FontWeight.bold : FontWeight.normal,
            color: done
                ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87)
                : Colors.grey,
          ),
        ),
      ],
    );
  }
}
