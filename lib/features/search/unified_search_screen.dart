import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_providers.dart';
import '../../core/data/hadith/hadith_repository.dart' show HadithSearchResult;
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart' show AyahSearchResult;
import '../../core/text/arabic_normalizer.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../azkar/azkar_full_repository.dart';
import '../azkar/azkar_library_category_screen.dart';
import '../hadith/hadith_detail_screen.dart';
import '../mushaf/mushaf_settings.dart' show mushafJumpRequestProvider;
import '../shell/root_shell.dart';

import '../../core/data/quran/quran_topics_data.dart';

/// نتيجة أذكار واحدة مطابقة للبحث — الفئة الأصلية (للتنقّل) + الذكر نفسه
/// (للعرض).
class _AzkarSearchHit {
  const _AzkarSearchHit({required this.category, required this.item});
  final AzkarLibraryCategory category;
  final AzkarLibraryItem item;
}

/// أقصى عدد نتائج معروضة لكل قسم — بحث سريع لمعاينة، لا استبدال لشاشات
/// البحث المخصَّصة الكاملة بكل ميزة (`MushafSearchScreen`/
/// `HadithSearchScreen`) لو المستخدم يحتاج نتائج أكتر.
const int _kMaxResultsPerSection = 6;

/// بحث موحّد عبر القرآن والحديث والأذكار بحقل واحد — نقطة دخول سريعة من
/// الشاشة الرئيسية بدل فتح ٣ شاشات بحث منفصلة لنفس السؤال. كل قسم يعرض
/// أفضل [_kMaxResultsPerSection] نتائج فقط.
class UnifiedSearchScreen extends ConsumerStatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  ConsumerState<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends ConsumerState<UnifiedSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  List<QuranTopic> _matchedTopics = [];
  List<AyahSearchResult> _ayahResults = [];
  List<HadithSearchResult> _hadithResults = [];
  List<_AzkarSearchHit> _azkarResults = [];
  bool _isSearching = false;
  int _searchToken = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _query = value;
        _matchedTopics = [];
        _ayahResults = [];
        _hadithResults = [];
        _azkarResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _query = value;
      _isSearching = true;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String query) async {
    final token = ++_searchToken;
    final quranRepo = ref.read(quranRepositoryProvider);
    final hadithRepo = ref.read(hadithRepositoryProvider);

    final topics = searchQuranTopics(query);

    final results = await Future.wait([
      quranRepo.search(query, limit: _kMaxResultsPerSection),
      hadithRepo.search(query, limit: _kMaxResultsPerSection),
    ]);

    // نتيجة بحث سباق (المستخدم كتب أسرع من رجوع الاستعلام) — تُهمَل، لا
    // تستبدل نتائج بحث أحدث بأخرى وصلت متأخرة.
    if (!mounted || token != _searchToken) return;

    final azkarCategories = ref.read(azkarLibraryProvider).value ?? const [];
    final normalizedQuery = normalizeArabicSearch(query);
    final azkarHits = <_AzkarSearchHit>[];
    outer:
    for (final category in azkarCategories) {
      for (final item in category.items) {
        if (normalizeArabicSearch(item.text).contains(normalizedQuery)) {
          azkarHits.add(_AzkarSearchHit(category: category, item: item));
          if (azkarHits.length >= _kMaxResultsPerSection) break outer;
        }
      }
    }

    setState(() {
      _matchedTopics = topics;
      _ayahResults = results[0] as List<AyahSearchResult>;
      _hadithResults = results[1] as List<HadithSearchResult>;
      _azkarResults = azkarHits;
      _isSearching = false;
    });
  }

  void _openAyah(AyahSearchResult r) {
    ref.read(mushafJumpRequestProvider.notifier).request(page: r.ayah.page, ayahId: r.ayah.id);
    ref.read(rootTabIndexProvider.notifier).select(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _selectTopic(QuranTopic topic) {
    _controller.text = topic.title.split(' ').first;
    _onQueryChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    // يضمن تحميل مكتبة الأذكار قبل أول بحث فعلي (عادة جاهزة سلفاً —
    // الشاشة الرئيسية تراقبها أصلاً بمكان آخر بالتطبيق).
    ref.watch(azkarLibraryProvider);
    final hasQuery = _query.trim().length >= 2;
    final hasAnyResult = _matchedTopics.isNotEmpty || _ayahResults.isNotEmpty || _hadithResults.isNotEmpty || _azkarResults.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'ابحث بالقرآن، المواضيع، الحديث، الأذكار...',
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _onQueryChanged('');
              },
            ),
        ],
      ),
      body: !hasQuery
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.topic_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'مواضيع قرآنية شائعة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in kQuranTopics)
                      ActionChip(
                        avatar: Text(topic.icon, style: const TextStyle(fontSize: 14)),
                        label: Text(topic.title),
                        onPressed: () => _selectTopic(topic),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                const EmptyState(
                  icon: Icons.search_outlined,
                  message: 'اكتب موضوعاً أو كلمة للبحث بالقرآن والحديث والأذكار',
                  subtitle: 'مثال: بر الوالدين، الصبر، التوبة، قيام الليل...',
                ),
              ],
            )
          : _isSearching
              ? const Center(child: CircularProgressIndicator())
              : !hasAnyResult
                  ? const EmptyState(
                      icon: Icons.search_off_outlined,
                      message: 'لا توجد نتائج مطابقة لبحثك',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        if (_matchedTopics.isNotEmpty)
                          _ResultSection(
                            title: 'مواضيع قرآنية مطابقة',
                            icon: Icons.auto_awesome_outlined,
                            children: [
                              for (final topic in _matchedTopics)
                                ListTile(
                                  leading: Text(topic.icon, style: const TextStyle(fontSize: 22)),
                                  title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  subtitle: Text(topic.description, style: const TextStyle(fontSize: 12)),
                                  trailing: const Icon(Icons.chevron_left, size: 18),
                                  onTap: () => _selectTopic(topic),
                                ),
                            ],
                          ),
                        if (_ayahResults.isNotEmpty)
                          _ResultSection(
                            title: 'القرآن الكريم',
                            icon: Icons.menu_book_outlined,
                            children: [
                              for (final r in _ayahResults) _AyahResultTile(result: r, onTap: () => _openAyah(r)),
                            ],
                          ),
                        if (_hadithResults.isNotEmpty)
                          _ResultSection(
                            title: 'الحديث الشريف',
                            icon: Icons.auto_stories_outlined,
                            children: [
                              for (final r in _hadithResults)
                                _HadithResultTile(
                                  result: r,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => HadithDetailScreen(bookId: r.hadith.bookId, hadithId: r.hadith.id),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        if (_azkarResults.isNotEmpty)
                          _ResultSection(
                            title: 'الأذكار',
                            icon: Icons.brightness_2_outlined,
                            children: [
                              for (final hit in _azkarResults)
                                _AzkarResultTile(
                                  hit: hit,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AzkarLibraryCategoryScreen(category: hit.category),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 2),
            child: Row(
              children: [
                Icon(icon, size: 16, color: onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: onSurface.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شكل نتيجة آية أرقى (بطلب صريح "شكل الآيات عند البحث") — كانت `ListTile`
/// مجرّدة بنص خام غير مُنظَّف (`textUthmani` بلا `stripQuranicMarksForDisplay`،
/// نفس القطع الظاهر بخط AmiriQuran الموثَّق بأماكن أخرى بالمشروع) وبلا شارة
/// موقع واضحة، بخلاف بطاقة نتائج المصحف المخصَّصة (`mushaf_search_screen.
/// dart._AyahResultCard`) — الآن نفس مستوى الجودة: نص منظَّف بارتفاع سطر
/// مريح، وشارة "سورة · آية · صفحة" بدل سطر فرعي عادي.
class _AyahResultTile extends StatelessWidget {
  const _AyahResultTile({required this.result, required this.onTap});
  final AyahSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stripQuranicMarksForDisplay(result.ayah.textUthmani),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 17, height: 1.8, color: onSurface),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.goldDeep.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${result.surahNameAr} · آية ${result.ayah.ayah}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldDeep),
                  ),
                ),
                const Spacer(),
                Text(
                  'صفحة ${result.ayah.page}',
                  style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_left, size: 16, color: onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HadithResultTile extends StatelessWidget {
  const _HadithResultTile({required this.result, required this.onTap});
  final HadithSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        result.hadith.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13.5),
      ),
      subtitle: Text(
        '${result.bookNameAr} · حديث ${result.hadith.hadithNumber}',
        style: TextStyle(fontSize: 11, color: AppColors.tealDeep),
      ),
      trailing: const Icon(Icons.chevron_left, size: 18),
    );
  }
}

class _AzkarResultTile extends StatelessWidget {
  const _AzkarResultTile({required this.hit, required this.onTap});
  final _AzkarSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        hit.item.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13.5),
      ),
      subtitle: Text(hit.category.title, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_left, size: 18),
    );
  }
}
