import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/data/hadith/hadith_providers.dart';
import 'core/data/user/hifz_prefs.dart';
import 'core/data/user/location_prefs.dart';
import 'core/data/user/prefs_migration.dart';
import 'core/data/user/user_database.dart';
import 'core/data/user/user_prefs.dart';
import 'core/data/user/user_providers.dart';
import 'core/data/user/user_repository.dart';
import 'core/theme/app_accent_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/audio/quran_audio_handler.dart';
import 'features/mushaf/mushaf_settings.dart';
import 'features/notifications/adhan_notification_prefs.dart';
import 'features/notifications/adhan_notification_service.dart';
import 'features/notifications/evening_summary_text.dart';
import 'features/notifications/reminder_messages.dart';
import 'features/notifications/smart_reminder_sync.dart';
import 'features/prayer/prayer_location_controller.dart';
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
  try {
    await migrateSharedPreferencesToUserDb(prefs: prefs, repo: userRepo);
  } catch (e) {
    debugPrint('تحذير: تعذّرت هجرة SharedPreferences: $e');
  }
  try {
    await migrateAdhanNotificationPrefs(prefs: prefs, repo: userRepo);
  } catch (e) {
    debugPrint('تحذير: تعذّرت هجرة تفضيلات الأذان: $e');
  }
  try {
    await userRepo.preload();
  } catch (e) {
    debugPrint('تحذير: تعذّر التحميل المسبق لبيانات المستخدم: $e');
  }

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

  // Firebase — بذرة بنية تحتية فقط حتى الآن (لا ميزة بالتطبيق تستهلكها
  // بعد، راجع تعليق `backup_service.dart` عن "مجموعة الأصدقاء" المخطَّطة).
  // `google-services.json` موجود بـ`android/app/` فقط حالياً (لا إعداد
  // iOS/ويب بعد) — راجع `Firebase.apps` بأي كود مستقبلي قبل استخدامه
  // بمنصّة غير مُعدَّة، لا تفترض نجاحه. بالخلفية بلا حظر `runApp` بنفس
  // فلسفة `AudioService.init`/إشعارات الأذان أعلاه.
  if (!kIsWeb && Platform.isAndroid) {
    unawaited(_initFirebaseInBackground());
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const HumamApp()),
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
        // كان اسمها "تلاوة القرآن" حصراً؛ عُمِّم الاسم بعد أن أصبح نفس
        // الإشعار يخدم دروس العلماء أيضاً (راجع `attachExternalSession`
        // بـ`quran_audio_handler.dart`) — الاسم هنا تصنيف قناة الإشعار
        // بإعدادات أندرويد فقط، لا يظهر بمحتوى الإشعار نفسه (العنوان/الفنان
        // يُؤخذان من `MediaItem` الفعلي بكل حالة).
        androidNotificationChannelName: 'تشغيل الصوت',
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
Future<void> _initAdhanNotificationsInBackground(
  ProviderContainer container,
) async {
  try {
    await AdhanNotificationService.instance.initialize();
    await AdhanNotificationService.instance.requestPermissions();

    // طلب إذن الموقع بعد إذن الإشعارات تلقائياً عند فتح التطبيق
    final loc = container.read(locationPrefsProvider);
    if (!loc.hasLocation) {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            Position? position = await Geolocator.getLastKnownPosition();
            position ??= await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                timeLimit: Duration(seconds: 3),
              ),
            );
            await loc.setLocation(
              lat: position.latitude,
              lon: position.longitude,
              cityName: 'الموقع الحالي (GPS)',
            );
            container.read(locationVersionProvider.notifier).bump();
          }
        }
      } catch (e) {
        debugPrint('طلب إذن الموقع تلقائياً عند الإقلاع: $e');
      }
    }

    if (loc.hasLocation) {
      final notifPrefs = container.read(adhanNotificationPrefsProvider);
      final userPrefs = container.read(userPrefsProvider);
      await AdhanNotificationService.instance.rescheduleUpcoming(
        lat: loc.lat!,
        lon: loc.lon!,
        methodKey: loc.calculationMethod,
        isEnabled: notifPrefs.effectivelyEnabled,
        voiceId: userPrefs.adhanVoiceId,
        getVoiceIdFor: (m) => userPrefs.adhanVoiceFor(m.name),
        getModeFor: (m) => notifPrefs.notificationModeFor(m),
        preAdhanMinutes: userPrefs.preAdhanMinutes,
        checkinEnabled: userPrefs.prayerCheckinEnabled,
        checkinFirstDelayMinutes: userPrefs.prayerCheckinFirstDelayMinutes,
      );
    }
  } catch (e) {
    debugPrint('تهيئة إشعارات الأذان والموقع فشلت/تعذّرت: $e');
  }

  // تذكيرَا قيام الليل/الحفظ: جدولتهما الدوّارة (راجع توثيق
  // `AdhanNotificationService.scheduleQiyamReminder`) تغطّي ٣٠ يوماً فقط
  // (خلافاً للتكرار الأزلي القديم) لتقدر تُنوِّع المحتوى يومياً — فتُعاد
  // تعبئتهما هون بكل إقلاع تطبيق (لا فقط عند تبديل المستخدم للإعداد يدوياً
  // بشاشتَي `qiyam_screen.dart`/`hifz_screen.dart`)، وإلا يتوقّفان صامتَين
  // بعد ٣٠ يوماً بلا تنبيه للمستخدم.
  try {
    final userPrefs = container.read(userPrefsProvider);
    final hifzPrefs = container.read(hifzPrefsProvider);
    final hadithRepo = container.read(hadithRepositoryProvider);
    final svc = AdhanNotificationService.instance;

    // كل الفروع أسفل تحترم "التكرار" المخصَّص (راجع `reminders_screen.dart`،
    // `pickRepeatIntervalMinutes`) — لو مفعَّل، الجدولة الدوّارة القديمة
    // (المحتوى المتجدّد يومياً) تُستبدَل بـ`scheduleRepeatingReminder`
    // (نافذة يومين/أول يوم أسبوع مطابق فقط)، فتحتاج نفس إعادة التعبئة
    // بكل إقلاع تطبيق وإلا تتوقّف صامتة.
    if (userPrefs.qiyamEnabled && userPrefs.qiyamHour != null) {
      final messages = await qiyamReminderMessages(hadithRepo);
      final interval = userPrefs.reminderIntervalMinutesFor(
        UserCategories.qiyam,
      );
      if (interval != null) {
        await svc.cancelQiyamReminder();
        await svc.scheduleRepeatingReminder(
          category: UserCategories.qiyam,
          body: messages[DateTime.now().day % messages.length],
          startHour: userPrefs.qiyamHour!,
          startMinute: userPrefs.qiyamMinute,
          intervalMinutes: interval,
        );
      } else {
        await svc.cancelRepeatingReminder(UserCategories.qiyam);
        await svc.scheduleQiyamReminder(
          hour: userPrefs.qiyamHour!,
          minute: userPrefs.qiyamMinute,
          messages: messages,
        );
      }
    }
    // لو راجع المستخدم آية حفظ واحدة على الأقل اليوم، لا نعيد جدولة تذكير
    // الحفظ من الأساس بهذا الإقلاع — نفس فكرة تفادي `readToday` بتذكير
    // الورد اليومي (راجع توثيق `syncHifzReminder`).
    if (hifzPrefs.reminderEnabled &&
        hifzPrefs.reminderHour != null &&
        !await hifzPrefs.reviewedToday()) {
      final messages = await hifzReminderMessages(hadithRepo);
      final interval = userPrefs.reminderIntervalMinutesFor(
        UserCategories.hifz,
      );
      if (interval != null) {
        await svc.cancelHifzReminder();
        await svc.scheduleRepeatingReminder(
          category: UserCategories.hifz,
          body: messages[DateTime.now().day % messages.length],
          startHour: hifzPrefs.reminderHour!,
          startMinute: hifzPrefs.reminderMinute,
          intervalMinutes: interval,
        );
      } else {
        await svc.cancelRepeatingReminder(UserCategories.hifz);
        await svc.scheduleHifzReminder(
          hour: hifzPrefs.reminderHour!,
          minute: hifzPrefs.reminderMinute,
          messages: messages,
        );
      }
    }
    if (userPrefs.hourlyDhikrEnabled) {
      await svc.rescheduleHourlyDhikr(
        isEnabled: true,
        startHour: userPrefs.hourlyDhikrStartHour,
        endHour: userPrefs.hourlyDhikrEndHour,
        intervalHours: userPrefs.hourlyDhikrIntervalHours,
      );
    }

    // تنبيهات السنن وصيام التطوع
    final notifPrefs = container.read(adhanNotificationPrefsProvider);
    if (notifPrefs.sunnahKahfEnabled) {
      // الساعة المخصَّصة من المستخدم (راجع `reminders_screen.dart`،
      // `_kSunnahKahfHourKey`) — لا الافتراضي الثابت، وإلا كانت تُستبدَل
      // بـ٩:٠٠ص في كل إعادة تشغيل للتطبيق.
      final kahfHour = userPrefs.reminderHourFor('sunnah_kahf_hour') ?? 9;
      final kahfMinute = userPrefs.reminderMinuteFor('sunnah_kahf_hour');
      final kahfInterval = userPrefs.reminderIntervalMinutesFor('sunnah_kahf');
      if (kahfInterval != null) {
        await svc.scheduleFridayKahfReminder(enabled: false);
        await svc.scheduleRepeatingReminder(
          category: 'sunnah_kahf',
          body: 'نورٌ ما بين الجمعتين — لا تنسَ قراءة سورة الكهف اليوم',
          startHour: kahfHour,
          startMinute: kahfMinute,
          intervalMinutes: kahfInterval,
          onlyWeekday: DateTime.friday,
        );
      } else {
        await svc.cancelRepeatingReminder('sunnah_kahf');
        await svc.scheduleFridayKahfReminder(
          enabled: true,
          hour: kahfHour,
          minute: kahfMinute,
        );
      }
    }
    if (notifPrefs.sunnahSalawatEnabled) {
      final fridayHour =
          userPrefs.reminderHourFor('sunnah_salawat_friday_hour') ?? 10;
      final fridayMinute = userPrefs.reminderMinuteFor(
        'sunnah_salawat_friday_hour',
      );
      final eveHour =
          userPrefs.reminderHourFor('sunnah_salawat_eve_hour') ?? 20;
      final eveMinute = userPrefs.reminderMinuteFor('sunnah_salawat_eve_hour');
      final fridayInterval = userPrefs.reminderIntervalMinutesFor(
        'sunnah_salawat_friday',
      );
      final eveInterval = userPrefs.reminderIntervalMinutesFor(
        'sunnah_salawat_eve',
      );
      await svc.scheduleFridaySalawatReminder(
        enabled: true,
        fridayHour: fridayHour,
        fridayMinute: fridayMinute,
        eveHour: eveHour,
        eveMinute: eveMinute,
        scheduleEve: eveInterval == null,
        scheduleFriday: fridayInterval == null,
      );
      if (eveInterval != null) {
        await svc.scheduleRepeatingReminder(
          category: 'sunnah_salawat_eve',
          body:
              'إن من أفضل أيامكم يوم الجمعة، فأكثروا عليّ من الصلاة فيه فإن صلاتكم معروضة عليّ',
          startHour: eveHour,
          startMinute: eveMinute,
          intervalMinutes: eveInterval,
          onlyWeekday: DateTime.thursday,
        );
      } else {
        await svc.cancelRepeatingReminder('sunnah_salawat_eve');
      }
      if (fridayInterval != null) {
        await svc.scheduleRepeatingReminder(
          category: 'sunnah_salawat_friday',
          body:
              'أكثروا من الصلاة والسلام على نبينا محمد ﷺ في هذا اليوم المبارك',
          startHour: fridayHour,
          startMinute: fridayMinute,
          intervalMinutes: fridayInterval,
          onlyWeekday: DateTime.friday,
        );
      } else {
        await svc.cancelRepeatingReminder('sunnah_salawat_friday');
      }
    }
    if (notifPrefs.sunnahFastingEnabled) {
      await AdhanNotificationService.instance.scheduleFastingReminders(
        enabled: true,
      );
    }
    if (notifPrefs.sunnahWhiteDaysEnabled) {
      await AdhanNotificationService.instance.scheduleWhiteDaysReminder(
        enabled: true,
      );
    }
  } catch (e) {
    debugPrint('إعادة جدولة تذكيرات قيام الليل/الحفظ/السنن/الصيام فشلت: $e');
  }

  // الملخّص المسائي: مثل تذكيرَي القيام/الحفظ أعلاه، محتواه (لا وقته فقط)
  // يحتاج إعادة تعبئة بكل إقلاع — راجع توثيق `scheduleEveningSummary` لسبب
  // هذا القيد تحديداً (محتوى "حيّ" بلا حزمة مهام خلفية جديدة).
  try {
    final userPrefs = container.read(userPrefsProvider);
    const category = 'evening_summary';
    final hour = userPrefs.reminderHourFor(category);
    if (userPrefs.reminderEnabledFor(category) && hour != null) {
      final body = await buildEveningSummaryBodyFor(userPrefs);
      await AdhanNotificationService.instance.scheduleEveningSummary(
        hour: hour,
        minute: userPrefs.reminderMinuteFor(category),
        body: body,
      );
    }
  } catch (e) {
    debugPrint('إعادة جدولة الملخّص المسائي فشلت: $e');
  }

  // تذكير "الورد اليومي" الذكي — يُلغى تلقائياً لو المستخدم قرأ اليوم
  // فعلاً (بدل تذكير أعمى يتكرر بلا وعي بالإنجاز)، راجع توثيق
  // `syncDailyWirdReminder` الكامل.
  await syncDailyWirdReminder(container.read(userPrefsProvider));
}

/// يهيّئ اتصال Firebase بالخلفية — راجع الملاحظة أعلى استدعائها بـ`main()`.
/// أي فشل (لا إنترنت وقت الإقلاع، إعداد ناقص) لا يوقف التطبيق ولا أي ميزة
/// موجودة فعلياً (لا شيء يعتمد على Firebase حالياً).
Future<void> _initFirebaseInBackground() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase.initializeApp فشل/تعذّر: $e');
    return; // بلا Firebase مهيَّأ، Crashlytics لن يشتغل — لا داعي للمحاولة.
  }

  // Crashlytics: تسجيل الاستثناءات غير المُمسَكة عن بعد فقط — لا يستبدل أي
  // `try/catch` موجود (كل التقاط هنا أعلى بالملف يبقى كما هو، يطبع تحذيراً
  // محلياً ويكمل التطبيق عادي). فشل تفعيل Crashlytics نفسه لا يوقف التطبيق،
  // بنفس فلسفة بقية التهيئات بالخلفية هون.
  try {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('تفعيل Crashlytics فشل/تعذّر: $e');
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
    ref.watch(accentColorVersionProvider);
    final accent = appAccentColorById(
      ref.read(userPrefsProvider).accentColorId,
    );
    return MaterialApp(
      title: 'هُمَام',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      darkTheme: AppTheme.dark(accent: accent),
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
