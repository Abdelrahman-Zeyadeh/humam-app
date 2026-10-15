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
  bool _isListView = true;

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
      final matchesCategory =
          _selectedCategory == 'all' || source.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    // السلسلة المميزة المختارة كـHero Banner عند فتح الشاشة
    final spotlightSource = kDuroosSources.firstWhere(
      (s) => s.id == 'fiqh',
      orElse: () => kDuroosSources.first,
    );

    Widget body = Column(
      children: [
        // 1. بانر السلسلة المختارة / Spotlight Hero
        if (_searchQuery.isEmpty && _selectedCategory == 'all')
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [const Color(0xFF1B2E3C), const Color(0xFF101C28)]
                    : [const Color(0xFF0F3254), const Color(0xFF0B2545)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF0B2545)).withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // صورة العالِم المميز الدائرية الفخمة
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: spotlightSource.imageAsset != null
                        ? Image.asset(
                            spotlightSource.imageAsset!,
                            fit: BoxFit.cover,
                            cacheWidth: 200,
                            errorBuilder: (_, __, ___) => const Icon(Icons.school, color: AppColors.gold, size: 28),
                          )
                        : const Icon(Icons.school, color: AppColors.gold, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'سلسلة علمية مختارة ⭐',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spotlightSource.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spotlightSource.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DuroosLecturesScreen(
                        source: spotlightSource,
                        title: spotlightSource.title,
                      ),
                    ),
                  ),
                  child: const Text(
                    'تصفح',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // 2. شريط البحث المنظّم
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: TextField(
            onChanged: (q) => setState(() => _searchQuery = q),
            decoration: InputDecoration(
              hintText: 'ابحث عن عالِم، متن، شرح كتاب، أو موضوع...',
              hintStyle: TextStyle(fontSize: 12.5, color: onSurface.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // 3. تصفية الفئات السريعة بأيقونات معبرة
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'الكل (${kDuroosSources.length})',
                icon: Icons.all_inclusive_rounded,
                isSelected: _selectedCategory == 'all',
                onTap: () => setState(() => _selectedCategory = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'كبار العلماء (${_countFor(DuroosCategoryIds.scholars)})',
                icon: Icons.school_rounded,
                isSelected: _selectedCategory == DuroosCategoryIds.scholars,
                onTap: () => setState(() => _selectedCategory = DuroosCategoryIds.scholars),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'شروح المتون والفقه (${_countFor(DuroosCategoryIds.mutoon)})',
                icon: Icons.menu_book_rounded,
                isSelected: _selectedCategory == DuroosCategoryIds.mutoon,
                onTap: () => setState(() => _selectedCategory = DuroosCategoryIds.mutoon),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'السيرة والفتاوى (${_countFor(DuroosCategoryIds.seerahGeneral)})',
                icon: Icons.history_edu_rounded,
                isSelected: _selectedCategory == DuroosCategoryIds.seerahGeneral,
                onTap: () => setState(() => _selectedCategory = DuroosCategoryIds.seerahGeneral),
              ),
              if (_countFor(DuroosCategoryIds.recitations) > 0) ...[
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'تلاوات كاملة (${_countFor(DuroosCategoryIds.recitations)})',
                  icon: Icons.record_voice_over_rounded,
                  isSelected: _selectedCategory == DuroosCategoryIds.recitations,
                  onTap: () => setState(() => _selectedCategory = DuroosCategoryIds.recitations),
                ),
              ],
            ],
          ),
        ),

        // 4. سطر التحكم في طريقة العرض وعدد النتائج
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            children: [
              Text(
                'المكتبة الصوتية (${filteredSources.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: onSurface.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              // زر التبديل بين القائمة والشبكة
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _isListView = !_isListView),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isListView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                        size: 14,
                        color: themeAccent(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isListView ? 'عرض القائمة' : 'عرض الشبكة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 5. قائمة / شبكة الدروس
        Expanded(
          child: filteredSources.isEmpty
              ? const EmptyState(
                  icon: Icons.school_outlined,
                  message: 'لا توجد دروس أو علماء مطابقين للبحث',
                )
              : _isListView
                  // نمط القائمة المريحة الواسعة المنظمة (يريح العين ويزيل العجقة)
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: filteredSources.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final source = filteredSources[index];
                        final accent = _kSourceAccents[index % _kSourceAccents.length];

                        return Material(
                          color: isDark ? const Color(0xFF1B2430) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DuroosLecturesScreen(
                                  source: source,
                                  title: source.title,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? Colors.black : accent).withValues(
                                      alpha: isDark ? 0.25 : 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // صورة الشيخ الدائرية الفخمة
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: source.imageAsset != null
                                          ? Image.asset(
                                              source.imageAsset!,
                                              fit: BoxFit.cover,
                                              cacheWidth: 160,
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
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          source.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          source.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: accent.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                source.kind == DuroosSourceKind.rss
                                                    ? 'بودكاست رسمي'
                                                    : source.kind == DuroosSourceKind.midad
                                                        ? 'موقع مِداد'
                                                        : 'إسلام ويب',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: accent,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'تصفح المحاضرات',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: onSurface.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left_rounded,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  // نمط الشبكة المتناسق
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.80,
                      ),
                      itemCount: filteredSources.length,
                      itemBuilder: (context, index) {
                        final source = filteredSources[index];
                        final accent = _kSourceAccents[index % _kSourceAccents.length];

                        return Material(
                          color: isDark ? const Color(0xFF1B2430) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
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
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? Colors.black : accent).withValues(
                                      alpha: isDark ? 0.25 : 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                                      child: source.imageAsset != null
                                          ? Image.asset(
                                              source.imageAsset!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              cacheWidth: 320,
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
                                  Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(9),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            source.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              height: 1.25,
                                              color: onSurface,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: accent.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  source.kind == DuroosSourceKind.rss ? 'بودكاست' : 'دروس',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: accent,
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.play_circle_fill_rounded, size: 20, color: accent),
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
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Theme.of(context).brightness == Brightness.dark ? AppColors.gold : AppColors.tealDeep;

    return ChoiceChip(
      avatar: icon != null
          ? Icon(icon, size: 14, color: isSelected ? Colors.white : accent)
          : null,
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
