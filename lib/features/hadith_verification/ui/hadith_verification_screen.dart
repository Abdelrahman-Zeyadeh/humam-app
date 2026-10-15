import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dorar_hadith_result.dart';
import '../services/dorar_search_cache.dart';
import '../services/hadith_verification_service.dart';
import '../services/dorar_webview_fetcher.dart';
import 'widgets/dorar_result_card.dart';

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

  // حالة صفحة النتائج الإضافية ("تحميل المزيد") — راجع `_loadMore`.
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _loadingMore = false;
  String _filterGrade = 'all';

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
      _currentPage = 1;
      _hasMorePages = true;
      _filterGrade = 'all';
    });

    try {
      final repo = ref.read(hadithVerificationRepositoryProvider);
      final result = await repo.verify(
        q,
        page: 1,
        fetchHtml: _fetcherController.fetchHtml,
      );

      if (!mounted || _lastQuery != q) return;

      if (result.isSuccess) {
        setState(() {
          _results = result.results;
          _status = _SearchStatus.loaded;
          _hasMorePages = result.hasMorePages;
        });
      } else {
        setState(() {
          _status = _SearchStatus.error;
          _errorMessage = result.userMessage ??
              'تعذر التحقق من الحديث حاليًا، حاول مرة أخرى لاحقًا.';
        });
      }
    } catch (_) {
      if (!mounted || _lastQuery != q) return;
      setState(() {
        _status = _SearchStatus.error;
        _errorMessage =
            'تعذر التحقق من الحديث حاليًا، حاول مرة أخرى لاحقًا.';
      });
    }
  }

  /// يجلب صفحة نتائج إضافية (`_currentPage + 1`) ويلحقها بالنتائج المعروضة
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMorePages || _status != _SearchStatus.loaded) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final repo = ref.read(hadithVerificationRepositoryProvider);
      final result = await repo.verify(
        _lastQuery,
        page: nextPage,
        fetchHtml: _fetcherController.fetchHtml,
      );

      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        if (!result.isSuccess || result.results.isEmpty) {
          _hasMorePages = false;
          return;
        }
        _currentPage = nextPage;
        final existingIds = _results.map((r) => r.id).toSet();
        _results = [
          ..._results,
          ...result.results.where((r) => !existingIds.contains(r.id)),
        ];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحميل المزيد من النتائج')),
      );
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
    SharePlus.instance.share(
      ShareParams(
        text: result.shareText,
        subject: 'حديث من موسوعة الدرر السنية',
      ),
    );
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
                          : IconButton(
                              icon: const Icon(Icons.content_paste_rounded, size: 18),
                              tooltip: 'لصق الحديث من الحافظة',
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null && data!.text!.trim().isNotEmpty) {
                                  _searchCtrl.text = data.text!.trim();
                                  _runSearch(data.text!.trim());
                                }
                              },
                            ),
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
    final cache = ref.watch(dorarSearchCacheProvider);
    final history = cache.getRecentQueries();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // لو فيه سجل بحث سابق
          if (history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'عمليات البحث الأخيرة',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await cache.clearHistory();
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.redAccent.shade100,
                  ),
                  child: const Text('مسح السجل', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history.map((q) {
                return InputChip(
                  label: Text(
                    q,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.ink,
                    ),
                  ),
                  avatar: Icon(Icons.search_rounded, size: 14, color: accent),
                  backgroundColor: isDark
                      ? const Color(0xFF1E2836)
                      : accent.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: isDark ? AppColors.lineDark : AppColors.line,
                  ),
                  onDeleted: () async {
                    await cache.removeFromHistory(q);
                    setState(() {});
                  },
                  onPressed: () {
                    _searchCtrl.text = q;
                    _runSearch(q);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Divider(color: isDark ? AppColors.lineDark : AppColors.line, height: 1),
            const SizedBox(height: 32),
          ],

          Center(
            child: Column(
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
                  'النتائج (الدرجة، الراوي، المصدر) تُجلب مباشرة من موسوعة الدرر السنية وتُحفظ بالكاش لسرعة الوصول',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'أحاديث شائعة يُكثر السؤال عنها:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'صوموا تصحوا',
                    'خير الأسماء ما حُمِّد وعُبِّد',
                    'من لم تنهه صلاته',
                    'اطلبوا العلم ولو في الصين',
                    'حب الوطن من الإيمان',
                    'اختلاف أمتي رحمة',
                  ].map((text) => ActionChip(
                    avatar: Icon(Icons.touch_app_outlined, size: 14, color: accent),
                    label: Text(text, style: const TextStyle(fontSize: 11.5)),
                    backgroundColor: isDark
                        ? const Color(0xFF1E2836)
                        : accent.withValues(alpha: 0.06),
                    side: BorderSide(
                      color: isDark ? AppColors.lineDark : AppColors.line,
                    ),
                    onPressed: () {
                      _searchCtrl.text = text;
                      _runSearch(text);
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
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
    final filtered = _results.where((r) {
      final g = r.grade ?? '';
      if (_filterGrade == 'sahih') {
        return g.contains('صحيح') || g.contains('حسن') || g.contains('إسناده جيد') || g.contains('ثابت');
      } else if (_filterGrade == 'daeef') {
        return g.contains('ضعيف') || g.contains('منكر') || g.contains('متروك') || g.contains('لا يصح') || g.contains('إسناده ضعيف');
      } else if (_filterGrade == 'mawdoo') {
        return g.contains('موضوع') || g.contains('باطل') || g.contains('كذب') || g.contains('لا أصل له');
      }
      return true;
    }).toList();

    return Column(
      children: [
        _buildFilterBar(accent, isDark),
        Expanded(
          child: RefreshIndicator(
            color: accent,
            onRefresh: () => _runSearch(_lastQuery),
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list_off_rounded,
                            size: 44,
                            color: accent.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد نتائج مطابقة لهذا التصنيف',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => setState(() => _filterGrade = 'all'),
                            child: const Text('عرض كافة النتائج'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: filtered.length + (_hasMorePages && _filterGrade == 'all' ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= filtered.length) {
                        return _buildLoadMoreFooter(accent);
                      }
                      return DorarResultCard(
                        result: filtered[index],
                        accent: accent,
                        isDark: isDark,
                        onOpenFullPage: () => _openFullPage(filtered[index]),
                        onShare: () => _shareResult(filtered[index]),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(Color accent, bool isDark) {
    int sahihCount = _results.where((r) {
      final g = r.grade ?? '';
      return g.contains('صحيح') || g.contains('حسن') || g.contains('إسناده جيد') || g.contains('ثابت');
    }).length;

    int daeefCount = _results.where((r) {
      final g = r.grade ?? '';
      return g.contains('ضعيف') || g.contains('منكر') || g.contains('متروك') || g.contains('لا يصح') || g.contains('إسناده ضعيف');
    }).length;

    int mawdooCount = _results.where((r) {
      final g = r.grade ?? '';
      return g.contains('موضوع') || g.contains('باطل') || g.contains('كذب') || g.contains('لا أصل له');
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.line,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _filterChip('الكل (${_results.length})', 'all', accent, isDark),
            const SizedBox(width: 8),
            _filterChip('🟢 صحيح وحسن ($sahihCount)', 'sahih', const Color(0xFF2E7D32), isDark),
            const SizedBox(width: 8),
            _filterChip('🔴 ضعيف ومتروك ($daeefCount)', 'daeef', const Color(0xFFE65100), isDark),
            const SizedBox(width: 8),
            _filterChip('⚠️ موضوع ومكذوب ($mawdooCount)', 'mawdoo', const Color(0xFFC62828), isDark),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value, Color color, bool isDark) {
    final isSelected = _filterGrade == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.ink),
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: isDark ? const Color(0xFF1E2836) : color.withValues(alpha: 0.08),
      side: BorderSide(
        color: isSelected ? color : (isDark ? AppColors.lineDark : AppColors.line),
      ),
      onSelected: (_) => setState(() => _filterGrade = value),
    );
  }

  Widget _buildLoadMoreFooter(Color accent) {
    if (_loadingMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
          ),
        ),
      );
    }
    return Center(
      child: OutlinedButton.icon(
        onPressed: _loadMore,
        icon: const Icon(Icons.expand_more_rounded, size: 18),
        label: const Text(
          'تحميل المزيد من النتائج',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}


