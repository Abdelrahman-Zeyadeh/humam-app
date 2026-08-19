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

/// خطط الختمة — تاريخياً أكتر من صف ممكن (خطط سابقة منتهية)، لكن `active`
/// وحدة بحدّ أقصى صفّاً واحداً true بأي لحظة (يفرضها منطق [UserRepository]
/// لا قيد قاعدة بيانات).
class KhatmaPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get targetDays => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// صف وحيد ثابت: القارئ وسرعة التشغيل المفضّلان.
class AudioSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get reciterId => text().withDefault(const Constant('husary'))();
  RealColumn get speed => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// صف وحيد ثابت: موقع حساب مواقيت الصلاة/القبلة وطريقة الحساب.
class LocationSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();
  TextColumn get cityName => text().nullable()();
  TextColumn get calcMethod => text().withDefault(const Constant('ummAlQura'))();

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
