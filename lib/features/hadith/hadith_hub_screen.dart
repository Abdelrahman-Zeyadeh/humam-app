import 'package:flutter/material.dart';

import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../hadith_verification/ui/hadith_verification_screen.dart';
import 'daily_hadith_screen.dart';
import 'hadith_books_screen.dart';

/// مدخل واحد موحَّد لثلاث أدوات كانت متفرّقة بشاشة "أدواتي" (موسوعة
/// الحديث/التحقق من صحته/حديث اليوم).
class HadithHubScreen extends StatelessWidget {
  const HadithHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const GradientAppBar(
          title: 'الحديث الشريف والمكتبة',
          centerTitle: true,
          colors: [AppColors.blue, AppColors.navy],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            _HubCard(
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF685197),
              title: 'موسوعة الحديث',
              subtitle: 'تصفّح كتب الحديث كاملة (البخاري، مسلم، الأربعون النووية وغيرها) والبحث بمتنها',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HadithBooksScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _HubCard(
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF2E7D32),
              title: 'التحقق من صحة الحديث',
              subtitle: 'ابحث عن أي حديث يصلك وتأكد من درجته عبر موسوعة الدرر السنية',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HadithVerificationScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _HubCard(
              icon: Icons.lightbulb_outline,
              color: const Color(0xFFC89218),
              title: 'حديث اليوم والفوائد',
              subtitle: 'حديث نبوي مختار يومياً مع فوائده وتذكير يمكن تفعيله',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DailyHadithScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: isDark ? const Color(0xFF1E2836) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppColors.lineDark : AppColors.line),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: isDark ? Colors.white24 : const Color(0xFFC7BEB0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
