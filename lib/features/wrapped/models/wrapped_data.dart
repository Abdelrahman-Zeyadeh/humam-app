import 'package:flutter/material.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/data/user/user_repository.dart' show UserCategories;

class FaithWrappedData {
  final String userName;
  final int totalPrayers;
  final int totalSunnahs;
  final int totalQuranPages;
  final int azkarCompletedDays;
  final int qiyamNights;
  final int weeklyScorePercentage;
  final String spiritualBadgeTitle;
  final String spiritualBadgeQuote;
  final IconData spiritualBadgeIcon;

  const FaithWrappedData({
    required this.userName,
    required this.totalPrayers,
    required this.totalSunnahs,
    required this.totalQuranPages,
    required this.azkarCompletedDays,
    required this.qiyamNights,
    required this.weeklyScorePercentage,
    required this.spiritualBadgeTitle,
    required this.spiritualBadgeQuote,
    required this.spiritualBadgeIcon,
  });

  static Future<FaithWrappedData> compute(UserPrefs prefs) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceSaturday = (today.weekday % 7 + 1) % 7;

    var prayersCount = 0;
    final fardCategories = [
      UserCategories.fajr,
      UserCategories.dhuhr,
      UserCategories.asr,
      UserCategories.maghrib,
      UserCategories.isha,
    ];

    for (final cat in fardCategories) {
      final days = await prefs.fixedWeekCompletionFor(cat);
      prayersCount += days.where((d) => d).length;
    }

    final morningDays = await prefs.fixedWeekCompletionFor(UserCategories.morningAzkar);
    final eveningDays = await prefs.fixedWeekCompletionFor(UserCategories.eveningAzkar);
    var azkarDays = 0;
    for (var i = 0; i < 7; i++) {
      if ((i < morningDays.length && morningDays[i]) ||
          (i < eveningDays.length && eveningDays[i])) {
        azkarDays++;
      }
    }

    var qiyamCount = 0;
    final qiyamDays = await prefs.fixedWeekCompletionFor(UserCategories.qiyam);
    qiyamCount = qiyamDays.where((d) => d).length;

    // تقدير صفحات القرآن لهذا الأسبوع بناءً على الورد والستريك
    final quranPages = (prefs.streakDays > 0 ? (prefs.streakDays % 7 + 1) * 4 : 10);
    final sunnahCount = (prayersCount * 0.4).round();

    // النسبة الإجمالية
    final totalOpportunities = (daysSinceSaturday + 1) * 7;
    final completedItems = prayersCount + azkarDays + qiyamCount;
    final score = totalOpportunities > 0
        ? ((completedItems / totalOpportunities) * 100).clamp(20, 100).round()
        : 85;

    // تحديد الوسام الروحي المناسب
    String badgeTitle;
    String badgeQuote;
    IconData badgeIcon;

    if (qiyamCount >= 3) {
      badgeTitle = 'قائم الليل والمستغفر بالأسحار';
      badgeQuote = '«تَتَجَافَىٰ جُنُوبُهُمْ عَنِ ٱلْمَضَاجِعِ يَدْعُونَ رَبَّهُمْ خَوْفًا وَطَمَعًا»';
      badgeIcon = Icons.nightlight_round;
    } else if (prayersCount >= 25) {
      badgeTitle = 'المحافظ على الصلاة والصلة';
      badgeQuote = '«وَأَقِمِ ٱلصَّلَوٰةَ لِذِكْرِىٓ» — صلواتك كانت نوراً وبرهاناً طوال الأسبوع';
      badgeIcon = Icons.mosque_rounded;
    } else if (azkarDays >= 5) {
      badgeTitle = 'الذاكر الله كثيراً والمطمئن';
      badgeQuote = '«أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ»';
      badgeIcon = Icons.favorite_rounded;
    } else {
      badgeTitle = 'صاحب الهمّة والإقبال';
      badgeQuote = '«وَسَارِعُوٓا۟ إِلَىٰ مَغْفِرَةٍ مِّن رَّبِّكُمْ» — خطوات مباركة نحو الثبات';
      badgeIcon = Icons.auto_awesome_rounded;
    }

    final name = prefs.userName.isNotEmpty ? prefs.userName : 'صاحب هُمَام';

    return FaithWrappedData(
      userName: name,
      totalPrayers: prayersCount,
      totalSunnahs: sunnahCount,
      totalQuranPages: quranPages,
      azkarCompletedDays: azkarDays,
      qiyamNights: qiyamCount,
      weeklyScorePercentage: score,
      spiritualBadgeTitle: badgeTitle,
      spiritualBadgeQuote: badgeQuote,
      spiritualBadgeIcon: badgeIcon,
    );
  }
}
