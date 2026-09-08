import 'package:flutter/material.dart';

import '../../../../core/theme/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../story_maker/models/story_content.dart';
import '../../../story_maker/ui/ayah_story_maker_screen.dart';
import '../../models/dorar_hadith_result.dart';

/// بطاقة نتيجة واحدة **قابلة للطي** — النص (المتن) والدرجة يظهران أولاً
/// فقط، وبقية التفاصيل (الراوي/المحدث/المصدر/التخريج/التصنيفات/أزرار
/// الإجراءات) تظهر فقط بعد الضغط على البطاقة، بطلب صريح ("النص أولاً...
/// اذا كبست بتوسع"، مطابقة لتجربة تطبيقات تحقّق حديث مشابهة). **بلا أي
/// طلب شبكة إضافي عند التوسيع** — كل الحقول مُستخرَجة أصلاً دفعة وحدة من
/// نفس صفحة نتائج البحث (`DorarSearchService.parseSearchResults`)، فطلب
/// جلب منفصل لكل بطاقة عبر الـWebView الهش أصلاً (راجع توثيق
/// `DorarWebViewFetcher`) كان سيُبطئ التوسيع ويُضاعف نقاط فشل الشبكة بلا
/// أي معلومة جديدة فعلياً — "التوسيع" هون كشف لبيانات محلية جاهزة، لا
/// إعادة جلب.
///
/// انُتزِعت من `hadith_verification_screen.dart` (كانت ٨٧٠ سطراً بملف
/// واحد) لتطابق عادة المشروع بتجزئة الشاشات الكبيرة — راجع سجل commits
/// المشابهة (`daily_hadith_screen`, `qiyam_screen`, `groups_hub_screen`...).
class DorarResultCard extends StatefulWidget {
  const DorarResultCard({
    super.key,
    required this.result,
    required this.accent,
    required this.isDark,
    required this.onOpenFullPage,
    required this.onShare,
  });

  final DorarHadithResult result;
  final Color accent;
  final bool isDark;
  final VoidCallback onOpenFullPage;
  final VoidCallback onShare;

  @override
  State<DorarResultCard> createState() => _DorarResultCardState();
}

class _DorarResultCardState extends State<DorarResultCard> {
  bool _expanded = false;

  Color _gradeColor(String? grade) {
    if (grade == null) return Colors.grey;
    if (grade.contains('صحيح')) return Colors.green.shade600;
    if (grade.contains('حسن')) return AppColors.goldDeep;
    if (grade.contains('ضعيف') ||
        grade.contains('منكر') ||
        grade.contains('باطل') ||
        grade.contains('موضوع') ||
        grade.contains('لا يصح') ||
        grade.contains('لا أصل له')) {
      return Colors.redAccent.shade200;
    }
    return Colors.blueGrey;
  }

  IconData _gradeIcon(String? grade) {
    if (grade == null) return Icons.help_outline_rounded;
    if (grade.contains('صحيح')) return Icons.check_circle_rounded;
    if (grade.contains('حسن')) return Icons.thumb_up_rounded;
    if (grade.contains('ضعيف') ||
        grade.contains('منكر') ||
        grade.contains('باطل') ||
        grade.contains('موضوع') ||
        grade.contains('لا يصح') ||
        grade.contains('لا أصل له')) {
      return Icons.cancel_rounded;
    }
    return Icons.info_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isDark = widget.isDark;
    final gradeColor = _gradeColor(result.grade);
    final hasMoreDetails =
        result.narrator != null ||
        result.muhaddith != null ||
        result.source != null ||
        result.takhrij != null ||
        result.categories.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.grade != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gradeColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_gradeIcon(result.grade), size: 14, color: gradeColor),
                      const SizedBox(width: 5),
                      Text(
                        result.grade!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: gradeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                result.matn,
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: !_expanded
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              if (result.narrator != null)
                                _detailChip(
                                  Icons.person_rounded,
                                  result.narrator!,
                                  isDark,
                                ),
                              if (result.muhaddith != null)
                                _detailChip(
                                  Icons.school_rounded,
                                  result.muhaddith!,
                                  isDark,
                                ),
                              if (result.source != null)
                                _detailChip(
                                  Icons.menu_book_rounded,
                                  result.pageOrNumber != null
                                      ? '${result.source} (${result.pageOrNumber})'
                                      : result.source!,
                                  isDark,
                                ),
                            ],
                          ),
                          if (result.takhrij != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'التخريج: ${result.takhrij}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : AppColors.inkSoft,
                              ),
                            ),
                          ],
                          if (result.categories.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: result.categories.take(4).map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.onOpenFullPage,
                                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                  label: const Text(
                                    'الصفحة الكاملة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: widget.accent,
                                    side: BorderSide(color: widget.accent.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // زر تصميم بطاقة ستوري
                              IconButton.filledTonal(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AyahStoryMakerScreen(
                                        initialContent: HadithContent(
                                          hadithText: result.matn,
                                          narrator: result.narrator ?? 'غير محدد',
                                          sourceBook: '${result.source ?? 'الدرر السنية'} · [${result.grade ?? ''}]',
                                          explanation: result.takhrij,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.palette_outlined, size: 18),
                                tooltip: 'تصميم بطاقة ستوري',
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: widget.onShare,
                                icon: const Icon(Icons.share_rounded, size: 18),
                                tooltip: 'مشاركة الحديث',
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              // إشارة قابلية الطي/الفتح — تظهر فقط لو فيه فعلاً تفاصيل
              // إضافية تستحق التوسيع (بعض النتائج بلا أي حقل إضافي أصلاً).
              if (hasMoreDetails) ...[
                const SizedBox(height: 6),
                Center(
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: (isDark ? Colors.white54 : AppColors.inkSoft),
                    ),
                  ),
                ),
              ],
            ],
          ),
    );
  }

  Widget _detailChip(IconData icon, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: isDark ? Colors.white54 : AppColors.inkSoft,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
