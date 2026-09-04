import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import 'user_prefs.dart';
import 'user_repository.dart';

/// فئات سلاسل الاستمرار المتاحة للعرض في الداشبورد
class DashboardStreakItem {
  final String key;
  final String label;
  final IconData icon;
  final Color defaultColor;
  final String description;

  const DashboardStreakItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.defaultColor,
    required this.description,
  });
}

const List<DashboardStreakItem> kAvailableDashboardStreaks = [
  DashboardStreakItem(
    key: 'prayers_fard',
    label: 'الصلوات الخمس',
    icon: Icons.mosque_outlined,
    defaultColor: Color(0xFF1B8A72),
    description: 'متابعة أداء الصلوات المكتوبة في وقتها',
  ),
  DashboardStreakItem(
    key: UserCategories.morningAzkar,
    label: 'أذكار الصباح',
    icon: Icons.wb_sunny_outlined,
    defaultColor: AppColors.goldDeep,
    description: 'سلسلة الحفاظ على أذكار الصباح بعد الفجر',
  ),
  DashboardStreakItem(
    key: UserCategories.eveningAzkar,
    label: 'أذكار المساء',
    icon: Icons.nights_stay_outlined,
    defaultColor: Color(0xFF2C5E8A),
    description: 'سلسلة الحفاظ على أذكار المساء بعد العصر',
  ),
  DashboardStreakItem(
    key: 'daily_quran',
    label: 'الورد اليومي',
    icon: Icons.menu_book_outlined,
    defaultColor: Color(0xFF1B8A72),
    description: 'سلسلة القراءة اليومية في المصحف الشريف',
  ),
  DashboardStreakItem(
    key: UserCategories.hifz,
    label: 'الحفظ والمراجعة',
    icon: Icons.school_outlined,
    defaultColor: Color(0xFF7E429B),
    description: 'سلسلة مراجعة وتثبيت خطط الحفظ',
  ),
  DashboardStreakItem(
    key: UserCategories.nightAzkar,
    label: 'أذكار النوم',
    icon: Icons.bedtime_outlined,
    defaultColor: Color(0xFF1A355B),
    description: 'سلسلة سنن وأذكار قبل النوم',
  ),
  DashboardStreakItem(
    key: UserCategories.qiyam,
    label: 'قيام الليل',
    icon: Icons.dark_mode_outlined,
    defaultColor: Color(0xFF8E5B45),
    description: 'سلسلة إحياء الليل والوتر',
  ),
  DashboardStreakItem(
    key: 'prayers_rawatib',
    label: 'السنن الرواتب',
    icon: Icons.auto_awesome_outlined,
    defaultColor: AppColors.goldDeep,
    description: 'سلسلة السنن الرواتب المؤكدة والمستحبة',
  ),
  DashboardStreakItem(
    key: 'tasbih',
    label: 'التسبيح والذكر',
    icon: Icons.fingerprint,
    defaultColor: Color(0xFF00796B),
    description: 'سلسلة التسبيح والاستغفار بالمسبحة الإلكترونية',
  ),
  DashboardStreakItem(
    key: UserCategories.customHabitsAny,
    label: 'عاداتي',
    icon: Icons.checklist_rtl_outlined,
    defaultColor: Color(0xFF546E7A),
    description: 'عادات تعرّفها بنفسك — اسم وهدف يومي وتذكير حرّ',
  ),
];

const _kDashboardStreaksPrefKey = 'dashboard_custom_streaks_v1';

final Set<String> _kDefaultStreaks = {
  'prayers_fard',
  UserCategories.morningAzkar,
  UserCategories.eveningAzkar,
  'daily_quran',
  UserCategories.hifz,
  UserCategories.nightAzkar,
};

class DashboardCustomPrefsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getStringList(_kDashboardStreaksPrefKey);
    if (saved == null || saved.isEmpty) {
      return _kDefaultStreaks;
    }
    return saved.toSet();
  }

  Future<void> toggle(String key) async {
    final current = {...state};
    if (current.contains(key)) {
      if (current.length > 1) {
        current.remove(key);
      }
    } else {
      current.add(key);
    }
    state = current;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kDashboardStreaksPrefKey, current.toList());
  }

  Future<void> resetToDefaults() async {
    state = _kDefaultStreaks;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(
      _kDashboardStreaksPrefKey,
      _kDefaultStreaks.toList(),
    );
  }
}

final dashboardCustomPrefsProvider =
    NotifierProvider<DashboardCustomPrefsNotifier, Set<String>>(
      DashboardCustomPrefsNotifier.new,
    );

// بطاقات الواجهة الرئيسية
class DashboardCardItem {
  final String key;
  final String label;
  final IconData icon;
  final String description;

  const DashboardCardItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.description,
  });
}

const List<DashboardCardItem> kAvailableDashboardCards = [
  DashboardCardItem(
    key: 'prayer_hero',
    label: 'مواقيت الصلاة والعد التنازلي',
    icon: Icons.access_time_outlined,
    description: 'البطاقة العلوية للصلاة القادمة والوقت المتبقي',
  ),
  DashboardCardItem(
    key: 'period_ayah',
    label: 'آية الفترة والذكر',
    icon: Icons.auto_awesome_outlined,
    description: 'عرض آية مناسبة لفترة اليوم وذكر نبوي مبارك',
  ),
  DashboardCardItem(
    key: 'daily_hadith_name',
    label: 'حديث اليوم واسم من أسماء الله',
    icon: Icons.menu_book_outlined,
    description:
        'حديث نبوي واسم من أسماء الله الحسنى يتجدّدان كل يوم عند فتح التطبيق',
  ),
  DashboardCardItem(
    key: 'streaks_section',
    label: 'سلاسل الاستمرار',
    icon: Icons.local_fire_department_outlined,
    description: 'قسم متابعة الاستمرار على الطاعات والأوراد',
  ),
  DashboardCardItem(
    key: 'khatma_card',
    label: 'خطة الختمة',
    icon: Icons.menu_book_outlined,
    description: 'متابعة وتيرة الختمة وورد اليوم في المصحف',
  ),
  DashboardCardItem(
    key: 'hifz_card',
    label: 'خطة الحفظ والمراجعة',
    icon: Icons.school_outlined,
    description: 'متابعة محفوظاتك القرآنية وجدول التكرار الذكي',
  ),
  DashboardCardItem(
    key: 'continue_reading',
    label: 'متابعة القراءة والفواصل',
    icon: Icons.bookmark_border_outlined,
    description: 'الانتقال السريع لآخر صفحة وفاصلة مسجلة',
  ),
  DashboardCardItem(
    key: 'start_plan_cta',
    label: 'دعوة لبدء خطة ختمة/حفظ',
    icon: Icons.rocket_launch_outlined,
    description: 'تظهر فقط لو ما عندك خطة نشطة بعد — تدعوك تبدأ واحدة',
  ),
];

const _kDashboardCardsPrefKey = 'dashboard_custom_cards_v1';

final Set<String> _kDefaultCards = {
  'prayer_hero',
  'period_ayah',
  'daily_hadith_name',
  'streaks_section',
  'khatma_card',
  'hifz_card',
  'continue_reading',
  'start_plan_cta',
};

class DashboardCardsPrefsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getStringList(_kDashboardCardsPrefKey);
    if (saved == null || saved.isEmpty) {
      return _kDefaultCards;
    }
    return saved.toSet();
  }

  Future<void> toggle(String key) async {
    final current = {...state};
    if (current.contains(key)) {
      if (current.length > 1) {
        current.remove(key);
      }
    } else {
      current.add(key);
    }
    state = current;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kDashboardCardsPrefKey, current.toList());
  }

  Future<void> resetToDefaults() async {
    state = _kDefaultCards;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kDashboardCardsPrefKey, _kDefaultCards.toList());
  }
}

final dashboardCardsPrefsProvider =
    NotifierProvider<DashboardCardsPrefsNotifier, Set<String>>(
      DashboardCardsPrefsNotifier.new,
    );
