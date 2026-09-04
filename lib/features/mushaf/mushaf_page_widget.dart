import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show GestureRecognizer, LongPressGestureRecognizer, TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart' show MushafPageLineInfo, MushafWord;
import '../../core/data/user/user_prefs.dart';
import '../../core/text/arabic_normalizer.dart'
    show sanitizeSurahNameForDisplay;
import '../../core/theme/app_colors.dart';
import '../../core/theme/mushaf_palettes.dart';
import '../audio/quran_audio_controller.dart';
import 'ayah_actions_sheet.dart';
import 'font_download_service.dart';
import 'mushaf_font_service.dart';
import 'mushaf_page_provider.dart';
import 'mushaf_settings.dart';

/// وسم مؤقّت (لا Riverpod، لا يستحق ودجت حالة لأجله) يمنع ازدواج ضغطة كلمة
/// **بوضعَي كشف الحفظ واختيار نطاق الحفظ فقط** (كلاهما يستخدم `onTap`
/// عادياً، فيتعارض مع `onTap` تبديل القوائم العائمة بمُغلِّف الصفحة
/// الخارجي — تابَّان متطابقان يقعان معاً بنفس اللمسة). **لا علاقة له بفتح
/// شيت إجراءات الآية العادي** (ذاك بضغطة مطوّلة منفصلة تماماً بحلبة
/// الإيماءات، لا تعارض معها أصلاً). كل كلمة تُعلِّمه `true` بـ`onTap`
/// **قبل** تنفيذ فعلها؛ اختبار الإصابة بفلَتر يستدعي معالِج العنصر الأعمق
/// أولاً دائماً (الكلمة قبل مُغلِّف الصفحة الخارجي) فالقيمة تكون جاهزة حين
/// يتحقّق منها المُغلِّف لاحقاً بنفس دورة اللمسة، فيتجاهل تبديل القوائم
/// ويُصفّر الوسم لللمسة التالية.
bool wordTapConsumedThisGesture = false;

/// اسم سورة سطر `surah_name` — استعلام صغير مستقل بدل تحميل كل السور
/// دفعة واحدة. Riverpod يخزّنه تلقائياً فلا يتكرر الاستعلام لنفس السورة.
final _surahNameProvider = FutureProvider.family<String, int>((
  ref,
  surahId,
) async {
  if (surahId == 5) return 'سُورَةُ الْمَائِدَةِ';
  final surah = await ref.watch(quranRepositoryProvider).surahById(surahId);
  return sanitizeSurahNameForDisplay(surah.nameAr);
});

/// معرّفات الآيات التي عليها ملاحظة — لعلامة صغيرة تُرسَم عند رمز نهاية
/// الآية (`Word.charType == 'ayah_marker'`) مباشرة، فتظهر بمجرد فتح
/// الصفحة بلا حاجة للضغط عليها (بطلب صاحب المشروع). `ayahNoteVersionProvider`
/// يجبر إعادة القراءة بعد أي حفظ/حذف ملاحظة (نفس نمط `_noteProvider` بـ
/// `ayah_actions_sheet.dart`).
final _notedAyahIdsProvider = FutureProvider<Set<int>>((ref) async {
  ref.watch(ayahNoteVersionProvider);
  return ref.watch(userPrefsProvider).notedAyahIds();
});

/// رسم صفحة مصحف واحدة: يحمّل تخطيطها وخطها الخاص (`p{page}.ttf`)، ثم
/// يرسم أسطرها الخمسة عشر بالترتيب. حالة تحميل/خطأ مستقلة عن باقي التطبيق.
class MushafPageWidget extends ConsumerWidget {
  const MushafPageWidget({super.key, required this.page});
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickingHifz = ref.watch(hifzPickerProvider.select((s) => s.active));
    final layoutAsync = ref.watch(mushafPageProvider(page));
    final fontAsync = ref.watch(pageFontFamilyProvider(page));

    if (fontAsync.hasError) {
      final error = fontAsync.error;
      final notBundled = error is PageFontNotBundledException;
      if (!notBundled) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'تعذّر تحميل خط الصفحة',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
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
    final noteAyahIds = ref.watch(_notedAyahIdsProvider).value ?? const <int>{};
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: textSize.horizontalPadding,
        vertical: 4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in mushafPage.lines)
            Expanded(
              child: _PageLineWidget(
                line: line,
                words: mushafPage.wordsByLine[line.lineNo] ?? const [],
                fontFamily: family,
                pickingHifz: pickingHifz,
                noteAyahIds: noteAyahIds,
              ),
            ),
        ],
      ),
    );

    // "المصحف الليلي" (راجع MushafColorSettings.nightMode) — قلب ألوان
    // الصفحة كاملة (بلا لمس منطق ألوان كل عنصر داخلها، البسملة/أسماء
    // السور/النص العادي كلها تُقلَب معاً تلقائياً) + تعتيم خفيف يريح العين
    // أكثر من الأبيض المقلوب الخام (رمادي فاتح جداً بدل أبيض ناصع).
    ref.watch(mushafPaletteVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);
    final nightMode = userPrefs.mushafNightMode;
    final nightModeActive =
        nightMode == 'on' || (nightMode == 'auto' && isDarkTheme);
    if (!nightModeActive) return content;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_kNightModeMatrix),
      child: Opacity(opacity: 0.92, child: content),
    );
  }
}

/// مصفوفة Night Mode دافئة مستوحاة من تطبيق quran_android الرسمي —
/// تقلب ألوان الصفحة مع تحيّز للدفء (sepia): الأحمر يحتفظ بإزاحة أعلى
/// (255) والأزرق أقل (245) مما يُنتج نبرة ذهبية دافئة أريح للعين من
/// القلب الأبيض الصريح القديم. `Opacity(0.92)` يُعتِّم قليلاً للراحة.
const _kNightModeMatrix = <double>[
  // R       G       B       A     offset
  -1.0, 0.0, 0.0, 0.0, 255.0, // قناة الأحمر — قلب كامل
  0.0, -1.0, 0.0, 0.0, 245.0, // قناة الأخضر — قلب بإزاحة أقل قليلاً
  0.0, 0.0, -1.0, 0.0, 210.0, // قناة الأزرق — إزاحة أخفض = دفء ذهبي
  0.0, 0.0, 0.0, 1.0, 0.0, // ألفا — بلا تغيير
];

/// **يمنع ازدواج التغميق** حين يكون "المصحف الليلي" مفعّلاً — الصفحة تُبنى
/// دائماً بألوان الوضع الفاتح للباقة (`palette.fg/bg(false)`) لمّا يكون
/// `MushafPageWidget` سيقلب الألوان لاحقاً عبر `ColorFiltered` (نفس حساب
/// `nightModeActive` هناك بالضبط). بدون هذا: لو صادف أن ثيم التطبيق داكن
/// **و**"المصحف الليلي" مفعَّل دائماً معاً (تركيبة شائعة جداً)، كانت
/// الصفحة تُبنى بألوان الوضع الداكن (نص أبيض) ثم تُقلَب **مرّة ثانية**
/// فوقها، فيصير النص أسود على خلفية عكسها — بلاغ صاحب المشروع "الآيات
/// بتصير لونها اسود وما بتبين" كان بالضبط بهذا السبب.
bool _effectivePaletteIsDark(BuildContext context, UserPrefs userPrefs) {
  final themeDark = Theme.of(context).brightness == Brightness.dark;
  final nightMode = userPrefs.mushafNightMode;
  final nightModeActive =
      nightMode == 'on' || (nightMode == 'auto' && themeDark);
  return themeDark && !nightModeActive;
}

/// زخرفة معينيّة صغيرة — لمسة واحدة متكرّرة على جانبَي اسم السورة، بلا أي
/// حركة أو تدرّج (راجع توثيق استخدامها بـ`_PageLineWidget`).
class _SurahNameOrnament extends StatelessWidget {
  const _SurahNameOrnament({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398, // ٤٥° — معيّن لا مربّع
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

class _PageLineWidget extends ConsumerWidget {
  const _PageLineWidget({
    required this.line,
    required this.words,
    required this.fontFamily,
    this.pickingHifz = false,
    this.noteAyahIds = const {},
  });
  final MushafPageLineInfo line;
  final List<MushafWord> words;
  final String fontFamily;
  final bool pickingHifz;

  /// معرّفات آيات عليها ملاحظة — راجع `_notedAyahIdsProvider` أعلى الملف.
  final Set<int> noteAyahIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (line.lineType) {
      case 'surah_name':
        ref.watch(mushafPaletteVersionProvider);
        ref.watch(accentColorVersionProvider);
        final userPrefs = ref.watch(userPrefsProvider);
        final isDark = _effectivePaletteIsDark(context, userPrefs);
        final accent = themeAccent(context);
        final nameAsync = ref.watch(_surahNameProvider(line.surahRef ?? 1));

        // إطار خفيف حول اسم السورة — لمسة زخرفية بسيطة بلون التمييز
        // المختار (تلقائياً بلون كل باقة/ثيم)، بدل النص العاري بلا حدود
        // سابقاً. حدّ شعري رفيع + خلفية بشفافية خافتة جداً + زخرفتان
        // صغيرتان معينيّتان على الجانبين — بلا ظل ولا تدرّج ولا حركة
        // (بطلب صاحب المشروع "خفيف لطيف بدون حركات كثيرة مريح للعين").
        return Semantics(
          label: nameAsync.value,
          child: Center(
            // `Center` عمداً — بدونه الصندوق كان يتمطّط لعرض الصفحة كامل
            // (السطر الأب `Column` بـcrossAxisAlignment.stretch)، فبان
            // "كبير" زيادة رغم صغر ارتفاعه (بلاغ صاحب المشروع). هيك يتقلّص
            // لعرض محتواه فقط — شارة صغيرة موسّطة لا شريط بعرض الصفحة.
            child: Container(
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.09 : 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SurahNameOrnament(color: accent),
                  const SizedBox(width: 6),
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // غليف `surah{NNN}` يرسم اسم السورة وحده بلا كلمة
                        // "سورة" (تحقّقنا: هيك مصمَّم الخط نفسه) — نضيفها
                        // بغليف `surah-icon` من **نفس الخط** (تحقّقنا من
                        // GSUB: موجود فعلاً)، لا نص AmiriQuran عادي — رسم
                        // عثماني أصيل متطابق تماماً مع غليف الاسم، لا خط
                        // واجهة مختلف الطراز (بطلب صاحب المشروع).
                        Text(
                          'surah-icon',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFF3DA8E) : const Color(0xFF1E1A16),
                            fontSize: 27,
                            height: 1.1,
                            fontFamily: 'SurahNameV4',
                            fontFeatures: const [FontFeature.enable('liga')],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'surah${(line.surahRef ?? 1).toString().padLeft(3, '0')}',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFF3DA8E) : const Color(0xFF1E1A16),
                            fontSize: 27,
                            height: 1.1,
                            fontFamily: 'SurahNameV4',
                            fontFeatures: const [FontFeature.enable('liga')],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _SurahNameOrnament(color: accent),
                ],
              ),
            ),
          ),
        );
      case 'basmallah':
        ref.watch(mushafPaletteVersionProvider);
        ref.watch(accentColorVersionProvider);
        final userPrefs = ref.watch(userPrefsProvider);
        final isDark = _effectivePaletteIsDark(context, userPrefs);
        final palette = mushafPaletteById(
          userPrefs.mushafPaletteId,
          accentId: userPrefs.accentColorId,
        );
        final fg = palette.fg(isDark);
        final edition = ref.watch(mushafFontEditionProvider);
        final p1FontAsync = ref.watch(pageFontFamilyProvider(1));
        // V4 Tajweed: لا رمز glyph معروف لبسملة مستقلة بهذه الطبعة (سطر
        // البسملة بلا كلمات بتخطيط V4 نفسه — لا مصدر بيانات نستنتج منه
        // الرمز الصحيح، بخلاف V1/V2 يلي رموزهما معروفة يدوياً). نستخدم
        // نص AmiriQuran العادي دايماً بدل تخمين رمز خاطئ.
        final p1FontFamily = edition == MushafFontEdition.v4Tajweed ? null : p1FontAsync.value;
        final basmallahText = p1FontFamily != null
            ? (edition == MushafFontEdition.v1
                ? '\ufb51 \ufb52 \ufb53 \ufb54'
                : 'ﱁ ﱂ ﱃ ﱄ')
            : 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              basmallahText,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: fg,
                fontSize: p1FontFamily != null ? 28 : 21,
                height: 1.0,
                fontFamily: p1FontFamily ?? 'AmiriQuran',
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        );
      case 'ayah':
      default:
        ref.watch(mushafPaletteVersionProvider);
        ref.watch(accentColorVersionProvider);
        final userPrefs = ref.watch(userPrefsProvider);
        final isDark = _effectivePaletteIsDark(context, userPrefs);
        final palette = mushafPaletteById(
          userPrefs.mushafPaletteId,
          accentId: userPrefs.accentColorId,
        );
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
        // تظليل التلاوة الصوتية أو تظليل القفز اليدوي المؤقت (متشابهات) —
        // أيّهما مضبوط يُظهَر بنفس اللون؛ الصوتي أولى لو تعارضا (نادر جداً
        // عملياً: قفز متشابهات أثناء تشغيل صوتي فعلي بنفس اللحظة).
        final highlightAyahId =
            ref.watch(
              quranAudioControllerProvider.select((s) => s.currentAyahId),
            ) ??
            ref.watch(highlightedAyahProvider);
        final memorizationOn = ref.watch(memorizationModeProvider);
        final revealedAyahs = ref.watch(revealedAyahsProvider);
        return Center(
          child: FittedBox(
            fit: isCentered ? BoxFit.scaleDown : BoxFit.fitWidth,
            child: _TappableAyahLine(
              words: words,
              highlightAyahId: highlightAyahId,
              memorizationOn: memorizationOn,
              revealedAyahs: revealedAyahs,
              pickingHifz: pickingHifz,
              noteAyahIds: noteAyahIds,
              noteMarkerColor: themeAccent(context),
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 28,
                color: palette.fg(isDark),
                height: 1,
              ),
            ),
          ),
        );
    }
  }
}

/// نفس نص السطر تماماً (نفس الخط والحجم واللون) — بس مفكّك لـ `TextSpan`
/// لكل كلمة بدل نص واحد متّصل، ليدعم **الضغط المطوّل** على كلمة ففتح شيت
/// إجراءات آيتها (تفسير/تشغيل/نسخ/مشاركة/علامة) — الضغطة العادية مقصودة
/// لتبديل رؤية القوائم العائمة فقط (`mushaf_screen.dart`)، لا لفتح الشيت
/// (بطلب صاحب المشروع صراحة، راجع سجل القرار بتعليق الفرع أسفل). أما
/// وضعا كشف الحفظ/اختيار نطاق الحفظ فيبقيان ضغطة عادية فورية — يُعلِّمان
/// [wordTapConsumedThisGesture] لمنع تعارضهما مع تبديل القوائم بنفس
/// اللمسة (تابَّان متطابقان بنفس السلسلة يتعارضان، بخلاف تاب/ضغط-مطوّل
/// اللذين يتفكّكان طبيعياً بحلبة الإيماءات). **لا يغيّر أي شيء بصري
/// بالخط نفسه**، فقط يضيف كاشف ضغط لكل كلمة.
class _TappableAyahLine extends ConsumerStatefulWidget {
  const _TappableAyahLine({
    required this.words,
    required this.style,
    this.highlightAyahId,
    this.memorizationOn = false,
    this.revealedAyahs = const {},
    this.pickingHifz = false,
    this.noteAyahIds = const {},
    this.noteMarkerColor,
  });
  final List<MushafWord> words;
  final TextStyle style;

  /// معرّفات آيات عليها ملاحظة — تُرسَم علامة صغيرة عند رمز نهاية الآية
  /// لكل واحدة منها (راجع `_notedAyahIdsProvider`).
  final Set<int> noteAyahIds;
  final Color? noteMarkerColor;

  /// معرّف الآية المشغَّلة صوتياً الآن — كلماتها بهالسطر تُلوَّن بخلفية
  /// مميّزة. `null` = لا تظليل (لا تشغيل جارٍ، أو قارئ بلا تقسيم بالآية).
  final int? highlightAyahId;

  /// وضع الحفظ مفعَّل؟ لو نعم، كل كلمة آيتها ليست بـ [revealedAyahs] تُستبدل
  /// بغطاء (■) يكشف آيته بالضغط عليه بدل فتح شيت الإجراءات — راجع
  /// `mushaf_settings.dart`.
  final bool memorizationOn;
  final Set<int> revealedAyahs;

  /// اختيار نطاق حفظ من المصحف نشط (`hifzPickerProvider.active`)؟ لو نعم،
  /// الضغط على كلمة يختار آيتها كطرف نطاق بدل فتح شيت الإجراءات — راجع
  /// `mushaf_settings.dart` (`HifzPickerNotifier.pick`).
  final bool pickingHifz;

  @override
  ConsumerState<_TappableAyahLine> createState() => _TappableAyahLineState();
}

class _TappableAyahLineState extends ConsumerState<_TappableAyahLine> {
  final List<GestureRecognizer> _recognizers = [];

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
    final highlightColor = themeAccent(context).withValues(alpha: 0.22);
    final pendingFrom = widget.pickingHifz
        ? ref.watch(hifzPickerProvider.select((s) => s.pendingFrom))
        : null;
    final pendingColor = AppColors.teal.withValues(alpha: 0.28);
    final spans = <InlineSpan>[];

    for (var i = 0; i < widget.words.length; i++) {
      final word = widget.words[i];
      final isHighlighted =
          widget.highlightAyahId != null &&
          word.ayahId == widget.highlightAyahId;
      final isPendingStart = pendingFrom != null && word.ayahId == pendingFrom;
      final isHidden =
          widget.memorizationOn && !widget.revealedAyahs.contains(word.ayahId);

      // اختيار glyph الطبعة الصحيحة (glyph_v1 لو V1 ومُعبَّأ، وإلا V2) صار
      // مسؤولية `QuranRepository.pageLayout`/`pageLayoutV4` — `word.glyph`
      // هون دايماً الرمز النهائي الجاهز للرسم مباشرة، بلا فرع طبعة هون.
      final glyphText = word.glyph;

      InlineSpan buildWordSpan(GestureRecognizer? recognizer) {
        return TextSpan(
          text: glyphText,
          recognizer: recognizer,
          style: TextStyle(
            backgroundColor: isPendingStart
                ? pendingColor
                : (isHighlighted ? highlightColor : null),
          ),
        );
      }

      if (isHidden) {
        // غطاء بخط النظام العادي لا QCF — الغليف نفسه رمز خاص بخط الصفحة،
        // واستبداله بحرف عادي بنفس الخط ممكن يطلع مربّعاً فارغاً (tofu).
        // الضغط يكشف آية الكلمة كاملة، لا كلمة وحدها — الحفظ باختبار
        // الآية ككل أصح من كشف كلمة كلمة.
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            wordTapConsumedThisGesture = true;
            ref.read(revealedAyahsProvider.notifier).reveal(word.ayahId);
          };
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: '■',
            recognizer: recognizer,
            style: TextStyle(
              fontFamily: null,
              color: widget.style.color?.withValues(alpha: 0.28),
            ),
          ),
        );
      } else if (widget.pickingHifz) {
        // وضع اختيار نطاق الحفظ: يبقى ضغطة عادية فورية (لا مطوّلة) — وضع
        // مقصود مُفعَّل صراحة أصلاً، لا تعارض مع لمسة إخفاء/إظهار القوائم.
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            wordTapConsumedThisGesture = true;
            ref.read(hifzPickerProvider.notifier).pick(word.ayahId);
          };
        _recognizers.add(recognizer);
        spans.add(buildWordSpan(recognizer));
      } else {
        // القراءة العادية: **ضغطة مطوّلة** تفتح شيت إجراءات الآية (تفسير/
        // تشغيل/نسخ/مشاركة/علامة) — بطلب صاحب المشروع صراحة بعد تجربة
        // الضغطة العادية فعلياً: فتحها بسهولة أثناء أي محاولة لمس عادية
        // بالصفحة (لتصفّح/تبديل القوائم) كان مزعجاً أكتر ممّا كان مفيداً.
        // الضغطة العادية على كلمة تبقى بلا أثر خاص بها — تُترك بالكامل
        // لـ`GestureDetector` الأب بـ`mushaf_screen.dart` لتبديل رؤية
        // القوائم العائمة (لا حاجة لـ[wordTapConsumedThisGesture] هون: تاب
        // وضغطة مطوّلة نوعا إيماءة مختلفان يتفكّكان طبيعياً بحلبة الإيماءات
        // حسب مدة الضغط، بخلاف تعارض تابَّين متطابقين بالفرعين أعلاه).
        final recognizer = LongPressGestureRecognizer()
          ..onLongPress = () => AyahActionsSheet.show(context, word.ayahId);
        _recognizers.add(recognizer);
        spans.add(buildWordSpan(recognizer));
      }

      // علامة "عندي ملاحظة" — تُرسَم مباشرة بعد رمز نهاية الآية الزخرفي
      // (`charType == 'ayah_marker'`، عنصر وحيد لكل آية بكامل المصحف) فتظهر
      // بمجرد فتح الصفحة بلا حاجة للضغط عليها. أيقونة بخط النظام لا QCF
      // (نفس سبب غطاء وضع الحفظ أعلاه) — الغليف المخصَّص لا يحوي رمزاً كهذا.
      if (word.charType == 'ayah_marker' &&
          widget.noteAyahIds.contains(word.ayahId)) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: widget.noteMarkerColor ?? widget.style.color,
              ),
            ),
          ),
        );
      }

      if (i != widget.words.length - 1) {
        // نلوّن الفاصلة بلون الكلمة قبلها — يخلّي التظليل شريطاً متّصلاً
        // بدل فجوات بيضاء بين كلمات نفس الآية المشغَّلة.
        spans.add(
          TextSpan(
            text: ' ',
            style: isHighlighted
                ? TextStyle(backgroundColor: highlightColor)
                : null,
          ),
        );
      }
    }
    return Text.rich(
      TextSpan(children: spans, style: widget.style),
      textDirection: TextDirection.rtl,
    );
  }
}

/// عرض بديل لصفحة غير مضمَّنة (٥١-٦٠٤). **الحالة الطبيعية الآن**: التنزيل
/// الكسول بالأولوية (`MushafScreen.requestPageWithPriority`) يبدأ تلقائياً
/// فور فتح هذه الصفحة (أو الاقتراب منها)، فمؤشر خافت بزاوية الشاشة فقط
/// كافٍ (لا شرح/زر يدوي — بلا داعٍ طالما التنزيل جارٍ فعلاً بالخلفية).
/// **الحالة الاستثنائية**: لو لم يبدأ تنزيل تلقائي أصلاً لهذه الصفحة بعد
/// (مثلاً قفزة مباشرة من فهرس/بحث بعيدة عن مدى الأولوية، أو فشل التنزيل
/// التلقائي سابقاً) يظهر الزر اليدوي كخيار احتياطي واضح.
class _PageDownloadPrompt extends ConsumerWidget {
  const _PageDownloadPrompt({required this.page});
  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(fontDownloadControllerProvider);
    final alreadyDownloading = downloadState.isBulkRunning;
    final autoDownloading = downloadState.inFlightPages.contains(page);

    if (autoDownloading) {
      return const Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      );
    }

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
              'خط هذه الصفحة يحتاج تنزيلاً',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('تنزيل هذه الصفحة'),
              onPressed: alreadyDownloading
                  ? null
                  : () async {
                      await ref
                          .read(fontDownloadControllerProvider.notifier)
                          .downloadPage(page);
                      ref.invalidate(pageFontFamilyProvider(page));
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class MushafSurahHeaderPainter extends CustomPainter {
  const MushafSurahHeaderPainter({required this.accent, required this.isDark});
  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    // ألوان فاخرة ومتناسقة تتبع لوحة المصحف والوضع الليلي/النهاري
    final goldMain = isDark
        ? const Color(0xFFD4AF37).withValues(alpha: 0.9)
        : const Color(0xFF9E782F).withValues(alpha: 0.85);
    final goldSoft = isDark
        ? const Color(0xFFC59B27).withValues(alpha: 0.4)
        : const Color(0xFFC59B27).withValues(alpha: 0.35);
    final bgFill = isDark
        ? const Color(0xFF1E2430).withValues(alpha: 0.6)
        : const Color(0xFFF7F3E9).withValues(alpha: 0.8);

    // 1. الإطار الخارجي المنحني بنعومة
    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, w - 2, h - 2),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..color = bgFill
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..color = goldMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // 2. خط داخلي خفيف
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.5, 3.5, w - 7, h - 7),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = goldSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // 3. زخرفة نجمية ثمانية إسلامية رقيقة وناعمة على الجانبين (شمسات مصحف المدينة)
    final sideOffset = (w * 0.08).clamp(24.0, 48.0);
    _drawDelicateStar(canvas, Offset(sideOffset, midY), h * 0.28, goldMain);
    _drawDelicateStar(canvas, Offset(w - sideOffset, midY), h * 0.28, goldMain);

    // 4. خط فاصل زخرفي صغير بجانب النجمتين
    final linePaint = Paint()
      ..color = goldSoft
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(sideOffset + 12, midY),
      Offset(sideOffset + 24, midY),
      linePaint,
    );
    canvas.drawLine(
      Offset(w - sideOffset - 24, midY),
      Offset(w - sideOffset - 12, midY),
      linePaint,
    );
  }

  void _drawDelicateStar(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final starPath = Path();
    const points = 8;
    final innerR = radius * 0.55;
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? radius : innerR;
      final angle = i * (math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    canvas.drawPath(
      starPath,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      starPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // نقطة مركزية
    canvas.drawCircle(
      center,
      1.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant MushafSurahHeaderPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.isDark != isDark;
}

class MushafPageBorderPainter extends CustomPainter {
  const MushafPageBorderPainter({required this.accent, required this.isDark});
  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final primaryColor = isDark
        ? const Color(0xFFD4AF37).withValues(alpha: 0.85)
        : accent.withValues(alpha: 0.8);
    final secondaryColor = isDark
        ? const Color(0xFF8E7026).withValues(alpha: 0.5)
        : accent.withValues(alpha: 0.45);

    const outerMargin = 2.5;
    const innerMargin = 5.5;

    final outerRect = Rect.fromLTWH(
      outerMargin,
      outerMargin,
      size.width - (outerMargin * 2),
      size.height - (outerMargin * 2),
    );
    final innerRect = Rect.fromLTWH(
      innerMargin,
      innerMargin,
      size.width - (innerMargin * 2),
      size.height - (innerMargin * 2),
    );

    // 1. Outer main line
    canvas.drawRect(
      outerRect,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 2. Inner thin line
    canvas.drawRect(
      innerRect,
      Paint()
        ..color = secondaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    // 3. Four Corner Islamic Rosette Knots
    _drawCornerKnot(canvas, Offset(outerMargin + 1.5, outerMargin + 1.5), primaryColor);
    _drawCornerKnot(canvas, Offset(size.width - outerMargin - 1.5, outerMargin + 1.5), primaryColor);
    _drawCornerKnot(canvas, Offset(outerMargin + 1.5, size.height - outerMargin - 1.5), primaryColor);
    _drawCornerKnot(canvas, Offset(size.width - outerMargin - 1.5, size.height - outerMargin - 1.5), primaryColor);
  }

  void _drawCornerKnot(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - 2.5)
      ..lineTo(center.dx + 2.5, center.dy)
      ..lineTo(center.dx, center.dy + 2.5)
      ..lineTo(center.dx - 2.5, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MushafPageBorderPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.isDark != isDark;
}
