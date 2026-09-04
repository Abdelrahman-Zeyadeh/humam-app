import 'package:flutter/widgets.dart';

/// مفاتيح عامة لعناصر واجهة محددة داخل شاشات التطبيق الحقيقية
/// يتم استخدامها لتحديد مواقع العناصر بدقة ووضع دائرة تركيز متحركة (Spotlight & Pulsing Ring)
/// حولها أثناء الجولة التعريفية والكتالوج التفاعلي.

// 1. الرئيسية
final GlobalKey homeStreakWirdKey = GlobalKey(debugLabel: 'onboarding_home_streak_wird');
final GlobalKey dashboardCustomizeButtonKey = GlobalKey(debugLabel: 'onboarding_dashboard_customize_button');

// 2. المصحف
final GlobalKey mushafTafsirReadingButtonKey = GlobalKey(debugLabel: 'onboarding_mushaf_tafsir_reading_button');
final GlobalKey mushafSurahIndexButtonKey = GlobalKey(debugLabel: 'onboarding_mushaf_surah_index_button');
final GlobalKey mushafAudioBarKey = GlobalKey(debugLabel: 'onboarding_mushaf_audio_bar');

// 3. الصلاة
final GlobalKey qiblaButtonKey = GlobalKey(debugLabel: 'onboarding_qibla_button');
final GlobalKey firstPrayerRowKey = GlobalKey(debugLabel: 'onboarding_first_prayer_row');
final GlobalKey adhanVoiceCardKey = GlobalKey(debugLabel: 'onboarding_adhan_voice_card');

// 4. الأذكار
final GlobalKey azkarTasbihButtonKey = GlobalKey(debugLabel: 'onboarding_azkar_tasbih_button');
final GlobalKey azkarQuickCardsKey = GlobalKey(debugLabel: 'onboarding_azkar_quick_cards');

// 5. أدواتي
final GlobalKey toolsKhatmaCardKey = GlobalKey(debugLabel: 'onboarding_tools_khatma_card');
final GlobalKey toolsGroupsCardKey = GlobalKey(debugLabel: 'onboarding_tools_groups_card');
final GlobalKey toolsHadithCardKey = GlobalKey(debugLabel: 'onboarding_tools_hadith_card');

