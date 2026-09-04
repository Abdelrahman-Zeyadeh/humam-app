import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/text/arabic_normalizer.dart' show formatAyahForWidgetDisplay;
import '../shell/root_shell.dart' show rootTabIndexProvider;

const String kHumamWidgetAndroidName = 'HumamWidgetProvider';
const String kHumamWidgetQualifiedAndroidName = 'com.humam.humam_app.HumamWidgetProvider';

const String kPrayerBarWidgetAndroidName = 'PrayerBarWidgetProvider';
const String kPrayerBarWidgetQualifiedAndroidName = 'com.humam.humam_app.PrayerBarWidgetProvider';

const String kDhikrWidgetAndroidName = 'DhikrWidgetProvider';
const String kDhikrWidgetQualifiedAndroidName = 'com.humam.humam_app.DhikrWidgetProvider';

const String kAyahDhikrWidgetAndroidName = 'AyahDhikrWidgetProvider';
const String kAyahDhikrWidgetQualifiedAndroidName = 'com.humam.humam_app.AyahDhikrWidgetProvider';

/// يدفع بيانات ودجتات الشاشة الرئيسية (الآية، مواقيت الصلاة، الأذكار والتسبيح، الشريط الكامل)
/// للجهة الأصلية ويطلب إعادة رسم كل الودجتات النشطة فوراً.
Future<void> updateHumamHomeWidget({
  required String ayahText,
  required String ayahRef,
  String? dhikrText,
  String? hijriDate,
  String? nextPrayerName,
  String? nextPrayerTime,
  String? nextPrayerCountdown,
  int? nextPrayerTargetEpochMs,
  String? timeFajr,
  String? timeSunrise,
  String? timeDhuhr,
  String? timeAsr,
  String? timeMaghrib,
  String? timeIsha,
  int? timeFajrMs,
  int? timeSunriseMs,
  int? timeDhuhrMs,
  int? timeAsrMs,
  int? timeMaghribMs,
  int? timeIshaMs,
  int? timeTomorrowFajrMs,
  String? activeMoment,
  String? ayahPoolJson,
  String? dhikrPoolJson,
  String? accentId,
}) async {
  try {
    await HomeWidget.saveWidgetData<String>('ayah_text', formatAyahForWidgetDisplay(ayahText));
    await HomeWidget.saveWidgetData<String>('ayah_ref', ayahRef);
    if (dhikrText != null && dhikrText.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>('dhikr_text', dhikrText);
    }
    if (hijriDate != null && hijriDate.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>('hijri_date', hijriDate);
    }
    await HomeWidget.saveWidgetData<String>('next_prayer_name', nextPrayerName ?? '');
    await HomeWidget.saveWidgetData<String>('next_prayer_time', nextPrayerTime ?? '');
    await HomeWidget.saveWidgetData<String>('next_prayer_countdown', nextPrayerCountdown ?? '');
    if (nextPrayerTargetEpochMs != null) {
      await HomeWidget.saveWidgetData<int>('next_prayer_target_epoch', nextPrayerTargetEpochMs);
    }

    if (timeFajr != null) await HomeWidget.saveWidgetData<String>('time_fajr', timeFajr);
    if (timeSunrise != null) await HomeWidget.saveWidgetData<String>('time_sunrise', timeSunrise);
    if (timeDhuhr != null) await HomeWidget.saveWidgetData<String>('time_dhuhr', timeDhuhr);
    if (timeAsr != null) await HomeWidget.saveWidgetData<String>('time_asr', timeAsr);
    if (timeMaghrib != null) await HomeWidget.saveWidgetData<String>('time_maghrib', timeMaghrib);
    if (timeIsha != null) await HomeWidget.saveWidgetData<String>('time_isha', timeIsha);

    if (timeFajrMs != null) await HomeWidget.saveWidgetData<int>('time_fajr_ms', timeFajrMs);
    if (timeSunriseMs != null) await HomeWidget.saveWidgetData<int>('time_sunrise_ms', timeSunriseMs);
    if (timeDhuhrMs != null) await HomeWidget.saveWidgetData<int>('time_dhuhr_ms', timeDhuhrMs);
    if (timeAsrMs != null) await HomeWidget.saveWidgetData<int>('time_asr_ms', timeAsrMs);
    if (timeMaghribMs != null) await HomeWidget.saveWidgetData<int>('time_maghrib_ms', timeMaghribMs);
    if (timeIshaMs != null) await HomeWidget.saveWidgetData<int>('time_isha_ms', timeIshaMs);
    if (timeTomorrowFajrMs != null) await HomeWidget.saveWidgetData<int>('time_tomorrow_fajr_ms', timeTomorrowFajrMs);

    if (activeMoment != null) await HomeWidget.saveWidgetData<String>('active_moment', activeMoment);
    if (ayahPoolJson != null) await HomeWidget.saveWidgetData<String>('ayah_pool_json', ayahPoolJson);
    if (dhikrPoolJson != null) await HomeWidget.saveWidgetData<String>('dhikr_pool_json', dhikrPoolJson);
    // لون تمييز الودجت — يطابق باقة `kAppAccentColors` المختارة بالتطبيق
    // (راجع `WidgetAccentColors.kt` بالجهة الأصلية لخريطة اللون↔الخلفية).
    if (accentId != null && accentId.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>('accent_id', accentId);
    }

    // تحديث الودجت الشامل (آية + ذكر + شريط الصلوات الكامل)
    await HomeWidget.updateWidget(
      name: kHumamWidgetAndroidName,
      androidName: kHumamWidgetAndroidName,
      qualifiedAndroidName: kHumamWidgetQualifiedAndroidName,
    );

    // تحديث ودجت مواقيت الصلاة الشريطي (4×1)
    await HomeWidget.updateWidget(
      name: kPrayerBarWidgetAndroidName,
      androidName: kPrayerBarWidgetAndroidName,
      qualifiedAndroidName: kPrayerBarWidgetQualifiedAndroidName,
    );

    // تحديث ودجت الأذكار والتسبيح (2×2)
    await HomeWidget.updateWidget(
      name: kDhikrWidgetAndroidName,
      androidName: kDhikrWidgetAndroidName,
      qualifiedAndroidName: kDhikrWidgetQualifiedAndroidName,
    );

    // تحديث ودجت الآية والذكر (4×2)
    await HomeWidget.updateWidget(
      name: kAyahDhikrWidgetAndroidName,
      androidName: kAyahDhikrWidgetAndroidName,
      qualifiedAndroidName: kAyahDhikrWidgetQualifiedAndroidName,
    );
  } catch (e, st) {
    debugPrint('updateHumamHomeWidget فشل: $e\n$st');
  }
}

/// يستمع لنقرات الودجت وينتقل للتبويب المناسب
void initHomeWidgetLaunchHandler(WidgetRef ref) {
  HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
    if (uri != null) _handleWidgetUri(uri, ref);
  });
  HomeWidget.widgetClicked.listen((uri) {
    if (uri != null) _handleWidgetUri(uri, ref);
  });
}

void _handleWidgetUri(Uri uri, WidgetRef ref) {
  final host = uri.host;
  final checkin = uri.queryParameters['checkin'];
  if (checkin != null && checkin.isNotEmpty) {
    final category = checkin.startsWith('prayer_') ? checkin : 'prayer_$checkin';
    final userPrefs = ref.read(userPrefsProvider);
    userPrefs.bumpCategoryStreakIfNewDay(category).then((_) {
      ref.read(categoryStreakVersionProvider.notifier).bump();
    });
  }
  if (host == 'prayer') {
    ref.read(rootTabIndexProvider.notifier).select(2); // تبويب الصلاة
  } else if (host == 'azkar') {
    ref.read(rootTabIndexProvider.notifier).select(3); // تبويب الأذكار
  } else if (host == 'quran') {
    ref.read(rootTabIndexProvider.notifier).select(1); // تبويب المصحف
  } else {
    ref.read(rootTabIndexProvider.notifier).select(0); // تبويب الرئيسية
  }
}
