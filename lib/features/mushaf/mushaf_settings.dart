import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';

const _kThemeModeKey = 'app_theme_mode'; // 'system' | 'light' | 'dark'

/// وضع الثيم العام للتطبيق — مُحفَّظ بـ`SharedPreferences` (إعداد بسيط،
/// لا بيانات مستخدم، فيبقى هون حسب القرار المعماري #٦ بتصميم-النظام.md
/// بدل `user.db`). كان بلا حفظ إطلاقاً (TODO سابق)؛ انسدّت الفجوة
/// ٢٠٢٦-٠٨-١٩ مع هجرة بيانات المستخدم لـdrift.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_kThemeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void cycle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    set(next);
  }

  /// اختيار مباشر (لا دوري) — تستخدمه شاشة الإعدادات (`SegmentedButton`)
  /// حيث الاختيار المباشر أنسب من التدوير المستخدَم بالمصحف.
  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_kThemeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

const _kMushafFontEditionKey = 'mushaf_font_edition';

/// نوع خط صفحة المصحف / الطبعة:
/// - `v2`: مصحف المدينة الحديث (QCF V2 - الافتراضي)
/// - `v1`: مصحف المدينة الكلاسيكي (QCF V1 طبعة 1405هـ من fadihittih repo)
/// - `v4Tajweed`: مصحف المدينة طبعة ١٤٤١هـ (خط عثمان طه) بألوان تجويد
///   مدمجة داخل الglyph نفسه من مصدر QUL (Tarteel AI، ترخيص SIL OFL) —
///   راجع `PageLinesV4`/`WordsV4` بـ`quran_tables.dart` وتوثيق
///   `tools/add_qcf_v4_tajweed.py`. تخطيط صفحات/أسطر **مستقل تماماً** عن
///   V1/V2 (طبعة مطبوعة مختلفة)، فلا يشارك ترقيمها إطلاقاً.
enum MushafFontEdition {
  // ترتيب الإعلان هون هو ترتيب ظهورها فعلياً بـ`SegmentedButton` بشاشة
  // الإعدادات (`_MushafFontEditionSection` بـ`settings_screen.dart` تكرّر
  // `MushafFontEdition.values` مباشرة) — v1 ثم v2 ثم v4Tajweed بطلب صاحب
  // المشروع، لا علاقة له بـ`.name` المخزَّن بـSharedPreferences (يعتمد
  // اسم الحالة نفسه لا ترتيبها، فإعادة الترتيب هون آمنة بلا أي هجرة).
  v1(label: 'مصحف المدينة (الكلاسيكي 1405هـ)'),
  v2(label: 'مصحف المدينة (الحديث 1422هـ)'),
  v4Tajweed(label: 'مصحف المدينة الملوّن (تجويد 1441هـ)');

  const MushafFontEdition({required this.label});
  final String label;
}

class MushafFontEditionNotifier extends Notifier<MushafFontEdition> {
  @override
  MushafFontEdition build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        .getString(_kMushafFontEditionKey);
    return switch (raw) {
      'v1' => MushafFontEdition.v1,
      _ => MushafFontEdition.v2,
    };
  }

  void set(MushafFontEdition edition) {
    state = edition;
    ref
        .read(sharedPreferencesProvider)
        .setString(_kMushafFontEditionKey, edition.name);
  }
}

final mushafFontEditionProvider =
    NotifierProvider<MushafFontEditionNotifier, MushafFontEdition>(
      MushafFontEditionNotifier.new,
    );

/// درجات حجم خط المصحف. التخطيط بخط QCF يملأ عرض السطر دايماً (`FittedBox`
/// بـ `fitWidth`) فلا معنى لرقم بكسل مباشر؛ نتحكم بالحجم عبر الهامش الجانبي
/// (هامش أقل ⇐ عرض أوسع للسطر ⇐ خط أكبر بصرياً). **٥ درجات** (كانت ٣) —
/// بطلب صاحب المشروع "اكتر عشان المستخدم يختار اللي بناسبه"؛ `smallest`/
/// `largest` جديدتان تحيطان بالثلاث الأصليتين (`small`/`medium`/`large`
/// أُبقيت بنفس قيمها بالضبط لتفادي تغيير تجربة من اعتاد عليها).
enum MushafTextSize {
  smallest(horizontalPadding: 40),
  small(horizontalPadding: 28),
  medium(horizontalPadding: 12),
  large(horizontalPadding: 2),
  largest(horizontalPadding: 0);

  const MushafTextSize({required this.horizontalPadding});
  final double horizontalPadding;

  /// دوري عبر كل الدرجات بالترتيب (لا سلسلة `switch` يدوية) — يبقى صحيحاً
  /// تلقائياً لو أُضيفت درجات جديدة لاحقاً بدل تحديثه يدوياً بكل مرة.
  MushafTextSize get next {
    final values = MushafTextSize.values;
    return values[(index + 1) % values.length];
  }
}

class MushafTextSizeNotifier extends Notifier<MushafTextSize> {
  @override
  MushafTextSize build() => MushafTextSize.medium;

  void cycle() => state = state.next;
}

final mushafTextSizeProvider =
    NotifierProvider<MushafTextSizeNotifier, MushafTextSize>(
      MushafTextSizeNotifier.new,
    );

/// وضع الحفظ: يخفي كل سطور الآيات خلف غطاء، وتُكشَف آية واحدة بالضغط
/// عليها (نفس الغليفات الحقيقية المرسومة أصلاً — لا نص بديل ولا تخمين).
/// حالة جلسة فقط، لا تُحفظ بين تشغيلات التطبيق.
class MemorizationModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
    if (!state) ref.read(revealedAyahsProvider.notifier).hideAll();
  }
}

final memorizationModeProvider =
    NotifierProvider<MemorizationModeNotifier, bool>(
      MemorizationModeNotifier.new,
    );

/// معرّفات الآيات المكشوفة حالياً بوضع الحفظ (تُصفَّر عند إيقاف الوضع أو
/// عند الضغط على "إخفاء الكل").
class RevealedAyahsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void reveal(int ayahId) => state = {...state, ayahId};

  void hideAll() => state = const {};
}

final revealedAyahsProvider = NotifierProvider<RevealedAyahsNotifier, Set<int>>(
  RevealedAyahsNotifier.new,
);

/// حالة "اختيار نطاق آيات للحفظ من المصحف" — جلسة فقط (لا تُحفظ)، تُفعَّل
/// حين تُفتح `MushafScreen(pickingHifzRange: true)` من `HifzScreen`
/// (`activate`/`deactivate` بـ`initState`/`dispose`). لمّا [active]، الضغط
/// على كلمة بالمصحف (`mushaf_page_widget.dart`) يستدعي [pick] بدل فتح
/// شيت إجراءات الآية — نفس نمط `memorizationModeProvider` بالضبط، فرع
/// جديد مستقل لا إعادة كتابة لذاك الوضع. أول ضغطة تحدّد البداية، والثانية
/// تملأ `completedFrom`/`completedTo` (مرتَّبين بصرف النظر عن ترتيب
/// الضغط) — `MushafScreen` يستمع لهما (`ref.listen`) ليُرجِعهما عبر
/// `Navigator.pop`.
class HifzPickerState {
  const HifzPickerState({
    this.active = false,
    this.pendingFrom,
    this.completedFrom,
    this.completedTo,
  });
  final bool active;
  final int? pendingFrom;
  final int? completedFrom;
  final int? completedTo;
}

class HifzPickerNotifier extends Notifier<HifzPickerState> {
  @override
  HifzPickerState build() => const HifzPickerState();

  void activate() => state = const HifzPickerState(active: true);
  void deactivate() => state = const HifzPickerState(active: false);

  void pick(int ayahId) {
    final pending = state.pendingFrom;
    if (pending == null) {
      state = HifzPickerState(active: true, pendingFrom: ayahId);
      return;
    }
    final from = pending <= ayahId ? pending : ayahId;
    final to = pending <= ayahId ? ayahId : pending;
    state = HifzPickerState(
      active: true,
      pendingFrom: pending,
      completedFrom: from,
      completedTo: to,
    );
  }
}

final hifzPickerProvider =
    NotifierProvider<HifzPickerNotifier, HifzPickerState>(
      HifzPickerNotifier.new,
    );

/// رؤية شريطَي المصحف العائمين (`_TopChromeBar`/`_BottomChromeBar` بـ
/// `mushaf_screen.dart`) — **مرفوعة هون** (لا حالة محلية بالشاشة) لأن
/// `RootShell` يحتاج قراءتها أيضاً: الشريط السفلي لتبويبات التطبيق
/// (الرئيسية/المصحف/الصلاة/الأذكار/المزيد) كان يبقى ظاهراً دائماً فوق
/// شريط المصحف حتى بعد إخفاء الأخير باللمس — بقية "قائمة سفلية" لا تختفي
/// رغم أن شريطَي المصحف نفسيهما يختفيان (باج حقيقي رُصد على الجهاز
/// الفعلي). `RootShell` يخفي شريط تبويباته أيضاً حين هذا `false` **وفقط**
/// حين تبويب المصحف نشط (راجع `root_shell.dart`).
class MushafChromeVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final mushafChromeVisibleProvider =
    NotifierProvider<MushafChromeVisibleNotifier, bool>(
      MushafChromeVisibleNotifier.new,
    );

/// طلب قفز لصفحة/آية معيّنة من مكان لا يملك مرجعاً مباشراً لـ`MushafScreen`
/// المفتوحة أصلاً (شيت إجراءات آية، شيت متشابهات...) — نفس فكرة
/// `hifzPickerProvider` بلا مرجع ودجت مباشر، `MushafScreen` تراقبه
/// (`ref.listen`) وتنفّذ القفز الفعلي بنفسها (`_jumpTo`)، بالضبط نفس نمط
/// `_followAudioToAyah`. `request` تزيد عدّاداً داخلياً حتى يختلف كل طلب
/// عن سابقه ولو كانت نفس الصفحة/الآية (وإلا `ref.listen` لا يُطلَق ثانية
/// لنفس القيمة).
typedef MushafJumpRequest = ({int page, int ayahId, int nonce});

class MushafJumpRequestNotifier extends Notifier<MushafJumpRequest?> {
  int _nonce = 0;

  @override
  MushafJumpRequest? build() => null;

  void request({required int page, required int ayahId}) {
    _nonce++;
    state = (page: page, ayahId: ayahId, nonce: _nonce);
  }
}

final mushafJumpRequestProvider =
    NotifierProvider<MushafJumpRequestNotifier, MushafJumpRequest?>(
      MushafJumpRequestNotifier.new,
    );

/// تظليل مؤقّت لآية وصلناها بقفز يدوي (متشابهات مثلاً) — مستقل تماماً عن
/// تظليل التلاوة الصوتية (`quranAudioControllerProvider.currentAyahId`).
/// `MushafScreen` يمسحه تلقائياً بعد مهلة قصيرة أو عند أي تغيير صفحة يدوي
/// لاحق (`_onPageChanged`) — راجع توثيق [MushafJumpRequestNotifier].
class HighlightedAyahNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? ayahId) => state = ayahId;
}

final highlightedAyahProvider = NotifierProvider<HighlightedAyahNotifier, int?>(
  HighlightedAyahNotifier.new,
);

/// جلسة "تتبّع قيام الليل" — تُفعَّل بزر "ابدأ قيام" بـ`qiyam_screen.dart`
/// (`MushafScreen(qiyamSessionMode: true)`)، جلسة فقط (لا تُحفظ بين
/// تشغيلات التطبيق، خلافاً للعدّاد التراكمي `QiyamAyahLog` بـ`user.db`
/// الذي تُحدَّثه هذه الجلسة عند إنهائها). نفس فكرة `hifzPickerProvider`/
/// `memorizationModeProvider`: حالة مرفوعة يقرأها/يعدّلها أكثر من ودجت
/// بلا مرجع مباشر لبعضها (`MushafScreen` تسجّل الآيات، `QiyamScreen` تعرض
/// الملخّص النهائي بعد الإغلاق).
class QiyamSessionState {
  const QiyamSessionState({this.active = false, this.seenAyahIds = const {}});
  final bool active;
  final Set<int> seenAyahIds;

  int get ayahCount => seenAyahIds.length;
}

class QiyamSessionNotifier extends Notifier<QiyamSessionState> {
  @override
  QiyamSessionState build() => const QiyamSessionState();

  void start() => state = const QiyamSessionState(active: true);

  /// يسجّل آيات صفحة زارها المستخدم أثناء الجلسة — مجموعة (`Set`) لا عدّاد
  /// تراكمي بسيط، فإعادة زيارة نفس الصفحة (تصفّح للخلف مثلاً) لا تُحتسَب مرتين.
  void recordAyahs(Iterable<int> ayahIds) {
    if (!state.active) return;
    state = QiyamSessionState(
      active: true,
      seenAyahIds: {...state.seenAyahIds, ...ayahIds},
    );
  }

  /// ينهي الجلسة ويعيد عدد الآيات النهائي — لا يُصفِّر الحالة فوراً
  /// (`QiyamScreen` قد تحتاج القراءة بعد `pop` مباشرة)، `reset` منفصلة.
  int end() => state.ayahCount;

  void reset() => state = const QiyamSessionState();
}

final qiyamSessionProvider =
    NotifierProvider<QiyamSessionNotifier, QiyamSessionState>(
      QiyamSessionNotifier.new,
    );

// ملاحظة: `tajweedModeProvider`/`TajweedModeNotifier` (سويتش "تلوين أحكام
// التجويد تلقائياً" القديم) حُذف — كان مرتبطاً بمحرك تلوين حرفي وقت
// التشغيل (`TajweedTextParser`، محذوف أيضاً) لم يكن مربوطاً أصلاً بصفحة
// المصحف الحية. التلوين الفعلي الآن عبر طبعة خط V4 Tajweed (ألوان مدمجة
// بالglyph نفسه، لا سويتش — راجع `MushafFontEdition.v4Tajweed`).

const _kTafsirFontSizeKey = 'tafsir_font_size_sp';

/// حجم خط التفسير/الأحاديث/الترجمة، وكذلك **نص القرآن نفسه** بشاشة "قراءة
/// مع التفسير" (`tafsir_reading_screen.dart` — نص متدفّق عادي لا صفحة
/// مصحف بتخطيط ثابت، فتكبير خطه لا يكسر أي محاذاة). الحدّ الأقصى مرفوع
/// لـ٣٤ (كان ٢٨) بطلب "وضع قراءة بخط أكبر لكبار السن/ضعاف البصر" — هامش
/// حقيقي إضافي فوق حجم خط النظام العام.
class TafsirFontSizeNotifier extends Notifier<double> {
  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble(_kTafsirFontSizeKey) ?? 16.0;
  }

  void setSize(double size) {
    final clamped = size.clamp(13.0, 34.0);
    state = clamped;
    ref.read(sharedPreferencesProvider).setDouble(_kTafsirFontSizeKey, clamped);
  }
}

final tafsirFontSizeProvider = NotifierProvider<TafsirFontSizeNotifier, double>(
  TafsirFontSizeNotifier.new,
);

const _kReadingTafsirEditionKey = 'reading_tafsir_edition';

/// إصدار التفسير المختار بشاشة "قراءة مع التفسير" (`tafsir_reading_screen.dart`
/// — تمرير طولي متواصل داخل سورة واحدة). محفوظ بين التشغيلات، يبدأ
/// افتراضياً بـ"المختصر في التفسير" (نفس افتراض اللوح المضمَّن السابق
/// المحذوف).
class ReadingTafsirEditionNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_kReadingTafsirEditionKey) ?? 'mukhtasar';
  }

  void set(String edition) {
    state = edition;
    ref
        .read(sharedPreferencesProvider)
        .setString(_kReadingTafsirEditionKey, edition);
  }
}

final readingTafsirEditionProvider =
    NotifierProvider<ReadingTafsirEditionNotifier, String>(
      ReadingTafsirEditionNotifier.new,
    );
