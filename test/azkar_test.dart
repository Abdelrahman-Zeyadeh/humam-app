// اختبار وحدة لتحليل بيانات الأذكار ومنطق تصفية الصباح/المساء.

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/features/azkar/azkar_repository.dart';

Map<String, dynamic> _row({required int type}) => {
      'order': 1,
      'content': 'نص تجريبي',
      'count': 3,
      'count_description': null,
      'fadl': null,
      'source': null,
      'type': type,
      'audio': '',
      'hadith_text': '',
      'explanation_of_hadith_vocabulary': '',
    };

void main() {
  test('type=0 يظهر بالصباح والمساء معاً', () {
    final d = Dhikr.fromJson(_row(type: 0));
    expect(d.appliesTo(AzkarPeriod.morning), isTrue);
    expect(d.appliesTo(AzkarPeriod.evening), isTrue);
  });

  test('type=1 صباح فقط', () {
    final d = Dhikr.fromJson(_row(type: 1));
    expect(d.appliesTo(AzkarPeriod.morning), isTrue);
    expect(d.appliesTo(AzkarPeriod.evening), isFalse);
  });

  test('type=2 مساء فقط', () {
    final d = Dhikr.fromJson(_row(type: 2));
    expect(d.appliesTo(AzkarPeriod.morning), isFalse);
    expect(d.appliesTo(AzkarPeriod.evening), isTrue);
  });

  test('الحقول الفارغة تُقرأ null لا نص فارغ', () {
    final d = Dhikr.fromJson(_row(type: 0));
    expect(d.fadl, isNull);
    expect(d.audioUrl, isNull);
  });
}
