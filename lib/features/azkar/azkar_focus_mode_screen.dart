import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'azkar_progress.dart';
import 'azkar_repository.dart';

/// شاشة وضع التركيز الكامل للأذكار (شاشة انغماسية لقراءة وتسبيح كل ذكر على حدة)
class AzkarFocusModeScreen extends ConsumerStatefulWidget {
  const AzkarFocusModeScreen({
    super.key,
    required this.azkar,
    required this.period,
    this.initialIndex = 0,
  });

  final List<Dhikr> azkar;
  final AzkarPeriod period;
  final int initialIndex;

  @override
  ConsumerState<AzkarFocusModeScreen> createState() =>
      _AzkarFocusModeScreenState();
}

class _AzkarFocusModeScreenState extends ConsumerState<AzkarFocusModeScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.azkar.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _nextPage() {
    if (_currentIndex < widget.azkar.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.azkar.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('لا توجد أذكار متاحة')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final currentDhikr = widget.azkar[_currentIndex];
    final progress = ref.watch(azkarProgressProvider);

    final remaining = progress[(widget.period, currentDhikr.order)] ?? currentDhikr.count;
    final isDone = remaining <= 0;
    final total = currentDhikr.count;
    final doneReps = (total - remaining).clamp(0, total);

    final title = widget.period == AzkarPeriod.morning ? 'أذكار الصباح' : 'أذكار المساء';
    final bgColor = isDark ? const Color(0xFF131A22) : const Color(0xFFFBF8F2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'وضع التركيز الكامل',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$title • ${_currentIndex + 1} من ${widget.azkar.length}',
              style: TextStyle(
                fontSize: 11.5,
                color: onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded, color: onSurface, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'إعادة ضبط هذا الذكر',
            icon: Icon(Icons.refresh_rounded, color: onSurface.withValues(alpha: 0.7)),
            onPressed: () {
              ref.read(azkarProgressProvider.notifier).resetSingle(widget.period, currentDhikr.order);
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // شريط التقدم العلوي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.azkar.length,
                  minHeight: 5,
                  backgroundColor: onSurface.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF67)),
                ),
              ),
            ),

            // الصفحات
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: widget.azkar.length,
                itemBuilder: (context, index) {
                  final dhikr = widget.azkar[index];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      children: [
                        // نص الذكر
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2430) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2B3848) : const Color(0xFFEBE3D3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                dhikr.content,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 21,
                                  height: 2.0,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                              if (dhikr.source != null) ...[
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      size: 13,
                                      color: onSurface.withValues(alpha: 0.45),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      dhikr.source!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // بطاقة الفضل إن وُجد
                        if (dhikr.fadl != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF262114)
                                  : const Color(0xFFF9F5EA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD4AF67).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Color(0xFFD4AF67),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dhikr.fadl!,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFE2C98D)
                                          : const Color(0xFF7A5C22),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // شريط أدوات المشاركة والنسخ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              color: onSurface.withValues(alpha: 0.6),
                              tooltip: 'نسخ الذكر',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: dhikr.content));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ نص الذكر'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.share_outlined, size: 20),
                              color: onSurface.withValues(alpha: 0.6),
                              tooltip: 'مشاركة الذكر',
                              onPressed: () {
                                final text = '${dhikr.content}\n\n'
                                    '${dhikr.fadl != null ? "الفضل: ${dhikr.fadl}\n" : ""}'
                                    '${dhikr.source != null ? "المصدر: ${dhikr.source}" : ""}';
                                SharePlus.instance.share(ShareParams(text: text.trim()));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // زر التسبيح التفاعلي الكبير بالأسفل
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  // دائرة العدّاد الكبيرة التفاعلية
                  GestureDetector(
                    onTap: () {
                      if (isDone) return;
                      HapticFeedback.lightImpact();
                      ref.read(azkarProgressProvider.notifier).tap(
                        widget.period,
                        currentDhikr.order,
                        currentDhikr.count,
                      );
                      final nextRemaining = remaining - 1;
                      if (nextRemaining <= 0) {
                        HapticFeedback.mediumImpact();
                        // انتقال تلقائي بعد انتهاء التكرارات
                        Future.delayed(const Duration(milliseconds: 350), () {
                          if (mounted && _currentIndex < widget.azkar.length - 1) {
                            _nextPage();
                          }
                        });
                      }
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDone
                              ? [const Color(0xFF2E8B57), const Color(0xFF1E603B)]
                              : [const Color(0xFFD6A868), const Color(0xFF9E7A3E)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDone ? const Color(0xFF2E8B57) : const Color(0xFF9E7A3E))
                                .withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isDone
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 42)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$remaining',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'من $total',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  if (!isDone) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E8B57),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      onPressed: () {
                        ref.read(azkarProgressProvider.notifier).complete(
                          widget.period,
                          currentDhikr.order,
                        );
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted && _currentIndex < widget.azkar.length - 1) {
                            _nextPage();
                          }
                        });
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: const Text(
                        'أتممت قراءة هذا الذكر (تمّ)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // أزرار التنقل السابق والتالي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: onSurface.withValues(alpha: isDark ? 0.12 : 0.06),
                          foregroundColor: onSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: _currentIndex > 0 ? _prevPage : null,
                        icon: const Icon(Icons.chevron_right_rounded, size: 18),
                        label: const Text('السابق', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$doneReps / $total تكرار',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: onSurface.withValues(alpha: isDark ? 0.12 : 0.06),
                          foregroundColor: onSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onPressed: _currentIndex < widget.azkar.length - 1 ? _nextPage : null,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.chevron_left_rounded, size: 18),
                        label: const Text('التالي', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
