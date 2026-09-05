import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/names_of_allah/names_of_allah_model.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../story_maker/models/story_content.dart';
import '../story_maker/ui/ayah_story_maker_screen.dart';

/// شيت تفاصيل وتدبر اسم من أسماء الله الحسنى
class NameDetailSheet extends StatelessWidget {
  const NameDetailSheet({super.key, required this.name});

  final NameOfAllah name;

  static Future<void> show(BuildContext context, NameOfAllah name) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NameDetailSheet(name: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = themeAccent(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141C26) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // مقبض السحب
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // المحتوى القابل للتمرير
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // بطاقة الاسم البارزة
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: isDark
                              ? [const Color(0xFF1E2836), const Color(0xFF16202C)]
                              : [const Color(0xFFFAF5E8), const Color(0xFFF3E8D0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'الاسم رقم ${name.id} · ${name.category}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldDeep,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            name.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // المعنى والبيان
                    _SectionHeader(title: 'المعنى والدلالة', icon: Icons.menu_book_rounded, color: accent),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        name.meaning,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.7,
                          color: onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // كيف تعيش وتتدبر هذا الاسم
                    _SectionHeader(
                      title: 'كيف تعيش بهذا الاسم؟',
                      icon: Icons.favorite_outline_rounded,
                      color: const Color(0xFF2E8071),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8071).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF2E8071).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        name.tadabbur,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.7,
                          color: onSurface.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // الشواهد القرآنية
                    if (name.quranReferences.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'من شواهد القرآن الكريم',
                        icon: Icons.auto_stories_rounded,
                        color: const Color(0xFF685197),
                      ),
                      const SizedBox(height: 8),
                      for (final ayah in name.quranReferences) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('﴿ ', style: TextStyle(color: Color(0xFF685197), fontSize: 16)),
                                Expanded(
                                  child: Text(
                                    ayah,
                                    style: TextStyle(
                                      fontFamily: 'AmiriQuran',
                                      fontSize: 15,
                                      height: 1.7,
                                      color: onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],

                    // الدعاء المأثور
                    _SectionHeader(
                      title: 'الدعاء بهذا الاسم الشريف',
                      icon: Icons.volunteer_activism_rounded,
                      color: AppColors.goldDeep,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            name.dua,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.7,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('نسخ الدعاء', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: name.dua));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم نسخ الدعاء بنجاح 📋')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // زر تصميم بطاقة / ستوري ومشاركة
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'تصميم بطاقة ستوري 🎨',
                            icon: Icons.palette_outlined,
                            color: AppColors.goldDeep,
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AyahStoryMakerScreen(
                                    initialContent: NameOfAllahContent(
                                      name: name.name,
                                      meaning: name.meaning,
                                      tadabbur: name.tadabbur,
                                      dua: name.dua,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.share_outlined),
                          tooltip: 'مشاركة الاسم',
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text: '﴿ ${name.name} ﴾\n\n${name.meaning}\n\n[دعاؤه: ${name.dua}]\n\nتطبيق هُمَام',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}
