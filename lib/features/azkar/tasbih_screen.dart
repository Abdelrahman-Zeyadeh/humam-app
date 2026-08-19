import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/user/tasbih_prefs.dart';
import '../../core/theme/app_colors.dart';

const List<String> _kQuickPhrases = ['سبحان الله', 'الحمد لله', 'الله أكبر', 'لا إله إلا الله', 'أستغفر الله'];

/// مسبحة إلكترونية بعدّاد محفوظ بين التشغيلات — الضغط بأي مكان بالدائرة
/// يزيد العدّ مع اهتزاز خفيف، والإطالة تصفّره.
class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = ref.read(tasbihPrefsProvider).count;
  }

  void _increment() {
    setState(() => _count++);
    HapticFeedback.mediumImpact();
    ref.read(tasbihPrefsProvider).setCount(_count);
  }

  void _reset() {
    setState(() => _count = 0);
    HapticFeedback.heavyImpact();
    ref.read(tasbihPrefsProvider).setCount(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.inkOnDark : AppColors.ink;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المسبحة'),
        actions: [
          IconButton(icon: const Icon(Icons.restart_alt), tooltip: 'تصفير', onPressed: _reset),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [for (final p in _kQuickPhrases) Chip(label: Text(p, style: const TextStyle(fontSize: 12)))],
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _increment,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  child: Center(
                    child: Text('$_count', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: fg)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text('اضغط بأي مكان بالدائرة للعدّ', style: TextStyle(color: fg.withValues(alpha: 0.5), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
