// اختبار منطق "last-write-wins" الفعلي المستخدَم بـ
// `CloudSyncController.syncNow` (cloud_sync_service.dart).
//
// **ملاحظة منهجية متعمَّدة**: لا يستخدم هذا الاختبار Firestore Mock حقيقي
// (كحزمة `fake_cloud_firestore`) — قرار واعٍ لتفادي إضافة حزمة اختبار
// جديدة (`pubspec.yaml` القيد: "لا تضف حزم جديدة إلا لضرورة مثبتة") مع
// مخاطر توافق إصدار غير مؤكَّدة مع `cloud_firestore: ^6.8.0` الحالية قد
// تكسر `flutter test` كاملاً. بدل ذلك، خوارزمية القرار نفسها
// (`shouldPullInsteadOfPush`) عُزلت كدالة نقيّة (Timestamp × Timestamp
// → قرار) بمعزل تام عن Firestore الحقيقي — فتُختبَر مباشرة وحتمياً هون،
// وهي **بالضبط** الدالة التي يستدعيها `syncNow()` الحقيقي (لا إعادة
// تنفيذ منطق منفصل قد ينحرف عن الكود الفعلي بمرور الوقت).

import 'package:flutter_test/flutter_test.dart';
import 'package:humam_app/features/auth/cloud_sync_service.dart' show shouldPullInsteadOfPush;

void main() {
  test('لا بيانات سحابية بعد — ارفع نسخة الجهاز (لا سحب لمستند غير موجود)', () {
    expect(
      shouldPullInsteadOfPush(remoteLastSyncedAt: null, localSyncCheckpoint: null),
      isFalse,
    );
  });

  test('جهاز جديد لم يُزامَن قط، والسحابة فيها بيانات — اسحب (استعادة أول مرة)', () {
    expect(
      shouldPullInsteadOfPush(
        remoteLastSyncedAt: DateTime(2026, 1, 1),
        localSyncCheckpoint: null,
      ),
      isTrue,
    );
  });

  test('السحابة عُدِّلت (من جهاز آخر) بعد آخر تزامن معروف لهذا الجهاز — اسحب', () {
    final localCheckpoint = DateTime(2026, 1, 1, 10, 0);
    final remoteNewer = DateTime(2026, 1, 1, 12, 0); // جهاز آخر عدّل بعدها
    expect(
      shouldPullInsteadOfPush(
        remoteLastSyncedAt: remoteNewer,
        localSyncCheckpoint: localCheckpoint,
      ),
      isTrue,
    );
  });

  test('هذا الجهاز هو آخر من زامن (لا تغيير سحابي جديد) — ارفع (لا سحب لبيانات قديمة فوق الحالية)', () {
    final localCheckpoint = DateTime(2026, 1, 1, 12, 0);
    final remoteOlderOrSame = DateTime(2026, 1, 1, 10, 0);
    expect(
      shouldPullInsteadOfPush(
        remoteLastSyncedAt: remoteOlderOrSame,
        localSyncCheckpoint: localCheckpoint,
      ),
      isFalse,
    );
  });

  test('تساوي الوقتين تماماً (نفس لحظة آخر رفع من هذا الجهاز) — ارفع لا تسحب (لا حلقة سحب عقيمة)', () {
    final same = DateTime(2026, 1, 1, 12, 0);
    expect(
      shouldPullInsteadOfPush(remoteLastSyncedAt: same, localSyncCheckpoint: same),
      isFalse,
    );
  });
}
