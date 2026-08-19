import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_colors.dart';
import 'azkar_full_repository.dart';
import 'azkar_library_category_screen.dart';
import 'azkar_screen.dart';

Color _surface(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white;
Color _border(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.lineDark : AppColors.line;
Color _strong(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.inkOnDark : AppColors.navy;
Color _soft(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? AppColors.inkSoftOnDark : AppColors.inkSoft;

/// الصفحة الأساسية لتبويب "الأذكار": بحث + شريط وصول سريع (الصباح
/// والمساء بالعدّاد المخصَّص `AzkarScreen`، أذكار النوم، المفضّلة) + مكتبة
/// حصن المسلم الكاملة (١٣١ قسماً). المفضّلة حقيقية ومحفوظة فعلياً
/// (`AzkarFavorites` بـ`user.db`)، لا زخرفة. راجع `azkar_full_repository.dart`
/// لمصدر البيانات ورخصتها.
class AzkarLibraryScreen extends ConsumerStatefulWidget {
  const AzkarLibraryScreen({super.key});

  @override
  ConsumerState<AzkarLibraryScreen> createState() => _AzkarLibraryScreenState();
}

class _AzkarLibraryScreenState extends ConsumerState<AzkarLibraryScreen> {
  String _query = '';
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(azkarLibraryProvider);
    ref.watch(azkarFavoriteVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث عن قسم (النوم، السفر، الطعام...)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: _surface(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _border(context))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _border(context))),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('الأكثر استخداماً', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _soft(context))),
            ),
          ),
          SizedBox(
            height: 56,
            child: categoriesAsync.maybeWhen(
              data: (categories) {
                AzkarLibraryCategory? sleep;
                for (final c in categories) {
                  if (c.id == 28) {
                    sleep = c;
                    break;
                  }
                }
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _QuickChip(
                      label: 'الصباح والمساء',
                      icon: Icons.wb_sunny_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AzkarScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (sleep case final sleepCategory?)
                      _QuickChip(
                        label: 'أذكار النوم',
                        icon: Icons.bedtime_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AzkarLibraryCategoryScreen(category: sleepCategory)),
                        ),
                      ),
                    const SizedBox(width: 10),
                    _QuickChip(
                      label: 'المفضّلة',
                      icon: _favoritesOnly ? Icons.favorite : Icons.favorite_border,
                      selected: _favoritesOnly,
                      onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _favoritesOnly ? 'المفضّلة' : 'كل التصنيفات (حصن المسلم)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _soft(context)),
              ),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('تعذّر تحميل مكتبة الأذكار')),
              data: (categories) {
                var filtered = _query.isEmpty ? categories : categories.where((c) => c.title.contains(_query)).toList();
                if (_favoritesOnly) {
                  filtered = filtered.where((c) => userPrefs.isAzkarFavorite(c.id)).toList();
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _favoritesOnly ? 'لا أقسام مفضَّلة بعد — اضغط القلب على أي قسم لإضافته' : 'لا نتائج',
                      style: TextStyle(color: _soft(context)),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final cat = filtered[i];
                    final isFav = userPrefs.isAzkarFavorite(cat.id);
                    return Material(
                      color: _surface(context),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AzkarLibraryCategoryScreen(category: cat)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: _border(context))),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? AppColors.gold : _soft(context)),
                                tooltip: isFav ? 'إزالة من المفضّلة' : 'إضافة للمفضّلة',
                                onPressed: () async {
                                  await userPrefs.toggleAzkarFavorite(cat.id);
                                  ref.read(azkarFavoriteVersionProvider.notifier).bump();
                                },
                              ),
                              const Icon(Icons.chevron_left),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    cat.title,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(color: _strong(context), fontWeight: FontWeight.w600, fontSize: 14.5),
                                  ),
                                ),
                              ),
                              Text('${cat.items.length}', style: TextStyle(fontSize: 11.5, color: _soft(context), fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.icon, required this.onTap, this.selected = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.gold : AppColors.navy,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? AppColors.navyDeep : AppColors.goldSoft, size: 17),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: selected ? AppColors.navyDeep : Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
