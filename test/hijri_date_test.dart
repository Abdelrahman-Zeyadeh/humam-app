// اختبار وحدة لتنسيق التاريخ الهجري — بلا شبكة، حساب جدولي محلي بحت.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/hijri/hijri_date.dart';

void main() {
  test('التاريخ الهجري لليوم بصيغة عربية معقولة (يحتوي هـ، وسنة بالنطاق المتوقَّع)', () {
    final result = todayHijriArabic();
    expect(result, isNotEmpty);
    expect(result, contains('هـ'));
    // السنة الهجرية اليوم (٢٠٢٦ ميلادي تقريباً) لازم تكون بمدى معقول —
    // نطاق فضفاض عمداً بدل رقم دقيق واحد (لا نعتمد على تاريخ اختبار ثابت).
    final yearMatch = RegExp(r'(\d{4})هـ').firstMatch(result);
    expect(yearMatch, isNotNull, reason: 'الناتج: $result');
    final year = int.parse(yearMatch!.group(1)!);
    expect(year, inInclusiveRange(1440, 1460));
  });
}
