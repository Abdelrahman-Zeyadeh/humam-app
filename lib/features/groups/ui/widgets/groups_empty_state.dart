import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// حالة "لا مجموعات بعد" — تشجّع المستخدم على إنشاء أو الانضمام لأول
/// مجموعة إيمانية.
class GroupsEmptyState extends StatelessWidget {
  const GroupsEmptyState({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
      ),
      child: Column(
        children: [
          const Text('🤝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'وَتَعَاوَنُوا عَلَى الْبِرِّ وَالتَّقْوَىٰ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Kitab',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أنشئ حلقة إيمانية مع أهلك أو أصدقائك وشاركهم رمز الانضمام للتواصي على أداء الصلوات والأذكار والسنن ومتابعة همم اليوم معاً.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
