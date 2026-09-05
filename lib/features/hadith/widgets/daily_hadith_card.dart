import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/daily_hadith_data.dart';

/// كرت متن الحديث الرئيسي: راوي الحديث، متنه الكامل، ومصدره ودرجته مع زر
/// نسخ سريع إلى الحافظة.
///
/// النسخ إلى الحافظة (وما يترتب عليه من رسالة تأكيد) يبقى منطقاً في الشاشة
/// الأم عبر [onCopy] لأنه يحتاج `BuildContext` الشاشة لعرض الـ SnackBar.
class DailyHadithCard extends StatelessWidget {
  const DailyHadithCard({
    super.key,
    required this.hadith,
    required this.onCopy,
  });

  final DailyHadithItem hadith;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.lineDark : AppColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeAccent(context).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_rounded, color: themeAccent(context), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عن ${hadith.narrator}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      'قال رسول الله ﷺ:',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '« ${hadith.matn} »',
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 16.5,
              height: 1.8,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
              color: onSurface,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '📚 ${hadith.source} · [${hadith.grade}]',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                tooltip: 'نسخ الحديث',
                onPressed: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
