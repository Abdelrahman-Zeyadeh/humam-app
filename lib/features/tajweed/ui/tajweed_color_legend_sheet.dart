import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// شيت دلالات ألوان التجويد في المصحف الشريف
class TajweedColorLegendSheet extends StatelessWidget {
  const TajweedColorLegendSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const TajweedColorLegendSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // **قيم مستخرَجة فعلياً من جدول ألوان (CPAL) خط QCF V4 Tajweed نفسه**
    // (فحص مباشر لملف p5.ttf، لا تخمين) — لا توثيق رسمي منشور من QUL يربط
    // كل لون برقمه بحكمه بالاسم صراحة، فالمطابقة هون بمستوى "أقرب لون
    // بنفس العائلة اللونية" (أحمر غامق/أحمر/برتقالي/أخضر/أزرق/تركواز/
    // رمادي) لا تحقّق حرفي طبقة-بطبقة لكل كلمة. القيم القديمة (قبل هالتعديل)
    // كانت تخميناً عاماً من اصطلاح "المصحف الملوّن" الشائع بلا مصدر محدد؛
    // هاي أدق لأنها فعلياً نفس بكسلات V4 يلي المستخدم شايفها بالمصحف.
    final colorLegends = [
      (
        const Color(0xFFB50000),
        'المد اللازم (٦ حركات)',
        'أحمر غامق — مد لازم كلمي أو حرفي مشبع ٦ حركات (مثل: الضَّالِّينَ، الحَاقَّةُ)',
      ),
      (
        const Color(0xFFF40000),
        'المد المتصل والمنفصل (٤-٥ حركات)',
        'أحمر — مد متصل واجب أو منفصل جائز ٤ إلى ٥ حركات (مثل: جَاءَ، السَّمَاءِ، إِنَّا أَعْطَيْنَاكَ)',
      ),
      (
        const Color(0xFFFF7B00),
        'المد الطبيعي والعارض (٢-٤-٦ حركات)',
        'برتقالي — مد طبيعي حركتان أو عارض للسكون (مثل: قَالُوا، كِتَابٌ، نَسْتَعِينُ)',
      ),
      (
        const Color(0xFF09B000),
        'الغنة والإخفاء والإدغام بغنة (حركتان)',
        'أخضر — إخفاء حقيقي، غنة النون والميم المشددتين، والإدغام بغنة (مثل: مِن شَرِّ، إِنَّ، مَن يَعْمَلْ)',
      ),
      (
        const Color(0xFF3F48E6),
        'الإقلاب (قلب النون ميماً)',
        'أزرق — قلب النون الساكنة أو التنوين ميماً مخفاة عند حرف الباء (مثل: أَنبِئْهُم، مِن بَعْدِ)',
      ),
      (
        const Color(0xFF2CA4AB),
        'القلقلة (قطب جد)',
        'تركواز — اضطراب الحرف الساكن من حروف قطب جد (مثل: الفَلَقْ، أَحَدٌ، يَطْمَعُ)',
      ),
      (
        const Color(0xFFA5A5A5),
        'الحروف التي لا تُنطق (الساقطة وصلاً)',
        'رمادي — الحروف المكتوبة التي لا تلفظ عند الوصل كألف الوصل واللام الشمسية (مثل: وَالشَّمْسِ، ادْعُ)',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.palette_outlined, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'دليل ومفتاح ألوان التجويد',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'دلالات الألوان المعتمدة لضبط التلاوة وأحكام التجويد برواية حفص عن عاصم:',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: colorLegends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final item = colorLegends[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: item.$1,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.$1.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
