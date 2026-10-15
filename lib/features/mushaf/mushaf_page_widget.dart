
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

/// آية → لون تصنيفها (راجع `AyahColorTags`/`kMarkerMeta` بـ
/// `ayah_actions_sheet.dart`) — بطلب صريح "نظام تصنيف ملوَّن يسع أكثر من
/// آية لكل لون". قراءة مباشرة (لا `Future` حقيقي، `colorTagsForAyah`
/// بالذاكرة أصلاً) لكن `Provider` عادي كافٍ — مصدر واحد يُبنى مرة واحدة
/// لكل صفحة بدل تكرار المنطق بكل سطر. لو تعدَّدت تصنيفات نفس الآية، يفوز
/// أول نوع بترتيب `kMarkerMeta` (لا مزج ألوان — أبسط بصرياً).
final _ayahColorTagMapProvider = Provider<Map<int, Color>>((ref) {
  ref.watch(ayahColorTagVersionProvider);
  final prefs = ref.watch(userPrefsProvider);
  final map = <int, Color>{};
  for (final entry in kMarkerMeta.entries.toList().reversed) {
    for (final ayahId in prefs.ayahColorTagsFor(entry.key)) {
      map[ayahId] = entry.value.color;
    }
  }
  return map;
});

/// رسم صفحة مصحف واحدة: يحمّل تخطيطها وخطها الخاص (`p{page}.ttf`)، ثم
/// يرسم أسطرها الخمسة عشر بالترتيب. حالة تحميل/خطأ مستقلة عن باقي التطبيق.
class MushafPageWidget extends ConsumerWidget {
  const MushafPageWidget({
    super.key,
    required this.page,
  });
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
    final ayahTagColors = ref.watch(_ayahColorTagMapProvider);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    ref.watch(mushafPaletteVersionProvider);
    ref.watch(accentColorVersionProvider);
    final userPrefs = ref.watch(userPrefsProvider);

    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        textSize.horizontalPadding,
        4,
        textSize.horizontalPadding,
        2,
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
                ayahTagColors: ayahTagColors,
              ),
            ),
        ],
      ),
    );

    // "المصحف الليلي"
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



class _PageLineWidget extends ConsumerWidget {
  const _PageLineWidget({
    required this.line,
    required this.words,
    required this.fontFamily,
    this.pickingHifz = false,
    this.noteAyahIds = const {},
    this.ayahTagColors = const {},
  });
  final MushafPageLineInfo line;
  final List<MushafWord> words;
  final String fontFamily;
  final bool pickingHifz;

  /// معرّفات آيات عليها ملاحظة — راجع `_notedAyahIdsProvider` أعلى الملف.
  final Set<int> noteAyahIds;

  /// آية → لون تصنيفها — راجع `_ayahColorTagMapProvider` أعلى الملف.
  final Map<int, Color> ayahTagColors;

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
        // ترويسة اسم السورة المطابقة تماماً لمصحف المدينة المنورة (مجمع الملك فهد):
        // شريط زخرفي مذهب مع خرطوشة اسم السورة وجناحين زخرفيين بشموس إسلامية وتوريق نباتي
        return Semantics(
          label: nameAsync.value,
          child: MadinahSurahHeaderBanner(
            surahNumber: line.surahRef ?? 1,
            surahName: nameAsync.value ?? '',
            accent: accent,
            isDark: isDark,
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
        final p1FontFamily = p1FontAsync.value;
        final String basmallahText;
        if (p1FontFamily != null) {
          switch (edition) {
            case MushafFontEdition.v1:
              basmallahText = '\ufb51 \ufb52 \ufb53 \ufb54';
              break;
            case MushafFontEdition.v4Tajweed:
              basmallahText = '\ufc41 \ufc42 \ufc43 \ufc44';
              break;
            case MushafFontEdition.v2:
              basmallahText = 'ﱁ ﱂ ﱃ ﱄ';
              break;
          }
        } else {
          basmallahText = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';
        }

        final basmallahFontSize = (line.page <= 2) ? 36.0 : (p1FontFamily != null ? 30.0 : 23.0);
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              basmallahText,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: fg,
                fontSize: basmallahFontSize,
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
        final baseFontSize = (line.page <= 2) ? 35.0 : 28.0;
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
              ayahTagColors: ayahTagColors,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: baseFontSize,
                color: palette.fg(isDark),
                height: 1.22,
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
    this.ayahTagColors = const {},
  });
  final List<MushafWord> words;
  final TextStyle style;

  /// آية → لون تصنيفها — راجع `_ayahColorTagMapProvider` أعلى الملف. خلفية
  /// دائمة (بلا انتظار تشغيل صوتي أو قفز مؤقت)، أضعف شفافية من
  /// [highlightAyahId] (`0.22`) كي لا تطغى على التمييز اللحظي لو تصادفا
  /// بنفس الآية.
  final Map<int, Color> ayahTagColors;

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
    final highlightColor = themeAccent(context).withValues(alpha: 0.28);
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
      // لون التصنيف الدائم لهذه الآية (لو مصنَّفة) — يُعرَض فقط لو ما في
      // تظليل لحظي أقوى (تشغيل/قفز) أو بداية اختيار نطاق حفظ فوقه، بنفس
      // ترتيب أولوية `buildWordSpan` أدناه.
      final tagColor = widget.ayahTagColors[word.ayahId];
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
                : (isHighlighted
                      ? highlightColor
                      : (tagColor?.withValues(alpha: 0.22))),
          ),
        );
      }

      if (isHidden) {
        // غطاء ناعم وأنيق يحفظ تناسق واصطفاف أسطر المصحف بالكامل:
        // نستخدم نفس الغليف الأصلي [glyphText] مع تعتيمه كحجاب خفيف
        // واللمسة الواحدة تكشف الآية بأكملها بسلاسة تامة.
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            wordTapConsumedThisGesture = true;
            ref.read(revealedAyahsProvider.notifier).reveal(word.ayahId);
          };
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: glyphText,
            recognizer: recognizer,
            style: TextStyle(
              color: (widget.style.color ?? Colors.black).withValues(alpha: 0.04),
              backgroundColor: (widget.style.color ?? Colors.black).withValues(alpha: 0.12),
            ),
          ),
        );
      } else if (widget.memorizationOn) {
        // الآية مكشوفة في وضع الحفظ: لمسة تعيد إخفاءها للاختبار والتكرار
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            wordTapConsumedThisGesture = true;
            ref.read(revealedAyahsProvider.notifier).hide(word.ayahId);
          };
        _recognizers.add(recognizer);
        spans.add(buildWordSpan(recognizer));
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
                : (tagColor != null
                      ? TextStyle(backgroundColor: tagColor.withValues(alpha: 0.22))
                      : null),
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

class MadinahSurahHeaderBanner extends StatelessWidget {
  const MadinahSurahHeaderBanner({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.accent,
    required this.isDark,
  });

  final int surahNumber;
  final String surahName;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35.0,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: CustomPaint(
        painter: MadinahSurahBannerPainter(
          accent: accent,
          isDark: isDark,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'surah-icon',
                style: const TextStyle(
                  color: Color(0xFFFFDF7D),
                  fontSize: 22.5,
                  height: 1.05,
                  fontFamily: 'SurahNameV4',
                  fontFeatures: [FontFeature.enable('liga')],
                  shadows: [
                    Shadow(
                      color: Color(0x99D4AF37),
                      blurRadius: 4.0,
                      offset: Offset(0, 0.5),
                    ),
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 2.0,
                      offset: Offset(0, 1.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'surah${surahNumber.toString().padLeft(3, '0')}',
                style: const TextStyle(
                  color: Color(0xFFFFDF7D),
                  fontSize: 22.5,
                  height: 1.05,
                  fontFamily: 'SurahNameV4',
                  fontFeatures: [FontFeature.enable('liga')],
                  shadows: [
                    Shadow(
                      color: Color(0x99D4AF37),
                      blurRadius: 4.0,
                      offset: Offset(0, 0.5),
                    ),
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 2.0,
                      offset: Offset(0, 1.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MadinahSurahBannerPainter extends CustomPainter {
  const MadinahSurahBannerPainter({required this.accent, required this.isDark});
  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    // الخيار C: الشريط المحرابي الأندلسي الفخم (Andalusian Mihrab Arch)
    // خلفية زمردية ملكية مع إطار مذهب وخرطوشة محرابية أندلسية وخط بماء الذهب
    final goldBright = const Color(0xFFFFDF7D);
    final goldMain = isDark ? const Color(0xFFE5C158) : const Color(0xFFD4AF37);
    final goldSoft = isDark
        ? const Color(0xFFD4AF37).withValues(alpha: 0.45)
        : const Color(0xFFC59B27).withValues(alpha: 0.45);

    // التدرج الزمردي الملكي لشريط السورة
    final emeraldGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [
              Color(0xFF0C241A),
              Color(0xFF143B2B),
              Color(0xFF081C14),
            ]
          : const [
              Color(0xFF0F3224),
              Color(0xFF184A37),
              Color(0xFF0C271C),
            ],
    );

    // أرضية الخرطوشة المحرابية المركزية (عمق زمردي مخملي ليبرز الخط الذهبي)
    final cartoucheFill = isDark ? const Color(0xFF05130D) : const Color(0xFF071B12);

    // 1. الإطار الخارجي العام للشريط مع خلفية زمردية فاخرة
    final outerRect = Rect.fromLTWH(0.8, 0.8, w - 1.6, h - 1.6);
    final outerRRect = RRect.fromRectAndRadius(
      outerRect,
      const Radius.circular(4.5),
    );

    // رسم الخلفية الزمردية الملكية بتدرج ناعم
    canvas.drawRRect(
      outerRRect,
      Paint()
        ..shader = emeraldGradient.createShader(outerRect)
        ..style = PaintingStyle.fill,
    );

    // الإطار الخارجي المذهب
    canvas.drawRRect(
      outerRRect,
      Paint()
        ..color = goldMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05,
    );

    // خط داخلي شعري مذهب
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2.6, 2.6, w - 5.2, h - 5.2),
      const Radius.circular(3.0),
    );
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = goldSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55,
    );

    // 2. الخرطوشة المحرابية الأندلسية المركزية (Mihrab Cartouche)
    // قوس محرابي مدبب بنهايات حدوة حصان أندلسية رشيقة
    final cartoucheHalfW = (w * 0.245).clamp(78.0, 112.0);
    final cLeft = w / 2 - cartoucheHalfW;
    final cRight = w / 2 + cartoucheHalfW;
    final topY = 2.6;
    final botY = h - 2.6;
    const cuspDepth = 9.0;

    final mihrabPath = Path();
    mihrabPath.moveTo(cLeft, topY);

    // الحافة العلوية مع قمة محرابية مدببة رقيقة في المنتصف
    mihrabPath.lineTo(w / 2 - 14, topY);
    mihrabPath.quadraticBezierTo(w / 2 - 5, topY - 1.2, w / 2, topY - 1.8);
    mihrabPath.quadraticBezierTo(w / 2 + 5, topY - 1.2, w / 2 + 14, topY);
    mihrabPath.lineTo(cRight, topY);

    // القوس المحرابي الأيمن (نهاية حدوة حصان أندلسية مدببة Cusp)
    mihrabPath.cubicTo(
      cRight + 2.0, topY + 4.0,
      cRight + 5.5, midY - 4.5,
      cRight + cuspDepth, midY,
    );
    mihrabPath.cubicTo(
      cRight + 5.5, midY + 4.5,
      cRight + 2.0, botY - 4.0,
      cRight, botY,
    );

    // الحافة السفلية مع قمة محرابية مماثلة
    mihrabPath.lineTo(w / 2 + 14, botY);
    mihrabPath.quadraticBezierTo(w / 2 + 5, botY + 1.2, w / 2, botY + 1.8);
    mihrabPath.quadraticBezierTo(w / 2 - 5, botY + 1.2, w / 2 - 14, botY);
    mihrabPath.lineTo(cLeft, botY);

    // القوس المحرابي الأيسر
    mihrabPath.cubicTo(
      cLeft - 2.0, botY - 4.0,
      cLeft - 5.5, midY + 4.5,
      cLeft - cuspDepth, midY,
    );
    mihrabPath.cubicTo(
      cLeft - 5.5, midY - 4.5,
      cLeft - 2.0, topY + 4.0,
      cLeft, topY,
    );
    mihrabPath.close();

    // ملء أرضية الخرطوشة المحرابية بالعمق المخملي
    canvas.drawPath(
      mihrabPath,
      Paint()
        ..color = cartoucheFill
        ..style = PaintingStyle.fill,
    );

    // تحديد حد المحراب المذهب
    canvas.drawPath(
      mihrabPath,
      Paint()
        ..color = goldMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95,
    );

    // حبات لؤلؤية ذهبية عند رؤوس المحراب الأربعة
    final pearlPaint = Paint()
      ..color = goldBright
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cRight + cuspDepth, midY), 1.2, pearlPaint);
    canvas.drawCircle(Offset(cLeft - cuspDepth, midY), 1.2, pearlPaint);
    canvas.drawCircle(Offset(w / 2, topY - 1.2), 1.0, pearlPaint);
    canvas.drawCircle(Offset(w / 2, botY + 1.2), 1.0, pearlPaint);

    // 3. الزخارف الجانبية الأندلسية (شمسيات قصر الحمراء والأرابيسك في الجناحين)
    final leftWingCenter = (4.0 + (cLeft - cuspDepth)) / 2;
    final rightWingCenter = ((cRight + cuspDepth) + (w - 4.0)) / 2;
    final starRadius = (h * 0.28).clamp(7.0, 9.5);

    _drawAndalusianStar(canvas, Offset(leftWingCenter, midY), starRadius, goldMain, goldBright, goldSoft);
    _drawAndalusianStar(canvas, Offset(rightWingCenter, midY), starRadius, goldMain, goldBright, goldSoft);

    // نقوش هندسية وتوريق أندلسي ممتد في الجناحين
    _drawAndalusianArabesque(canvas, 4.0, cLeft - cuspDepth, midY, h, goldSoft, goldBright);
    _drawAndalusianArabesque(canvas, cRight + cuspDepth, w - 4.0, midY, h, goldSoft, goldBright);

    // منمنمات أركان الشريط
    _drawCornerAccents(canvas, w, h, goldMain);
  }

  /// نجمة قصر الحمراء الثمانية (Moorish 8-pointed star) مع حلقة شمسية وجوهرة مركزية
  void _drawAndalusianStar(
    Canvas canvas,
    Offset center,
    double radius,
    Color goldMain,
    Color goldBright,
    Color goldSoft,
  ) {
    final fillPaint = Paint()
      ..color = goldMain.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = goldMain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;

    final starPath = Path();
    const points = 8;
    final innerR = radius * 0.52;
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

    canvas.drawPath(starPath, fillPaint);
    canvas.drawPath(starPath, strokePaint);

    // حلقة داخلية مذهبة
    canvas.drawCircle(
      center,
      radius * 0.44,
      Paint()
        ..color = goldSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // جوهرة مركزية ساطعة
    canvas.drawCircle(
      center,
      1.5,
      Paint()
        ..color = goldBright
        ..style = PaintingStyle.fill,
    );

    // حبيبات ذهبية عند الرؤوس الأساسية
    final dotPaint = Paint()
      ..color = goldBright.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final dx = center.dx + (radius + 2.0) * math.cos(angle);
      final dy = center.dy + (radius + 2.0) * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 0.75, dotPaint);
    }
  }

  /// تموجات أرابيسك وتوريق نباتي أندلسي ممتد في الجناحين
  void _drawAndalusianArabesque(
    Canvas canvas,
    double xStart,
    double xEnd,
    double midY,
    double h,
    Color color,
    Color goldBright,
  ) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    final cx = (xStart + xEnd) / 2;
    final halfLen = (xEnd - xStart).abs() / 2;

    if (halfLen < 12) return;

    // خط المحور الرابط
    canvas.drawLine(
      Offset(cx - halfLen * 0.78, midY),
      Offset(cx - halfLen * 0.42, midY),
      linePaint,
    );
    canvas.drawLine(
      Offset(cx + halfLen * 0.42, midY),
      Offset(cx + halfLen * 0.78, midY),
      linePaint,
    );

    // أقواس توريق علوية وسفلية رشيقة
    final pTop = Path()
      ..moveTo(cx - halfLen * 0.65, midY)
      ..quadraticBezierTo(cx - halfLen * 0.32, midY - h * 0.25, cx, midY - h * 0.25)
      ..quadraticBezierTo(cx + halfLen * 0.32, midY - h * 0.25, cx + halfLen * 0.65, midY);
    canvas.drawPath(pTop, linePaint);

    final pBottom = Path()
      ..moveTo(cx - halfLen * 0.65, midY)
      ..quadraticBezierTo(cx - halfLen * 0.32, midY + h * 0.25, cx, midY + h * 0.25)
      ..quadraticBezierTo(cx + halfLen * 0.32, midY + h * 0.25, cx + halfLen * 0.65, midY);
    canvas.drawPath(pBottom, linePaint);

    // حبيبات ذهبية متلألئة على قمم التوريق
    final dotPaint = Paint()
      ..color = goldBright
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, midY - h * 0.25), 1.0, dotPaint);
    canvas.drawCircle(Offset(cx, midY + h * 0.25), 1.0, dotPaint);
    canvas.drawCircle(Offset(cx - halfLen * 0.78, midY), 0.8, dotPaint);
    canvas.drawCircle(Offset(cx + halfLen * 0.78, midY), 0.8, dotPaint);
  }

  void _drawCornerAccents(Canvas canvas, double w, double h, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const arm = 4.6;
    canvas.drawCircle(const Offset(arm, arm), 1.1, paint);
    canvas.drawCircle(Offset(w - arm, arm), 1.1, paint);
    canvas.drawCircle(Offset(arm, h - arm), 1.1, paint);
    canvas.drawCircle(Offset(w - arm, h - arm), 1.1, paint);
  }

  @override
  bool shouldRepaint(covariant MadinahSurahBannerPainter oldDelegate) =>
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
