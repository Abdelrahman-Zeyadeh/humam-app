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
import 'package:humam_app/core/data/user/user_database.dart';
import 'package:humam_app/core/data/user/user_prefs.dart';
import 'package:humam_app/core/data/user/user_providers.dart';
import 'package:humam_app/core/data/user/user_repository.dart';
import 'package:humam_app/features/mushaf/widgets/mushaf_chrome_bars.dart';

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

  testWidgets('شريط المصحف العلوي: عرض أدوات التحكم الأساسية ورقم الصفحة', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(userRepo),
          quranRepositoryProvider.overrideWithValue(quranRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TopChromeBar(
              bg: Colors.black87,
              fg: Colors.white,
              currentPage: 1,
              onSurahIndex: () {},
              onSearch: () {},
              onSave: () {},
              onReadWithTafsir: () {},
              onSettings: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // التحقق من أزرار وأدوات شريط التحكم
    expect(find.byTooltip('فهرس السور'), findsOneWidget);
    expect(find.byTooltip('بحث'), findsOneWidget);
    expect(find.byTooltip('قراءة مع التفسير'), findsOneWidget);
    expect(find.byTooltip('الإعدادات'), findsOneWidget);
  });

  testWidgets('شريط التنقل السفلي للمصحف: عرض شريط التنقل وأرقام الصفحات', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userRepositoryProvider.overrideWithValue(userRepo),
          quranRepositoryProvider.overrideWithValue(quranRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: BottomChromeBar(
              bg: Colors.black87,
              fg: Colors.white,
              currentPage: 1,
              onJump: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // التحقق من وجود شريط التنقل
    expect(find.byType(PageNavStrip), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });
}
