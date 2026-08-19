// اختبار دخان أساسي: يتأكد أن التطبيق يُقلع ويعرض شاشة الترحيب دون أخطاء.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:humam_app/core/data/user/user_prefs.dart';
import 'package:humam_app/main.dart';

void main() {
  testWidgets('يُقلع التطبيق ويعرض اسم هُمَام في شاشة الترحيب', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const HumamApp(),
      ),
    );
    await tester.pump();

    expect(find.text('هُمَام'), findsOneWidget);

    // نُفرغ مؤقّت الانتقال التلقائي لشاشة الترحيب حتى لا يبقى معلّقاً بعد
    // انتهاء الاختبار.
    await tester.pump(const Duration(seconds: 1));
  });
}
