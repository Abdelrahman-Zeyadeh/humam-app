import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/user_prefs.dart';
import '../../core/theme/app_colors.dart';
import 'mushaf_page_jump_dialog.dart';
import 'mushaf_page_widget.dart';
import 'mushaf_search_screen.dart';
import 'mushaf_settings.dart';
import 'mushaf_surah_index_sheet.dart';
import 'quran_audio_bar.dart';

const int kMushafPageCount = 604;

/// شاشة عرض المصحف: تقليب أفقي بين الصفحات (٦٠٤ صفحة)، كل صفحة تُبنى
/// وتُحمَّل خطها عند زيارتها فقط. الاتجاه العام RTL (مضبوط بجذر التطبيق)
/// فيخلي السحب الطبيعي يقدّم للصفحة التالية بترتيب المصحف.
///
/// حالياً: أول ٥٠ صفحة فقط لها خط مُضمَّن (راجع MushafFontService)، الباقي
/// يعرض رسالة "غير متوفر بعد" ريثما يُبنى مدير التنزيلات.
class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({super.key, this.initialPage});
  /// null = ابدأ من آخر صفحة مقروءة محفوظة (أو ١ إن لم توجد). مرّر رقماً
  /// صريحاً فقط لفتح صفحة محدَّدة عمداً (قفز من فهرس/بحث مثلاً).
  final int? initialPage;

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ?? ref.read(userPrefsProvider).lastReadPage ?? 1;
    _controller = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(int page) {
    _controller.jumpToPage(page - 1);
    setState(() => _currentPage = page);
  }

  Future<void> _openSurahIndex() async {
    final startPage = await MushafSurahIndexSheet.show(context);
    if (startPage != null) _jumpTo(startPage);
  }

  Future<void> _openPageJump() async {
    final page = await MushafPageJumpDialog.show(context);
    if (page != null) _jumpTo(page);
  }

  Future<void> _openSearch() async {
    final page = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const MushafSearchScreen()),
    );
    if (page != null) _jumpTo(page);
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    setState(() => _currentPage = page);
    final prefs = ref.read(userPrefsProvider);
    prefs.setLastReadPage(page);
    prefs.bumpStreakIfNewDay();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.paperDark : AppColors.paper;
    final fg = isDark ? AppColors.inkOnDark : AppColors.ink;
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(mushafTextSizeProvider);
    final memorizationOn = ref.watch(memorizationModeProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: fg,
        leading: IconButton(
          icon: const Icon(Icons.list_alt_outlined),
          tooltip: 'فهرس السور',
          onPressed: _openSurahIndex,
        ),
        title: InkWell(
          onTap: _openPageJump,
          child: Text('صفحة $_currentPage', style: TextStyle(color: fg, fontSize: 15)),
        ),
        actions: [
          if (memorizationOn)
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined),
              tooltip: 'إخفاء الكل',
              onPressed: () => ref.read(revealedAyahsProvider.notifier).hideAll(),
            ),
          IconButton(
            icon: Icon(memorizationOn ? Icons.school : Icons.school_outlined),
            tooltip: 'وضع الحفظ',
            color: memorizationOn ? AppColors.gold : null,
            onPressed: () {
              ref.read(memorizationModeProvider.notifier).toggle();
              if (!memorizationOn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('وضع الحفظ: اضغط أي آية لكشفها')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'حجم الخط',
            onPressed: () => ref.read(mushafTextSizeProvider.notifier).cycle(),
          ),
          IconButton(
            icon: Icon(switch (themeMode) {
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            }),
            tooltip: 'الوضع الليلي',
            onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: kMushafPageCount,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final page = index + 1;
                return RepaintBoundary(
                  key: ValueKey('mushaf_page_${page}_${textSize.name}'),
                  child: MushafPageWidget(page: page),
                );
              },
            ),
          ),
          const QuranAudioBar(),
        ],
      ),
    );
  }
}
