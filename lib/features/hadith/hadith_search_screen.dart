import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/hadith/hadith_book_catalog.dart';
import '../../core/data/hadith/hadith_providers.dart';
import '../../core/data/hadith/hadith_repository.dart';
import '../../core/theme/app_colors.dart';
import '../hadith_verification/ui/hadith_verification_screen.dart';
import '../story_maker/models/story_content.dart';
import '../story_maker/ui/ayah_story_maker_screen.dart';
import 'hadith_detail_screen.dart';

/// بحث نصي متقدم في أمهات كتب الحديث النبوي الشريف
/// بتصميم بطاقات إسلامية عريقة مستوحاة من نمط "منار"
/// مع إبراز كلمات البحث (Keyword Highlighting) والتحقق والتصميم والمشاركة.
class HadithSearchScreen extends ConsumerStatefulWidget {
  const HadithSearchScreen({super.key});

  @override
  ConsumerState<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends ConsumerState<HadithSearchScreen> {
  final _controller = TextEditingController();
  List<HadithSearchResult>? _results;
  bool _loading = false;
  int? _selectedBookId; // null = كل الكتب

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(hadithRepositoryProvider);
    final results = await repo.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);

    final filteredResults = _results == null
        ? null
        : (_selectedBookId == null
            ? _results!
            : _results!.where((r) => r.hadith.bookId == _selectedBookId).toList());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Container(
            height: 44,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2836) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFEBE4D6),
              ),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: onSurface, fontSize: 14.5),
              decoration: InputDecoration(
                hintText: 'ابحث في المتن أو الراوي أو الموضوع…',
                hintStyle: TextStyle(
                  color: onSurface.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.tealDeep,
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: onSurface.withValues(alpha: 0.5),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: _search,
              onChanged: (text) {
                setState(() {});
                _search(text);
              },
            ),
          ),
        ),
        body: Column(
          children: [
            // شريط فلترة سريع بالكتب عند وجود نتائج
            if (_results != null && _results!.isNotEmpty) ...[
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildBookFilterChip(
                      label: 'الكل (${_results!.length})',
                      isSelected: _selectedBookId == null,
                      onTap: () => setState(() => _selectedBookId = null),
                      isDark: isDark,
                    ),
                    ...kHadithBookCatalog.where((book) {
                      final count = _results!.where((r) => r.hadith.bookId == book.id).length;
                      return count > 0;
                    }).map((book) {
                      final count = _results!.where((r) => r.hadith.bookId == book.id).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildBookFilterChip(
                          label: '${book.nameAr} ($count)',
                          isSelected: _selectedBookId == book.id,
                          onTap: () => setState(() => _selectedBookId = book.id),
                          isDark: isDark,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEBE4D6)),
            ],

            Expanded(
              child: Builder(
                builder: (context) {
                  if (_loading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.tealDeep),
                    );
                  }
                  if (filteredResults == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B8A72).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 34,
                                color: Color(0xFF1B8A72),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'البحث الشامل في الأحاديث النبوية',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ابحث بكلمة أو عبارة في الصحيحين والسنن الأربعة والموطأ والأربعينيات',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: onSurface.withValues(alpha: 0.55),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (filteredResults.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: onSurface.withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد نتائج مطابقة',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'جرّب البحث بكلمات أبسط أو بدون تشكيل أو اختر تصنيفاً آخر',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                    itemCount: filteredResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final r = filteredResults[i];
                      return _HadithSearchCard(
                        result: r,
                        query: _controller.text.trim(),
                        accent: accent,
                        isDark: isDark,
                        onSurface: onSurface,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B8A72)
              : (isDark ? const Color(0xFF1E2836) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B8A72)
                : (isDark ? Colors.white12 : const Color(0xFFEBE4D6)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// بطاقة عرض الحديث النبوي الشريف الفاخرة لنتائج البحث
class _HadithSearchCard extends StatelessWidget {
  const _HadithSearchCard({
    required this.result,
    required this.query,
    required this.accent,
    required this.isDark,
    required this.onSurface,
  });

  final HadithSearchResult result;
  final String query;
  final Color accent;
  final bool isDark;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final book = hadithBookCatalogById(result.hadith.bookId);
    final bookBadgeColor = _colorForBook(book.key);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18222E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.lineDark : const Color(0xFFEBE4D6),
          width: 1.2,
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
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HadithDetailScreen(
                bookId: result.hadith.bookId,
                hadithId: result.hadith.id,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ١. رأس البطاقة: اسم الكتاب والمصنف + رقم الحديث + أزرار الإجراءات
                Row(
                  children: [
                    // وسم الكتاب بلونه التراثي المعتمد
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bookBadgeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: bookBadgeColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 13, color: bookBadgeColor),
                          const SizedBox(width: 5),
                          Text(
                            result.bookNameAr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: bookBadgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // شارة رقم الحديث
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF3ECE0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'حديث #${result.hadith.hadithNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // أزرار سريعة: تصميم بطاقة + نسخ + مشاركة
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      iconSize: 17,
                      tooltip: 'تصميم بطاقة دعوية',
                      icon: const Icon(Icons.palette_outlined, color: Color(0xFFC89218)),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AyahStoryMakerScreen(
                            initialContent: HadithContent(
                              hadithText: result.hadith.content,
                              narrator: 'حديث رقم ${result.hadith.hadithNumber}',
                              sourceBook: result.bookNameAr,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      iconSize: 17,
                      tooltip: 'مشاركة الحديث',
                      icon: Icon(
                        Icons.share_outlined,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: '${result.hadith.content}\n\n[${result.bookNameAr} - حديث #${result.hadith.hadithNumber}]',
                          ),
                        );
                      },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      iconSize: 17,
                      tooltip: 'نسخ الحديث',
                      icon: Icon(
                        Icons.copy_rounded,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: '${result.hadith.content}\n\n[${result.bookNameAr} - حديث #${result.hadith.hadithNumber}]',
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ نص الحديث وتوثيقه بنجاح'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ٢. متن الحديث الشريف مع شريط قرآني وتظليل كلمات البحث
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131C26)
                        : const Color(0xFFF9F6F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      right: BorderSide(
                        color: const Color(0xFF1B8A72),
                        width: 3.5,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildHighlightedText(
                          content: result.hadith.content,
                          query: query,
                          onSurface: onSurface,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ٣. تذييل البطاقة: التحقق بالدرر + فتح التفاصيل
                Row(
                  children: [
                    // زر فحص الحديث بالدرر السنية
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        // استخراج عينة من المتن للبحث بالدرر السنية
                        final snippet = _extractSearchSnippet(result.hadith.content);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HadithVerificationScreen(
                              initialQuery: snippet,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'تحقق بالدرر السنية',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // رابط قراءة الحديث في بابه
                    Row(
                      children: const [
                        Text(
                          'عرض الحديث كاملاً في بابه',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B8A72),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFF1B8A72),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// إبراز وتظليل كلمات البحث داخل متن الحديث الشريف
  Widget _buildHighlightedText({
    required String content,
    required String query,
    required Color onSurface,
    required bool isDark,
  }) {
    final cleanQueryWords = query
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '').trim())
        .where((w) => w.length >= 2)
        .toList();

    if (cleanQueryWords.isEmpty) {
      return Text(
        '« ${content.trim()} »',
        textDirection: TextDirection.rtl,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: onSurface,
          fontSize: 14.5,
          height: 1.85,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final patternStr = cleanQueryWords.map(_arabicWordRegex).join('|');
    final regExp = RegExp(patternStr, caseSensitive: false);
    final trimmedContent = content.trim();

    final matches = regExp.allMatches(trimmedContent);
    if (matches.isEmpty) {
      return Text(
        '« $trimmedContent »',
        textDirection: TextDirection.rtl,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: onSurface,
          fontSize: 14.5,
          height: 1.85,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final spans = <TextSpan>[
      const TextSpan(
        text: '« ',
        style: TextStyle(
          color: Color(0xFF1B8A72),
          fontWeight: FontWeight.w700,
        ),
      ),
    ];

    int lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(text: trimmedContent.substring(lastIndex, match.start)),
        );
      }
      spans.add(
        TextSpan(
          text: trimmedContent.substring(match.start, match.end),
          style: TextStyle(
            color: isDark ? const Color(0xFF80E5CB) : const Color(0xFF0C4E3F),
            backgroundColor: isDark
                ? const Color(0xFF1B8A72).withValues(alpha: 0.35)
                : const Color(0xFF1B8A72).withValues(alpha: 0.2),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      lastIndex = match.end;
    }
    if (lastIndex < trimmedContent.length) {
      spans.add(TextSpan(text: trimmedContent.substring(lastIndex)));
    }
    spans.add(
      const TextSpan(
        text: ' »',
        style: TextStyle(
          color: Color(0xFF1B8A72),
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: onSurface,
        fontSize: 14.5,
        height: 1.85,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// بناء تعبير نمطي يتجاهل حركات التشكيل في اللغة العربية ويطابق الألفات
  String _arabicWordRegex(String word) {
    final clean = word.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      final char = clean[i];
      if (char == 'ا' || char == 'أ' || char == 'إ' || char == 'آ') {
        buffer.write('[اأإآ]');
      } else if (char == 'ه' || char == 'ة') {
        buffer.write('[هة]');
      } else if (char == 'ي' || char == 'ى') {
        buffer.write('[يى]');
      } else {
        buffer.write(RegExp.escape(char));
      }
      buffer.write(r'[\u064B-\u065F\u0670]*');
    }
    return buffer.toString();
  }

  /// استخراج نص عينة موجز للتحقق من صحته عبر الدرر السنية
  String _extractSearchSnippet(String content) {
    const markers = ['صلى الله عليه وسلم', 'قال رسول الله', 'سمعت رسول الله'];
    for (final marker in markers) {
      final idx = content.indexOf(marker);
      if (idx != -1) {
        final after = content.substring(idx + marker.length).trim();
        final words = after.split(RegExp(r'\s+')).take(7).join(' ');
        if (words.length > 8) return words;
      }
    }
    final words = content.split(RegExp(r'\s+')).take(7).join(' ');
    return words;
  }

  Color _colorForBook(String key) {
    switch (key) {
      case 'bukhari':
        return const Color(0xFF102844);
      case 'muslim':
        return const Color(0xFF1B8A72);
      case 'nawawi':
        return const Color(0xFF754515);
      case 'abudawud':
        return const Color(0xFF6F213C);
      case 'tirmidhi':
        return const Color(0xFF4C2C6E);
      case 'nasai':
        return const Color(0xFF17516B);
      case 'ibnmajah':
        return const Color(0xFF713821);
      case 'malik':
        return const Color(0xFF4D5524);
      case 'qudsi':
      default:
        return const Color(0xFF2A366E);
    }
  }
}
