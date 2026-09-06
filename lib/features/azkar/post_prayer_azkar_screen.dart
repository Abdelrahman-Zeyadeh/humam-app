import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'azkar_full_repository.dart';
import 'azkar_library_category_screen.dart';

/// نقطة الدخول لقسم "الأَذْكَارُ بَعْدَ السَّلَامِ مِنَ الصَّلَاةِ" (`id == 24` بمكتبة
/// حصن المسلم الكاملة — تحقّقتُ منه مباشرة بـ`assets/azkar/azkar_categories.json`،
/// موجود أصلاً بلا حاجة تصنيف جديد) — تُفتح مباشرة من زر "اقرأ الآن" بتنبيه
/// أذكار بعد الصلاة (`adhan_notification_service.dart`)، بنفس فكرة
/// `sleepAzkarProvider` (القسم `id == 28`).
class PostPrayerAzkarScreen extends ConsumerWidget {
  const PostPrayerAzkarScreen({super.key});

  static const _categoryId = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(azkarLibraryProvider);

    return categoriesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('أذكار بعد الصلاة')),
        body: Center(child: Text('تعذّر تحميل الأذكار: $e')),
      ),
      data: (categories) {
        final category = categories.firstWhere(
          (c) => c.id == _categoryId,
          // احتياط نظري بحت — التصنيف تحقّقتُ من وجوده فعلياً بالبيانات
          // المضمَّنة، لا يُفترض الوصول لهذا الفرع إطلاقاً.
          orElse: () => const AzkarLibraryCategory(
            id: _categoryId,
            title: 'الأذكار بعد السلام من الصلاة',
            items: [],
          ),
        );
        return AzkarLibraryCategoryScreen(category: category);
      },
    );
  }
}
