import 'package:drift/drift.dart';

/// علامات مرجعية على آيات. `label`/`folderId` غير مستخدَمين بالواجهة بعد
/// (مجلدات العلامات ميزة مستقبلية بوثيقة التصميم §٢.٢) — الأعمدة موجودة
/// الآن لتفادي هجرة مخطط لاحقة عند إضافتها.
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer().unique()();
  IntColumn get folderId => integer().nullable()();
  TextColumn get label => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// صف وحيد ثابت (id=1): آخر صفحة قراءة وسلسلة الأيام المتتالية.
class ReadingProgress extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get lastPage => integer().nullable()();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  TextColumn get streakLastDay => text().nullable()(); // yyyy-mm-dd محلي

  @override
  Set<Column> get primaryKey => {id};
}

/// خطط الختمة — **أكثر من صف `active=true` ممكن بنفس الوقت** (تعدّد خطط
/// متعمَّد، راجع توثيق `KhatmaPlan` بـ`user_repository.dart`)، نفس مبدأ
/// [HifzPlans] بالضبط. `active=false` = خطة أُلغيت صراحة، لا تُقرأ ثانية
/// بـ[UserRepository.preload].
class KhatmaPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get targetDays => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  // `startPage`/`currentPage` (schemaVersion 12) — تتبّع تقدّم **مستقل لكل
  // خطة** عن `ReadingProgress.lastPage` العام، بطلب صاحب المشروع صراحة:
  // خطة الختمة تبدأ من نقطة يختارها المستخدم (لا بالضرورة صفحة ١)
  // و"التقدّم يكون مختلف عن التقدّم الحالي" — نفس مبدأ `HifzPlan.
  // currentAyahId` بالضبط. الافتراضي ١ لصفوف الترقية القديمة (خطط بدأت
  // قبل هذا العمود، لا معلومة حقيقية عن نقطة بدايتها الفعلية)، تُصحَّح
  // بعملية ترحيل تُطابق `currentPage` مع `lastReadPage` وقت الترقية —
  // راجع `user_database.dart` (`onUpgrade`, `from < 12`).
  IntColumn get startPage => integer().withDefault(const Constant(1))();
  IntColumn get currentPage => integer().withDefault(const Constant(1))();
}

/// صف وحيد ثابت: القارئ وسرعة التشغيل المفضّلان.
class AudioSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get reciterId => text().withDefault(const Constant('husary'))();
  RealColumn get speed => real().withDefault(const Constant(1.0))();

  /// وضع "سماع مباشر" (بث بلا تحميل) — يتجاهل `QuranAudioController` أي
  /// ملف محلي منزَّل ويشغّل رابط كل آية/سورة مباشرة دائماً حين مفعَّل، راجع
  /// `quran_audio_bar.dart`/`audio_downloads_screen.dart`.
  BoolColumn get liveListenEnabled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// صف وحيد ثابت: موقع حساب مواقيت الصلاة/القبلة وطريقة الحساب.
class LocationSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();
  TextColumn get cityName => text().nullable()();
  TextColumn get calcMethod =>
      text().withDefault(const Constant('ummAlQura'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// صف وحيد ثابت: عدّاد المسبحة الإلكترونية المحفوظ بين التشغيلات.
class TasbihCounter extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get count => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// سلسلة استمرار مستقلة لكل نشاط عبادي (صف واحد لكل `category`) — بديل
/// عمود `ReadingProgress.streakDays` الوحيد اللي كان يخلط كل الأنشطة
/// بعدّاد واحد. القيم المعتمَدة حالياً (راجع `UserCategories` بـ
/// `user_repository.dart`): `morning_azkar`، `evening_azkar`، `hifz`،
/// `night_azkar`، `qiyam`. **"الورد اليومي" ليس هون** — يبقى مخزَّناً
/// بـ`ReadingProgress.streakDays` القديم عمداً (لا داعي لهجرة بيانات
/// موجودة فعلاً)، راجع تعليق `UserCategories.dailyWird`.
class CategoryStreaks extends Table {
  TextColumn get category => text()();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  TextColumn get streakLastDay => text().nullable()(); // yyyy-mm-dd محلي

  @override
  Set<Column> get primaryKey => {category};
}

/// أقسام مفضَّلة من مكتبة حصن المسلم (`azkar_full_repository.dart`) —
/// `categoryId` يطابق `AzkarLibraryCategory.id` (فهرس القسم بالملف الخام،
/// ثابت عبر إعادة البناء). صف واحد لكل قسم مفضَّل، لا ترتيب مخزَّن.
class AzkarFavorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().unique()();
  DateTimeColumn get createdAt => dateTime()();
}

/// صف وحيد ثابت: تذكير قيام الليل — ساعة/دقيقة محليتان يختارهما المستخدم
/// (لا علاقة بحساب مواقيت الصلاة، تذكير وقت اختياري بحت). `enabled` منفصل
/// عن كون `reminderHour` معيَّناً حتى يقدر يعطّل التذكير مؤقتاً بلا فقدان
/// الوقت المختار سابقاً.
class QiyamSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get reminderHour => integer().nullable()(); // 0-23 محلي
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// خطة حفظ نشطة: نطاق آيات (`ayah_id` عام ١-٦٢٣٦، ضمن سورة واحدة بهذه
/// الجولة) يريد المستخدم حفظه. `currentAyahId` مؤشر تقدّم الحفظ **المستقل
/// كلياً عن `ReadingProgress.lastPage`** — لا يُحدَّث إلا أثناء "تابع
/// الحفظ" بـ`hifzPracticeMode`، بخلاف تصفّح المصحف العادي. نفس نمط
/// `KhatmaPlans` (صف واحد نشط بحدّ أقصى، يفرضه [UserRepository] لا قيد
/// قاعدة بيانات).
class HifzPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromAyahId => integer()();
  IntColumn get toAyahId => integer()();
  IntColumn get currentAyahId => integer()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// صف وحيد ثابت: تذكير يومي للحفظ — نسخة طبق الأصل من [QiyamSettings]
/// بقناة/معرّف إشعار مستقلَّين (راجع `adhan_notification_service.dart`).
class HifzSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get reminderHour => integer().nullable()();
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// تذكير يومي عام **بمفتاح `category`** (نفس مفاتيح [UserCategories]
/// المستخدَمة بـ[CategoryStreaks]) — صف واحد لكل نشاط يريد المستخدم تذكيراً
/// له (أذكار الصباح/المساء، الورد اليومي...). بديل تكرار جدول مخصَّص لكل
/// نشاط (كـ[QiyamSettings]/[HifzSettings] القديمين) — أنشطة إضافية بلا
/// هجرة مخطط جديدة كل مرة.
class ActivityReminders extends Table {
  TextColumn get category => text()();
  IntColumn get reminderHour => integer().nullable()();
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {category};
}

/// صف وحيد ثابت: صوت الأذان المختار للإشعارات (`voiceId` يطابق مفتاح
/// بـ`adhan_voices.dart`، `'system'` = صوت الإشعار الافتراضي للنظام).
class AdhanSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get voiceId => text().withDefault(const Constant('system'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// سجلّ إتمام يومي لكل فئة (نفس مفاتيح [UserCategories]) — صف واحد لكل
/// (فئة، يوم) **تمّ** فيه النشاط فعلاً؛ غياب الصف يعني لم يتم.
/// [CategoryStreaks] وحده لا يكفي لهذا: يخزّن فقط عدّاد السلسلة الحالية
/// وآخر يوم، لا كل الأيام السابقة — فلا يمكن معرفة "أي أيام الأسبوع
/// تحديداً تمّت" منه. يُكتَب صف جديد هون بكل استدعاء ناجح لـ
/// `bumpCategoryStreakIfNewDay` (نفس الشرط: مرة واحدة فقط لكل يوم تقويمي)
/// — راجع `UserRepository.weekCompletionFor`.
class CategoryDailyLog extends Table {
  TextColumn get category => text()();
  TextColumn get dateKey => text()(); // yyyy-mm-dd محلي (نفس `_dateKey`)

  @override
  Set<Column> get primaryKey => {category, dateKey};
}

/// تفعيل إشعار أذان — **مفتاح واحد إضافي `'master'`** بجانب مفاتيح الصلوات
/// الخمس الحقيقية (`fajr`/`dhuhr`/`asr`/`maghrib`/`isha`) بنفس الجدول، نفس
/// أسلوب [ActivityReminders]/[CategoryStreaks] (مفتاح نصي بدل خمسة أعمدة
/// منفصلة أو ستة جداول). هُجِّر من `SharedPreferences`
/// (`adhan_notification_prefs.dart`) — راجع `prefs_migration.dart`.
class AdhanNotificationSettings extends Table {
  TextColumn get prayer => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {prayer};
}

/// صف وحيد ثابت: إعداد متابعة "هل صليت؟" (راجع `AdhanNotificationService`)
/// — تفعيل مستقل عن إشعار الأذان العادي (أكثر إلحاحاً، تكرار)، وتأخير أول
/// سؤال بعد دخول الوقت يختاره المستخدم (١٠ أو ١٥ دقيقة). **لا جدول تسجيل
/// منفصل**: الضغط على "صليت" بالإشعار يستدعي نفس آلية `CategoryStreaks`/
/// `CategoryDailyLog` المستخدَمة أصلاً بقائمة "الصلوات والعبادات" اليدوية
/// (`UserCategories.fajr`..`isha`، `prayer_screen.dart`) — لا نظامَي "هل
/// صليت" منفصلين بلا علاقة ببعض.
class PrayerCheckinSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  IntColumn get firstDelayMinutes =>
      integer().withDefault(const Constant(15))();

  @override
  Set<Column> get primaryKey => {id};
}

/// عدد آيات جلسات قيام الليل المتراكم ليوم واحد (`dateKey`) — يتراكم لو
/// المستخدم بدأ أكثر من جلسة بنفس الليلة (`+=` لا استبدال). راجع "ابدأ
/// قيام" بـ`qiyam_screen.dart`/`qiyamSessionProvider` بـ`mushaf_settings.dart`.
class QiyamAyahLog extends Table {
  TextColumn get dateKey => text()();
  IntColumn get ayahCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {dateKey};
}

/// صف وحيد ثابت: لوحة ألوان صفحة المصحف المختارة (`paletteId` يطابق مفتاح
/// بـ`mushaf_palettes.dart`، `'default'` = الهوية الورقية الأصلية). نطاق
/// محدود عمداً لخلفية/نص صفحة المصحف فقط، لا هوية التطبيق العامة (راجع
/// تعليق الحماية بـ`app_colors.dart`) — قسم "ألوان" بالإعدادات.
class MushafColorSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get paletteId => text().withDefault(const Constant('default'))();

  /// وضع "المصحف الليلي" (قلب ألوان الصفحة + تعتيم خفيف، راجع
  /// `mushaf_page_widget.dart`) — واحدة من `off`/`on`/`auto` (`auto` تتبع
  /// وضع الثيم العام المظلم تلقائياً، الافتراضي).
  TextColumn get nightMode => text().withDefault(const Constant('auto'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// ملاحظة نصية واحدة قابلة للتعديل لكل آية (`ayahId` مفتاح أساسي — ملاحظة
/// واحدة لا متعدّد، يكفي طلب "أضف قسم ملاحظات" بشيت إجراءات الآية). راجع
/// `ayah_actions_sheet.dart` زر "ملاحظة".
class AyahNotes extends Table {
  IntColumn get ayahId => integer()();
  TextColumn get noteText => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {ayahId};
}

/// "فاصلة" واحدة **بمخزن أحادي لكل نوع** (`type` مفتاح أساسي، لا `id`
/// تلقائي) — عكس [Bookmarks] (علامات مرجعية حرّة، عدد غير محدود لكل آية).
/// كل نوع (`BookmarkTypes`) له فاصلة واحدة فقط بأي لحظة: "آخر آية وصلتها
/// بهذا النشاط" — ضبط فاصلة جديدة يستبدل القديمة لنفس النوع تلقائياً
/// (`insertOnConflictUpdate` بمفتاح `type`)، بطلب صاحب المشروع "فواصل
/// وعلامات حفظ للمصحف زي اللي بالصورة" (فواصل تلاوة/حفظ/مراجعة/تدبر —
/// راجع `bookmarks_screen.dart`).
class ActivityBookmarks extends Table {
  TextColumn get type => text()();
  IntColumn get ayahId => integer().named('ayah_id')();
  DateTimeColumn get setAt => dateTime().named('set_at')();

  @override
  Set<Column> get primaryKey => {type};
}

/// صف وحيد ثابت: لون تمييز التطبيق العام — بطلب صاحب المشروع "ضيف على
/// الاعدادات المستخدم بختار لون التطبيق اللي بده اياه"، ثم "لا لون التطبيق
/// كامل مش بس الايقونات". يبدّل تمييز الثيم (`ThemeData.colorScheme.
/// secondary` وأزرار/مفاتيح/تبويب سفلي Material القياسية) **و**كل الإشارات
/// المباشرة لـ`AppColors.gold` بواجهات مخصَّصة (بطاقات/شارات/حدود) عبر
/// المشروع (`themeAccent(context)` بـ`app_colors.dart`، ~٧٩ موضعاً بـ٢٨
/// ملفاً استُبدلت جولة كاملة) — من مجموعة ألوان الهوية المعتمدة أصلاً
/// بـ`app_colors.dart` فقط (لا لون حرّ جديد)، راجع `app_accent_colors.dart`.
class AppThemeSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get accentColorId => text().withDefault(const Constant('gold'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// عادة يعرّفها المستخدم بنفسه (اسم/هدف يومي/تذكير حرّ) — **جديد ومستقل**
/// عن أنظمة الأنشطة المتخصّصة الجاهزة (أذكار/قيام/حفظ/ختمة، [UserCategories]/
/// [CategoryStreaks]): تلك تبقى كما هي بلا مساس، هذا لأي نشاط إضافي يريد
/// المستخدم تتبّعه بعنوانه الخاص لا موجوداً بالكود سلفاً. بطلب صاحب المشروع
/// "متتبّع عادات عام قابل للتخصيص" (راجع `memory/humam-app-project.md`).
/// `active=false` = عادة حُذفت، لا تُقرأ ثانية بـ[UserRepository.preload]
/// (نفس نمط `HifzPlans`/`KhatmaPlans`).
class CustomHabits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get targetDaily => integer().withDefault(const Constant(1))();
  IntColumn get reminderHour => integer().nullable()(); // 0-23 محلي
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}

/// سجلّ تقدّم يومي لكل عادة مخصّصة — `count` (لا حضور ثنائي فقط) لدعم
/// "هدف يومي" حقيقي (مثلاً "اقرأ ٣ صفحات": يزيد بمقدار الصفحات المقروءة
/// لا مجرّد ١). سلسلة الاستمرار **تُحسَب من هذا الجدول عند الطلب** (لا كاش
/// منفصل كـ[CategoryStreaks]) — راجع `UserRepository.customHabitStreakDays`.
class CustomHabitLogs extends Table {
  IntColumn get habitId => integer()();
  TextColumn get dateKey => text()(); // yyyy-mm-dd محلي، نفس نمط CategoryDailyLog
  IntColumn get count => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {habitId, dateKey};
}

/// جدولة مراجعة ذكية (SM-2 مبسّطة) لآية واحدة ضمن خطة حفظ واحدة —
/// `(planId, ayahId)` مفتاح مركّب لأن نفس الآية قد تنتمي لأكثر من خطة حفظ
/// بنفس الوقت (تعدّد الخطط، راجع `HifzPlans`)، ولكل خطة تقدّم مراجعة مستقل.
/// صف يُنشأ تلقائياً أول مرة يصل تقدّم الخطة لهذه الآية (`UserRepository.
/// updateHifzCurrentAyah`)، لا يدوياً. `dueDate` عمداً **ليست** بصيغة
/// `UserRepository._dateKey` غير المبطَّنة بالأصفار (`yyyy-m-d`) — تلك
/// كافية للمقارنة بالتساوي فقط (كل الاستخدامات الحالية بالمشروع)، لكن هذا
/// الجدول يحتاج **ترتيباً/مقارنة نصية حقيقية** (`dueDate <= اليوم`) فتحتاج
/// صيغة مبطَّنة بالأصفار (`yyyy-MM-dd`) لتطابق الترتيب الزمني الفعلي —
/// راجع `UserRepository._isoDateKey`.
class HifzAyahReviews extends Table {
  IntColumn get planId => integer()();
  IntColumn get ayahId => integer()();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  TextColumn get dueDate => text()(); // yyyy-MM-dd محلي (مبطَّن بالأصفار)
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {planId, ayahId};
}

/// عدّاد ضغطات كل أداة بشاشة "أدواتي" — صف واحد لكل `toolId` (يطابق
/// `_ToolItem.id` بـ`more_placeholder_screen.dart`). يغذّي صف "الأكثر
/// استخدامًا" المثبَّت أعلى الشاشة **بتتبّع حقيقي لا قائمة ثابتة** (بطلب
/// صاحب المشروع صراحة أثناء إعادة تصميم الشاشة — راجع
/// `memory/humam-app-project.md`). يزيد بمعاملة ذرّية عند كل ضغطة، نفس
/// مبدأ [QiyamAyahLog]/`addQiyamAyahCount`.
class ToolUsageStats extends Table {
  TextColumn get toolId => text()();
  IntColumn get tapCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {toolId};
}

/// سجل جلسات قراءة المصحف — **صف واحد لكل جلسة/فرق صفحات مسجَّل** (دفتر
/// تراكمي بـ`id` مستقل، لا صف واحد محدَّث لكل يوم كـ[CategoryDailyLog])،
/// يُجمَع لاحقاً بالاستعلام حسب [dateDay] عند الحاجة
/// (`UserRepository.getReadingLog`). يغذّي "ورد اليوم"/التقرير الأسبوعي.
class ReadingLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dateDay => text()(); // yyyy-MM-dd محلي (مبطَّن بالأصفار، نفس _isoDateKey)
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();
  IntColumn get ayahsRead => integer().withDefault(const Constant(0))();
  IntColumn get minutesSpent => integer().withDefault(const Constant(0))();
}

/// سجل ثوانٍ الاستماع الفعلية للتلاوة — صف واحد لكل دفعة ثوانٍ مُسجَّلة
/// (كل ٣٠ ثانية تشغيل فعلي أو عند الإيقاف، راجع `quran_audio_controller.dart`)،
/// نفس مبدأ [ReadingLog] (دفتر تراكمي يُجمَع بالاستعلام لا صف محدَّث).
class AudioLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dateDay => text()(); // yyyy-MM-dd محلي
  IntColumn get seconds => integer().withDefault(const Constant(0))();
}

/// سجل إتمام سبحات/أذكار بعدد مستهدف (راجع `tasbih_screen.dart`) — صف واحد
/// لكل مرة يكتمل فيها عدّاد سبحة معيّنة (`azkarKey` يطابق مفتاح السبحة
/// الثابت بالمكتبة)، يغذّي "آخر مرة: البارحة" بقائمة السبحات.
class TasbihLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dateDay => text()(); // yyyy-MM-dd محلي
  TextColumn get azkarKey => text()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime()();
}
