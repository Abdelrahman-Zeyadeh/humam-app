import 'package:hijri/hijri_calendar.dart';

enum FastingType {
  monday,
  thursday,
  whiteDay,
  arafah,
  ashura,
  tasua,
  shawwal,
  custom,
}

class FastingDay {
  final DateTime date;
  final HijriCalendar hijriDate;
  final FastingType type;
  final String title;
  final String description;

  const FastingDay({
    required this.date,
    required this.hijriDate,
    required this.type,
    required this.title,
    required this.description,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool get isTomorrow {
    final tom = DateTime.now().add(const Duration(days: 1));
    return date.year == tom.year && date.month == tom.month && date.day == tom.day;
  }

  static List<FastingDay> getUpcomingFastingDays({int daysAhead = 30}) {
    final list = <FastingDay>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var i = 0; i < daysAhead; i++) {
      final d = today.add(Duration(days: i));
      final h = HijriCalendar.fromDate(d);

      // 1. الأيام البيض (13, 14, 15) عدا أيام التشريق في ذي الحجة ورمضان
      if (h.hMonth != 9 && (h.hDay == 13 || h.hDay == 14 || h.hDay == 15)) {
        if (!(h.hMonth == 12 && (h.hDay == 13 || h.hDay == 14 || h.hDay == 15))) {
          list.add(FastingDay(
            date: d,
            hijriDate: h,
            type: FastingType.whiteDay,
            title: 'الأيام البيض (${h.hDay} ${h.longMonthName})',
            description: 'صيام ثلاثة أيام من كل شهر كصيام الدهر كله',
          ));
          continue;
        }
      }

      // 2. يوم عرفة (9 ذو الحجة)
      if (h.hMonth == 12 && h.hDay == 9) {
        list.add(FastingDay(
          date: d,
          hijriDate: h,
          type: FastingType.arafah,
          title: 'يوم عرفة المبارك',
          description: 'يكفر السنة الماضية والباقية',
        ));
        continue;
      }

      // 3. تاسوعاء وعاشوراء (9 و 10 محرم)
      if (h.hMonth == 1 && h.hDay == 10) {
        list.add(FastingDay(
          date: d,
          hijriDate: h,
          type: FastingType.ashura,
          title: 'يوم عاشوراء',
          description: 'يكفر السنة الماضية',
        ));
        continue;
      } else if (h.hMonth == 1 && h.hDay == 9) {
        list.add(FastingDay(
          date: d,
          hijriDate: h,
          type: FastingType.tasua,
          title: 'يوم تاسوعاء',
          description: 'مستحب صيامه مع عاشوراء مخالفة لليهود',
        ));
        continue;
      }

      // 4. صيام الإثنين والخميس (خارج رمضان وأيام العيد)
      if (h.hMonth != 9 && !(h.hMonth == 10 && h.hDay == 1) && !(h.hMonth == 12 && (h.hDay >= 10 && h.hDay <= 13))) {
        if (d.weekday == DateTime.monday) {
          list.add(FastingDay(
            date: d,
            hijriDate: h,
            type: FastingType.monday,
            title: 'سنة الإثنين',
            description: 'تُعرض فيه الأعمال على الله تعالى',
          ));
        } else if (d.weekday == DateTime.thursday) {
          list.add(FastingDay(
            date: d,
            hijriDate: h,
            type: FastingType.thursday,
            title: 'سنة الخميس',
            description: 'تُعرض فيه الأعمال على الله تعالى',
          ));
        }
      }
    }

    return list;
  }
}
