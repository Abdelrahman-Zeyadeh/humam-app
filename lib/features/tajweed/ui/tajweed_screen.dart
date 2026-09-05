import 'package:flutter/material.dart';

import '../../../core/data/tajweed/tajweed_data.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import 'tajweed_color_legend_sheet.dart';

class TajweedScreen extends StatefulWidget {
  const TajweedScreen({super.key});

  @override
  State<TajweedScreen> createState() => _TajweedScreenState();
}

class _TajweedScreenState extends State<TajweedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أحكام التجويد والضبط'),
        actions: [
          IconButton(
            tooltip: 'مفتاح ألوان التجويد',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => TajweedColorLegendSheet.show(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldDeep,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'أحكام التجويد'),
            Tab(icon: Icon(Icons.signpost_outlined), text: 'علامات الوقف'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. أحكام التجويد
          _buildRulesTab(context, isDark),

          // 2. علامات الوقف والضبط
          _buildStopMarksTab(context, isDark),
        ],
      ),
    );
  }

  Widget _buildRulesTab(BuildContext context, bool isDark) {
    final filteredRules = TajweedData.allRules.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.title.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          r.letters.toLowerCase().contains(q) ||
          r.definition.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // شريط البحث
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'ابحث عن حكم، حرف، أو قاعدة تجويدية...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.lineDark : AppColors.line,
                ),
              ),
            ),
          ),
        ),

        // قائمة الأحكام
        Expanded(
          child: filteredRules.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_outlined,
                  message: 'لا توجد نتائج مطابقة لبحثك',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filteredRules.length,
                  itemBuilder: (ctx, index) {
                    final rule = filteredRules[index];
                    return _buildRuleCard(context, rule, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(BuildContext context, TajweedRule rule, bool isDark) {
    final ruleColor = _hexToColor(rule.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppColors.lineDark : AppColors.line,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: ruleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ruleColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          title: Text(
            rule.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            rule.category,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // التعريف
                  _buildSectionBox(
                    title: '📖 التعريف والحكم:',
                    content: rule.definition,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),

                  // الحروف
                  _buildSectionBox(
                    title: '🔤 الحروف والضابط:',
                    content: rule.letters,
                    isDark: isDark,
                    highlightColor: ruleColor.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 10),

                  // الشرح والتوضيح
                  _buildSectionBox(
                    title: '💡 الشرح والتطبيق:',
                    content: rule.explanation,
                    isDark: isDark,
                  ),

                  // الشاهد الشعري إن وجد
                  if (rule.poetryProof != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.format_quote, size: 16, color: AppColors.goldDeep),
                              SizedBox(width: 4),
                              Text(
                                'الشاهد من المتن (تحفة الأطفال / الجزرية):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldDeep,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rule.poetryProof!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                              fontFamily: 'Kitab',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // الأمثلة القرآنية التطبيقية
                  const SizedBox(height: 14),
                  const Text(
                    '✨ أمثلة قرآنية تطبيقية:',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  for (final ex in rule.examples) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.lineDark : AppColors.line,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'سورة ${ex.surah}: ${ex.ayah}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'الشاهد: ${ex.highlightedWord}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: ruleColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '«${ex.versePart}»',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontFamily: 'Kitab',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ex.note,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionBox({
    required String title,
    required String content,
    required bool isDark,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlightColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.87)
                  : Colors.black.withValues(alpha: 0.87),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopMarksTab(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: TajweedData.stopMarks.length,
      itemBuilder: (ctx, index) {
        final mark = TajweedData.stopMarks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark ? AppColors.lineDark : AppColors.line,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          mark.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Kitab',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mark.name,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mark.rule,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.goldDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  mark.meaning,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مثال: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          mark.example,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontFamily: 'Kitab',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
