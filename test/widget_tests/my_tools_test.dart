import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:humam_app/core/data/user/user_prefs.dart';
import 'package:humam_app/features/more/more_placeholder_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget(SharedPreferences prefs) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: MorePlaceholderScreen(),
        ),
      ),
    );
  }

  testWidgets('أدواتي: تعرض قائمة الأدوات ومربّع البحث بدون أخطاء', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    // التحقق من عنوان الشاشة ومربع البحث
    expect(find.text('أدواتي'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // التحقق من وجود تصنيفات رئيسية
    expect(find.text('القرآن والتعليم'), findsWidgets);
    expect(find.text('الحديث الشريف'), findsWidgets);
  });

  testWidgets('أدواتي: البحث بدون اتصال يعمل باللغة العربية (حديث)', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    // كتابة كلمة بحث "حديث"
    await tester.enterText(find.byType(TextField), 'حديث');
    await tester.pumpAndSettle();

    // يجب أن تظهر أدوات الحديث
    expect(find.textContaining('التحقق من صحة الحديث'), findsOneWidget);
    expect(find.textContaining('موسوعة وكتب الحديث'), findsOneWidget);

    // ولا تظهر أدوات بعيدة
    expect(find.text('اتجاه القبلة'), findsNothing);
  });

  testWidgets('أدواتي: البحث عن "حفظ" يعرض أدوات الحفظ والمراجعة', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'حفظ');
    await tester.pumpAndSettle();

    expect(find.textContaining('خطة الحفظ والجدول'), findsOneWidget);
    expect(find.textContaining('مركز الحفظ والمراجعة'), findsOneWidget);
  });

  testWidgets('أدواتي: حالة البحث الفارغ تعرض رسالة واضحة وزر مسح البحث', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'كلمة_غير_موجودة_نهائيا');
    await tester.pumpAndSettle();

    expect(find.textContaining('لم نجد أي أداة تطابق'), findsOneWidget);
    expect(find.text('مسح البحث'), findsOneWidget);

    // الضغط على زر مسح البحث يعيد القائمة الأصلية
    await tester.tap(find.text('مسح البحث'));
    await tester.pumpAndSettle();

    expect(find.textContaining('لم نجد أي أداة تطابق'), findsNothing);
    expect(find.text('القرآن والتعليم'), findsWidgets);
  });

  testWidgets('أدواتي: تثبيت وإلغاء تثبيت الأدوات المفضلة', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    // في البداية قسم المفضلة لا يظهر إن كانت القائمة فارغة
    expect(find.text('المفضلة'), findsNothing);

    // نضغط مطولاً على أداة خطة الختمة لإضافتها للمفضلة
    await tester.longPress(find.text('خطة الختمة'));
    await tester.pumpAndSettle();

    // الآن يجب أن يظهر قسم المفضلة
    expect(find.text('المفضلة'), findsOneWidget);
  });

  testWidgets('أدواتي: طي وتوسيع أقسام الأدوات', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildTestWidget(prefs));
    await tester.pumpAndSettle();

    // التحقق من أن قسم القرآن مفتوح وأدواته معروضة
    expect(find.text('خطة الختمة'), findsOneWidget);

    // الضغط على ترويسة فئة "القرآن والتعليم" لطيّها
    await tester.tap(find.text('القرآن والتعليم').first);
    await tester.pumpAndSettle();

    // اختفاء أدوات القسم بعد طيّه
    expect(find.text('خطة الختمة'), findsNothing);

    // الضغط مجدداً لإعادة فتح القسم
    await tester.tap(find.text('القرآن والتعليم').first);
    await tester.pumpAndSettle();

    // عودة ظهور أدوات القسم
    expect(find.text('خطة الختمة'), findsOneWidget);
  });
}
