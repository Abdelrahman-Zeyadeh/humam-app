import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_book_catalog.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../hadith_verification/ui/hadith_verification_screen.dart';
import 'daily_hadith_screen.dart';
import 'hadith_book_screen.dart';
import 'hadith_download_service.dart';
import 'hadith_search_screen.dart';

String _formatSize(int bytes) {
  final mb = bytes / 1024 / 1024;
  return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} ميجا';
}

/// نغمات ألوان المجلدات التراثية الفاخرة لكل كتاب بحسب مكانته
class _BookBindingTheme {
  const _BookBindingTheme({
    required this.spineColor,
    required this.coverGradient,
    required this.goldColor,
  });

  final Color spineColor;
  final List<Color> coverGradient;
  final Color goldColor;
}

_BookBindingTheme _themeForBook(String key) {
  switch (key) {
    case 'bukhari':
      return const _BookBindingTheme(
        spineColor: Color(0xFF091C30),
        coverGradient: [Color(0xFF102844), Color(0xFF193B63)],
        goldColor: Color(0xFFFFD56B),
      );
    case 'muslim':
      return const _BookBindingTheme(
        spineColor: Color(0xFF0C2C20),
        coverGradient: [Color(0xFF123E2E), Color(0xFF1A5741)],
        goldColor: Color(0xFFFFE082),
      );
    case 'nawawi':
      return const _BookBindingTheme(
        spineColor: Color(0xFF382006),
        coverGradient: [Color(0xFF52300D), Color(0xFF754515)],
        goldColor: Color(0xFFFFD54F),
      );
    case 'abudawud':
      return const _BookBindingTheme(
        spineColor: Color(0xFF340B19),
        coverGradient: [Color(0xFF4E1428), Color(0xFF6F213C)],
        goldColor: Color(0xFFFFCC80),
      );
    case 'tirmidhi':
      return const _BookBindingTheme(
        spineColor: Color(0xFF211132),
        coverGradient: [Color(0xFF331D4B), Color(0xFF4C2C6E)],
        goldColor: Color(0xFFE1BEE7),
      );
    case 'nasai':
      return const _BookBindingTheme(
        spineColor: Color(0xFF092430),
        coverGradient: [Color(0xFF0F3647), Color(0xFF17516B)],
        goldColor: Color(0xFF80DEEA),
      );
    case 'ibnmajah':
      return const _BookBindingTheme(
        spineColor: Color(0xFF36180C),
        coverGradient: [Color(0xFF502615), Color(0xFF713821)],
        goldColor: Color(0xFFFFAB91),
      );
    case 'malik':
      return const _BookBindingTheme(
        spineColor: Color(0xFF22260E),
        coverGradient: [Color(0xFF353B18), Color(0xFF4D5524)],
        goldColor: Color(0xFFE6EE9C),
      );
    case 'qudsi':
    default:
      return const _BookBindingTheme(
        spineColor: Color(0xFF121731),
        coverGradient: [Color(0xFF1B2348), Color(0xFF2A366E)],
        goldColor: Color(0xFFFFD700),
      );
  }
}

/// شاشة موسوعة وكتالوج كتب الحديث النبوي الشريف
/// بتصميم يجمع بين:
/// ١. "الرفوف والمكتبة الإسلامية الملكية" (Royal Islamic Bookshelf)
/// ٢. "مركز الموسوعة المدمج" (Compact Hub & Quick Navigation)
class HadithBooksScreen extends ConsumerStatefulWidget {
  const HadithBooksScreen({super.key});

  @override
  ConsumerState<HadithBooksScreen> createState() => _HadithBooksScreenState();
}

class _HadithBooksScreenState extends ConsumerState<HadithBooksScreen> {
  HadithBookCategory _selectedCategory = HadithBookCategory.all;
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(hadithDownloadControllerProvider);
    final controller = ref.read(hadithDownloadControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    ref.listen(hadithDownloadControllerProvider.select((s) => s.errorMessage), (
      prev,
      next,
    ) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    final filteredBooks = _selectedCategory == HadithBookCategory.all
        ? kHadithBookCatalog
        : kHadithBookCatalog.where((b) => b.category == _selectedCategory).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'موسوعة الحديث والمكتبة النبوية',
          colors: const [AppColors.tealDeep, AppColors.navy],
          actions: [
            // مفتاح التبديل بين عرض الرفوف وعرض البطاقات المفصلة
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
                size: 22,
              ),
              tooltip: _isGridView ? 'عرض القائمة المفصلة' : 'عرض رفوف المكتبة',
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            IconButton(
              icon: const Icon(Icons.verified_outlined),
              tooltip: 'التحقق من صحة الحديث',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HadithVerificationScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'بحث في متون الأحاديث',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HadithSearchScreen()),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            // ١. مركز الموسوعة الذكي (Compact Hub Banner)
            _buildCompactHubHeader(context, isDark),

            const SizedBox(height: 12),

            // ٢. التبويبات الفقهية والتصنيف التراثي (Category Filter Chips)
            _buildCategoryTabs(isDark),

            const SizedBox(height: 16),

            // ٣. شريط العنوان وإحصائيات الكتب المعروضة
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.goldDeep,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filteredBooks.length} كتب',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.inkSoft,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _isGridView ? 'نمط رفوف المكتبة' : 'نمط البطاقات الموسعة',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ٤. عرض الكتب (إما شبكة مجلدات إسلامية فاخرة أو قائمة تفصيلية)
            if (_isGridView)
              _buildBooksGrid(filteredBooks, downloadState, controller, isDark)
            else
              _buildBooksList(filteredBooks, downloadState, controller, isDark),
          ],
        ),
      ),
    );
  }

  /// رأس مركز الموسوعة المدمج مع البحث السريع والتحقق والفوائد
  Widget _buildCompactHubHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF132230), const Color(0xFF0D1722)]
              : [const Color(0xFFE8F4F8), const Color(0xFFD4E8F2)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF23405E) : const Color(0xFFB5D4E6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط البحث الشامل
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HadithSearchScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.tealDeep.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.tealDeep,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'البحث الشامل في متون الأحاديث',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F3A4B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ابحث بالكلمة في ٩ أمهات كتب وأكثر من ٤١,٠٠٠ حديث',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF2C6075),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.tealDeep,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white12 : const Color(0xFFC8DEE8),
          ),

          // روابط سريعة: حديث اليوم + التحقق من صحة الحديث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'حديث اليوم والفوائد',
                    color: const Color(0xFFC89218),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DailyHadithScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.verified_user_outlined,
                    label: 'التحقق عبر الدرر',
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HadithVerificationScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// تبويبات التصنيف الإسلامي
  Widget _buildCategoryTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: HadithBookCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(cat.label),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedCategory = cat);
              },
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.ink),
              ),
              selectedColor: AppColors.tealDeep,
              backgroundColor: isDark ? const Color(0xFF1B2633) : const Color(0xFFF0EBE1),
              side: BorderSide(
                color: isSelected
                    ? AppColors.tealDeep
                    : (isDark ? Colors.white12 : const Color(0xFFDDD4C5)),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// شبكة رفوف المكتبة الملكية (Royal Islamic Bookshelf Grid)
  Widget _buildBooksGrid(
    List<HadithBookCatalogEntry> books,
    HadithDownloadState downloadState,
    HadithDownloadController controller,
    bool isDark,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.65, // شكل مجلد مستطيل فاخر
      ),
      itemBuilder: (context, i) {
        final book = books[i];
        final theme = _themeForBook(book.key);
        final status = downloadState.statusFor(book.key);
        final isAvailable = status == HadithBookDownloadStatus.downloaded;
        final isDownloading = status == HadithBookDownloadStatus.downloading;

        return _RoyalBookHardcover(
          book: book,
          theme: theme,
          isAvailable: isAvailable,
          isDownloading: isDownloading,
          downloadProgress: downloadState.downloadProgress,
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
            } else if (status == HadithBookDownloadStatus.notDownloaded) {
              controller.downloadBook(book.key);
            }
          },
          onCancelDownload: controller.cancelDownload,
        );
      },
    );
  }

  /// قائمة تفصيلية عريضة للموسوعة (Detailed Editorial List)
  Widget _buildBooksList(
    List<HadithBookCatalogEntry> books,
    HadithDownloadState downloadState,
    HadithDownloadController controller,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final book = books[i];
        final theme = _themeForBook(book.key);
        final status = downloadState.statusFor(book.key);
        final isAvailable = status == HadithBookDownloadStatus.downloaded;
        final isDownloading = status == HadithBookDownloadStatus.downloading;

        return _EditorialBookCard(
          book: book,
          theme: theme,
          isAvailable: isAvailable,
          isDownloading: isDownloading,
          downloadProgress: downloadState.downloadProgress,
          isDark: isDark,
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
            } else if (status == HadithBookDownloadStatus.notDownloaded) {
              controller.downloadBook(book.key);
            }
          },
          onCancelDownload: controller.cancelDownload,
        );
      },
    );
  }
}

/// زر إجراء سريع مصغر في الهيدر
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1B2936) : Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E3A4B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مجلد إسلامي فاخر بنمط التجليد المذهب والتراثي (The Royal Hardcover)
class _RoyalBookHardcover extends StatelessWidget {
  const _RoyalBookHardcover({
    required this.book,
    required this.theme,
    required this.isAvailable,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onTap,
    required this.onCancelDownload,
  });

  final HadithBookCatalogEntry book;
  final _BookBindingTheme theme;
  final bool isAvailable;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onCancelDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(2, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // خلفية الغلاف الجلدية المتدرجة
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: theme.coverGradient,
                    ),
                  ),
                ),

                // كعب التجليد الأيمن الفاخر (Spine) لتعزيز واقعية المجلد
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.spineColor,
                      border: Border(
                        left: BorderSide(
                          color: theme.goldColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (_) => Container(
                          width: 8,
                          height: 2,
                          decoration: BoxDecoration(
                            color: theme.goldColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // محتوى واجهة الغلاف
                Positioned.fill(
                  left: 8,
                  right: 18,
                  top: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // إطار الزخرفة الذهبية الداخلي
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.goldColor.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // زخرفة إسلامية علوية
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 1,
                                    color: theme.goldColor.withValues(alpha: 0.5),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 10,
                                      color: theme.goldColor,
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 1,
                                    color: theme.goldColor.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // اسم الكتاب بالخط العربي المذهب
                              Text(
                                book.nameAr,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.goldColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.25,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 6),

                              // اسم الإمام والمصنف
                              Text(
                                book.authorAr,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF5EEDB),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              if (book.authorDeath.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  book.authorDeath,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.goldColor.withValues(alpha: 0.75),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],

                              const Spacer(),

                              // شارة عدد الأحاديث
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.goldColor.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${book.hadithCount} حديث',
                                  style: TextStyle(
                                    color: theme.goldColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // شريط الإجراء السفلي (فتح / تنزيل / جارٍ التنزيل)
                      if (isDownloading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(downloadProgress * 100).round()}٪',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: downloadProgress > 0 ? downloadProgress : null,
                                  color: theme.goldColor,
                                ),
                              ),
                              InkWell(
                                onTap: onCancelDownload,
                                child: const Icon(
                                  Icons.pause_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? const Color(0xFF14533C)
                                : Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAvailable
                                  ? const Color(0xFF2E9970)
                                  : theme.goldColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.auto_stories_rounded
                                    : Icons.download_rounded,
                                size: 14,
                                color: isAvailable ? Colors.white : theme.goldColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAvailable
                                    ? 'تصفّح الكتاب'
                                    : (book.embedded
                                        ? 'مضمّن'
                                        : 'تنزيل (${_formatSize(book.approxDownloadBytes)})'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isAvailable ? Colors.white : theme.goldColor,
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
      ),
    );
  }
}

/// بطاقة موسوعية أفقية مفصلة (Editorial List View)
class _EditorialBookCard extends StatelessWidget {
  const _EditorialBookCard({
    required this.book,
    required this.theme,
    required this.isAvailable,
    required this.isDownloading,
    required this.downloadProgress,
    required this.isDark,
    required this.onTap,
    required this.onCancelDownload,
  });

  final HadithBookCatalogEntry book;
  final _BookBindingTheme theme;
  final bool isAvailable;
  final bool isDownloading;
  final double downloadProgress;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onCancelDownload;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18222E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.lineDark : AppColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // مصغر المجلد الفاخر على الجانب
                Container(
                  width: 72,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: theme.coverGradient,
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(1, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: 8,
                        child: Container(
                          color: theme.spineColor,
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 26,
                            color: theme.goldColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // تفاصيل الكتاب والمؤلف والنبذة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              book.nameAr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                              ),
                            ),
                          ),
                          if (book.embedded)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B8A72).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'مضمّن',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B8A72),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${book.authorAr} · ${book.authorDeath}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFFD56B) : const Color(0xFF8A5A1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${book.hadithCount} حديث',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          if (!book.embedded && !isAvailable) ...[
                            Text(
                              ' · ${_formatSize(book.approxDownloadBytes)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (isDownloading) ...[
                            Text(
                              '${(downloadProgress * 100).round()}٪',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.pause, size: 18),
                              tooltip: 'إيقاف مؤقت',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: onCancelDownload,
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? const Color(0xFF1B8A72)
                                    : (isDark ? Colors.white12 : const Color(0xFFE8EEF5)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isAvailable ? 'فتح الكتاب' : 'تنزيل',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isAvailable
                                      ? Colors.white
                                      : (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1A4568)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
