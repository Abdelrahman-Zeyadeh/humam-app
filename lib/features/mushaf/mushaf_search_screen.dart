import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart' show Surah;
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart';
import '../../core/text/arabic_normalizer.dart';
import '../../core/theme/app_colors.dart';

enum _SearchFilter { all, surahs, ayahs }

/// شاشة بحث متطورة ومطوّرة بالمصحف الشريف:
/// - بحث نصي مطبّع للسور والآيات مع تظليل الكلمات المطابقة (Highlighting)
/// - فلاتر سريعة مع عدّادات دقيقة (الكل / السور / الآيات)
/// - عرض الآيات بخط المصحف العثماني (AmiriQuran) وبطاقات عصرية
class MushafSearchScreen extends ConsumerStatefulWidget {
  const MushafSearchScreen({super.key});

  @override
  ConsumerState<MushafSearchScreen> createState() => _MushafSearchScreenState();
}

class _MushafSearchScreenState extends ConsumerState<MushafSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<Surah>? _surahResults;
  List<AyahSearchResult>? _ayahResults;
  bool _loading = false;
  String _currentQuery = '';
  _SearchFilter _filter = _SearchFilter.all;

  static const _kSuggestions = ['الفاتحة', 'الكهف', 'يس', 'الملك', 'الرحمن', 'آية الكرسي'];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    _currentQuery = trimmed;
    if (trimmed.isEmpty) {
      setState(() {
        _surahResults = null;
        _ayahResults = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(quranRepositoryProvider);

    final normalizedQuery = normalizeArabicSearch(trimmed);
    final allSurahs = await repo.allSurahs();
    final surahMatches = allSurahs
        .where((s) => normalizeArabicSearch(s.nameArPlain).contains(normalizedQuery))
        .toList();

    final ayahMatches = await repo.search(trimmed);

    if (!mounted) return;
    setState(() {
      _surahResults = surahMatches;
      _ayahResults = ayahMatches;
      _loading = false;
    });
  }

  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: suggestion.length));
    _search(suggestion);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'ابحث باسم سورة أو كلمة في القرآن…',
              hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 13.5),
              prefixIcon: Icon(Icons.search, size: 20, color: onSurface.withValues(alpha: 0.6)),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      color: onSurface.withValues(alpha: 0.6),
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
            ),
            onChanged: _onQueryChanged,
            onSubmitted: _search,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final surahs = _surahResults;
          final ayahs = _ayahResults;

          if (surahs == null || ayahs == null) {
            return _SearchEmptyLanding(
              suggestions: _kSuggestions,
              onSelectSuggestion: _applySuggestion,
            );
          }

          final totalSurahs = surahs.length;
          final totalAyahs = ayahs.length;
          final totalAll = totalSurahs + totalAyahs;

          if (totalAll == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_outlined, size: 48, color: onSurface.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد نتائج مطابقة لـ "$_currentQuery"',
                      style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'تأكد من كتابة الكلمة بشكل صحيح، أو ابحث بجذر الكلمة',
                      style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // شريط الفلاتر السريعة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line)),
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل ($totalAll)',
                      selected: _filter == _SearchFilter.all,
                      onTap: () => setState(() => _filter = _SearchFilter.all),
                    ),
                    const SizedBox(width: 8),
                    if (totalSurahs > 0) ...[
                      _FilterChip(
                        label: 'السور ($totalSurahs)',
                        selected: _filter == _SearchFilter.surahs,
                        onTap: () => setState(() => _filter = _SearchFilter.surahs),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (totalAyahs > 0)
                      _FilterChip(
                        label: 'الآيات ($totalAyahs)',
                        selected: _filter == _SearchFilter.ayahs,
                        onTap: () => setState(() => _filter = _SearchFilter.ayahs),
                      ),
                  ],
                ),
              ),

              // قائمة النتائج
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if ((_filter == _SearchFilter.all || _filter == _SearchFilter.surahs) && surahs.isNotEmpty) ...[
                      _SectionHeader(label: 'السور المطابقة ($totalSurahs)'),
                      for (final s in surahs) ...[
                        _SurahResultCard(
                          surah: s,
                          query: _currentQuery,
                          accent: accent,
                          onTap: () => Navigator.of(context).pop(s.startPage),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                    ],
                    if ((_filter == _SearchFilter.all || _filter == _SearchFilter.ayahs) && ayahs.isNotEmpty) ...[
                      _SectionHeader(label: 'الآيات الكريمة ($totalAyahs)'),
                      for (final r in ayahs) ...[
                        _AyahResultCard(
                          result: r,
                          query: _currentQuery,
                          accent: accent,
                          onTap: () => Navigator.of(context).pop(r.ayah.page),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : (isDark ? AppColors.surfaceDark : AppColors.paper),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : (isDark ? AppColors.lineDark : AppColors.line),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _SurahResultCard extends StatelessWidget {
  const _SurahResultCard({
    required this.surah,
    required this.query,
    required this.accent,
    required this.onTap,
  });

  final Surah surah;
  final String query;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${surah.id}',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameAr,
                      style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'} · ${surah.ayahCount} آية',
                      style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'صفحة ${surah.startPage}',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AyahResultCard extends StatelessWidget {
  const _AyahResultCard({
    required this.result,
    required this.query,
    required this.accent,
    required this.onTap,
  });

  final AyahSearchResult result;
  final String query;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      result.surahNameAr,
                      style: TextStyle(color: accent, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الآية ${result.ayah.ayah}',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 11.5),
                  ),
                  const Spacer(),
                  Text(
                    'صفحة ${result.ayah.page}',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 11.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _HighlightedQuranText(
                rawText: stripQuranicMarksForDisplay(result.ayah.textUthmani),
                query: query,
                textColor: onSurface,
                highlightColor: accent,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedQuranText extends StatelessWidget {
  const _HighlightedQuranText({
    required this.rawText,
    required this.query,
    required this.textColor,
    required this.highlightColor,
    required this.isDark,
  });

  final String rawText;
  final String query;
  final Color textColor;
  final Color highlightColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final normQuery = normalizeArabicSearch(query.trim());
    if (normQuery.isEmpty) {
      return Text(
        rawText,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: textColor,
          fontFamily: 'AmiriQuran',
          fontSize: 18,
          height: 1.9,
        ),
      );
    }

    final words = rawText.split(' ');
    final spans = <InlineSpan>[];

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final normWord = normalizeArabicSearch(word);
      final isMatch = normWord.contains(normQuery);

      if (isMatch) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: highlightColor.withValues(alpha: isDark ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: highlightColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                word,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: highlightColor,
                  fontFamily: 'AmiriQuran',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$word ',
            style: TextStyle(
              color: textColor,
              fontFamily: 'AmiriQuran',
              fontSize: 18,
              height: 1.9,
            ),
          ),
        );
      }
      if (isMatch && i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
    );
  }
}

class _SearchEmptyLanding extends StatelessWidget {
  const _SearchEmptyLanding({
    required this.suggestions,
    required this.onSelectSuggestion,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelectSuggestion;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: onSurface.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ابحث في آيات وسور القرآن الكريم',
          style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'يمكنك البحث باسم السورة (مثل: الكهف) أو بأي كلمة أو عبارة من الآيات',
          style: TextStyle(color: onSurface.withValues(alpha: 0.55), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Text(
          'عمليات بحث شائعة',
          style: TextStyle(color: onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in suggestions)
              ActionChip(
                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.paper,
                label: Text(s, style: TextStyle(color: onSurface, fontSize: 12.5)),
                onPressed: () => onSelectSuggestion(s),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
