import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../audio/ui/global_mini_audio_player_bar.dart';
import '../auth/cloud_sync_service.dart';
import '../azkar/azkar_library_screen.dart';
import '../azkar/post_prayer_azkar_screen.dart';
import '../groups/providers/groups_providers.dart';
import '../home/home_screen.dart';
import '../more/more_placeholder_screen.dart';
import '../mushaf/mushaf_screen.dart';
import '../mushaf/mushaf_settings.dart' show mushafChromeVisibleProvider;
import '../notifications/adhan_notification_service.dart'
    show kPendingOpenPostPrayerAzkarKey, postPrayerAzkarOpenCallback;
import '../onboarding/onboarding_screen.dart';
import '../prayer/prayer_screen.dart';
import '../widget/home_widget_service.dart' show initHomeWidgetLaunchHandler;

const Duration _kNavAnim = Duration(milliseconds: 220);

/// فهرس التبويب النشط في القشرة الرئيسية.
class RootTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final rootTabIndexProvider = NotifierProvider<RootTabIndexNotifier, int>(
  RootTabIndexNotifier.new,
);

class _TabDef {
  const _TabDef({
    required this.label,
    required this.icon,
    required this.builder,
  });
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

final _tabs = <_TabDef>[
  _TabDef(
    label: 'الرئيسية',
    icon: Icons.home_outlined,
    builder: (_) => const HomeScreen(),
  ),
  _TabDef(
    label: 'المصحف',
    icon: Icons.menu_book_outlined,
    builder: (_) => const MushafScreen(),
  ),
  _TabDef(
    label: 'الصلاة',
    icon: Icons.access_time_outlined,
    builder: (_) => const PrayerScreen(),
  ),
  _TabDef(
    label: 'الأذكار',
    icon: Icons.brightness_2_outlined,
    builder: (_) => const AzkarLibraryScreen(),
  ),
  _TabDef(
    label: 'أدواتي',
    icon: Icons.grid_view_rounded,
    builder: (_) => const MorePlaceholderScreen(),
  ),
];

/// القشرة الرئيسية مع شريط التنقل السفلي العائم (Floating Pill Dock)
class RootShell extends ConsumerStatefulWidget {
  const RootShell({
    super.key,
    this.startTour = false,
  });

  final bool startTour;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> with WidgetsBindingObserver {
  final _built = List<Widget?>.filled(_tabs.length, null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initHomeWidgetLaunchHandler(ref);
    // نسخ احتياطي سحابي دوري تلقائي — راجع `CloudSyncController.
    // maybeAutoSync` (فشل صامت تماماً لو غير مسجَّل دخول/بلا إنترنت الآن).
    unawaited(ref.read(cloudSyncControllerProvider.notifier).maybeAutoSync());
    // "اقرأ الآن" بتنبيه أذكار بعد الصلاة — فتح فوري لو التطبيق حيّ بنفس
    // الجلسة (راجع توثيق `postPrayerAzkarOpenCallback`)، بلا حاجة إعادة
    // بناء الشاشة أو انتظار استئناف. تُلغى بالتخلّص (`dispose`) لتفادي
    // استدعاء `context` بعد التخلّص من هالحالة.
    postPrayerAzkarOpenCallback = () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PostPrayerAzkarScreen()),
      );
    };
    // حالة الإطلاق البارد: التطبيق كان مغلقاً كلياً وقت ضغط "اقرأ الآن"،
    // فـ[postPrayerAzkarOpenCallback] ما كانت مسجَّلة بعد — العلم المحفوظ
    // هون هو البديل الوحيد لمعرفة القصد بعد الإقلاع.
    _consumePendingPostPrayerAzkarOpen();
    if (widget.startTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tourActiveProvider.notifier).start();
      });
    }
  }

  Future<void> _consumePendingPostPrayerAzkarOpen() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final pending = sp.getBool(kPendingOpenPostPrayerAzkarKey) ?? false;
      if (!pending) return;
      await sp.remove(kPendingOpenPostPrayerAzkarKey);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PostPrayerAzkarScreen()),
      );
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(cloudSyncControllerProvider.notifier).maybeAutoSync());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    postPrayerAzkarOpenCallback = null;
    super.dispose();
  }

  Widget _tabAt(int index, BuildContext context) {
    return _built[index] ??= _tabs[index].builder(context);
  }

  static final int _mushafTabIndex = _tabs.indexWhere((t) => t.label == 'المصحف');

  @override
  Widget build(BuildContext context) {
    ref.watch(globalNudgesListenerProvider);
    final activeIndex = ref.watch(rootTabIndexProvider);
    final isTourActive = ref.watch(tourActiveProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _tabAt(activeIndex, context);

    final chromeVisible = ref.watch(mushafChromeVisibleProvider);
    final showNav = activeIndex != _mushafTabIndex || chromeVisible;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: activeIndex,
            children: List.generate(
              _tabs.length,
              (i) => _built[i] ?? const SizedBox.shrink(),
            ),
          ),
          if (isTourActive)
            OnboardingTourOverlay(
              onDismiss: () => ref.read(tourActiveProvider.notifier).dismiss(),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GlobalMiniAudioPlayerBar(),
            AnimatedSlide(
              duration: _kNavAnim,
              offset: showNav ? Offset.zero : const Offset(0, 1.5),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                duration: _kNavAnim,
                opacity: showNav ? 1.0 : 0.0,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B232E) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        _FloatingDockItem(
                          tab: _tabs[i],
                          isSelected: i == activeIndex,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(rootTabIndexProvider.notifier).select(i);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDockItem extends StatelessWidget {
  const _FloatingDockItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _TabDef tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);
    final unselectedColor = isDark ? Colors.white60 : const Color(0xFF6B6760);

    return Semantics(
      label: tab.label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? accent.withValues(alpha: 0.22) : accent.withValues(alpha: 0.14))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: isSelected ? accent : unselectedColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF2A2824))
                      : unselectedColor,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
