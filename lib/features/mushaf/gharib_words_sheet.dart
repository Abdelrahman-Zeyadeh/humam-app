import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/gharib_quran_data.dart';
import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';

final _ayahProvider = FutureProvider.family<Ayah, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahById(ayahId);
});

/// شيت سفلي مخصص لمعاني الكلمات وغريب القرآن الكريم للآية المحددة
class GharibWordsSheet extends ConsumerStatefulWidget {
  const GharibWordsSheet({super.key, required this.ayahId});

  final int ayahId;

  static Future<void> show(BuildContext context, int ayahId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GharibWordsSheet(ayahId: ayahId),
    );
  }

  @override
  ConsumerState<GharibWordsSheet> createState() => _GharibWordsSheetState();
}

class _GharibWordsSheetState extends ConsumerState<GharibWordsSheet> {
  late int _ayahId = widget.ayahId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final ayahAsync = ref.watch(_ayahProvider(_ayahId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
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
              // مقبض ورأس الشيت
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                                color: const Color(0xFF2E8071).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFF2E8071),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'معاني الكلمات وغريب القرآن',
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
                  ],
                ),
              ),
              const Divider(height: 1),

              // قائمة الكلمات
              Expanded(
                child: ayahAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('تعذر تحميل الآية: $e')),
                  data: (ayah) {
                    final words = GharibQuranData.hasGharib(ayah.id)
                        ? GharibQuranData.getWordsForAyah(ayah.id)
                        : GharibQuranData.generateQuickVocabulary(ayahText: ayah.textUthmani);

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        // بطاقة نص الآية
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2836) : const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            ayah.textUthmani,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 19,
                              height: 1.8,
                              color: onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (words.isEmpty) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'ألفاظ هذه الآية الكريمة واضحة جليّة في التفسير الميسر.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          for (final word in words) ...[
                            _WordMeaningCard(word: word),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),

              // شريط التنقل
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
                      'آية $_ayahId من 6236',
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

class _WordMeaningCard extends StatelessWidget {
  const _WordMeaningCard({required this.word});

  final GharibWord word;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2E8071).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '﴿ ${word.word} ﴾',
                style: const TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8071),
                ),
              ),
              if (word.root != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8071).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'جذر: ${word.root}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E8071),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // نص كثيف التشكيل مثل نص "لغويات" بشاشة التفسير — راجع تعليق
          // مطابق بـ`ayah_text_view_screen.dart._AccordionTafsirTile`.
          Text(
            word.meaning,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 15,
              height: 1.9,
              color: onSurface.withValues(alpha: 0.9),
            ),
          ),
          if (word.benefit != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A24B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.goldDeep),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      word.benefit!,
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
