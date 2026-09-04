/// نتيجة حديث واحدة كما تُرجعها موسوعة الدرر السنية (dorar.net) — تُستخرَج
/// من صفحة البحث نفسها (`services/dorar_search_service.dart`)، لا عبر API
/// رسمي (الموقع لا يوفّر واحداً)، فكل الحقول اختيارية عدا المتن والمعرّف.
class DorarHadithResult {
  const DorarHadithResult({
    required this.id,
    required this.matn,
    this.grade,
    this.narrator,
    this.muhaddith,
    this.source,
    this.pageOrNumber,
    this.takhrij,
    this.categories = const [],
  });

  /// معرّف الحديث بموقع الدرر (مثلاً "RaGR74gn") — يُستخدَم لبناء رابط
  /// الصفحة الكاملة على الموقع.
  final String id;

  /// نص الحديث (المتن) بعد إزالة رقم الترتيب وتنظيف الفراغات.
  final String matn;

  /// خلاصة حكم المحدث (صحيح/حسن/ضعيف/موضوع...).
  final String? grade;

  final String? narrator;
  final String? muhaddith;
  final String? source;
  final String? pageOrNumber;
  final String? takhrij;
  final List<String> categories;

  /// رابط صفحة الحديث الكاملة على موقع الدرر السنية (شرح، أحاديث مشابهة،
  /// أصول الحديث... تفاصيل أكبر من أن تُعرَض محلياً).
  String get permalink => 'https://dorar.net/h/$id';

  /// نص مرجعي جاهز للمشاركة/النسخ — بنفس صيغة زر "نسخ الحديث" بالموقع.
  String get shareText {
    final buffer = StringBuffer(matn);
    buffer.writeln();
    buffer.writeln();
    if (narrator != null) buffer.writeln('الراوي: $narrator');
    if (muhaddith != null) buffer.writeln('المحدث: $muhaddith');
    if (source != null)
      buffer.writeln(
        'المصدر: $source${pageOrNumber != null ? ' - الصفحة أو الرقم: $pageOrNumber' : ''}',
      );
    if (grade != null) buffer.writeln('خلاصة حكم المحدث: $grade');
    buffer.writeln('موقع الدرر السنية: $permalink');
    return buffer.toString().trim();
  }
}
