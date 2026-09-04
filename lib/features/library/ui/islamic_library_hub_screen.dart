import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/hadith/hadith_book_catalog.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../hadith/hadith_books_screen.dart';
import '../../hadith/hadith_book_screen.dart';
import '../../hadith_verification/ui/hadith_verification_screen.dart';
import '../../mushaf/tafsir_reading_screen.dart';
import '../data/islamic_library_catalog.dart';

/// الشاشة المركزية للمكتبة الإسلامية الشاملة وموسوعة الدرر السنية
class IslamicLibraryHubScreen extends ConsumerStatefulWidget {
  const IslamicLibraryHubScreen({super.key});

  @override
  ConsumerState<IslamicLibraryHubScreen> createState() =>
      _IslamicLibraryHubScreenState();
}

class _IslamicLibraryHubScreenState
    extends ConsumerState<IslamicLibraryHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedTab = 'الكل';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LibraryBookItem> get _filteredBooks {
    return kIslamicLibraryBooks.where((book) {
      final matchesCat = _selectedTab == 'الكل' ||
          switch (_selectedTab) {
            'الحديث والسنة' =>
              book.category == LibraryCategory.hadithBooks ||
                  book.category == LibraryCategory.dorarHadith,
            'التفسير والقرآن' => book.category == LibraryCategory.tafsirQuran,
            'الفقه والأحكام' => book.category == LibraryCategory.fiqhRules,
            'السيرة والتزكية' =>
              book.category == LibraryCategory.seerahHistory ||
                  book.category == LibraryCategory.tazkiyah,
            _ => true,
          };

      final matchesQuery = _searchQuery.isEmpty ||
          book.title.contains(_searchQuery) ||
          book.author.contains(_searchQuery) ||
          book.description.contains(_searchQuery);

      return matchesCat && matchesQuery;
    }).toList();
  }

  void _onOpenBook(LibraryBookItem book) {
    HapticFeedback.lightImpact();
    if (book.id == 'dorar_engine') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HadithVerificationScreen(),
        ),
      );
      return;
    }

    if (book.category == LibraryCategory.tafsirQuran) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TafsirReadingScreen(initialPage: 1),
        ),
      );
      return;
    }

    // كتب الحديث التسعة في الكتالوج
    final catalogEntry = kHadithBookCatalog.where((c) {
      if (book.id == 'forty_nawawi') return c.key == 'nawawi';
      return c.key == book.id;
    }).firstOrNull;

    if (catalogEntry != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HadithBookScreen(
            bookId: catalogEntry.id,
            bookNameAr: catalogEntry.nameAr,
          ),
        ),
      );
    } else {
      // فتح قسم الفقه أو السيرة أو التفاسير
      _showTopicDetailsDialog(book);
    }
  }

  void _showTopicDetailsDialog(LibraryBookItem book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B232E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: book.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(book.icon,
                            color: book.accentColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              book.author,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    book.description,
                    style: const TextStyle(fontSize: 13.5, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'أبواب وموضوعات الكتاب:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (int i = 1; i <= 6; i++) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            book.accentColor.withValues(alpha: 0.15),
                        child: Text(
                          '$i',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: book.accentColor,
                          ),
                        ),
                      ),
                      title: Text(
                        'الباب $i: في أصول وفضائل وأحكام هذا المبحث',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      trailing: const Icon(Icons.chevron_left, size: 16),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);

    final tabs = [
      'الكل',
      'الحديث والسنة',
      'التفسير والقرآن',
      'الفقه والأحكام',
      'السيرة والتزكية',
    ];

    final filtered = _filteredBooks;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1722) : const Color(0xFFF9F7F1),
      appBar: GradientAppBar(
        title: 'المكتبة الإسلامية الشاملة',
        centerTitle: true,
        colors: const [AppColors.blue, AppColors.navy],
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_outlined),
            tooltip: 'التحقق من الحديث',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HadithVerificationScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // 1. بطاقة محرك التحقق من الأحاديث (الدرر السنية) البارزة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [const Color(0xFF1B8A72), const Color(0xFF0E4D40)]
                    : [const Color(0xFF1B8A72), const Color(0xFF146C59)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B8A72).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'موسوعة الدرر السنية لتخريج الأحاديث',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ابحث عن أي حديث فوراً للتحقق من صحته، درجته (صحيح، حسن، ضعيف)، وأحكام كبار المحدثين.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: 'ابحث وتأكد من صحة الحديث الآن',
                  icon: Icons.search,
                  color: Colors.white,
                  foregroundColor: const Color(0xFF0E4D40),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HadithVerificationScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. شريط البحث في مصادر وموسوعات المكتبة
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2836) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppColors.lineDark : AppColors.line)
                    .withValues(alpha: 0.6),
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث في كتب الحديث والتفاسير والفقه...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.search, size: 20, color: accent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. شريط التبويبات الفئوية
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final tab = tabs[idx];
                final isSelected = tab == _selectedTab;
                return ChoiceChip(
                  label: Text(tab),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppColors.ink),
                  ),
                  selectedColor: accent,
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _selectedTab = tab);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 4. شبكة البطاقات والمصادر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المصادر والموسوعات المعتمدة (${filtered.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HadithBooksScreen()),
                ),
                child: const Text('كل كتب الحديث', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          for (final book in filtered) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: isDark ? const Color(0xFF1E2836) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _onOpenBook(book),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: (isDark ? AppColors.lineDark : AppColors.line)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: book.accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(book.icon,
                              color: book.accentColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      book.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: book.accentColor
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      book.hadithsOrVersesCount,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: book.accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                book.author,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: onSurface.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: onSurface.withValues(alpha: 0.8),
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
            ),
          ],

          const SizedBox(height: 16),

          // 5. قسم أبواب الفقه الميسر
          if (_selectedTab == 'الكل' || _selectedTab == 'الفقه والأحكام') ...[
            const SizedBox(height: 8),
            const Text(
              'أبواب الفقه الإسلامي الميسر:',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            for (final fTopic in kFiqhTopics) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    leading: Icon(fTopic.icon, color: const Color(0xFF27AE60)),
                    title: Text(
                      fTopic.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      fTopic.summary,
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          children: fTopic.subtopics.map((st) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 14, color: Color(0xFF27AE60)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      st,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
