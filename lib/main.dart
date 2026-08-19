import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/data/user/location_prefs.dart';
import 'core/data/user/prefs_migration.dart';
import 'core/data/user/user_database.dart';
import 'core/data/user/user_prefs.dart';
import 'core/data/user/user_providers.dart';
import 'core/data/user/user_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/audio/quran_audio_handler.dart';
import 'features/mushaf/mushaf_settings.dart';
import 'features/notifications/adhan_notification_prefs.dart';
import 'features/notifications/adhan_notification_service.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // `user.db` (drift) — يحل محل بيانات المستخدم التي كانت بـSharedPreferences
  // مباشرة (تصميم-النظام.md §٢.٢/٢.٥). الهجرة والتحميل المسبق (preload)
  // *يجب* أن يكتملا قبل `runApp` حتى تبقى كل قراءات `UserPrefs`/`KhatmaPrefs`/...
  // متزامنة بالشاشات بلا إعادة كتابتها لـ`FutureProvider` — راجع تعليق
  // `UserRepository.preload`.
  final userDb = UserDatabase();
  final userRepo = UserRepository(userDb);
  await migrateSharedPreferencesToUserDb(prefs: prefs, repo: userRepo);
  await userRepo.preload();

  // حاوية providers نبنيها يدوياً (بدل ProviderScope العادي) لأن
  // `AudioService.init` يحتاج القارئ الصوتي (`quranAudioHandlerProvider`)
  // جاهزاً *قبل* `runApp` — راجع توثيق audio_service. الودجتات تصل لنفس
  // الحاوية عبر `UncontrolledProviderScope` بالأسفل.
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      userRepositoryProvider.overrideWithValue(userRepo),
    ],
  );

  // audio_service لا يدعم Windows/Linux إطلاقاً — تفعيله هون فقط بأندرويد
  // وiOS ليتحكّم بالتلاوة من إشعار النظام/شاشة القفل. بباقي المنصّات
  // (وضع التطوير المكتبي الليلة) المشغّل يشتغل عادي بلا إشعار نظام —
  // التحكّم من داخل التطبيق فقط عبر QuranAudioBar.
  //
  // ⚠️ **لا ننتظر (`await`) نتيجة `AudioService.init` قبل `runApp`** —
  // جُرِّب هذا على جهاز أندرويد حقيقي (Honor/Android 15) وعلّق التطبيق
  // إلى الأبد قبل أول رسم (ANR: "Input dispatching timed out ...
  // DRAW_PENDING")، لأن `init` لم يكتمل أبداً على ذاك الجهاز. المشغّل
  // الفعلي (`quranAudioControllerProvider` + just_audio بالأسفل) لا
  // يعتمد على نجاح هذا الاستدعاء إطلاقاً — `QuranAudioHandler` مجرّد
  // مترجم لأوامر الإشعار لنفس المشغّل، فتشغيله بالخلفية بلا حظر يبقي
  // الواجهة تشتغل دائماً حتى لو تعطّل/تأخّر إعداد الإشعار نفسه فقط.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    unawaited(_initAudioServiceInBackground(container));
  }

  // إشعارات الأذان — نفس فلسفة `AudioService.init` أعلاه: تُشغَّل بالخلفية
  // بلا حظر `runApp`. مقصورة على أندرويد/iOS فقط (نفس قيد `audio_service`
  // أعلاه) — `flutter_local_notifications` يحتاج `WindowsInitializationSettings`
  // صريحة (appUserModelId/guid) على ويندوز، غير معدّة هون لأن ويندوز بيئة
  // تطوير مكتبي فقط لا هدف نشر فعلي؛ تُرك التفعيل هناك خارج النطاق بدل
  // إعداد جزئي مضلِّل. جُرِّب فعلياً على ويندوز الليلة (`flutter run -d
  // windows`) وتأكّدنا أن غيابه هون لا يرمي استثناء غير مُمسَك — راجع أيضاً
  // `_toggleNotifications` بـ`prayer_screen.dart` لنفس الحماية عند التبديل اليدوي.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    unawaited(_initAdhanNotificationsInBackground(container));
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HumamApp(),
    ),
  );
}

/// يشغّل `AudioService.init` بالخلفية بلا حظر `runApp` — راجع الملاحظة
/// أعلى استدعائها بـ`main()`. أي فشل/استثناء هون يعطّل الإشعار فقط، لا
/// يوقف التطبيق ولا التشغيل داخل التطبيق نفسه.
Future<void> _initAudioServiceInBackground(ProviderContainer container) async {
  try {
    await AudioService.init(
      builder: () => container.read(quranAudioHandlerProvider),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.humam.app.audio',
        androidNotificationChannelName: 'تلاوة القرآن',
        androidNotificationOngoing: true,
      ),
    );
  } catch (e) {
    debugPrint('AudioService.init فشل/تعذّر — التشغيل من داخل التطبيق فقط: $e');
  }
}

/// يهيّئ إشعارات الأذان ويطلب أذوناتها ويجدول القادم منها بالخلفية —
/// راجع تحذيرات `AdhanNotificationService` (لا صوت أذان مخصَّص بعد، غير
/// مُختبرة بجهاز فعلي). فشل أي خطوة هون لا يوقف التطبيق، فقط الإشعارات
/// تتأخر لإعادة جدولة لاحقة (عند فتح شاشة الصلاة أو تغيير الموقع).
Future<void> _initAdhanNotificationsInBackground(ProviderContainer container) async {
  try {
    await AdhanNotificationService.instance.initialize();
    await AdhanNotificationService.instance.requestPermissions();

    final loc = container.read(locationPrefsProvider);
    if (!loc.hasLocation) return;
    final notifPrefs = container.read(adhanNotificationPrefsProvider);
    await AdhanNotificationService.instance.rescheduleUpcoming(
      lat: loc.lat!,
      lon: loc.lon!,
      methodKey: loc.calculationMethod,
      isEnabled: notifPrefs.effectivelyEnabled,
    );
  } catch (e) {
    debugPrint('تهيئة إشعارات الأذان فشلت/تعذّرت: $e');
  }
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
