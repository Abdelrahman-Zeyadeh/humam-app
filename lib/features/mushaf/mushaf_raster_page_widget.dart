import 'dart:convert' show jsonDecode;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'ayah_actions_sheet.dart';
import 'mushaf_image_download_service.dart';
import 'mushaf_settings.dart';

/// صندوق كلمة واحد بـ`layout.json` نسخة مصورة — نسبي (٠..١) لأبعاد صورة
/// الصفحة، لا بكسل مطلق (يستقل عن دقة الصورة الفعلية). `id` يطابق
/// `Words.id` و`ayahId` يطابق `Ayahs.id` بـ`quran.db` — راجع خطة
/// `golden-cuddling-tiger.md` للـschema المتّفق عليه بين الجلستين.
class RasterWordBox {
  const RasterWordBox({
    required this.id,
    required this.ayahId,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final int id;
  final int ayahId;
  final double x;
  final double y;
  final double w;
  final double h;

  factory RasterWordBox.fromJson(Map<String, dynamic> json) => RasterWordBox(
    id: json['id'] as int,
    ayahId: json['ayah_id'] as int,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    w: (json['w'] as num).toDouble(),
    h: (json['h'] as num).toDouble(),
  );
}

/// تخطيط نسخة مصورة كاملة، مفهرَس برقم الصفحة (١-٦٠٤). يُحمَّل من أصل
/// مضمَّن بالتطبيق `assets/quran/mushaf_images/<editionId>/layout.json`
/// (**غير موجود بعد** — أداة تحويل PDF لخطوة منفصلة قيد التنفيذ بالتوازي)
/// — `try/catch` يرجع خريطة فاضية لو الملف مفقود عشان الودجت ما تكسر
/// أثناء التطوير، تعرض حالة "بلا صناديق كلمات" (الصورة فقط بلا تفاعل)
/// بدل كراش.
final _rasterLayoutProvider =
    FutureProvider.family<Map<int, List<RasterWordBox>>, String>((
      ref,
      editionId,
    ) async {
      try {
        final raw = await rootBundle.loadString(
          'assets/quran/mushaf_images/$editionId/layout.json',
        );
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return {
          for (final entry in decoded.entries)
            int.parse(entry.key): [
              for (final item in entry.value as List<dynamic>)
                RasterWordBox.fromJson(item as Map<String, dynamic>),
            ],
        };
      } catch (_) {
        return const {};
      }
    });

typedef _RasterPageKey = ({String editionId, int page});

/// ملف صورة صفحة منزَّل محلياً فعلاً — `null` لو غير منزَّل بعد. يراقب
/// [MushafImageDownloadController] عشان يتحدّث تلقائياً فور اكتمال تنزيل
/// هذه الصفحة بالذات بلا حاجة لإعادة فتح الصفحة يدوياً.
final _rasterPageFileProvider = FutureProvider.family<File?, _RasterPageKey>((
  ref,
  key,
) async {
  final downloaded = ref.watch(
    mushafImageDownloadControllerProvider.select(
      (s) => s.forEdition(key.editionId).downloadedPages.contains(key.page),
    ),
  );
  if (!downloaded) return null;
  final controller = ref.watch(mushafImageDownloadControllerProvider.notifier);
  final file = await controller.localImageFile(key.editionId, key.page);
  if (await file.exists() && (await file.length()) > 0) return file;
  return null;
});

/// أبعاد صورة الصفحة الحقيقية (عرض×ارتفاع بالبكسل) — تُحسَب مرّة واحدة
/// بفكّ ترميز الصورة، لتحويل صناديق [RasterWordBox] النسبية لموضع دقيق
/// داخل `AspectRatio` مطابق تماماً لأبعاد الصورة الأصلية.
final _rasterImageSizeProvider = FutureProvider.family<Size, String>((
  ref,
  path,
) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final size = Size(
    frame.image.width.toDouble(),
    frame.image.height.toDouble(),
  );
  frame.image.dispose();
  return size;
});

/// ودجت شقيقة لـ`MushafPageWidget` — ترسم صفحة من طبعة مصورة (سكان) بدل
/// النص الحي بخط QCF. **بلا تلوين تجويد** بهذا الوضع (قرار مستخدم صريح،
/// راجع خطة `golden-cuddling-tiger.md`) — صورة سكان فعلية لا نص، فلا معنى
/// أصلاً لأي طبعة خط (V1/V2/V4 Tajweed) هون.
class MushafRasterPageWidget extends ConsumerWidget {
  const MushafRasterPageWidget({
    super.key,
    required this.page,
    required this.edition,
  });

  final int page;
  final RasterMushafEdition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileAsync = ref.watch(
      _rasterPageFileProvider((editionId: edition.id, page: page)),
    );

    if (fileAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final file = fileAsync.value;
    if (file == null) {
      return _RasterPageDownloadPrompt(edition: edition, page: page);
    }

    return _RasterPageImage(file: file, edition: edition, page: page);
  }
}

class _RasterPageImage extends ConsumerWidget {
  const _RasterPageImage({
    required this.file,
    required this.edition,
    required this.page,
  });

  final File file;
  final RasterMushafEdition edition;
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizeAsync = ref.watch(_rasterImageSizeProvider(file.path));
    if (!sizeAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final intrinsicSize = sizeAsync.value!;
    if (intrinsicSize.width <= 0 || intrinsicSize.height <= 0) {
      return const Center(child: Text('تعذّر قراءة صورة هذه الصفحة'));
    }

    final layout =
        ref.watch(_rasterLayoutProvider(edition.id)).value ?? const {};
    final wordsForPage = layout[page] ?? const <RasterWordBox>[];
    final byAyah = <int, List<RasterWordBox>>{};
    for (final word in wordsForPage) {
      (byAyah[word.ayahId] ??= []).add(word);
    }

    final memorizationOn = ref.watch(memorizationModeProvider);
    final revealedAyahs = ref.watch(revealedAyahsProvider);

    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      // **باج حقيقي مُصلَح هون**: بلا `Center` هون، `InteractiveViewer`
      // كان يثبّت `AspectRatio` بزاوية الحاوية (يسار/أعلى) بدل توسيطها كل
      // ما تختلف نسبة أبعاد صورة الصفحة عن نسبة أبعاد شاشة القراءة —
      // بالضبط "الإزاحة" اللي وصفها صاحب المشروع بالسكرين شوت (هامش فاضٍ
      // من جهة واحدة فقط بدل توسيط متماثل).
      child: Center(
        child: AspectRatio(
          aspectRatio: intrinsicSize.width / intrinsicSize.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file, fit: BoxFit.fill),
                  for (final entry in byAyah.entries)
                    _AyahOverlay(
                      ayahId: entry.key,
                      boxes: entry.value,
                      canvasWidth: width,
                      canvasHeight: height,
                      revealed:
                          !memorizationOn || revealedAyahs.contains(entry.key),
                      memorizationOn: memorizationOn,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// اتحاد صناديق كلمات آية واحدة (`ayah_id` مشترك) — صندوق ضغط واحد يفتح
/// شيت الإجراءات بضغطة مطوّلة (نفس آلية `mushaf_page_widget.dart`)، ومغطّى
/// بمستطيل معتم بوضع الحفظ حتى تُكشَف (يختفي عند الضغط عليه، بلا تلوين أو
/// تخمين نص — مجرد تغطية).
class _AyahOverlay extends ConsumerWidget {
  const _AyahOverlay({
    required this.ayahId,
    required this.boxes,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.revealed,
    required this.memorizationOn,
  });

  final int ayahId;
  final List<RasterWordBox> boxes;
  final double canvasWidth;
  final double canvasHeight;
  final bool revealed;
  final bool memorizationOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var left = 1.0, top = 1.0, right = 0.0, bottom = 0.0;
    for (final box in boxes) {
      left = math.min(left, box.x);
      top = math.min(top, box.y);
      right = math.max(right, box.x + box.w);
      bottom = math.max(bottom, box.y + box.h);
    }
    if (right <= left || bottom <= top) return const SizedBox.shrink();

    final rect = Rect.fromLTRB(
      left * canvasWidth,
      top * canvasHeight,
      right * canvasWidth,
      bottom * canvasHeight,
    );

    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: revealed
            ? () => AyahActionsSheet.show(context, ayahId)
            : null,
        onTap: !revealed
            ? () => ref.read(revealedAyahsProvider.notifier).reveal(ayahId)
            : null,
        child: !revealed
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.inkSoft.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(3),
                ),
              )
            : null,
      ),
    );
  }
}

/// عرض بديل لصفحة مصورة غير منزَّلة بعد — نفس شكل `_PageDownloadPrompt`
/// بـ`mushaf_page_widget.dart` بس يستدعي تحميل صورة الصفحة بدل الخط.
class _RasterPageDownloadPrompt extends ConsumerWidget {
  const _RasterPageDownloadPrompt({required this.edition, required this.page});

  final RasterMushafEdition edition;
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editionState = ref
        .watch(mushafImageDownloadControllerProvider)
        .forEdition(edition.id);
    final busy = editionState.isBulkRunning;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_outlined,
              size: 32,
              color: AppColors.inkSoft,
            ),
            const SizedBox(height: 8),
            const Text(
              'صورة هذه الصفحة تحتاج تنزيلاً',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('تنزيل هذه الصفحة'),
              onPressed: busy
                  ? null
                  : () => ref
                        .read(mushafImageDownloadControllerProvider.notifier)
                        .downloadPage(edition.id, page),
            ),
          ],
        ),
      ),
    );
  }
}
