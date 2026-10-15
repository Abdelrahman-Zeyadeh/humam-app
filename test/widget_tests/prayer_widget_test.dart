import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:humam_app/core/data/user/location_prefs.dart';
import 'package:humam_app/core/data/user/user_database.dart';
import 'package:humam_app/core/data/user/user_prefs.dart';
import 'package:humam_app/core/data/user/user_providers.dart';
import 'package:humam_app/core/data/user/user_repository.dart';
import 'package:humam_app/features/prayer/prayer_location_controller.dart';
import 'package:humam_app/features/prayer/prayer_screen.dart';

class _FakeLoadingLocationController extends LocationController {
  @override
  AsyncValue<void> build() => const AsyncValue.loading();
}

class _FakeErrorLocationController extends LocationController {
  @override
  AsyncValue<void> build() => AsyncValue.error('GPS disabled', StackTrace.empty);
}

void main() {
  late UserDatabase db;
  late UserRepository repo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = UserDatabase.forTesting(NativeDatabase.memory());
    repo = UserRepository(db);
    await repo.preload();
  });

  tearDown(() => db.close());

  testWidgets('شاشة الصلاة: عرض المواقيت كاملة عند توفر الموقع', (tester) async {
    // ضبط موقع مكة المكرمة
    await repo.setLocation(lat: 21.4225, lon: 39.8262, cityName: 'مكة المكرمة');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(repo),
          locationPrefsProvider.overrideWithValue(LocationPrefs(repo)),
        ],
        child: const MaterialApp(
          home: PrayerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // التحقق من عنوان الشاشة
    expect(find.text('مواقيت الصلاة'), findsOneWidget);

    // التحقق من عرض الصلوات الرئيسية
    expect(find.text('الفجر'), findsWidgets);
    expect(find.text('الظهر'), findsWidgets);
    expect(find.text('العصر'), findsWidgets);
    expect(find.text('المغرب'), findsWidgets);
    expect(find.text('العشاء'), findsWidgets);
  });

  testWidgets('شاشة الصلاة: عرض مؤشر التحميل أثناء جلب الموقع', (tester) async {
    // الموقع غير محدد وحالة المتحكم في حالة تحميل
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(repo),
          locationPrefsProvider.overrideWithValue(LocationPrefs(repo)),
          locationControllerProvider.overrideWith(_FakeLoadingLocationController.new),
        ],
        child: const MaterialApp(
          home: PrayerScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('حدّد موقعك لحساب مواقيت الصلاة'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('شاشة الصلاة: عرض رسالة خطأ واضحة عند تعذر تحديد الموقع عبر GPS', (tester) async {
    // الموقع غير محدد وحالة المتحكم في حالة خطأ
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(repo),
          locationPrefsProvider.overrideWithValue(LocationPrefs(repo)),
          locationControllerProvider.overrideWith(_FakeErrorLocationController.new),
        ],
        child: const MaterialApp(
          home: PrayerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('حدّد موقعك لحساب مواقيت الصلاة'), findsOneWidget);
    expect(
      find.text('تعذّر تحديد الموقع عبر GPS. يرجى التحقق من أذونات الموقع والمحاولة مجدداً.'),
      findsOneWidget,
    );
  });
}
