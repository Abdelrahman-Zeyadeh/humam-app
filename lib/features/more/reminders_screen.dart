import 'package:flutter/material.dart';

import '../../core/data/user/user_repository.dart' show UserCategories;
import 'widgets/activity_reminder_row.dart';
import 'widgets/daily_hadith_reminder_row.dart';
import 'widgets/daily_name_of_allah_reminder_row.dart';
import 'widgets/evening_summary_reminder_row.dart';
import 'widgets/hifz_reminder_row.dart';
import 'widgets/hourly_dhikr_section.dart';
import 'widgets/qiyam_reminder_row.dart';
import 'widgets/reminder_section_title.dart';
import 'widgets/sunnah_reminders_section.dart';
import 'widgets/weekly_summary_reminder_row.dart';

/// شاشة "التذكيرات" — كل ما يخصّ تذكيرات التطبيق مجمَّعاً بمكان واحد
/// (كانت موزَّعة داخل شاشة الإعدادات نفسها: تذكيرات يومية، أذكار كل ساعة،
/// تنبيهات السنن). نُقلت هون بالكامل بطلب صاحب المشروع — الإعدادات
/// أصبحت مخصَّصة للمظهر/الصوت/النسخ الاحتياطي، والتذكيرات قسم مستقل
/// بشاشة "أدواتي".
///
/// الشاشة نفسها مجرّد تنسيق (composition): كل صف/قسم تذكير استُخرج لملفه
/// الخاص بمجلد `widgets/` (كان ~١٦٧٣ سطراً بملف واحد)، بلا أي تغيير سلوكي.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التذكيرات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ReminderSectionTitle('تذكيرات يومية'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const ActivityReminderRow(
                  category: UserCategories.morningAzkar,
                  label: 'أذكار الصباح',
                  icon: Icons.wb_sunny_outlined,
                ),
                const Divider(height: 1),
                const ActivityReminderRow(
                  category: UserCategories.eveningAzkar,
                  label: 'أذكار المساء',
                  icon: Icons.nights_stay_outlined,
                ),
                const Divider(height: 1),
                const ActivityReminderRow(
                  category: UserCategories.dailyWird,
                  label: 'الورد اليومي',
                  icon: Icons.menu_book_outlined,
                ),
                const Divider(height: 1),
                const EveningSummaryReminderRow(),
                const Divider(height: 1),
                const WeeklySummaryReminderRow(),
                const Divider(height: 1),
                // بطلب صاحب المشروع "اشعارات التذكير الموجودة بكل مكان
                // اجمعها بمكان واحد" — تذكير قيام الليل والحفظ كانا مخفيَّين
                // داخل شاشتيهما فقط (`qiyam_screen.dart`/`hifz_screen.dart`)
                // رغم استخدامهما نفس نظام التذكيرات؛ هون **نفس** التخزين
                // (`userPrefsProvider`/`hifzPrefsProvider`) لا نسخة موازية،
                // فالتعديل من أي شاشة ينعكس تلقائياً بالثانية.
                const QiyamReminderRow(),
                const Divider(height: 1),
                const HifzReminderRow(),
                const Divider(height: 1),
                // بطلب صاحب المشروع "حديث اليوم بحب ينبعث كاشعار... واسماء
                // الله الحسنى كذلك"، وبنفس منطق "هو يحدد اي ساعة".
                const DailyHadithReminderRow(),
                const Divider(height: 1),
                const DailyNameOfAllahReminderRow(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const ReminderSectionTitle('أذكار وأدعية كل ساعة 📿'),
          const HourlyDhikrSection(),
          const SizedBox(height: 24),
          const ReminderSectionTitle('تنبيهات السنن والأيام الفاضلة'),
          const SunnahRemindersSection(),
        ],
      ),
    );
  }
}
