import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/user/user_prefs.dart' show sharedPreferencesProvider;
import '../../core/theme/app_colors.dart';
import 'data/daily_hadith_data.dart';
import 'hadith_books_screen.dart';
import 'hadith_download_service.dart';
import 'widgets/daily_hadith_card.dart';
import 'widgets/daily_hadith_category_chips.dart';
import 'widgets/daily_hadith_fawaid_card.dart';
import 'widgets/daily_hadith_index_sheet.dart';
import 'widgets/daily_hadith_navigation_bar.dart';
import 'widgets/daily_hadith_notification_card.dart';
import '../story_maker/models/story_content.dart';
import '../story_maker/ui/ayah_story_maker_screen.dart';

// يُعاد تصدير طبقة البيانات هنا حتى تبقى الاستيرادات القديمة من
// `daily_hadith_screen.dart` (مثل `show kCuratedDailyHadiths`) تعمل دون
// تغيير، رغم انتقال البيانات فعلياً إلى `data/daily_hadith_data.dart`.
export 'data/daily_hadith_data.dart';

class DailyHadithScreen extends ConsumerStatefulWidget {
  const DailyHadithScreen({
    super.key,
    this.initialIndex,
    this.initialHadithId,
    this.scrollToFawaid = false,
  });

  final int? initialIndex;
  final int? initialHadithId;
  final bool scrollToFawaid;

  @override
  ConsumerState<DailyHadithScreen> createState() => _DailyHadithScreenState();
}

const _kHadithVarietyBannerDismissedKey = 'daily_hadith_variety_banner_dismissed';

class _DailyHadithScreenState extends ConsumerState<DailyHadithScreen> {
  late final ScrollController _scrollController;
  int _selectedIndex = 0;
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  bool _varietyBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final initialIdx = widget.initialIndex;
    final initialId = widget.initialHadithId;
    if (initialIdx != null && initialIdx >= 0 && initialIdx < kCuratedDailyHadiths.length) {
      _selectedIndex = initialIdx;
    } else if (initialId != null) {
      final found = kCuratedDailyHadiths.indexWhere((h) => h.id == initialId);
      _selectedIndex = found != -1 ? found : 0;
    } else {
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      _selectedIndex = dayOfYear % kCuratedDailyHadiths.length;
    }
    _varietyBannerDismissed =
        ref.read(sharedPreferencesProvider).getBool(_kHadithVarietyBannerDismissedKey) ?? false;

    if (widget.scrollToFawaid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            260,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _dismissVarietyBanner() {
    setState(() => _varietyBannerDismissed = true);
    ref.read(sharedPreferencesProvider).setBool(_kHadithVarietyBannerDismissedKey, true);
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
    // لا تنويع فعلي بلا تنزيل كتاب حديث حقيقي (البخاري/مسلم/إلخ) —
    // الكتابان المضمَّنان بالتطبيق (الأربعون النووية/القدسية) بلا تنزيل لا
    // يُحسبان هون؛ "حديث اليوم" بيدور فقط على ٣٦ حديثاً مختاراً يدوياً
    // (`kCuratedDailyHadiths`) بغضّ النظر عن هالبانر، لكن التنزيل يفتح
    // للمستخدم تصفّح/بحث آلاف الأحاديث الحقيقية بميزة "موسوعة الحديث".
    final hasDownloadedAnyBook = ref.watch(
      hadithDownloadControllerProvider.select((s) => s.downloadedKeys.isNotEmpty),
    );

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
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (!hasDownloadedAnyBook && !_varietyBannerDismissed) ...[
            _HadithVarietyBanner(onDismiss: _dismissVarietyBanner),
            const SizedBox(height: 14),
          ],

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
            onDesignCard: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AyahStoryMakerScreen(
                    initialContent: HadithContent(
                      hadithText: hadith.matn,
                      narrator: hadith.narrator,
                      sourceBook: '${hadith.source} (${hadith.grade})',
                      explanation: hadith.fawaid.isNotEmpty
                          ? hadith.fawaid.first
                          : null,
                    ),
                  ),
                ),
              );
            },
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

/// بانر اقتراح تنزيل كتاب حديث (بطلب صريح) — يظهر فقط لمن لم يُنزّل أي
/// كتاب بعد، ويختفي دائماً بعد إغلاقه يدوياً (`_kHadithVarietyBannerDismissedKey`)
/// حتى لو نزّل كتاباً لاحقاً ثم حذفه. الهدف تعريف المستخدم أن "حديث اليوم"
/// الحالي مبني على قائمة مختارة يدوياً محدودة، وأن تنزيل كتاب حقيقي (من
/// شاشة "موسوعة الحديث") يفتح له تصفّح وبحث آلاف الأحاديث الحقيقية.
class _HadithVarietyBanner extends StatelessWidget {
  const _HadithVarietyBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.goldDeep.withValues(alpha: isDark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldDeep.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_stories_outlined, color: AppColors.goldDeep, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حديث اليوم حالياً من قائمة مختارة محدودة',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'نزّل كتاب حديث كامل (كصحيح البخاري أو مسلم) من "موسوعة الحديث" لتنويع أكبر وتصفّح آلاف الأحاديث.',
                  style: TextStyle(fontSize: 11, height: 1.5),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HadithBooksScreen()),
                  ),
                  child: const Text(
                    'تصفّح كتب الحديث ونزّل واحداً ←',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.goldDeep),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'إخفاء',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
