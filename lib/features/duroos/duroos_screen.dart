import 'package:flutter/material.dart';

import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import 'duroos_lectures_screen.dart';
import 'duroos_models.dart';

export 'duroos_models.dart' show DuroosSource, kDuroosSources, DuroosCategoryIds;

/// ألوان شارات فئات الدروس
const List<Color> _kSourceAccents = [
  AppColors.goldDeep,
  AppColors.tealDeep,
  AppColors.blue,
  AppColors.purple,
  Color(0xFFE67E22),
  Color(0xFF2E7D32),
  AppColors.navy,
  Color(0xFF8D6E63),
];

/// رأس البطاقة الاحتياطي في حال عدم توفر صورة
class _SourceIconHeader extends StatelessWidget {
  const _SourceIconHeader({
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  final IconData icon;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.35 : 0.2),
            accent.withValues(alpha: isDark ? 0.15 : 0.06),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 44, color: accent),
    );
  }
}

/// شاشة الدروس والمحاضرات العلمية المستقلة
class DuroosScreen extends StatefulWidget {
  const DuroosScreen({super.key, this.isStandalone = true});

  /// إذا كانت الشاشة تُعرض كصفحة رئيسية بمفردها (مع AppBar) أو داخل تبويب
  final bool isStandalone;

  @override
  State<DuroosScreen> createState() => _DuroosScreenState();
}

class _DuroosScreenState extends State<DuroosScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';

  int _countFor(String category) =>
      kDuroosSources.where((s) => s.category == category).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final filteredSources = kDuroosSources.where((source) {
      final matchesQuery = _searchQuery.isEmpty ||
          source.title.contains(_searchQuery.trim()) ||
          source.subtitle.contains(_searchQuery.trim());
      // فلترة **حقيقية** بحقل `category` الصريح بدل قوائم معرّفات ثابتة
      // يدوية (كانت تنسى مصادر جديدة بصمت — راجع توثيق `DuroosSource.
      // category`).
      final matchesCategory =
          _selectedCategory == 'all' || source.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    Widget body = Column(
      children: [
        // بانر ترحيبي فخم للمكتبة العلمية
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [AppColors.navy.withValues(alpha: 0.06), AppColors.blue.withValues(alpha: 0.12)],
            ),
            border: Border.all(
              color: isDark ? AppColors.lineDark : AppColors.gold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldDeep.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.goldDeep, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مكتبة الدروس والمحاضرات الشرعية',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'سلاسل علمية وشروح متون لكبار العلماء والدعاة مع تشغيل مباشر وبودكاست',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // شريط البحث
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            onChanged: (q) => setState(() => _searchQuery = q),
            decoration: InputDecoration(
              hintText: 'ابحث عن عالِم، شرح كتاب، متن، أو مادة علمية...',
              hintStyle: TextStyle(fontSize: 12.5, color: onSurface.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // تصفية الفئات السريعة
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'الكل (${kDuroosSources.length})',
                isSelected: _selectedCategory == 'all',
                onTap: () => setState(() => _selectedCategory = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label:
                    'كبار العلماء والأئمة (${_countFor(DuroosCategoryIds.scholars)})',
                isSelected: _selectedCategory == DuroosCategoryIds.scholars,
                onTap: () => setState(() => _selectedCategory = DuroosCategoryIds.scholars),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'شروح المتون والفقه (${_countFor(DuroosCategoryIds.mutoon)})',
                isSelected: _selectedCategory == DuroosCategoryIds.mutoon,
                onTap: () => setState(() => _selectedCategory = DuroosCategoryIds.mutoon),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label:
                    'السيرة والفتاوى العامة (${_countFor(DuroosCategoryIds.seerahGeneral)})',
                isSelected: _selectedCategory == DuroosCategoryIds.seerahGeneral,
                onTap: () => setState(() => _selectedCategory = DuroosCategoryIds.seerahGeneral),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'تلاوات قرآن كاملة (${_countFor(DuroosCategoryIds.recitations)})',
                isSelected: _selectedCategory == DuroosCategoryIds.recitations,
                onTap: () => setState(() => _selectedCategory = DuroosCategoryIds.recitations),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // شبكة كروت المشايخ والدروس
        Expanded(
          child: filteredSources.isEmpty
              ? const EmptyState(
                  icon: Icons.school_outlined,
                  message: 'لا توجد دروس أو علماء مطابقين للبحث',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: filteredSources.length,
                  itemBuilder: (context, index) {
                    final source = filteredSources[index];
                    final accent = _kSourceAccents[index % _kSourceAccents.length];

                    return Material(
                      color: isDark ? const Color(0xFF1B2430) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DuroosLecturesScreen(
                              source: source,
                              title: source.title,
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.lineDark
                                  : accent.withValues(alpha: 0.2),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.35)
                                    : accent.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // رأس الكرت (صورة الشيخ أو الأيقونة الفخمة)
                              Expanded(
                                flex: 6,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(19),
                                        ),
                                        child: source.imageAsset != null
                                            ? Image.asset(
                                                source.imageAsset!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                cacheWidth: 480,
                                                errorBuilder: (_, __, ___) => _SourceIconHeader(
                                                  icon: source.icon,
                                                  accent: accent,
                                                  isDark: isDark,
                                                ),
                                              )
                                            : _SourceIconHeader(
                                                icon: source.icon,
                                                accent: accent,
                                                isDark: isDark,
                                              ),
                                      ),
                                    ),
                                    // شارة نوع المصدر (أرشيف ويب أو بودكاست)
                                    PositionedDirectional(
                                      top: 8,
                                      start: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              source.kind == DuroosSourceKind.rss
                                                  ? Icons.podcasts_rounded
                                                  : Icons.library_music_rounded,
                                              size: 11,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              source.kind == DuroosSourceKind.rss ? 'بودكاست' : 'سلاسل صوتية',
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // معلومات السلسلة والعالِم
                              Expanded(
                                flex: 5,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            source.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12.5,
                                              height: 1.25,
                                              color: onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            source.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: accent.withValues(alpha: 0.15),
                                            ),
                                            child: Icon(
                                              Icons.play_arrow_rounded,
                                              size: 14,
                                              color: accent,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'تصفح المحاضرات',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (!widget.isStandalone) {
      return body;
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: 'الدروس والمحاضرات العلمية',
        colors: const [AppColors.tealDeep, AppColors.navy],
      ),
      body: body,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Theme.of(context).brightness == Brightness.dark ? AppColors.gold : AppColors.tealDeep;

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      selected: isSelected,
      selectedColor: accent,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      side: BorderSide(
        color: isSelected ? accent : theme.colorScheme.onSurface.withValues(alpha: 0.15),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
