import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../azkar/azkar_screen.dart';
import '../home/home_screen.dart';
import '../more/more_placeholder_screen.dart';
import '../mushaf/mushaf_screen.dart';
import '../prayer/prayer_screen.dart';

/// فهرس التبويب النشط في القشرة الرئيسية.
class RootTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final rootTabIndexProvider = NotifierProvider<RootTabIndexNotifier, int>(RootTabIndexNotifier.new);

class _TabDef {
  const _TabDef({required this.label, required this.icon, required this.builder});
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

final _tabs = <_TabDef>[
  _TabDef(label: 'الرئيسية', icon: Icons.home_outlined, builder: (_) => const HomeScreen()),
  _TabDef(label: 'المصحف', icon: Icons.menu_book_outlined, builder: (_) => const MushafScreen()),
  _TabDef(label: 'الصلاة', icon: Icons.access_time_outlined, builder: (_) => const PrayerScreen()),
  _TabDef(label: 'الأذكار', icon: Icons.brightness_2_outlined, builder: (_) => const AzkarScreen()),
  _TabDef(label: 'المزيد', icon: Icons.more_horiz, builder: (_) => const MorePlaceholderScreen()),
];

/// القشرة الرئيسية: `IndexedStack` ببناء كسول للتبويبات — كل تبويب يُبنى
/// أول مرة تُزار فيه فقط، ثم يبقى حياً (لا يُعاد بناؤه) عند التنقل بينها.
/// هذا القرار موثّق في تصميم-النظام.md ويجب الحفاظ عليه عند إضافة تبويبات جديدة.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  final _built = List<Widget?>.filled(_tabs.length, null);

  Widget _tabAt(int index, BuildContext context) {
    return _built[index] ??= _tabs[index].builder(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = ref.watch(rootTabIndexProvider);
    // نضمن بناء التبويب النشط قبل عرضه، بلا بناء البقية سلفاً.
    _tabAt(activeIndex, context);

    return Scaffold(
      body: IndexedStack(
        index: activeIndex,
        children: List.generate(
          _tabs.length,
          (i) => _built[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activeIndex,
        onTap: (i) => ref.read(rootTabIndexProvider.notifier).select(i),
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

/// سكافولد موحّد للشاشات المؤقتة (placeholder) — يُستبدل كل واحد منها
/// بميزته الحقيقية في مرحلته المحددة بخطة العمل.
class ComingSoonScaffold extends StatelessWidget {
  const ComingSoonScaffold({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.inkSoft),
            const SizedBox(height: 12),
            Text('قيد التطوير — مرحلة قادمة', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
