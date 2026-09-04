import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/tafsir_edition_catalog.dart';
import '../../core/text/arabic_normalizer.dart' show stripQuranicMarksForDisplay;
import '../../core/theme/app_colors.dart';
import 'ayah_actions_sheet.dart';
import 'mushaf_settings.dart';
import 'tafsir_download_service.dart';

/// نفس عدد صفحات المصحف الفعلي (`kMushafPageCount` بـ`mushaf_screen.dart`)
/// — مكرَّرة محلياً هون بدل استيراد ذاك الملف (يستورد هذا الملف أصلاً
/// لفتح هذه الشاشة، فتفادي استيراد دائري بلا داعٍ لثابت واحد).
const int _kMushafPageCount = 604;

// Provider محلي — تفسير آية بإصدار معيّن، نفس نمط الملفات المشابهة
// (`ayah_text_view_screen.dart`) بدل provider مشترك واحد (كل شاشة تفسير
// بالمشروع تُعرِّف نسختها الخاصة عمداً).
final _tafsirProvider =
    FutureProvider.family<Tafsir?, ({int ayahId, String edition})>((ref, arg) {
  return ref.watch(quranRepositoryProvider).tafsirForAyah(arg.ayahId, edition: arg.edition);
});

/// آيات صفحة مصحف معيّنة (١-٦٠٤، نفس ترقيم المصحف الفعلي) — مموَّه بـ
/// `FutureProvider.family` ليُخزَّن مؤقتاً تلقائياً عبر Riverpod (تصفّح
/// الصفحات جيئة وذهاباً بالسحب لا يُعيد الاستعلام لصفحة زارها المستخدم أصلاً).
final _pageAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, page) {
  return ref.watch(quranRepositoryProvider).ayahsForPage(page);
});

/// سورة معيّنة بمعرّفها — لعرض لافتة رأس السورة عند بداية سورة جديدة
/// وسط صفحة، ولعنوان الشريط العلوي (سورة أول آية بالصفحة الحالية).
final _surahByIdProvider = FutureProvider.family<Surah, int>((ref, id) {
  return ref.watch(quranRepositoryProvider).surahById(id);
});

/// سورة أول آية بصفحة معيّنة — تحديداً لعنوان الشريط العلوي.
final _pageLeadSurahProvider = FutureProvider.family<Surah?, int>((ref, page) async {
  final ayahs = await ref.watch(_pageAyahsProvider(page).future);
  if (ayahs.isEmpty) return null;
  return ref.watch(_surahByIdProvider(ayahs.first.surah).future);
});

/// شاشة "قراءة مع التفسير" — صفحة-بصفحة مطابقة لترقيم المصحف الفعلي
/// (٦٠٤ صفحة)، والتنقّل بينها بالسحب الأفقي (`PageView`) بدل تمرير طولي
/// متواصل عبر السورة كاملة. كل آية بالصفحة وتحتها تفسيرها مباشرة، ولافتة
/// رأس سورة جديدة تظهر تلقائياً كلّما بدأت سورة وسط الصفحة (نفس ما يظهر
/// بصفحة المصحف الحقيقية).
class TafsirReadingScreen extends ConsumerStatefulWidget {
  const TafsirReadingScreen({
    super.key,
    required this.initialPage,
    this.surahId,
  });

  /// رقم صفحة المصحف (١-٦٠٤) للفتح عليها مباشرة.
  final int initialPage;
  final int? surahId;

  @override
  ConsumerState<TafsirReadingScreen> createState() => _TafsirReadingScreenState();
}

class _TafsirReadingScreenState extends ConsumerState<TafsirReadingScreen> {
  late final int _initialPage = widget.initialPage.clamp(1, _kMushafPageCount);
  late final PageController _pageController = PageController(initialPage: _initialPage - 1);
  late int _currentPage = _initialPage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPage = index + 1);

  void _goToPage(int page) {
    final clamped = page.clamp(1, _kMushafPageCount);
    _pageController.animateToPage(
      clamped - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showSurahPicker() {
    final surahsAsync = ref.read(allSurahsProvider);
    surahsAsync.whenData((surahs) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('اختر سورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: surahs.length,
                  itemBuilder: (ctx, i) {
                    final s = surahs[i];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 15,
                        backgroundColor: themeAccent(context).withValues(alpha: 0.15),
                        child: Text(
                          '${s.id}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeAccent(context)),
                        ),
                      ),
                      title: Text(s.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${s.ayahCount} آية • ${s.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'}'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _goToPage(s.startPage);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showEditionPicker() {
    final current = ref.read(readingTafsirEditionProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text('اختر التفسير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              for (final e in kTafsirEditionCatalog.where((e) => e.category == 'tafsir'))
                ListTile(
                  title: Text(e.nameAr, style: const TextStyle(fontWeight: FontWeight.w600)),
                  // تنويه مسبق لإصدار لا يغطي القرآن كاملاً (عثيمين/أضواء
                  // البيان) — قبل الاختيار لا بعده، حتى لا يفاجأ المستخدم
                  // بآية بلا تفسير ويظنّها عطلاً.
                  subtitle: e.coverageNote == null
                      ? null
                      : Text(
                          'تغطية جزئية للقرآن',
                          style: TextStyle(fontSize: 11, color: AppColors.goldDeep.withValues(alpha: 0.9)),
                        ),
                  trailing: current == e.key
                      ? Icon(Icons.check_circle_rounded, color: themeAccent(context))
                      : null,
                  onTap: () {
                    ref.read(readingTafsirEditionProvider.notifier).set(e.key);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editionKey = ref.watch(readingTafsirEditionProvider);
    final editionEntry = tafsirEditionCatalogByKey(editionKey);
    final downloadState = ref.watch(tafsirDownloadControllerProvider);
    final status = downloadState.statusFor(editionKey);
    final fontSize = ref.watch(tafsirFontSizeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leadSurahAsync = ref.watch(_pageLeadSurahProvider(_currentPage));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(leadSurahAsync.value?.nameAr ?? 'قراءة مع التفسير'),
            Text(
              'صفحة $_currentPage',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'تغيير السورة',
            onPressed: _showSurahPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط اختيار إصدار التفسير — صف مستقل بعرض كامل (بدل زر بشريط
          // العنوان) لأن اسم إصدار مثل "المختصر في التفسير" يزاحم عنوان
          // السورة وأيقونة تغييرها بمساحة AppBar الضيّقة.
          InkWell(
            onTap: _showEditionPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                border: Border(
                  bottom: BorderSide(color: (isDark ? AppColors.lineDark : AppColors.line)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 15, color: themeAccent(context)),
                  const SizedBox(width: 6),
                  Text('التفسير: ', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  Expanded(
                    child: Text(
                      editionEntry.nameAr,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
          if (status == TafsirEditionDownloadStatus.notDownloaded)
            _DownloadBanner(edition: editionEntry),
          if (status == TafsirEditionDownloadStatus.downloading)
            LinearProgressIndicator(
              value: downloadState.downloadProgress > 0 ? downloadState.downloadProgress : null,
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              // بلا `reverse: true` صراحة — نفس نمط `mushaf_screen.dart`:
              // Flutter يعكس اتجاه سحب `PageView` تلقائياً حسب `Directionality`
              // المحيطة (RTL بكل التطبيق)، فتعيينها صراحة هون كان سيعكسها
              // مرّتين (اتجاه سحب معكوس فعلياً عن المطلوب).
              itemCount: _kMushafPageCount,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final page = index + 1;
                return _TafsirPageView(
                  page: page,
                  editionKey: editionKey,
                  isEditionReady: status == TafsirEditionDownloadStatus.downloaded,
                  fontSize: fontSize,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// محتوى صفحة واحدة — قائمة رأسية (لو احتاجت الآيات تمريراً داخلياً بصفحة
/// مزدحمة) لكل آيات هذه الصفحة، ولافتة سورة جديدة تلقائياً أينما بدأت
/// سورة (`ayah.ayah == 1`) وسط الصفحة نفسها.
class _TafsirPageView extends ConsumerWidget {
  const _TafsirPageView({
    required this.page,
    required this.editionKey,
    required this.isEditionReady,
    required this.fontSize,
    required this.isDark,
  });

  final int page;
  final String editionKey;
  final bool isEditionReady;
  final double fontSize;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahsAsync = ref.watch(_pageAyahsProvider(page));

    return ayahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('تعذّر تحميل آيات هذه الصفحة')),
      data: (ayahs) {
        if (ayahs.isEmpty) return const SizedBox.shrink();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          itemCount: ayahs.length,
          itemBuilder: (context, i) {
            final ayah = ayahs[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ayah.ayah == 1) _SurahHeaderFor(surahId: ayah.surah),
                _AyahTafsirTile(
                  ayah: ayah,
                  editionKey: editionKey,
                  isEditionReady: isEditionReady,
                  fontSize: fontSize,
                  isDark: isDark,
                  onTap: () => AyahActionsSheet.show(context, ayah.id),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// يجلب سورة بمعرّفها ويعرض [_SurahHeader] لها — يفصل الجلب عن العرض
/// ليُعاد استخدام [_SurahHeader] نفسها لو احتجناها مكاناً آخر بدون شبكة.
class _SurahHeaderFor extends ConsumerWidget {
  const _SurahHeaderFor({required this.surahId});
  final int surahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(_surahByIdProvider(surahId));
    return surahAsync.when(
      data: (s) => _SurahHeader(surah: s),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// رأس السورة — لافتة الاسم/معلوماتها، والبسملة إن كانت السورة تُستهَل
/// بها (`bismillahPre == 1`؛ يستثني الفاتحة حيث البسملة نفسها الآية
/// الأولى، والتوبة بلا بسملة إطلاقاً — القيمة جاهزة بقاعدة البيانات).
class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(
                  surah.nameAr,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${surah.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'} • ${surah.ayahCount} آية',
                  style: TextStyle(fontSize: 11.5, color: onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          if (surah.bismillahPre == 1) ...[
            const SizedBox(height: 16),
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 22, color: onSurface),
            ),
          ],
        ],
      ),
    );
  }
}

/// بطاقة آية واحدة + تفسيرها مباشرة تحتها — عنصر القائمة المتكرّر الأساسي
/// لهذه الشاشة.
class _AyahTafsirTile extends ConsumerWidget {
  const _AyahTafsirTile({
    required this.ayah,
    required this.editionKey,
    required this.isEditionReady,
    required this.fontSize,
    required this.isDark,
    required this.onTap,
  });

  final Ayah ayah;
  final String editionKey;
  final bool isEditionReady;
  final double fontSize;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);
    final tafsirAsync =
        isEditionReady ? ref.watch(_tafsirProvider((ayahId: ayah.id, edition: editionKey))) : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Text(
                '${ayah.ayah}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stripQuranicMarksForDisplay(ayah.textUthmani),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 1.9, color: onSurface),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            const SizedBox(height: 10),
            if (tafsirAsync == null)
              Text(
                'التفسير غير منزَّل بعد — نزّله من زر اسم التفسير أعلى الشاشة',
                style: TextStyle(fontSize: 11.5, color: onSurface.withValues(alpha: 0.55)),
              )
            else
              tafsirAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => Text(
                  'تعذّر تحميل التفسير',
                  style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
                ),
                data: (tafsir) {
                  final text = tafsir?.content.trim() ?? '';
                  if (text.isEmpty) {
                    return Text(
                      'لا يوجد تفسير لهذه الآية بهذا الإصدار',
                      style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
                    );
                  }
                  return Text(
                    text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: fontSize,
                      height: 1.7,
                      color: onSurface.withValues(alpha: 0.85),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// بانر تنزيل التفسير المختار حين لا يكون منزَّلاً بعد — واحد أعلى الشاشة
/// (لا زر منفصل بكل آية) لتجنّب تكراره عشرات المرات بصفحة مزدحمة.
class _DownloadBanner extends ConsumerWidget {
  const _DownloadBanner({required this.edition});
  final TafsirEditionCatalogEntry edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      color: AppColors.gold.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.download_for_offline_outlined, size: 18, color: AppColors.goldDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تفسير ${edition.nameAr} غير منزَّل — نزّله للقراءة بلا إنترنت',
              style: TextStyle(fontSize: 11.5, color: onSurface),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(tafsirDownloadControllerProvider.notifier).downloadEdition(edition.key),
            child: const Text('تنزيل'),
          ),
        ],
      ),
    );
  }
}
