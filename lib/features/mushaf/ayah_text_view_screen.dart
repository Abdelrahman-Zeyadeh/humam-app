import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/tafsir_edition_catalog.dart';
import '../../core/text/arabic_normalizer.dart' show stripQuranicMarksForDisplay;
import '../../core/theme/app_colors.dart';
import 'mushaf_settings.dart' show readingTafsirEditionProvider;
import 'tafsir_download_service.dart';

enum AyahTextViewKind { tafsir, translation }

const int kQuranAyahCount = 6236;

enum MainTafsirTab { tafasir, lughawiyyat, uloom, tadabbur }

final _ayahRefProvider = FutureProvider.family<Ayah, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahById(ayahId);
});

final _tafsirProvider =
    FutureProvider.family<Tafsir?, ({int ayahId, String edition})>((ref, arg) {
      return ref
          .watch(quranRepositoryProvider)
          .tafsirForAyah(arg.ayahId, edition: arg.edition);
    });

/// ترجمة صحيح إنترناشونال الإنجليزية لآية واحدة — **باج حقيقي مُصلَح هون**:
/// `AyahTextViewKind.translation` كان مُعرَّفاً ومُمرَّراً فعلياً من "Golden
/// Quran English" بـ`ayah_actions_sheet.dart`، لكن `build()` هون ما كان
/// يستخدم `widget.kind` إطلاقاً بأي مكان — فالضغط على "Golden Quran
/// English" كان يفتح شاشة التفاسير العربية العادية بلا أي ترجمة إنجليزية
/// ظاهرة كلياً، رغم وجود جدول `translations`/`translationForAyah` جاهزَين.
final _translationProvider = FutureProvider.family<Translation?, int>((
  ref,
  ayahId,
) {
  return ref.watch(quranRepositoryProvider).translationForAyah(ayahId);
});

class AyahTextViewScreen extends ConsumerStatefulWidget {
  const AyahTextViewScreen({
    super.key,
    required this.ayahId,
    required this.kind,
    this.initialTab = MainTafsirTab.tafasir,
  });

  final int ayahId;
  final AyahTextViewKind kind;
  final MainTafsirTab initialTab;

  @override
  ConsumerState<AyahTextViewScreen> createState() => _AyahTextViewScreenState();
}

class _AyahTextViewScreenState extends ConsumerState<AyahTextViewScreen> {
  late int _ayahId = widget.ayahId;
  late MainTafsirTab _activeTab = widget.initialTab;
  String _tafsirLengthFilter = 'mukhtasarat'; // 'mukhtasarat' | 'mutawassitat' | 'tiwal'
  // يبدأ مفتوحاً على "تفسير المستخدم الرئيسي" المحفوظ (نفس تفضيل شاشة
  // "قراءة مع التفسير" — `readingTafsirEditionProvider`) بدل قيمة ثابتة،
  // فيكون هناك تفسير واحد افتراضي متّسق بكل الشاشة، والبقية مطويّة تحته.
  late final Set<String> _expandedEditions = {
    ref.read(readingTafsirEditionProvider),
  };

  void _goTo(int ayahId) {
    if (ayahId < 1 || ayahId > kQuranAyahCount) return;
    setState(() => _ayahId = ayahId);
  }

  void _toggleExpand(String key) {
    setState(() {
      if (_expandedEditions.contains(key)) {
        _expandedEditions.remove(key);
      } else {
        _expandedEditions.add(key);
        // فتح تفسير من تبويب "التفاسير" يجعله التفسير الرئيسي المحفوظ
        // للمرّة القادمة (بهذه الشاشة وبشاشة "قراءة مع التفسير" معاً).
        if (_activeTab == MainTafsirTab.tafasir) {
          ref.read(readingTafsirEditionProvider.notifier).set(key);
        }
      }
    });
  }

  List<TafsirEditionCatalogEntry> _getEditionsForTab() {
    switch (_activeTab) {
      case MainTafsirTab.tafasir:
        if (_tafsirLengthFilter == 'mukhtasarat') {
          return [
            tafsirEditionCatalogByKey('mukhtasar'),
            tafsirEditionCatalogByKey('jalalayn'),
            tafsirEditionCatalogByKey('muyassar'),
          ];
        } else if (_tafsirLengthFilter == 'mutawassitat') {
          return [
            tafsirEditionCatalogByKey('saadi'),
            tafsirEditionCatalogByKey('adwaa'),
            tafsirEditionCatalogByKey('baghawi'),
          ];
        } else {
          // تفسير ابن عثيمين هون لا بالمختصرات — تحقّق فعلي من متوسط طول
          // شرحه لكل آية (٣٨٩٤ كلمة) أثبت أنه أطول تفسير بالكتالوج كله،
          // راجع تعليق `tafsir_edition_catalog.dart` للتفصيل الكامل.
          return [
            tafsirEditionCatalogByKey('ibnkathir'),
            tafsirEditionCatalogByKey('tabari'),
            tafsirEditionCatalogByKey('qurtubi'),
            tafsirEditionCatalogByKey('uthaymeen'),
          ];
        }
      case MainTafsirTab.lughawiyyat:
        return [
          tafsirEditionCatalogByKey('words_meanings'),
          tafsirEditionCatalogByKey('irab_jadwal'),
          tafsirEditionCatalogByKey('irab_darwish'),
          tafsirEditionCatalogByKey('irab_muyassar'),
        ];
      case MainTafsirTab.uloom:
        return [
          tafsirEditionCatalogByKey('muyassar'),
          tafsirEditionCatalogByKey('adwaa'),
        ];
      case MainTafsirTab.tadabbur:
        return [
          tafsirEditionCatalogByKey('saadi'),
          tafsirEditionCatalogByKey('mukhtasar'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kind == AyahTextViewKind.translation) {
      return _TranslationView(ayahId: _ayahId, onGoTo: _goTo);
    }

    final ayahAsync = ref.watch(_ayahRefProvider(_ayahId));
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final editions = _getEditionsForTab();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التفسير والعلوم القرآنية', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ayahAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذّر تحميل الآية: $e')),
        data: (ayah) {
          final isFirst = _ayahId <= 1;
          final isLast = _ayahId >= kQuranAyahCount;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // نص الآية الشريفة (نقي وبلا تلوين تجويد بالتفسير)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'السورة ${ayah.surah} · الآية ${ayah.ayah}',
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stripQuranicMarksForDisplay(ayah.textUthmani),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 22,
                              height: 1.85,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // التبويبات الرئيسية: تفاسير | لغويات | علوم | تدبرات
                    Row(
                      children: [
                        _MainTabButton(
                          label: 'تفاسير',
                          isActive: _activeTab == MainTafsirTab.tafasir,
                          onTap: () => setState(() => _activeTab = MainTafsirTab.tafasir),
                        ),
                        _MainTabButton(
                          label: 'لغويات',
                          isActive: _activeTab == MainTafsirTab.lughawiyyat,
                          onTap: () => setState(() => _activeTab = MainTafsirTab.lughawiyyat),
                        ),
                        _MainTabButton(
                          label: 'علوم',
                          isActive: _activeTab == MainTafsirTab.uloom,
                          onTap: () => setState(() => _activeTab = MainTafsirTab.uloom),
                        ),
                        _MainTabButton(
                          label: 'تدبرات',
                          isActive: _activeTab == MainTafsirTab.tadabbur,
                          onTap: () => setState(() => _activeTab = MainTafsirTab.tadabbur),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // الفلاتر الفرعية للتفاسير (مختصرات / متوسطات / مطولات)
                    if (_activeTab == MainTafsirTab.tafasir) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _FilterPill(
                              label: 'المختصرات',
                              isSelected: _tafsirLengthFilter == 'mukhtasarat',
                              onTap: () => setState(() => _tafsirLengthFilter = 'mukhtasarat'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterPill(
                              label: 'المتوسطات',
                              isSelected: _tafsirLengthFilter == 'mutawassitat',
                              onTap: () => setState(() => _tafsirLengthFilter = 'mutawassitat'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterPill(
                              label: 'المطولات',
                              isSelected: _tafsirLengthFilter == 'tiwal',
                              onTap: () => setState(() => _tafsirLengthFilter = 'tiwal'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // قوائم منسدلة Accordion لكل كتاب تفسير / لغويات
                    for (final ed in editions) ...[
                      _AccordionTafsirTile(
                        edition: ed,
                        ayahId: _ayahId,
                        isExpanded: _expandedEditions.contains(ed.key),
                        onToggle: () => _toggleExpand(ed.key),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),

              // شريط التنقل بين الآيات السابق والتالي
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B232E) : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line)),
                ),
                child: SafeArea(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.arrow_back_ios, size: 14),
                          label: const Text('الآية السابقة'),
                          onPressed: isFirst ? null : () => _goTo(_ayahId - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'آية ${ayah.ayah} / سورة ${ayah.surah}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: onSurface.withValues(alpha: 0.7)),
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.arrow_back_ios, size: 14),
                            label: const Text('الآية التالية'),
                            onPressed: isLast ? null : () => _goTo(_ayahId + 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MainTabButton extends StatelessWidget {
  const _MainTabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? themeAccent(context) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? themeAccent(context) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? (isDark ? const Color(0xFF2C3E50) : const Color(0xFF34495E))
          : (isDark ? const Color(0xFF1E2836) : const Color(0xFFEAECEE)),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccordionTafsirTile extends ConsumerWidget {
  const _AccordionTafsirTile({
    required this.edition,
    required this.ayahId,
    required this.isExpanded,
    required this.onToggle,
  });

  final TafsirEditionCatalogEntry edition;
  final int ayahId;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tafsirAsync = ref.watch(_tafsirProvider((ayahId: ayahId, edition: edition.key)));
    final isDownloaded = ref
            .watch(tafsirDownloadControllerProvider)
            .statusFor(edition.key) ==
        TafsirEditionDownloadStatus.downloaded;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط العنوان القابل للضغط لفتح وإغلاق القائمة
          Material(
            color: isDark ? const Color(0xFF243345) : const Color(0xFF3B5998),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: Radius.circular(isExpanded ? 0 : 14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: Radius.circular(isExpanded ? 0 : 14),
              ),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        edition.nameAr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // تنويه تغطية جزئية — يظهر فوراً عند الفتح بغضّ النظر عن حالة
          // التنزيل، حتى يعرف المستخدم *قبل حتى* أن يصادف آية بلا تفسير
          // أن هذا الإصدار أصلاً لا يغطي القرآن كاملاً (مؤلّفه توفي قبل
          // إكماله)، لا عطلاً بالتطبيق.
          if (isExpanded && edition.coverageNote != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.goldDeep),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      edition.coverageNote!,
                      style: TextStyle(fontSize: 11, height: 1.5, color: onSurface.withValues(alpha: 0.75)),
                    ),
                  ),
                ],
              ),
            ),

          // المحتوى الداخلي عند الفتح
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: tafsirAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text('تعذّر جلب التفسير: $e'),
                data: (tafsir) {
                  final text = tafsir?.content.trim() ?? '';
                  if (text.isEmpty) {
                    // **مقفَّلة بحالة التنزيل لا بفراغ النص وحده** — إصدار
                    // مُنزَّل فعلاً (كعثيمين/أضواء البيان) قد يكون فارغاً
                    // لهذه الآية تحديداً لأنه أصلاً لا يغطيها (راجع
                    // `coverageNote`)، لا لأنه يحتاج تنزيلاً؛ عرض زر
                    // "تنزيل" هون كان يضلِّل المستخدم لإعادة تنزيل شيء
                    // منزَّل أصلاً بلا أي فائدة.
                    if (isDownloaded) {
                      return Text(
                        'لا يوجد تفسير لهذه الآية بهذا الإصدار'
                        '${edition.coverageNote != null ? ' (خارج نطاق تغطيته)' : ''}.',
                        style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.55)),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'هذا التفسير يحتاج إلى تنزيل ملف القاعدة (${edition.key}.db) للاستفادة منه بلا إنترنت.',
                          style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('تنزيل التفسير الآن'),
                          onPressed: () async {
                            await ref.read(tafsirDownloadControllerProvider.notifier).downloadEdition(edition.key);
                            ref.invalidate(_tafsirProvider);
                          },
                        ),
                      ],
                    );
                  }

                  // معاني الكلمات/الإعراب نص كثيف التشكيل (فتحات/ضمّات/كسرات
                  // متراكبة، ألف مقصورة، شدّة+حركة معاً) — خط الواجهة
                  // الافتراضي (Cairo) غير مصمَّم لتباعد/تموضع علامات تشكيل
                  // كثيفة كهذي فتبدو مقطوعة أو متراكبة. `AmiriQuran` (خط
                  // Naskh كامل، مستخدَم أصلاً لنص الآية بأعلى الشاشة) يعرضها
                  // سليمة. التفاسير العادية (نثر تفسيري بتشكيل خفيف) تبقى
                  // بخط الواجهة — وضوح أفضل لقراءة طويلة.
                  final isTashkeelHeavy = edition.category == 'words' || edition.category == 'irab';
                  return SelectableText(
                    text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: isTashkeelHeavy ? 'AmiriQuran' : null,
                      fontSize: isTashkeelHeavy ? 16.5 : 15.5,
                      height: isTashkeelHeavy ? 2.0 : 1.8,
                      color: onSurface,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// عرض "القرآن الكريم بالترجمة" (إنجليزي — صحيح إنترناشونال حالياً، الترجمة
/// الوحيدة المتوفرة بقاعدة البيانات) — شاشة مستقلة عن تبويبات التفاسير
/// العربية، بنفس شريط التنقل بين الآيات.
class _TranslationView extends ConsumerWidget {
  const _TranslationView({required this.ayahId, required this.onGoTo});

  final int ayahId;
  final void Function(int ayahId) onGoTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(_ayahRefProvider(ayahId));
    final translationAsync = ref.watch(_translationProvider(ayahId));
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFirst = ayahId <= 1;
    final isLast = ayahId >= kQuranAyahCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم بالترجمة', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ayahAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذّر تحميل الآية: $e')),
        data: (ayah) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'السورة ${ayah.surah} · الآية ${ayah.ayah}',
                            style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stripQuranicMarksForDisplay(ayah.textUthmani),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 22,
                              height: 1.85,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    translationAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('تعذّر تحميل الترجمة: $e'),
                      ),
                      data: (translation) {
                        if (translation == null) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('لا توجد ترجمة محفوظة لهذه الآية'),
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.goldDeep.withValues(alpha: isDark ? 0.12 : 0.07),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sahih International',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldDeep,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                translation.content,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(fontSize: 15, height: 1.6, color: onSurface),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B232E) : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line)),
                ),
                child: SafeArea(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.arrow_back_ios, size: 14),
                          label: const Text('الآية السابقة'),
                          onPressed: isFirst ? null : () => onGoTo(ayahId - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'آية ${ayah.ayah} / سورة ${ayah.surah}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: onSurface.withValues(alpha: 0.7)),
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.arrow_back_ios, size: 14),
                            label: const Text('الآية التالية'),
                            onPressed: isLast ? null : () => onGoTo(ayahId + 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
