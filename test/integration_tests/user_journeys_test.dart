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
import 'package:humam_app/features/more/more_placeholder_screen.dart';
import 'package:humam_app/features/mushaf/widgets/mushaf_chrome_bars.dart';
import 'package:humam_app/features/prayer/prayer_times_service.dart';
import 'package:humam_app/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserDatabase userDb;
  late UserRepository userRepo;
  late SharedPreferences prefs;
  late QuranDatabase quranDb;
  late QuranRepository quranRepo;

  setUpAll(() {
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

  tearDown(() async {
    await userDb.close();
  });

  Widget createTestApp(Widget home) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userRepositoryProvider.overrideWithValue(userRepo),
        userPrefsProvider.overrideWithValue(UserPrefs(userRepo)),
        hifzPrefsProvider.overrideWithValue(HifzPrefs(userRepo)),
        locationPrefsProvider.overrideWithValue(LocationPrefs(userRepo)),
        quranRepositoryProvider.overrideWithValue(quranRepo),
      ],
      child: MaterialApp(
        home: home,
      ),
    );
  }

  // --- رحلة المستخدم 1: البحث في أدواتي -> فتح إحدى الأدوات ---
  testWidgets('رحلة 1: البحث في أدواتي ثم فتح إحدى الأدوات والانتقال لشاشتها', (tester) async {
    await tester.pumpWidget(createTestApp(const Scaffold(body: MorePlaceholderScreen())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // التأكد من شاشة أدواتي
    expect(find.text('أدواتي'), findsOneWidget);

    // البحث عن "حفظ"
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'حفظ');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // التأكد من ظهور بطاقة خطة الحفظ
    final toolItem = find.text('خطة الحفظ والجدول');
    expect(toolItem, findsOneWidget);

    // الضغط على الأداة
    await tester.tap(toolItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // التحقق من فتح شاشة الحفظ بنجاح
    expect(find.byType(HifzScreen), findsOneWidget);
  });

  // --- رحلة المستخدم 2: شريط المصحف -> فتح الإعدادات -> العودة للمصحف ---
  testWidgets('رحلة 2: من المصحف إلى الإعدادات ثم العودة', (tester) async {
    await tester.pumpWidget(createTestApp(
      Scaffold(
        body: Builder(
          builder: (context) => TopChromeBar(
            bg: Colors.black87,
            fg: Colors.white,
            currentPage: 1,
            onSurahIndex: () {},
            onSearch: () {},
            onSave: () {},
            onReadWithTafsir: () {},
            onSettings: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // التحقق من وجود زر الإعدادات والضغط عليه
    final settingsButton = find.byTooltip('الإعدادات');
    expect(settingsButton, findsOneWidget);

    await tester.tap(settingsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // التحقق من الانتقال إلى شاشة الإعدادات
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);

    // الرجوع إلى الشاشة السابقة
    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // التحقق من العودة لشاشة المصحف
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(TopChromeBar), findsOneWidget);
  });

  // --- رحلة المستخدم 3: وضع عدم الاتصال (Offline Mode) بالكامل ---
  testWidgets('رحلة 3: التحقق من عمل كافة الخصائص المحلية دون اتصال بالشبكة', (tester) async {
    // 1. حساب مواقيت الصلاة محلياً دون شبكة
    final prayerTimes = computeDayTimes(
      lat: 21.4225,
      lon: 39.8262,
      date: DateTime(2026, 9, 28),
      methodKey: 'ummAlQura',
    );
    expect(prayerTimes.length, 6);
    expect(prayerTimes.first.moment, PrayerMoment.fajr);

    // 2. قراءة بيانات القرآن محلياً من ملف SQLite دون شبكة
    final surah = await quranRepo.surahById(1);
    expect(surah.nameAr, 'سُورَةُ الفَاتِحَةِ');
    final ayahs = await quranRepo.ayahsForSurah(1);
    expect(ayahs.length, 7);

    // 3. إدارة خطط الحفظ محلياً بـ SQLite
    final plan = await userRepo.startHifzPlan(fromAyahId: 1, toAyahId: 7);
    expect(plan.id, isPositive);
    expect(userRepo.hifzPlans.length, 1);

    // 4. فحص واجهة أدواتي بدون شبكة
    await tester.pumpWidget(createTestApp(const Scaffold(body: MorePlaceholderScreen())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'قبلة');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('اتجاه القبلة'), findsOneWidget);
  });
}
