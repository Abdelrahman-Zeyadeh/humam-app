import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dorar_hadith_result.dart';
import '../services/dorar_search_cache.dart';
import '../services/dorar_search_service.dart';
import '../services/dorar_webview_fetcher.dart';

enum _SearchStatus { idle, loading, loaded, error }

/// شاشة التحقق من صحة الحديث — بحث أصلي بشكل التطبيق نفسه، بينما البيانات
/// تُجلَب مباشرة من موسوعة الدرر السنية (dorar.net) وتُعرَض كبطاقات، بدل
/// عرض صفحة الموقع كاملة بـWebView (كان شكلها غريباً عن هوية التطبيق).
class HadithVerificationScreen extends ConsumerStatefulWidget {
  const HadithVerificationScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<HadithVerificationScreen> createState() =>
      _HadithVerificationScreenState();
}

class _HadithVerificationScreenState
    extends ConsumerState<HadithVerificationScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final DorarWebViewFetcherController _fetcherController =
      DorarWebViewFetcherController();
  _SearchStatus _status = _SearchStatus.idle;
  List<DorarHadithResult> _results = [];
  String? _errorMessage;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchCtrl.text = widget.initialQuery!;
      // نؤجّل للإطار التالي — `DorarWebViewFetcher` (راجع بناء الشاشة
      // بالأسفل) ما بيكون مركَّب بالشجرة بعد وقت `initState` نفسه.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    _lastQuery = q;
    setState(() {
      _status = _SearchStatus.loading;
      _errorMessage = null;
    });

    try {
      final cache = ref.read(dorarSearchCacheProvider);
      // كاش محلي أولاً — الجلب الفعلي يحتاج WebView كاملاً (بطيء نسبياً)،
      // فتكرار نفس الاستعلام (بحث المستخدم لنفس الحديث مرة ثانية، أو نفس
      // النص من "التحقق من صحة" بشاشات أخرى) يعيد النتيجة المحفوظة فوراً
      // بدل تحميل صفحة جديدة كل مرة (راجع `DorarSearchCache` لمدة الصلاحية).
      final cached = cache.get(q);
      if (cached != null) {
        setState(() {
          _results = cached;
          _status = _SearchStatus.loaded;
        });
        return;
      }

      // جلب حقيقي عبر WebView (محرك متصفح حقيقي) لا Dio — راجع توثيق
      // `DorarWebViewFetcher` لسبب هذا القرار (Cloudflare يرفض طلبات Dio
      // بـ٤٠٣ مهما كانت الترويسات، حتى مع كوكيز جلسة صالحة).
      final html = await _fetcherController.fetchHtml(dorarSearchUrl(q));
      if (!mounted || _lastQuery != q) return;
      final service = ref.read(dorarSearchServiceProvider);
      final results = service.parseSearchResults(html);
      unawaited(cache.set(q, results));
      setState(() {
        _results = results;
        _status = _SearchStatus.loaded;
      });
    } catch (e) {
      if (!mounted || _lastQuery != q) return;
      setState(() {
        _status = _SearchStatus.error;
        _errorMessage =
            'تعذر الاتصال بموسوعة الدرر السنية. تأكد من اتصال الإنترنت وحاول مجدداً.';
      });
    }
  }

  Future<void> _openFullPage(DorarHadithResult result) async {
    HapticFeedback.selectionClick();
    final url = Uri.parse(result.permalink);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الصفحة الكاملة')),
        );
      }
    }
  }

  void _shareResult(DorarHadithResult result) {
    HapticFeedback.lightImpact();
    Share.share(result.shareText, subject: 'حديث من موسوعة الدرر السنية');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = themeAccent(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDeep : AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'التحقق من صحة الحديث',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          // بحجم صفر عمداً — يجلب HTML صفحة النتائج فقط، بلا عرض على
          // المستخدم (راجع `DorarWebViewFetcher`).
          DorarWebViewFetcher(controller: _fetcherController),
          _buildHeader(accent, isDark),
          Expanded(child: _buildBody(accent, isDark)),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [AppColors.navyDeep, AppColors.surfaceDark]
              : [accent.withValues(alpha: 0.12), AppColors.cream],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.line,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.verified_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'موسوعة الدرر السنية',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    Text(
                      'ابحث عن أي حديث لمعرفة درجته وراويه ومصدره',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                    onSubmitted: _runSearch,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'اكتب نص الحديث أو جزءاً منه...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: accent,
                        size: 20,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _status = _SearchStatus.idle;
                                  _results = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: ElevatedButton(
                    onPressed: () => _runSearch(_searchCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تحقق',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Color accent, bool isDark) {
    switch (_status) {
      case _SearchStatus.idle:
        return _buildIdleState(accent, isDark);
      case _SearchStatus.loading:
        return _buildLoadingState(accent);
      case _SearchStatus.error:
        return _buildErrorState(accent);
      case _SearchStatus.loaded:
        if (_results.isEmpty) return _buildNoResultsState(accent);
        return _buildResultsList(accent, isDark);
    }
  }

  Future<void> _openDorarWebSearch() async {
    final q = _searchCtrl.text.trim();
    final url = Uri.parse(
      q.isEmpty
          ? 'https://dorar.net/hadith/search'
          : 'https://dorar.net/hadith/search?q=${Uri.encodeComponent(q)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح موقع الدرر السنية')),
        );
      }
    }
  }

  Widget _buildIdleState(Color accent, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 56,
              color: accent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'اكتب نص الحديث بالأعلى للتحقق من صحته',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'النتائج (الدرجة، الراوي، المصدر) تُجلب مباشرة من موسوعة الدرر السنية',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'جاري البحث في موسوعة الدرر السنية...',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color accent) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 54,
              color: accent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قد تفرض خدمة الحماية بالدرر قيوداً على الشبكة مؤقتاً.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _runSearch(_searchCtrl.text),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openDorarWebSearch,
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('فتح في موقع الدرر'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 54,
              color: accent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'لم يتم العثور على نتائج لهذا النص',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'جرّب صياغة أخرى أو جزءاً أقصر من نص الحديث',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(Color accent, bool isDark) {
    return RefreshIndicator(
      color: accent,
      onRefresh: () => _runSearch(_lastQuery),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _ExpandableResultCard(
          result: _results[index],
          accent: accent,
          isDark: isDark,
          onOpenFullPage: () => _openFullPage(_results[index]),
          onShare: () => _shareResult(_results[index]),
        ),
      ),
    );
  }
}

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
class _ExpandableResultCard extends StatefulWidget {
  const _ExpandableResultCard({
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
  State<_ExpandableResultCard> createState() => _ExpandableResultCardState();
}

class _ExpandableResultCardState extends State<_ExpandableResultCard> {
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

