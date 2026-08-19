import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/remote_assets_config.dart';
import '../audio/quran_audio_controller.dart';
import 'ayah_actions_sheet.dart';
import 'font_download_service.dart';
import 'mushaf_font_service.dart';
import 'mushaf_page_provider.dart';
import 'mushaf_settings.dart';

/// اسم سورة سطر `surah_name` — استعلام صغير مستقل بدل تحميل كل السور
/// دفعة واحدة. Riverpod يخزّنه تلقائياً فلا يتكرر الاستعلام لنفس السورة.
///
/// `nameArPlain` (مجرّد من التشكيل) لا `nameAr` عمداً: التشكيل الكامل
/// (`سُوْرَةُ الْفَاتِحَةِ`) عبر خط الواجهة Cairo — لا خط QCF — أنتج علامات
/// تشكيل طائرة/بمكان غلط لاحظها صاحب المشروع (أوضح ما يكون بأول صفحتين،
/// خصوصاً لو Cairo لسا عم يُجلب من الشبكة عند فتح التطبيق أول مرة، راجع
/// TODO الأداء بـ app_theme.dart). عنوان السورة بلا تشكيل معياري بمعظم
/// تطبيقات المصحف أصلاً، وأسلم إلى حين توفّر خط عناوين مخصّص من QUL.
final _surahNameProvider = FutureProvider.family<String, int>((ref, surahId) async {
  final surah = await ref.watch(quranRepositoryProvider).surahById(surahId);
  return surah.nameArPlain;
});

/// رسم صفحة مصحف واحدة: يحمّل تخطيطها وخطها الخاص (`p{page}.ttf`)، ثم
/// يرسم أسطرها الخمسة عشر بالترتيب. حالة تحميل/خطأ مستقلة عن باقي التطبيق.
class MushafPageWidget extends ConsumerWidget {
  const MushafPageWidget({super.key, required this.page});
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(mushafPageProvider(page));
    final fontAsync = ref.watch(pageFontFamilyProvider(page));

    if (fontAsync.hasError) {
      final error = fontAsync.error;
      final notBundled = error is PageFontNotBundledException;
      if (!notBundled) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('تعذّر تحميل خط الصفحة', textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          ),
        );
      }
      return _PageDownloadPrompt(page: page);
    }

    if (!fontAsync.hasValue || !layoutAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (layoutAsync.hasError) {
      return const Center(child: Text('تعذّر تحميل بيانات هذه الصفحة'));
    }

    final family = fontAsync.value!;
    final mushafPage = layoutAsync.value!;
    final textSize = ref.watch(mushafTextSizeProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: textSize.horizontalPadding, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        // إلزامي: بلا stretch، الـ Column يعطي كل سطر قيود عرض "مرنة" فيسيّر
        // FittedBox حجمه حسب عرض محتواه الطبيعي هو، لا عرض الشاشة — فتفيض
        // الأسطر الأطول من العرض المتاح وتنقطع عند حافة الشاشة.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in mushafPage.lines)
            _PageLineWidget(line: line, words: mushafPage.wordsByLine[line.lineNo] ?? const [], fontFamily: family),
        ],
      ),
    );
  }
}

class _PageLineWidget extends ConsumerWidget {
  const _PageLineWidget({required this.line, required this.words, required this.fontFamily});
  final PageLine line;
  final List<Word> words;
  final String fontFamily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (line.lineType) {
      case 'surah_name':
        final nameAsync = ref.watch(_surahNameProvider(line.surahRef!));
        return SizedBox(
          height: 32,
          child: Center(
            child: Text(
              nameAsync.value ?? '',
              style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        );
      case 'basmallah':
        // TODO: نص البسملة الزخرفي يحتاج خط/أصل مخصص من نفس مصدر خطوط
        // أسماء السور بـ QUL — لم يُجلب بعد. سطر فارغ مؤقتاً بدل تخمين نص.
        return const SizedBox(height: 24);
      case 'ayah':
      default:
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // أسطر `is_centered` (قصيرة بطبعها — غالباً آخر سطر بالسورة، وكل
        // أسطر الفاتحة) لا تُمطّ لملء العرض بالمصحف الحقيقي، بل تُرسم
        // بحجمها الطبيعي مُوسّطة. تجاهلنا هالعلامة سابقاً ففرضنا
        // BoxFit.fitWidth على الكل، فسطر من ٤ كلمات بس كان يتمطّط بعنف
        // ليملأ العرض كاملاً — والارتفاع يكبر مع العرض بنفس النسبة
        // (fitWidth يكبّر البعدين معاً) فيفيض ويتراكب مع السطر يلي جنبه.
        final isCentered = line.isCentered == 1;
        // آية التلاوة الحالية (لو في تشغيل صوتي جارٍ) — لتظليلها بالسطر.
        // `select` يمنع إعادة بناء كل سطور الصفحة لمجرّد تبديل تشغيل/إيقاف
        // أو تغيير السرعة؛ فقط تغيّر معرّف الآية نفسه يعيد البناء هون.
        final highlightAyahId = ref.watch(quranAudioControllerProvider.select((s) => s.currentAyahId));
        final memorizationOn = ref.watch(memorizationModeProvider);
        final revealedAyahs = ref.watch(revealedAyahsProvider);
        return SizedBox(
          height: 34,
          child: Center(
            child: FittedBox(
              fit: isCentered ? BoxFit.scaleDown : BoxFit.fitWidth,
              clipBehavior: Clip.hardEdge,
              child: _TappableAyahLine(
                words: words,
                highlightAyahId: highlightAyahId,
                memorizationOn: memorizationOn,
                revealedAyahs: revealedAyahs,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 28,
                  color: isDark ? AppColors.inkOnDark : AppColors.ink,
                  height: 1,
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// نفس نص السطر تماماً (نفس الخط والحجم واللون) — بس مفكّك لـ `TextSpan`
/// لكل كلمة بدل نص واحد متّصل، ليدعم الضغط على كلمة ففتح شيت إجراءات
/// آيتها. **لا يغيّر أي شيء بصري بالخط نفسه**، فقط يضيف كاشف ضغط لكل كلمة.
class _TappableAyahLine extends ConsumerStatefulWidget {
  const _TappableAyahLine({
    required this.words,
    required this.style,
    this.highlightAyahId,
    this.memorizationOn = false,
    this.revealedAyahs = const {},
  });
  final List<Word> words;
  final TextStyle style;

  /// معرّف الآية المشغَّلة صوتياً الآن — كلماتها بهالسطر تُلوَّن بخلفية
  /// مميّزة. `null` = لا تظليل (لا تشغيل جارٍ، أو قارئ بلا تقسيم بالآية).
  final int? highlightAyahId;

  /// وضع الحفظ مفعَّل؟ لو نعم، كل كلمة آيتها ليست بـ [revealedAyahs] تُستبدل
  /// بغطاء (■) يكشف آيته بالضغط عليه بدل فتح شيت الإجراءات — راجع
  /// `mushaf_settings.dart`.
  final bool memorizationOn;
  final Set<int> revealedAyahs;

  @override
  ConsumerState<_TappableAyahLine> createState() => _TappableAyahLineState();
}

class _TappableAyahLineState extends ConsumerState<_TappableAyahLine> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant _TappableAyahLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    _disposeRecognizers();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final highlightColor = AppColors.gold.withValues(alpha: 0.22);
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.words.length; i++) {
      final word = widget.words[i];
      final isHighlighted = widget.highlightAyahId != null && word.ayahId == widget.highlightAyahId;
      final isHidden = widget.memorizationOn && !widget.revealedAyahs.contains(word.ayahId);

      if (isHidden) {
        // غطاء بخط النظام العادي لا QCF — الغليف نفسه رمز خاص بخط الصفحة،
        // واستبداله بحرف عادي بنفس الخط ممكن يطلع مربّعاً فارغاً (tofu).
        // الضغط يكشف آية الكلمة كاملة، لا كلمة وحدها — الحفظ باختبار
        // الآية ككل أصح من كشف كلمة كلمة.
        final recognizer = TapGestureRecognizer()
          ..onTap = () => ref.read(revealedAyahsProvider.notifier).reveal(word.ayahId);
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: '■',
          recognizer: recognizer,
          style: TextStyle(fontFamily: null, color: widget.style.color?.withValues(alpha: 0.28)),
        ));
      } else {
        final recognizer = TapGestureRecognizer()..onTap = () => AyahActionsSheet.show(context, word.ayahId);
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: word.glyph,
          recognizer: recognizer,
          style: isHighlighted ? TextStyle(backgroundColor: highlightColor) : null,
        ));
      }

      if (i != widget.words.length - 1) {
        // نلوّن الفاصلة بلون الكلمة قبلها — يخلّي التظليل شريطاً متّصلاً
        // بدل فجوات بيضاء بين كلمات نفس الآية المشغَّلة.
        spans.add(TextSpan(text: ' ', style: isHighlighted ? TextStyle(backgroundColor: highlightColor) : null));
      }
    }
    return Text.rich(TextSpan(children: spans, style: widget.style), textDirection: TextDirection.rtl);
  }
}

/// عرض بديل لصفحة غير مضمَّنة (٥١-٦٠٤): زر تنزيلها فردياً — راجع
/// `font_download_service.dart`. لو الاستضافة مو مهيّأة بعد (`kFontsBaseUrl`
/// لسا placeholder) يعرض رسالة واضحة بدل زر يفشل صامتاً.
class _PageDownloadPrompt extends ConsumerWidget {
  const _PageDownloadPrompt({required this.page});
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(fontDownloadControllerProvider);
    final alreadyDownloading = downloadState.isBulkRunning;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_outlined, size: 32, color: AppColors.inkSoft),
            const SizedBox(height: 8),
            Text(
              isFontsBaseUrlConfigured ? 'خط هذه الصفحة يحتاج تنزيلاً' : 'تنزيل الصفحات ٥١-٦٠٤ غير متوفّر بهذا الإصدار بعد',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            if (isFontsBaseUrlConfigured) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('تنزيل هذه الصفحة'),
                onPressed: alreadyDownloading
                    ? null
                    : () async {
                        await ref.read(fontDownloadControllerProvider.notifier).downloadPage(page);
                        ref.invalidate(pageFontFamilyProvider(page));
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
