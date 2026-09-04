// اختبار SingleFlightGuard — الآلية الفعلية اللي تمنع FontDownloadController
// من تنزيل نفس صفحة المصحف مرّتين بالتوازي (راجع
// font_download_service.dart.requestPageWithPriority).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/core/data/single_flight_guard.dart';

void main() {
  test('طلبان متزامنان لنفس المفتاح — المهمّة تُنفَّذ مرّة واحدة فقط', () async {
    final guard = SingleFlightGuard<int>();
    var executions = 0;
    final completer = Completer<void>();

    Future<void> slowTask() async {
      executions++;
      await completer.future;
    }

    // نفس نمط `requestPageWithPriority` بالضبط: طلب أولوية ثانٍ لنفس
    // الصفحة (٥١ هون) يصل قبل اكتمال الأول.
    final first = guard.run(51, slowTask);
    final second = guard.run(51, slowTask);

    expect(guard.isRunning(51), isTrue);
    expect(executions, 1); // ليس ٢ — الطلب الثاني لم يبدأ تنفيذاً مستقلاً

    completer.complete();
    await first;
    await second;

    expect(executions, 1);
    expect(guard.isRunning(51), isFalse); // يُنظَّف بعد الاكتمال
  });

  test('مفتاحان مختلفان — تنفيذان مستقلّان بلا تداخل', () async {
    final guard = SingleFlightGuard<int>();
    final log = <int>[];

    await Future.wait([
      guard.run(51, () async => log.add(51)),
      guard.run(52, () async => log.add(52)),
    ]);

    expect(log, containsAll([51, 52]));
  });

  test('طلب جديد لنفس المفتاح بعد اكتمال الأول يُنفَّذ فعلياً (لا يبقى محظوراً للأبد)', () async {
    final guard = SingleFlightGuard<int>();
    var executions = 0;

    await guard.run(51, () async => executions++);
    expect(guard.isRunning(51), isFalse);
    await guard.run(51, () async => executions++);

    expect(executions, 2);
  });

  test('فشل المهمّة يُنظِّف السجلّ أيضاً (لا يبقى "جارياً" للأبد بعد استثناء)', () async {
    final guard = SingleFlightGuard<int>();

    await expectLater(
      guard.run(51, () async => throw StateError('فشل تنزيل وهمي')),
      throwsA(isA<StateError>()),
    );

    expect(guard.isRunning(51), isFalse);
  });
}
