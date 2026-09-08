import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/features/hadith_verification/services/dorar_search_service.dart';

/// نسخة مبسّطة لكن مطابقة بنيوياً لصفحة نتائج بحث dorar.net الحقيقية —
/// نفس العناصر/الأصناف (`div.border-bottom.py-4`, `article h5.h5-responsive`,
/// `a.shareLink[tag]`, `div.d-block.mb-2 strong.px-2 > span`,
/// `a.badge-dorar`) التي يعتمد عليها `DorarSearchService._parseResultBlock`
/// (راجع توثيقه). لو غيّر الموقع هذه البنية مستقبلاً، هذا الاختبار هو
/// أول من يكتشف الانكسار — قبل هذا لم يكن هناك أي اختبار لهذا المنطق.
const _sampleResultsHtml = '''
<html><body>
<div class="border-bottom py-4">
  <article>
    <h5 class="h5-responsive">1  -  إنما الأعمال بالنيات</h5>
  </article>
  <a class="shareLink" tag="abc123" href="#"></a>
  <div class="d-block mb-2">
    <strong class="px-2">خلاصة حكم المحدث: <span>صحيح</span></strong>
    <strong class="px-2">الراوي: <span>عمر بن الخطاب</span></strong>
    <strong class="px-2">المحدث: <span>البخاري</span></strong>
    <strong class="px-2">المصدر: <span>صحيح البخاري</span></strong>
    <strong class="px-2">الصفحة أو الرقم: <span>1</span></strong>
    <strong class="px-2">التخريج: <span>أخرجه البخاري ومسلم</span></strong>
    <a class="badge-dorar" href="#">النية</a>
    <a class="badge-dorar" href="#">الإخلاص</a>
  </div>
</div>
<div class="border-bottom py-4">
  <article>
    <h5 class="h5-responsive">2  -  حديث بلا تفاصيل إضافية</h5>
  </article>
  <a href="/h/xyz789">عرض الحديث</a>
</div>
</body></html>
''';

const _cloudflareChallengeHtml = '''
<html><head><title>Just a moment...</title></head>
<body><div class="cf-chl-container">Checking your browser before accessing dorar.net</div></body></html>
''';

void main() {
  final service = DorarSearchService();

  test('parseSearchResults يستخرج كل الحقول من نتيجة كاملة', () {
    final results = service.parseSearchResults(_sampleResultsHtml);

    expect(results, hasLength(2));
    final first = results[0];
    expect(first.id, 'abc123');
    expect(first.matn, 'إنما الأعمال بالنيات'); // رقم الترتيب "1 - " أُزيل
    expect(first.grade, 'صحيح');
    expect(first.narrator, 'عمر بن الخطاب');
    expect(first.muhaddith, 'البخاري');
    expect(first.source, 'صحيح البخاري');
    expect(first.pageOrNumber, '1');
    expect(first.takhrij, 'أخرجه البخاري ومسلم');
    expect(first.categories, ['النية', 'الإخلاص']);
  });

  test('parseSearchResults يستخرج المعرّف من رابط /h/ احتياطياً بلا shareLink', () {
    final results = service.parseSearchResults(_sampleResultsHtml);

    final second = results[1];
    expect(second.id, 'xyz789');
    expect(second.matn, 'حديث بلا تفاصيل إضافية');
    expect(second.grade, isNull);
    expect(second.categories, isEmpty);
  });

  test('parseSearchResults يرجع قائمة فاضية لصفحة بلا أي نتائج ولا علامات حجب', () {
    final results = service.parseSearchResults('<html><body>لا نتائج</body></html>');
    expect(results, isEmpty);
  });

  test('parseSearchResults يرمي DorarBlockedException لصفحة تحدي Cloudflare', () {
    expect(
      () => service.parseSearchResults(_cloudflareChallengeHtml),
      throwsA(isA<DorarBlockedException>()),
    );
  });

  test('parseSearchResults يرجع قائمة فاضية لنص فارغ', () {
    expect(service.parseSearchResults(''), isEmpty);
  });
}
