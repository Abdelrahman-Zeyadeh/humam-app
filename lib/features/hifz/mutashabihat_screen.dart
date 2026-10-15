import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart';
import '../../core/text/arabic_normalizer.dart' show stripQuranicMarksForDisplay;
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../mushaf/mushaf_settings.dart' show mushafJumpRequestProvider;
import '../shell/root_shell.dart' show rootTabIndexProvider;

/// شاشة متشابهات القرآن الكريم — أداة لمساعدة الحفّاظ على ضبط وتثبيت المتشابهات اللفظية
/// تتيح تصفح السور التي تحتوي على آيات متشابهة، عرض تفاصيل التشابه، والقفز المباشر للمصحف.
class MutashabihatScreen extends ConsumerStatefulWidget {
  final int? initialSurahId;

  const MutashabihatScreen({super.key, this.initialSurahId});

  @override
  ConsumerState<MutashabihatScreen> createState() => _MutashabihatScreenState();
}

class _MutashabihatScreenState extends ConsumerState<MutashabihatScreen> {
  int _selectedSurahId = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';
  // بحث بكل القرآن بلا تحديد سورة — بطلب صريح: البحث كان يقتصر دائماً على
  // متشابهات السورة المحدَّدة فقط. `false` افتراضياً (يحافظ على السلوك
  // القديم المألوف: تصفّح سورة واحدة)، والمستخدم يبدّل صراحة لو بده يبحث
  // بكل القرآن بعبارة معيّنة بلا معرفة سورتها مسبقاً.
  bool _searchAllQuran = false;

  @override
  void initState() {
    super.initState();
    _selectedSurahId = widget.initialSurahId ?? 1;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// شيت اختيار السورة القابل للبحث بالاسم — نفس نمط `_showReciterPicker`
  /// بـ`quran_audio_bar.dart`.
  void _showSurahPicker(BuildContext context, List<Surah> surahs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        var query = '';
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.8,
            child: StatefulBuilder(
              builder: (sheetContext, setSheetState) {
                final filtered = query.trim().isEmpty
                    ? surahs
                    : surahs.where((s) => s.nameAr.contains(query.trim())).toList();
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'اختر السورة',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: onSurface),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: TextField(
                        onChanged: (v) => setSheetState(() => query = v),
                        decoration: InputDecoration(
                          hintText: 'ابحث باسم السورة...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'لا توجد سورة بهذا الاسم',
                                style: TextStyle(color: onSurface.withValues(alpha: 0.5)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final s = filtered[i];
                                final selected = s.id == _selectedSurahId;
                                return ListTile(
                                  selected: selected,
                                  selectedTileColor: AppColors.teal.withValues(alpha: 0.1),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                                    child: Text(
                                      '${s.id}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.teal),
                                    ),
                                  ),
                                  title: Text(s.nameAr, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.teal) : null,
                                  onTap: () {
                                    setState(() => _selectedSurahId = s.id);
                                    Navigator.of(sheetContext).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _goToAyah(Ayah ayah) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref.read(mushafJumpRequestProvider.notifier).request(
          page: ayah.page,
          ayahId: ayah.id,
        );
    ref.read(rootTabIndexProvider.notifier).select(1); // تبويب المصحف
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(allSurahsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const GradientAppBar(
          title: 'متشابهات القرآن الكريم',
          centerTitle: true,
          colors: [AppColors.blue, AppColors.navy],
        ),
        body: Column(
          children: [
            // شريط اختيار السورة
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              child: Column(
                children: [
                  // اختيار السورة **قابل للبحث بالاسم** بدل تمرير قائمة
                  // منسدلة بـ١١٤ سورة يدوياً — بطلب صريح "ضيف بحث باسم
                  // السورة"، بنفس نمط شيت اختيار القارئ (`quran_audio_bar.
                  // dart`). يُعطَّل بصرياً بوضع "بحث بكل القرآن" (لا معنى
                  // لتحديد سورة بينما البحث أصلاً يتجاوز كل السور).
                  surahsAsync.when(
                    data: (surahs) {
                      Surah? selected;
                      for (final s in surahs) {
                        if (s.id == _selectedSurahId) {
                          selected = s;
                          break;
                        }
                      }
                      return Opacity(
                        opacity: _searchAllQuran ? 0.5 : 1,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _searchAllQuran ? null : () => _showSurahPicker(context, surahs),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.lineDark : AppColors.line,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_stories_outlined, color: AppColors.teal, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selected != null ? '${selected.id}. ${selected.nameAr}' : 'اختر سورة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: onSurface,
                                    ),
                                  ),
                                ),
                                Icon(Icons.search, size: 18, color: onSurface.withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 10),
                  // حقل فلترة سريع
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.navyDeep : const Color(0xFFF4EFE6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchFilter = val.trim()),
                      decoration: InputDecoration(
                        hintText: _searchAllQuran
                            ? 'ابحث عن المتشابهة بكل القرآن...'
                            : 'ابحث في كلمات المتشابهات...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchFilter.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchFilter = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // تبديل نطاق البحث — بطلب صريح "بحث بالمتشابهة اللي بدك
                  // اياها بدون ما تحدد السورة... حالياً البحث مقتصر على
                  // السورة المحدَّدة فقط". `false` افتراضياً كي لا يتغيّر
                  // السلوك المألوف (تصفّح سورة واحدة) بلا اختيار صريح.
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilterChip(
                      label: const Text('بحث بكل القرآن', style: TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.travel_explore_rounded, size: 16),
                      selected: _searchAllQuran,
                      visualDensity: VisualDensity.compact,
                      onSelected: (v) => setState(() => _searchAllQuran = v),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // قائمة المتشابهات: إما بكل القرآن (بحث نصّي) أو ضمن سورة واحدة
            Expanded(
              child: _searchAllQuran
                  ? _AllQuranMutashabihatList(
                      filterQuery: _searchFilter,
                      onGoToAyah: _goToAyah,
                    )
                  : _SurahMutashabihatList(
                      surahId: _selectedSurahId,
                      filterQuery: _searchFilter,
                      onGoToAyah: _goToAyah,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahMutashabihatList extends ConsumerWidget {
  final int surahId;
  final String filterQuery;
  final void Function(Ayah ayah) onGoToAyah;

  const _SurahMutashabihatList({
    required this.surahId,
    required this.filterQuery,
    required this.onGoToAyah,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(quranRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return FutureBuilder<List<Ayah>>(
      future: repo.ayahsForSurah(surahId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد بيانات لهذه السورة'));
        }

        final surahAyahs = snapshot.data!;

        return FutureBuilder<List<_AyahWithSimilar>>(
          future: _fetchMutashabihatForAyahs(repo, surahAyahs),
          builder: (context, simSnapshot) {
            if (simSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var items = simSnapshot.data ?? [];

            if (filterQuery.isNotEmpty) {
              items = items.where((it) {
                if (it.origin.textUthmani.contains(filterQuery)) return true;
                return it.similarList.any((s) => s.ayah.textUthmani.contains(filterQuery));
              }).toList();
            }

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 48, color: AppColors.teal.withValues(alpha: 0.6)),
                      const SizedBox(height: 12),
                      Text(
                        filterQuery.isNotEmpty
                            ? 'لا توجد نتائج تطابق بحثك'
                            : 'لا توجد مواضع تشابه مسجلة في هذه السورة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return _MutashabihCard(
                  item: item,
                  isDark: isDark,
                  onGoToAyah: onGoToAyah,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<_AyahWithSimilar>> _fetchMutashabihatForAyahs(
    QuranRepository repo,
    List<Ayah> ayahs,
  ) async {
    final list = <_AyahWithSimilar>[];
    for (final a in ayahs) {
      final similar = await repo.similarAyahsFor(a.id);
      if (similar.isNotEmpty) {
        list.add(_AyahWithSimilar(origin: a, similarList: similar));
      }
    }
    return list;
  }
}

/// نتائج البحث بكل القرآن (بلا تحديد سورة) — راجع
/// `QuranRepository.searchMutashabihatOrigins`. بخلاف [_SurahMutashabihatList]
/// (يعرض كل متشابهات سورة واحدة حتى بلا بحث)، هذه لا تُظهر شيئاً قبل كتابة
/// عبارة بحث فعلية (لا معنى لعرض كل متشابهات القرآن الـ٦٢٣٦ آية دفعة واحدة).
class _AllQuranMutashabihatList extends ConsumerWidget {
  final String filterQuery;
  final void Function(Ayah ayah) onGoToAyah;

  const _AllQuranMutashabihatList({required this.filterQuery, required this.onGoToAyah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(quranRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (filterQuery.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.travel_explore_rounded, size: 48, color: AppColors.teal.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(
                'اكتب كلمة أو مقطع الآية اللي بتدور عليها — رح نبحث بمتشابهات القرآن كله',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<Ayah>>(
      future: repo.searchMutashabihatOrigins(filterQuery.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final origins = snapshot.data ?? [];
        if (origins.isEmpty) {
          return Center(
            child: Text(
              'لا توجد نتائج تطابق بحثك',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.7)),
            ),
          );
        }

        return FutureBuilder<List<_AyahWithSimilar>>(
          future: Future.wait(origins.map((a) async {
            final similar = await repo.similarAyahsFor(a.id);
            return _AyahWithSimilar(origin: a, similarList: similar);
          })),
          builder: (context, itemsSnap) {
            if (itemsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = itemsSnap.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              itemBuilder: (context, i) => _MutashabihCard(
                item: items[i],
                isDark: isDark,
                onGoToAyah: onGoToAyah,
              ),
            );
          },
        );
      },
    );
  }
}

class _AyahWithSimilar {
  final Ayah origin;
  final List<SimilarAyahResult> similarList;

  _AyahWithSimilar({required this.origin, required this.similarList});
}

class _MutashabihCard extends StatelessWidget {
  final _AyahWithSimilar item;
  final bool isDark;
  final void Function(Ayah ayah) onGoToAyah;

  const _MutashabihCard({
    required this.item,
    required this.isDark,
    required this.onGoToAyah,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.lineDark : AppColors.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس الآية الأصلية
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الآية ${item.origin.ayah}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => onGoToAyah(item.origin),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'في المصحف (ص ${item.origin.page})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: AppColors.teal),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // نص الآية الأصلية — **باج حقيقي مُصلَح هون**: كان بخط 'Amiri' غير
            // المُعرَّف إطلاقاً بالتطبيق (`pubspec.yaml` يعرّف 'AmiriQuran' فقط)،
            // فيرتدّ لخط النظام الافتراضي العاجز عن رسم رموز يونيكود القرآنية
            // الخاصة (علامات الوقف، الألف الصغيرة، رموز السجدة...) بشكل صحيح —
            // هذا سبب "القطع" الظاهر بنص الآيات. 'AmiriQuran' + تنظيف النص
            // (`stripQuranicMarksForDisplay`) هو نفس المعيار المستخدم بكل
            // شاشات عرض نص الآية الأخرى (راجع `hifz_review_screen.dart` مثلاً).
            Text(
              stripQuranicMarksForDisplay(item.origin.textUthmani),
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 18,
                height: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            // خط فاصل مع شارة المواضع المتشابهة
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.goldDeep,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'المواضع المتشابهة معها (${item.similarList.length}):',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // بطاقات الآيات المتشابهة
            ...item.similarList.map((sim) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162232) : const Color(0xFFF9F7F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.lineDark : AppColors.line.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${sim.surahNameAr} • آية ${sim.ayah.ayah}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => onGoToAyah(sim.ayah),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  'ص ${sim.ayah.page}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 9, color: onSurface.withValues(alpha: 0.7)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stripQuranicMarksForDisplay(sim.ayah.textUthmani),
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 17,
                        height: 1.9,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
