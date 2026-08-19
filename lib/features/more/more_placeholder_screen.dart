import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../hadith/hadith_books_screen.dart';
import '../khatma/khatma_screen.dart';
import '../mushaf/bookmarks_screen.dart';
import '../mushaf/font_download_screen.dart';

/// المزيد: نقاط الدخول للميزات المستقلة عن التبويبات الأربعة الرئيسية.
/// كل عنصر هنا شاشة حقيقية شغّالة — لا وعود بمزايا غير منفَّذة.
class MorePlaceholderScreen extends StatelessWidget {
  const MorePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المزيد')),
      body: ListView(
        children: [
          _MoreTile(
            icon: Icons.bookmark_outline,
            title: 'العلامات المرجعية',
            subtitle: 'الآيات المحفوظة للرجوع إليها',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookmarksScreen())),
          ),
          _MoreTile(
            icon: Icons.flag_outlined,
            title: 'خطة الختمة',
            subtitle: 'ورد يومي وتتبّع تقدّم ختم المصحف',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KhatmaScreen())),
          ),
          _MoreTile(
            icon: Icons.menu_book_outlined,
            title: 'الأحاديث',
            subtitle: 'صحيح البخاري، صحيح مسلم، الأربعون النووية',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HadithBooksScreen())),
          ),
          _MoreTile(
            icon: Icons.cloud_download_outlined,
            title: 'تنزيل بقية صفحات المصحف',
            subtitle: 'الصفحات ٥١-٦٠٤ (أول ٥٠ مضمَّنة أصلاً)',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FontDownloadScreen())),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: AppColors.gold.withValues(alpha: 0.15), foregroundColor: AppColors.gold, child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }
}
