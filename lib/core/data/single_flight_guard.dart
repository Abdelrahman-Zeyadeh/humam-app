/// يمنع تشغيل أكثر من مهمة متزامنة واحدة لنفس المفتاح [K] بنفس الوقت —
/// طلب ثانٍ لنفس المفتاح أثناء تنفيذ الأول يعيد نفس الـ `Future` الجاري
/// فعلياً بدل بدء تنفيذ مستقل ثانٍ (يمنع ازدواج العمل/الشبكة). يُستخدَم
/// فعلياً بـ`font_download_service.dart` (`FontDownloadController`) لمنع
/// تنزيل نفس صفحة المصحف مرّتين بالتوازي عند تصفّح سريع ذهاباً وإياباً
/// يطلب نفس الصفحة أكثر من مرّة قبل اكتمال أول تنزيل لها (راجع
/// `requestPageWithPriority`).
class SingleFlightGuard<K> {
  final Map<K, Future<void>> _inFlight = {};

  /// يشغّل [task] لأجل [key] — لو فيه تنفيذ جارٍ فعلاً لنفس [key] يعيد
  /// نفس الـ `Future` الجاري (لا يشغّل [task] مرّة ثانية إطلاقاً)، وإلا
  /// يبدأ تنفيذاً جديداً ويسجّله حتى يكتمل (نجاحاً أو فشلاً).
  Future<void> run(K key, Future<void> Function() task) {
    final existing = _inFlight[key];
    if (existing != null) return existing;
    // **لا** تستخدم دالة سهمية هون (`() => _inFlight.remove(key)`) — قيمة
    // إرجاعها (`Future<void>?` المُزال نفسه، وهو `future` أدناه بذاتها لحظة
    // التنفيذ) تجعل `whenComplete` ينتظر اكتمال تلك القيمة المُرجَعة قبل
    // اعتبار نفسه مكتملاً — انتظار ذاتي دائري (`future` تنتظر اكتمال
    // نفسها) يعلّق التنفيذ للأبد. جسم `{}` بلا `return` صريح يتجاهل قيمة
    // `remove` بأمان.
    final future = task().whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  bool isRunning(K key) => _inFlight.containsKey(key);

  /// عدد المهام الجارية الآن — للاختبار بشكل رئيسي.
  int get runningCount => _inFlight.length;
}
