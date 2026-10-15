import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:humam_app/core/data/user/location_prefs.dart';
import 'package:humam_app/core/data/user/user_database.dart';
import 'package:humam_app/core/data/user/user_prefs.dart';
import 'package:humam_app/core/data/user/user_providers.dart';
import 'package:humam_app/core/data/user/user_repository.dart';
import 'package:humam_app/features/hifz/hifz_screen.dart';
import 'package:humam_app/features/home/home_dashboard_data.dart';
import 'package:humam_app/features/home/home_screen.dart';
import 'package:humam_app/features/more/more_placeholder_screen.dart';
import 'package:humam_app/features/mushaf/widgets/mushaf_chrome_bars.dart';
import 'package:humam_app/features/prayer/prayer_screen.dart';

class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {this.tolerance = 0.02});
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent > tolerance) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserDatabase userDb;
  late UserRepository userRepo;
  late SharedPreferences prefs;
  late QuranDatabase quranDb;
  late QuranRepository quranRepo;

  setUpAll(() {
    if (goldenFileComparator is LocalFileComparator) {
      final base = (goldenFileComparator as LocalFileComparator).basedir;
      goldenFileComparator = _TolerantGoldenComparator(
        base.resolve('app_screens_golden_test.dart'),
        tolerance: 0.02,
      );
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (call) async => true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget/glance'), (call) async => true);

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

  Widget wrapWithScope({required Widget child, HomeDashboardData? dashboardData}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userRepositoryProvider.overrideWithValue(userRepo),
        locationPrefsProvider.overrideWithValue(LocationPrefs(userRepo)),
        hifzPrefsProvider.overrideWithValue(HifzPrefs(userRepo)),
        quranRepositoryProvider.overrideWithValue(quranRepo),
        if (dashboardData != null)
          homeDashboardDataProvider.overrideWith((ref) async => dashboardData),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(540, 1000),
            devicePixelRatio: 1.0,
            textScaler: TextScaler.linear(1.0),
          ),
          child: SizedBox(
            width: 540,
            height: 1000,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('اختبار جولدن: الشاشة الرئيسية (Home Screen)', (tester) async {
    tester.view.physicalSize = const Size(540, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await userRepo.setLocation(lat: 21.4225, lon: 39.8262, cityName: 'مكة المكرمة');
    final ayah = await quranRepo.ayahById(1);
    final mockDashboard = HomeDashboardData(
      continueReadingSurah: 'سورة الفاتحة',
      ayahOfDay: ayah,
      ayahOfDaySurah: 'سورة الفاتحة',
      dhikrOfDay: 'سبحان الله وبحمده',
      audioMinutesThisWeek: 10,
    );

    await tester.pumpWidget(wrapWithScope(child: const HomeScreen(), dashboardData: mockDashboard));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen.png'),
    );
  });

  testWidgets('اختبار جولدن: شاشة أدواتي (My Tools Screen)', (tester) async {
    tester.view.physicalSize = const Size(540, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(wrapWithScope(child: const MorePlaceholderScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MorePlaceholderScreen),
      matchesGoldenFile('goldens/my_tools_screen.png'),
    );
  });

  testWidgets('اختبار جولدن: شاشة مواقيت الصلاة (Prayer Screen)', (tester) async {
    tester.view.physicalSize = const Size(540, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await userRepo.setLocation(lat: 21.4225, lon: 39.8262, cityName: 'مكة المكرمة');

    await tester.pumpWidget(wrapWithScope(child: const PrayerScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PrayerScreen),
      matchesGoldenFile('goldens/prayer_screen.png'),
    );
  });

  testWidgets('اختبار جولدن: شاشة الحفظ والمراجعة (Hifz Screen)', (tester) async {
    tester.view.physicalSize = const Size(540, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await userRepo.startHifzPlan(fromAyahId: 1, toAyahId: 7);

    await tester.pumpWidget(wrapWithScope(child: const Scaffold(body: HifzScreen())));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HifzScreen),
      matchesGoldenFile('goldens/hifz_screen.png'),
    );
  });

  testWidgets('اختبار جولدن: شريط المصحف (Quran Chrome Bar)', (tester) async {
    tester.view.physicalSize = const Size(540, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final widget = Scaffold(
      body: Column(
        children: [
          TopChromeBar(
            bg: Colors.black87,
            fg: Colors.white,
            currentPage: 1,
            onSurahIndex: () {},
            onSearch: () {},
            onSave: () {},
            onReadWithTafsir: () {},
            onSettings: () {},
          ),
          const SizedBox(height: 10),
          BottomChromeBar(
            bg: Colors.black87,
            fg: Colors.white,
            currentPage: 1,
            onJump: (_) {},
          ),
        ],
      ),
    );

    await tester.pumpWidget(wrapWithScope(child: widget));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/quran_chrome.png'),
    );
  });
}
