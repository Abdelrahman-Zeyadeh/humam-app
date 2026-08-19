import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';

/// أي نص إضافي نعرضه لآية: تفسير أو ترجمة. حالياً كتاب/لغة واحدة لكل
/// نوع (`jalalayn` و`en_sahih`) — راجع `QuranRepository` لسبب كون
/// `edition` معياراً عاماً بالمخطط بدل التوسّع.
enum AyahTextViewKind { tafsir, translation }

final _ayahRefProvider = FutureProvider.family<Ayah, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahById(ayahId);
});

final _tafsirProvider = FutureProvider.family<Tafsir?, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).tafsirForAyah(ayahId);
});

final _translationProvider = FutureProvider.family<Translation?, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).translationForAyah(ayahId);
});

/// شاشة نص إضافي لآية واحدة (تفسير الجلالين أو ترجمة صحيح إنترناشونال).
/// النص العثماني يبقى ظاهراً بالأعلى دائماً كمرجع، والمحتوى المطلوب تحته.
class AyahTextViewScreen extends ConsumerWidget {
  const AyahTextViewScreen({super.key, required this.ayahId, required this.kind});
  final int ayahId;
  final AyahTextViewKind kind;

  String get _title => kind == AyahTextViewKind.tafsir ? 'التفسير' : 'الترجمة';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(_ayahRefProvider(ayahId));
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ayahAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('تعذّر تحميل الآية')),
        data: (ayah) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'سورة ${ayah.surah} · الآية ${ayah.ayah}',
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                ayah.textUthmani,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: onSurface, fontSize: 22, height: 1.9),
              ),
              const SizedBox(height: 8),
              const Divider(height: 32, color: AppColors.line),
              if (kind == AyahTextViewKind.tafsir)
                _TafsirBody(ayahId: ayahId, onSurface: onSurface)
              else
                _TranslationBody(ayahId: ayahId, onSurface: onSurface),
            ],
          );
        },
      ),
    );
  }
}

class _TafsirBody extends ConsumerWidget {
  const _TafsirBody({required this.ayahId, required this.onSurface});
  final int ayahId;
  final Color onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_tafsirProvider(ayahId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Text('تعذّر تحميل التفسير'),
      data: (tafsir) {
        if (tafsir == null) return const Text('لا يوجد تفسير لهذه الآية بعد');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tafsir.content,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: onSurface, fontSize: 16, height: 1.8),
            ),
            const SizedBox(height: 16),
            Text(
              'تفسير الجلالين',
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}

class _TranslationBody extends ConsumerWidget {
  const _TranslationBody({required this.ayahId, required this.onSurface});
  final int ayahId;
  final Color onSurface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_translationProvider(ayahId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Text('تعذّر تحميل الترجمة'),
      data: (translation) {
        if (translation == null) return const Text('لا توجد ترجمة لهذه الآية بعد');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              translation.content,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: onSurface, fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Saheeh International',
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withValues(alpha: 0.5), fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}
