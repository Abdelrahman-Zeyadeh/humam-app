import '../../core/data/hadith/hadith_repository.dart'
    show HadithRepository, hadithMatnOnly;
import '../../core/data/names_of_allah/names_of_allah_data.dart';
import '../hadith/daily_hadith_screen.dart' show kCuratedDailyHadiths;

/// نصوص تذكير قيام الليل/الحفظ اليومية — **كلها أحاديث حقيقية تُقرأ حياً من
/// `hadith.db` المرخّصة**، لا نص مؤلَّف بالكود (بطلب صاحب المشروع صراحة:
/// "خليه يبعث اشعار يحث... حديث او مقولة اسلامية مش من راسك"). تُستخدَم
/// لتدوير محتوى الإشعار المتكرر يومياً بدل نص ثابت واحد ("خليهن متغيرات مش
/// ثابتات كل يوم") — راجع `AdhanNotificationService.scheduleQiyamReminder`/
/// `.scheduleHifzReminder` لآلية الجدولة الدوّارة نفسها.
///
/// [hadithMatnOnly] تقصّ الإسناد وتُبقي المتن فقط — **موثوقة فقط** للأحاديث
/// اللي عبارة "صلى الله عليه وسلم" تظهر بها مرة واحدة تماماً قبل المتن مباشرة
/// (راجع تحذير توثيقها بـ`hadith_repository.dart`)؛ تحقّقتُ شخصياً من نص كل
/// حديث هون (`assets/hadith/hadith.db`) قبل إدراجه بهذه القائمة تحديداً لهذا
/// الشرط، ما عدا حديث عائشة (أبو داود ١٣٠٧) المكتوب يدوياً أدناه لأن العبارة
/// تظهر بمنتصف كلامها هي نفسه لا قبل متن منقول عن النبي ﷺ، فالقصّ الآلي كان
/// سيحذف بداية كلامها ("لا تدع قيام الليل") خطأً.
Future<List<String>> qiyamReminderMessages(HadithRepository repo) async {
  final messages = <String>[];

  // سنن النسائي ١٦١٤: "أفضل الصلاة بعد الفريضة قيام الليل".
  final nasai1614 = await repo.hadithByBookAndNumber(6, 1614);
  if (nasai1614 != null) messages.add(hadithMatnOnly(nasai1614.content));

  // سنن النسائي ١٧٦٣: تحذير النبي ﷺ لعبد الله بن عمرو من ترك قيام الليل.
  final nasai1763 = await repo.hadithByBookAndNumber(6, 1763);
  if (nasai1763 != null) messages.add(hadithMatnOnly(nasai1763.content));

  // صحيح البخاري ١١٤٥: حديث نزول الله تبارك وتعالى بالثلث الأخير من الليل
  // (نفس الحديث المعروض ببطاقة "فضل قيام الليل" بالشاشة نفسها).
  final bukhari1145 = await repo.hadithByBookAndNumber(1, 1145);
  if (bukhari1145 != null) messages.add(hadithMatnOnly(bukhari1145.content));

  // سنن أبي داود ١٣٠٧: قول عائشة رضي الله عنها — مكتوب يدوياً (راجع تحذير
  // [hadithMatnOnly] أعلى الملف)، حرفياً كما بقاعدة البيانات.
  messages.add(
    'لاَ تَدَعْ قِيَامَ اللَّيْلِ فَإِنَّ رَسُولَ اللَّهِ صلى الله عليه وسلم كَانَ لاَ يَدَعُهُ — قول عائشة رضي الله عنها (رواه أبو داود ١٣٠٧)',
  );

  if (messages.isEmpty) messages.add('حان وقت التذكير الذي اخترته لقيام الليل');
  return messages;
}

/// راجع توثيق [qiyamReminderMessages] أعلاه — نفس المبدأ لتذكير الحفظ.
Future<List<String>> hifzReminderMessages(HadithRepository repo) async {
  final messages = <String>[];

  // صحيح مسلم ١٨٤٤: "تعاهدوا هذا القرآن... أشد تفلتاً من الإبل في عقلها".
  final muslim1844 = await repo.hadithByBookAndNumber(2, 1844);
  if (muslim1844 != null) messages.add(hadithMatnOnly(muslim1844.content));

  // صحيح البخاري ٤٩٣٧: فضل حافظ القرآن (نفس بطاقة "فضل حافظ القرآن").
  final bukhari4937 = await repo.hadithByBookAndNumber(1, 4937);
  if (bukhari4937 != null) messages.add(hadithMatnOnly(bukhari4937.content));

  // صحيح البخاري ٥٠٣٣: "تعاهدوا القرآن..." (نفس بطاقة تذكير المراجعة).
  final bukhari5033 = await repo.hadithByBookAndNumber(1, 5033);
  if (bukhari5033 != null) messages.add(hadithMatnOnly(bukhari5033.content));

  if (messages.isEmpty)
    messages.add('حان وقت التذكير الذي اخترته لمتابعة حفظك');
  return messages;
}

/// نصوص تذكير "حديث اليوم" — من القائمة المنسَّقة نفسها المعروضة بشاشة
/// `DailyHadithScreen` (`kCuratedDailyHadiths`)، حديث مختلف كل يوم عبر
/// الجدولة الدوّارة (راجع توثيق [qiyamReminderMessages] أعلاه لنفس المبدأ).
/// لا حاجة لـ`HadithRepository` هون — القائمة منسَّقة سلفاً بالكود.
List<String> dailyHadithReminderMessages() {
  return [for (final h in kCuratedDailyHadiths) '${h.matn}\n— ${h.source}'];
}

/// نصوص تذكير "اسم من أسماء الله الحسنى" — من الموسوعة الكاملة (٩٩ اسماً)
/// `NamesOfAllahData.items`، اسم مختلف كل يوم.
List<String> dailyNameOfAllahReminderMessages() {
  return [for (final n in NamesOfAllahData.items) '${n.name}: ${n.meaning}'];
}
