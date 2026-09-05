import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'data/daily_hadith_data.dart';
import 'widgets/daily_hadith_card.dart';
import 'widgets/daily_hadith_category_chips.dart';
import 'widgets/daily_hadith_fawaid_card.dart';
import 'widgets/daily_hadith_index_sheet.dart';
import 'widgets/daily_hadith_navigation_bar.dart';
import 'widgets/daily_hadith_notification_card.dart';

// يُعاد تصدير طبقة البيانات هنا حتى تبقى الاستيرادات القديمة من
// `daily_hadith_screen.dart` (مثل `show kCuratedDailyHadiths`) تعمل دون
// تغيير، رغم انتقال البيانات فعلياً إلى `data/daily_hadith_data.dart`.
export 'data/daily_hadith_data.dart';

class DailyHadithScreen extends ConsumerStatefulWidget {
  const DailyHadithScreen({super.key});

  @override
  ConsumerState<DailyHadithScreen> createState() => _DailyHadithScreenState();
}

class _DailyHadithScreenState extends ConsumerState<DailyHadithScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // تدوير يومي موثوق حسب أيام السنة
    final dayKey = (now.year * 366) + (now.month * 31) + now.day;
    _selectedIndex = dayKey % kCuratedDailyHadiths.length;
  }

  List<DailyHadithItem> get _filteredHadiths {
    return kCuratedDailyHadiths.where((h) {
      final matchesCat =
          _selectedCategory == 'الكل' || h.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          h.matn.contains(_searchQuery) ||
          h.narrator.contains(_searchQuery) ||
          h.source.contains(_searchQuery) ||
          h.fawaid.any((f) => f.contains(_searchQuery));
      return matchesCat && matchesQuery;
    }).toList();
  }

  void _pickRandomHadith() {
    HapticFeedback.mediumImpact();
    final list = _filteredHadiths;
    if (list.isEmpty) return;
    final r = math.Random().nextInt(list.length);
    final target = list[r];
    setState(() {
      _selectedIndex = kCuratedDailyHadiths.indexOf(target);
    });
  }

  void _shareHadith(DailyHadithItem hadith) {
    final text = '📜 حديث اليوم:\n\n'
        '«${hadith.matn}»\n\n'
        '🎙️ الراوي: ${hadith.narrator}\n'
        '📚 المصدر: ${hadith.source} (${hadith.grade})\n\n'
        '💡 من فوائد الحديث:\n'
        '${hadith.fawaid.map((f) => '• $f').join('\n')}\n\n'
        'تطبيق هُمَام 🕌';
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _copyHadith(DailyHadithItem hadith) {
    final text = '«${hadith.matn}»\n[${hadith.source}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الحديث الشريف إلى الحافظة ✨'),
        backgroundColor: Color(0xFF1B8A72),
      ),
    );
  }

  void _showAllHadithsSheet() {
    showDailyHadithIndexSheet(
      context,
      selectedIndex: _selectedIndex,
      filteredHadiths: () => _filteredHadiths,
      onSearchChanged: (v) => setState(() => _searchQuery = v),
      onHadithSelected: (origIndex) => setState(() => _selectedIndex = origIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hadith = kCuratedDailyHadiths[_selectedIndex];

    final categories = [
      'الكل',
      'الإخلاص والنية',
      'الصلاة والطهور',
      'فضل القرآن والعلم',
      'الصبر واليقين',
      'حسن الخلق والرفق',
      'بر الوالدين وصلة الرحم',
      'حفظ اللسان والآداب',
      'فضل الذكر والدعاء',
      'الصدقة والإنفاق',
      'التوبة والاستغفار',
      'الأمانة والصدق',
      'محبة المسلمين والأخوة',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('حديث اليوم والفوائد النبوية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'فهرس الأحاديث',
            onPressed: _showAllHadithsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'مشاركة',
            onPressed: () => _shareHadith(hadith),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // شريط الفئات السريعة
          DailyHadithCategoryChips(
            categories: categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) {
              setState(() {
                _selectedCategory = cat;
                final filtered = _filteredHadiths;
                if (filtered.isNotEmpty && !filtered.contains(hadith)) {
                  _selectedIndex = kCuratedDailyHadiths.indexOf(filtered.first);
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // شريط التنقل بين الأحاديث وزر الحديث العشوائي
          DailyHadithNavigationBar(
            hadithId: hadith.id,
            totalCount: kCuratedDailyHadiths.length,
            onPrevious: _selectedIndex > 0
                ? () => setState(() => _selectedIndex--)
                : null,
            onNext: _selectedIndex < kCuratedDailyHadiths.length - 1
                ? () => setState(() => _selectedIndex++)
                : null,
            onRandom: _pickRandomHadith,
          ),
          const SizedBox(height: 14),

          // كرت متن الحديث الرئيسي
          DailyHadithCard(
            hadith: hadith,
            onCopy: () => _copyHadith(hadith),
          ),
          const SizedBox(height: 20),

          // الفوائد والدروس المستنبطة
          DailyHadithFawaidCard(fawaid: hadith.fawaid),
          const SizedBox(height: 20),

          // كرت ضبط إشعار حديث اليوم
          const DailyHadithNotificationCard(),
        ],
      ),
    );
  }
}
