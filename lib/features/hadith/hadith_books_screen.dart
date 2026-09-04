import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_book_catalog.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../hadith_verification/ui/hadith_verification_screen.dart';
import 'hadith_book_screen.dart';
import 'hadith_download_service.dart';
import 'hadith_search_screen.dart';

String _formatSize(int bytes) {
  final mb = bytes / 1024 / 1024;
  return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} ميجا';
}

/// لون هوية "غلاف" كل كتاب بالشبكة — يدور على مجموعة ثابتة من ألوان
/// التطبيق حسب ترتيب الكتاب بالكتالوج، لإعطاء كل كتاب هوية بصرية مستقلة
/// بدل تكرار نفس الأيقونة الرمادية لكل الكتب (بطلب صاحب المشروع).
const List<Color> _kBookAccents = [
  AppColors.goldDeep,
  AppColors.tealDeep,
  AppColors.purple,
  AppColors.blue,
  Color(0xFFE67E22),
  Color(0xFF2E7D32),
  AppColors.navy,
  Color(0xFF8D6E63),
  Color(0xFFC0392B),
];

/// نقطة الدخول لقسم الأحاديث — تسع مجموعات (البخاري، مسلم، أبو داود،
/// الترمذي، النسائي، ابن ماجه، موطأ مالك، الأربعون النووية، الأربعون
/// القدسية) مع قسم التحقق من صحة الحديث والموسوعة الحديثية.
class HadithBooksScreen extends ConsumerWidget {
  const HadithBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(hadithDownloadControllerProvider);
    final controller = ref.read(hadithDownloadControllerProvider.notifier);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(hadithDownloadControllerProvider.select((s) => s.errorMessage), (
      prev,
      next,
    ) {
      if (next != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      // هيدر بتدرّج مطابق لأسلوب لوحة التصميم المعتمدة — `AppBar` عادي
      // بلا لمس هيكل الجسم، فقط زُيِّن بصرياً (`flexibleSpace`). كمان
      // إزالة `accent` المحلي غير المستخدَم إطلاقاً (باج قديم غير مرتبط
      // بهالتعديل — كان يُحسب بلا أي استخدام لاحقاً بالملف).
      appBar: GradientAppBar(
        title: 'موسوعة الحديث النبوي',
        colors: const [AppColors.purple, AppColors.navy],
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_outlined),
            tooltip: 'التحقق من صحة الحديث',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HadithVerificationScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث في النصوص',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HadithSearchScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        children: [
          // بطاقة التحقق من صحة الحديث (الموسوعة الحديثية والدرر السنية)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1B3A2B), const Color(0xFF0F241B)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF2E7D32,
                  ).withValues(alpha: isDark ? 0.2 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HadithVerificationScreen(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF2E7D32),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'التحقق من صحة الحديث',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'جديد',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'ابحث عن أي حديث وتأكد من درجته وصحته وتخريجه',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // عنوان قائمة كتب الحديث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'كتب وأمهات الحديث النبوي',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : AppColors.inkSoft,
              ),
            ),
          ),

          // كتب الحديث — شبكة "أغلفة" بلون هوية مستقل لكل كتاب بدل قائمة
          // صفوف متطابقة الشكل (بطلب صاحب المشروع "مش هذاك التغيير" على
          // النسخة السابقة بصفوف مسطّحة).
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemCount: kHadithBookCatalog.length,
            itemBuilder: (context, i) {
              final book = kHadithBookCatalog[i];
              final accent = _kBookAccents[i % _kBookAccents.length];
              final status = downloadState.statusFor(book.key);
              final isAvailable = status == HadithBookDownloadStatus.downloaded;
              final isDownloading =
                  status == HadithBookDownloadStatus.downloading;

              return Material(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    if (isAvailable) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HadithBookScreen(
                            bookId: book.id,
                            bookNameAr: book.nameAr,
                          ),
                        ),
                      );
                    } else if (status ==
                        HadithBookDownloadStatus.notDownloaded) {
                      controller.downloadBook(book.key);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.lineDark : AppColors.line,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.22 : 0.05,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // "غلاف" الكتاب — شريط علوي بلون هوية الكتاب.
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: isDark ? 0.4 : 0.24),
                                  accent.withValues(alpha: isDark ? 0.18 : 0.1),
                                ],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: isDownloading
                                ? SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: accent,
                                      value: downloadState.downloadProgress > 0
                                          ? downloadState.downloadProgress
                                          : null,
                                    ),
                                  )
                                : Icon(
                                    isAvailable
                                        ? Icons.menu_book_rounded
                                        : Icons.download_for_offline_outlined,
                                    size: 38,
                                    color: accent,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.nameAr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                switch (status) {
                                  HadithBookDownloadStatus.downloaded =>
                                    '${book.hadithCount} حديث',
                                  HadithBookDownloadStatus.downloading =>
                                    'جارٍ التنزيل… ${(downloadState.downloadProgress * 100).round()}٪',
                                  _ =>
                                    '${book.hadithCount} حديث · '
                                        '${_formatSize(book.approxDownloadBytes)}',
                                },
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (isDownloading)
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    // منطقة لمس ٤٤×٤٤ فعلية رغم الأيقونة الصغيرة
                                    // (١٦px) — إلغاء تنزيل نشط إجراء يستاهل دقة
                                    // لمس موثوقة، `BoxConstraints()` الفارغة
                                    // كانت تلغي الحد الأدنى الافتراضي بالكامل.
                                    constraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    iconSize: 16,
                                    icon: const Icon(Icons.close),
                                    tooltip: 'إلغاء',
                                    onPressed: controller.cancelDownload,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAvailable
                                            ? Icons.chevron_left_rounded
                                            : Icons.download_outlined,
                                        size: 13,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        isAvailable ? 'فتح' : 'تنزيل',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
