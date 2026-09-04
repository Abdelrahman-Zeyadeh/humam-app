import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/data/user/user_repository.dart' show UserCategories;
import '../../core/text/arabic_normalizer.dart' show normalizeArabicSearch;
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../onboarding/onboarding_target_keys.dart';
import 'azkar_full_repository.dart';
import 'azkar_library_category_screen.dart';
import 'azkar_repository.dart' show AzkarPeriod;
import 'azkar_screen.dart';
import 'tasbih_screen.dart';

Color _strong(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkOnDark
    : AppColors.navy;
Color _soft(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? AppColors.inkSoftOnDark
    : AppColors.inkSoft;

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

  /// يطابق التطبيع نفسه المستخدَم ببحث القرآن (`normalizeArabicSearch`) —
  /// **يحذف التشكيل**. عناوين أقسام حصن المسلم مكتوبة بتشكيل كامل
  /// (مثلاً "دُعَاءُ السَّفَرِ")، فمطابقة نصية خام كانت تفشل لأي استعلام
  /// بلا تشكيل يطول عن أول حرفين قبل أول علامة تشكيل — بلاغ صاحب المشروع
  /// "لما ابحث عن السفر ما بظهر... لازم بس اكتب الس" **كان بالضبط بهذا
  /// السبب**، مش عطل عشوائي.
  bool _matches(String haystack, String needle) =>
      normalizeArabicSearch(haystack).contains(normalizeArabicSearch(needle));

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(azkarLibraryProvider);
    ref.watch(azkarFavoriteVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);

    return Scaffold(
      body: Column(
        children: [
          // هيدر بتدرّج كحلي مع حقل البحث مدمَجاً بداخله — مطابق لهيدر
          // شاشة الأذكار بلوحة التصميم المعتمدة (`Azkar.dc.html`)، بدل
          // `AppBar` الأبيض + حقل بحث منفصل تحته.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 14,
                16,
                16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.blue, AppColors.navy],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'الأذكار',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        key: azkarTasbihButtonKey,
                        borderRadius: BorderRadius.circular(17),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TasbihScreen(),
                          ),
                        ),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.fingerprint,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن قسم أو بنص الذكر نفسه…',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الأكثر استخداماً',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _soft(context),
                ),
              ),
            ),
          ),
          SizedBox(
            key: azkarQuickCardsKey,
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
                      label: 'أذكار الصباح',
                      icon: Icons.wb_sunny_outlined,
                      // بطلب صاحب المشروع: "هل اتممتها اليوم ام لا" — علامة
                      // صح صغيرة لو أُنجزت أذكار الفترة كاملة اليوم فعلاً
                      // (`bumpCategoryStreakIfNewDay` تُستدعى عند الاكتمال
                      // بـ`azkar_screen.dart`).
                      doneToday: userPrefs.completedTodayFor(
                        UserCategories.morningAzkar,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AzkarScreen(period: AzkarPeriod.morning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _QuickChip(
                      label: 'أذكار المساء',
                      icon: Icons.nights_stay_outlined,
                      doneToday: userPrefs.completedTodayFor(
                        UserCategories.eveningAzkar,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AzkarScreen(period: AzkarPeriod.evening),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (sleep case final sleepCategory?)
                      _QuickChip(
                        label: 'أذكار النوم',
                        icon: Icons.bedtime_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AzkarLibraryCategoryScreen(
                              category: sleepCategory,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    _QuickChip(
                      label: 'المسبحة',
                      icon: Icons.fingerprint,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TasbihScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _QuickChip(
                      label: 'المفضّلة',
                      icon: _favoritesOnly
                          ? Icons.favorite
                          : Icons.favorite_border,
                      selected: _favoritesOnly,
                      onTap: () =>
                          setState(() => _favoritesOnly = !_favoritesOnly),
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
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _soft(context),
                ),
              ),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text('تعذّر تحميل مكتبة الأذكار')),
              data: (categories) {
                // بحث موحَّد بلا فلتر — يطابق عنوان القسم أو نص أي ذكر
                // بداخله معاً (بطلب صريح: "وحد البحث... بدون فلتر").
                var filtered = _query.isEmpty
                    ? categories
                    : categories.where((c) {
                        return _matches(c.title, _query) ||
                            c.items.any((item) => _matches(item.text, _query));
                      }).toList();
                if (_favoritesOnly) {
                  filtered = filtered
                      .where((c) => userPrefs.isAzkarFavorite(c.id))
                      .toList();
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _favoritesOnly
                          ? 'لا أقسام مفضَّلة بعد — اضغط القلب على أي قسم لإضافته'
                          : 'لا نتائج',
                      style: TextStyle(color: _soft(context)),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 95),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final cat = filtered[i];
                    final isFav = userPrefs.isAzkarFavorite(cat.id);
                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AzkarLibraryCategoryScreen(category: cat),
                        ),
                      ),
                      child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav
                                      ? themeAccent(context)
                                      : _soft(context),
                                ),
                                tooltip: isFav
                                    ? 'إزالة من المفضّلة'
                                    : 'إضافة للمفضّلة',
                                onPressed: () async {
                                  await userPrefs.toggleAzkarFavorite(cat.id);
                                  ref
                                      .read(
                                        azkarFavoriteVersionProvider.notifier,
                                      )
                                      .bump();
                                },
                              ),
                              const Icon(Icons.chevron_left),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    cat.title,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      color: _strong(context),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '${cat.items.length}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _soft(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
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
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.doneToday,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  /// `null` = لا مؤشّر (شريحة "المفضّلة" مثلاً لا تخص "اليوم"). راجع طلب
  /// صاحب المشروع: "هل اتممتها اليوم ام لا" لأذكار الصباح/المساء.
  final bool? doneToday;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? themeAccent(context) : AppColors.navy,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.navyDeep : AppColors.goldSoft,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.navyDeep : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (doneToday == true) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle, size: 15, color: AppColors.teal),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
