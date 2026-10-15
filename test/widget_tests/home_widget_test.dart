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
import 'package:humam_app/core/data/user/location_prefs.dart';
import 'package:humam_app/core/data/user/user_database.dart';
import 'package:humam_app/core/data/user/user_prefs.dart';
import 'package:humam_app/core/data/user/user_providers.dart';
import 'package:humam_app/core/data/user/user_repository.dart';
import 'package:humam_app/features/home/home_dashboard_data.dart';
import 'package:humam_app/features/home/home_screen.dart';
import 'package:humam_app/features/prayer/prayer_countdown_card.dart';

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

  testWidgets('الشاشة الرئيسية: عرض المحتوى الأساسي والبطاقات الرئيسية', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // ضبط موقع لاختبار بطاقة الصلاة
    await userRepo.setLocation(lat: 21.4225, lon: 39.8262, cityName: 'مكة المكرمة');

    final ayah1 = await quranRepo.ayahById(1);
    final mockDashboard = HomeDashboardData(
      continueReadingSurah: 'سورة الفاتحة',
      ayahOfDay: ayah1,
      ayahOfDaySurah: 'سورة الفاتحة',
      dhikrOfDay: 'سبحان الله وبحمده',
      audioMinutesThisWeek: 15,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(userRepo),
          userPrefsProvider.overrideWithValue(UserPrefs(userRepo)),
          locationPrefsProvider.overrideWithValue(LocationPrefs(userRepo)),
          quranRepositoryProvider.overrideWithValue(quranRepo),
          homeDashboardDataProvider.overrideWith((ref) async => mockDashboard),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // التحقق من ظهور بطاقة مواقيت الصلاة وبداية العداد
    expect(find.byType(PrayerCountdownCard), findsOneWidget);

    // التحقق من ظهور تبويب آية اليوم
    expect(find.textContaining('آية اليوم'), findsWidgets);

    // التحقق من متابعة القراءة
    expect(find.textContaining('سورة الفاتحة'), findsWidgets);
  });
}
