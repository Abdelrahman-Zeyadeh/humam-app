import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/names_of_allah/names_of_allah_data.dart';
import '../../core/data/names_of_allah/names_of_allah_model.dart';
import '../../core/theme/app_colors.dart';
import 'name_detail_sheet.dart';

/// شاشة موسوعة أسماء الله الحسنى والتدبر
class NamesOfAllahScreen extends ConsumerStatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  ConsumerState<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends ConsumerState<NamesOfAllahScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<NameOfAllah> _getFilteredList() {
    List<NameOfAllah> list = NamesOfAllahData.items;

    if (_selectedCategory != 'الكل') {
      list = list.where((n) => n.category == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      list = NamesOfAllahData.search(_searchQuery);
      if (_selectedCategory != 'الكل') {
        list = list.where((n) => n.category == _selectedCategory).toList();
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);
    final todayName = NamesOfAllahData.nameOfTheDay();
    final names = _getFilteredList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('أسماء الله الحسنى والتدبر', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // بطاقة اسم اليوم للتدبر
          _FeaturedNameCard(
            name: todayName,
            onTap: () => NameDetailSheet.show(context, todayName),
          ),
          const SizedBox(height: 18),

          // شريط البحث
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث في أسماء الله الحسنى أو المعاني...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E2836) : const Color(0xFFF7F8FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // تصنيفات وفئات الأسماء
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final cat in NamesOfAllahData.categories) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: accent.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                        color: _selectedCategory == cat ? accent : onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // عدد النتائج
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأسماء الحسنى (${names.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: onSurface.withValues(alpha: 0.75),
                ),
              ),
              const Text(
                '﴿ وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا ﴾',
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 12.5,
                  color: AppColors.goldDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // شبكة بطاقات الأسماء
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemCount: names.length,
            itemBuilder: (context, index) {
              final name = names[index];
              return _NameGridCard(
                name: name,
                onTap: () => NameDetailSheet.show(context, name),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturedNameCard extends StatelessWidget {
  const _FeaturedNameCard({required this.name, required this.onTap});

  final NameOfAllah name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [const Color(0xFF1E2836), const Color(0xFF131D2A)]
                  : [const Color(0xFFFAF4E6), const Color(0xFFF3E7CA)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.5),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.goldDeep),
                        SizedBox(width: 4),
                        Text(
                          'اسم اليوم للتدبر',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.goldDeep),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name.name,
                    style: const TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name.meaning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameGridCard extends StatelessWidget {
  const _NameGridCard({required this.name, required this.onTap});

  final NameOfAllah name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: isDark ? const Color(0xFF1C2533) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${name.id}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Text(
                    name.category,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              Text(
                name.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldDeep,
                ),
              ),
              Text(
                name.meaning,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
