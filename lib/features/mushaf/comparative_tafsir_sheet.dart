import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';
import 'tafsir_download_service.dart';

final _ayahProvider = FutureProvider.family<Ayah, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahById(ayahId);
});

final _tafsirCompareProvider = FutureProvider.family<Tafsir?, ({int ayahId, String edition})>((ref, arg) {
  return ref.watch(quranRepositoryProvider).tafsirForAyah(arg.ayahId, edition: arg.edition);
});

/// شاشة وشيت التفسير المقارن للآية الشريفة
class ComparativeTafsirSheet extends ConsumerStatefulWidget {
  const ComparativeTafsirSheet({
    super.key,
    required this.ayahId,
    this.initialEditions = const ['muyassar', 'saadi'],
  });

  final int ayahId;
  final List<String> initialEditions;

  static Future<void> show(BuildContext context, int ayahId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComparativeTafsirSheet(ayahId: ayahId),
    );
  }

  @override
  ConsumerState<ComparativeTafsirSheet> createState() => _ComparativeTafsirSheetState();
}

class _ComparativeTafsirSheetState extends ConsumerState<ComparativeTafsirSheet> {
  late int _ayahId = widget.ayahId;
  late final Set<String> _selectedEditions = Set.from(widget.initialEditions);

  static const List<({String key, String nameAr, String desc})> _availableEditions = [
    (key: 'muyassar', nameAr: 'الميسر', desc: 'مجمع الملك فهد'),
    (key: 'saadi', nameAr: 'السعدي', desc: 'تيسير الكريم الرحمن'),
    (key: 'mukhtasar', nameAr: 'المختصر', desc: 'مركز تفسير'),
    (key: 'jalalayn', nameAr: 'الجلالين', desc: 'تفسير لغوي موجز'),
    (key: 'ibnkathir', nameAr: 'ابن كثير', desc: 'تفسير القرآن العظيم'),
    (key: 'baghawi', nameAr: 'البغوي', desc: 'معالم التنزيل'),
    (key: 'tabari', nameAr: 'الطبري', desc: 'جامع البيان'),
  ];

  void _toggleEdition(String key) {
    setState(() {
      if (_selectedEditions.contains(key)) {
        if (_selectedEditions.length > 1) {
          _selectedEditions.remove(key);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب إبقاء تفسير واحد على الأقل للمقارنة'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _selectedEditions.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);
    final ayahAsync = ref.watch(_ayahProvider(_ayahId));
    final downloadState = ref.watch(tafsirDownloadControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141C26) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // مقبض السحب والعنوان
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.compare_arrows_rounded, color: accent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'التفسير المقارن',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // شريط اختيار التفاسير للمقارنة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final ed in _availableEditions) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: FilterChip(
                                label: Text(ed.nameAr),
                                selected: _selectedEditions.contains(ed.key),
                                onSelected: (_) => _toggleEdition(ed.key),
                                selectedColor: accent.withValues(alpha: 0.2),
                                checkmarkColor: accent,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedEditions.contains(ed.key)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedEditions.contains(ed.key) ? accent : onSurface,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // محتوى الآية والتفاسير المقارنة
              Expanded(
                child: ayahAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('تعذر تحميل الآية: $e')),
                  data: (ayah) {
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        // بطاقة نص الآية
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2836) : const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'السورة ${ayah.surah} · آية ${ayah.ayah}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ayah.textUthmani,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 20,
                                  height: 1.8,
                                  color: onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // بطاقات التفاسير المقارنة
                        for (final edKey in _selectedEditions) ...[
                          _TafsirComparisonCard(
                            ayahId: ayah.id,
                            editionKey: edKey,
                            editionName: _availableEditions
                                .firstWhere((e) => e.key == edKey, orElse: () => (key: edKey, nameAr: edKey, desc: ''))
                                .nameAr,
                            editionDesc: _availableEditions
                                .firstWhere((e) => e.key == edKey, orElse: () => (key: edKey, nameAr: edKey, desc: ''))
                                .desc,
                            downloadState: downloadState,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // شريط التنقل بين الآيات
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF19222E) : const Color(0xFFF9FAFB),
                  border: Border(
                    top: BorderSide(
                      color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      tooltip: 'الآية التالية',
                      onPressed: _ayahId < 6236 ? () => setState(() => _ayahId++) : null,
                    ),
                    Text(
                      'الآية $_ayahId من 6236',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                      tooltip: 'الآية السابقة',
                      onPressed: _ayahId > 1 ? () => setState(() => _ayahId--) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TafsirComparisonCard extends ConsumerWidget {
  const _TafsirComparisonCard({
    required this.ayahId,
    required this.editionKey,
    required this.editionName,
    required this.editionDesc,
    required this.downloadState,
  });

  final int ayahId;
  final String editionKey;
  final String editionName;
  final String editionDesc;
  final TafsirDownloadState downloadState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);
    final status = downloadState.statusFor(editionKey);

    final tafsirAsync = ref.watch(
      _tafsirCompareProvider((ayahId: ayahId, edition: editionKey)),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عنوان التفسير ومصدره
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      editionName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($editionDesc)',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'نسخ نص التفسير',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final text = tafsirAsync.asData?.value?.content;
                    if (text != null && text.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: '[$editionName]\n$text'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم نسخ $editionName 📋'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // محتوى التفسير
          Padding(
            padding: const EdgeInsets.all(16),
            child: status == TafsirEditionDownloadStatus.notDownloaded
                ? Column(
                    children: [
                      Text(
                        'كتاب $editionName يتطلب تنزيلاً لمرة واحدة للاستخدام أوفلاين',
                        style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('تنزيل التفسير', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          ref.read(tafsirDownloadControllerProvider.notifier).downloadEdition(editionKey);
                        },
                      ),
                    ],
                  )
                : status == TafsirEditionDownloadStatus.downloading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              CircularProgressIndicator(value: downloadState.downloadProgress),
                              const SizedBox(height: 8),
                              const Text('جاري تنزيل التفسير...', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : tafsirAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('تعذر تحميل النص: $e'),
                        data: (t) {
                          final text = t?.content;
                          if (text == null || text.trim().isEmpty) {
                            return Text(
                              'لا يتوفر نص مسجل لهذا التفسير في هذه الآية.',
                              style: TextStyle(
                                fontSize: 13,
                                color: onSurface.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return SelectableText(
                            text,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.75,
                              color: onSurface.withValues(alpha: 0.9),
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
