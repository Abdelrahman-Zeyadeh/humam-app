import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:humam_app/core/data/quran/quran_database.dart';
import 'package:humam_app/core/data/quran/quran_providers.dart';
import 'package:humam_app/core/data/quran/quran_repository.dart';
import 'package:humam_app/core/data/quran/tafsir_edition_database.dart';
import 'package:humam_app/core/data/quran/tafsir_edition_registry.dart';
import 'package:humam_app/core/data/user/hifz_prefs.dart';
import 'package:humam_app/core/data/user/user_database.dart';
import 'package:humam_app/core/data/user/user_prefs.dart';
import 'package:humam_app/core/data/user/user_providers.dart';
import 'package:humam_app/core/data/user/user_repository.dart';
import 'package:humam_app/features/hifz/hifz_screen.dart';
import 'package:humam_app/features/hifz/hifz_review_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserDatabase userDb;
  late UserRepository userRepo;
  late SharedPreferences prefs;
  late QuranDatabase quranDb;
  late QuranRepository quranRepo;

  setUpAll(() {
    final dbFile = File(p.join(p.current, 'assets', 'quran', 'quran.db'));
    quranDb = QuranDatabase.forTesting(NativeDatabase(dbFile));
    final tafsirRegistry = TafsirEditionRegistry.forTesting(<String, TafsirEditionDatabase>{});
    quranRepo = QuranRepository(quranDb, tafsirRegistry);
  });

  tearDownAll(() async {
    await quranDb.close();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    userDb = UserDatabase.forTesting(NativeDatabase.memory());
    userRepo = UserRepository(userDb);
    await userRepo.preload();
  });

  tearDown(() => userDb.close());

  testWidgets('شاشة الحفظ: عرض الحالة الفارغة عند عدم وجود خطط حفظ نشطة', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(userRepo),
          hifzPrefsProvider.overrideWithValue(HifzPrefs(userRepo)),
          quranRepositoryProvider.overrideWithValue(quranRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HifzScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // التحقق من ظهور نصوص الحالة الفارغة وزر بدء الخطة
    expect(find.text('لا خطط حفظ بعد'), findsOneWidget);
    expect(find.text('ابدأ خطة حفظ'), findsOneWidget);
  });

  testWidgets('شاشة الحفظ: عرض بطاقة الخطة ونسبة التقدم عند وجود خطة نشطة', (tester) async {
    // إضافة خطة حفظ لسورة الفاتحة (الآيات ١ إلى ٧)
    await userRepo.startHifzPlan(fromAyahId: 1, toAyahId: 7);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(userRepo),
          hifzPrefsProvider.overrideWithValue(HifzPrefs(userRepo)),
          quranRepositoryProvider.overrideWithValue(quranRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HifzScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // يجب ألا تظهر الحالة الفارغة
    expect(find.text('لا خطط حفظ بعد'), findsNothing);

    // يجب ظهور بطاقة الخطة وزر المتابعة ونسبة الإنجاز
    expect(find.text('تابع الحفظ'), findsOneWidget);
    expect(find.textContaining('٪'), findsWidgets);
  });

  testWidgets('شاشة تثبيت ومراجعة الحفظ: عرض المصحف مع أنماط التثبيت واختبار الحفظ', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(userRepo),
          hifzPrefsProvider.overrideWithValue(HifzPrefs(userRepo)),
          quranRepositoryProvider.overrideWithValue(quranRepo),
        ],
        child: const MaterialApp(
          home: HifzReviewScreen(initialPage: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // التحقق من وجود خيارات أنماط التثبيت
    expect(find.text('تثبيت ومراجعة'), findsWidgets);
    expect(find.text('إختبار الحفظ'), findsOneWidget);

    // التحقق من زر تثبيت الصفحة كاملة
    expect(find.textContaining('تثبيت الصفحة'), findsOneWidget);
  });
}
