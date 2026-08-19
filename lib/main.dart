import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/data/user/user_prefs.dart';
import 'core/theme/app_theme.dart';
import 'features/audio/quran_audio_handler.dart';
import 'features/mushaf/mushaf_settings.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // حاوية providers نبنيها يدوياً (بدل ProviderScope العادي) لأن
  // `AudioService.init` يحتاج القارئ الصوتي (`quranAudioHandlerProvider`)
  // جاهزاً *قبل* `runApp` — راجع توثيق audio_service. الودجتات تصل لنفس
  // الحاوية عبر `UncontrolledProviderScope` بالأسفل.
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // audio_service لا يدعم Windows/Linux إطلاقاً — تفعيله هون فقط بأندرويد
  // وiOS ليتحكّم بالتلاوة من إشعار النظام/شاشة القفل. بباقي المنصّات
  // (وضع التطوير المكتبي الليلة) المشغّل يشتغل عادي بلا إشعار نظام —
  // التحكّم من داخل التطبيق فقط عبر QuranAudioBar.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await AudioService.init(
      builder: () => container.read(quranAudioHandlerProvider),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.humam.app.audio',
        androidNotificationChannelName: 'تلاوة القرآن',
        androidNotificationOngoing: true,
      ),
    );
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HumamApp(),
    ),
  );
}

/// جذر تطبيق هُمَام. عربية فقط، بلا استثناء — لا تُضف `supportedLocales`
/// أخرى ولا بنية ترجمة. `flutter_localizations` هنا لتفعيل عناصر Material
/// الأصلية (منتقي التاريخ، شريط التمرير...) بالعربية فقط، وليست بذرة تعدد لغات.
class HumamApp extends ConsumerWidget {
  const HumamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'هُمَام',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
