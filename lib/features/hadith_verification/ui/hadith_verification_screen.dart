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
    } on DorarBlockedException {
      // مختلف عمداً عن الرسالة العامة أسفله — "لا نتائج" ليست نفس معنى
      // "الموقع حجب الطلب مؤقتاً" (راجع توثيق [DorarBlockedException]).
      if (!mounted || _lastQuery != q) return;
      setState(() {
        _status = _SearchStatus.error;
        _errorMessage =
            'موسوعة الدرر السنية فرضت حماية مؤقتة على الطلبات الآن. انتظر قليلاً ثم أعد المحاولة.';
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

  /// يجلب صفحة نتائج إضافية (`_currentPage + 1`) ويلحقها بالنتائج
  /// المعروضة — بلا كاش (الكاش الحالي يخزّن الصفحة الأولى فقط لكل
  /// استعلام، راجع `DorarSearchCache`؛ تعميمه لكل الصفحات خارج نطاق هذا
  /// الإصلاح). فشل جلب صفحة إضافية لا يمسح النتائج المعروضة أصلاً — مجرد
  /// تنبيه عابر (`SnackBar`).
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMorePages || _status != _SearchStatus.loaded) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final cache = ref.read(dorarSearchCacheProvider);
      // كاش لكل صفحة على حدة الآن (راجع `DorarSearchCache._key`) — رجوع
      // المستخدم لنفس البحث و"تحميل المزيد" مجدداً يعيد النتيجة المحفوظة
      // فوراً بدل WebView جديد.
      final cached = cache.get(_lastQuery, page: nextPage);
      final List<DorarHadithResult> more;
      if (cached != null) {
        more = cached;
      } else {
        final html = await _fetcherController.fetchHtml(
          dorarSearchUrl(_lastQuery, page: nextPage),
        );
        final service = ref.read(dorarSearchServiceProvider);
        more = service.parseSearchResults(html);
        unawaited(cache.set(_lastQuery, more, page: nextPage));
      }
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        if (more.isEmpty) {
          _hasMorePages = false;
          return;
        }
        _currentPage = nextPage;
        final existingIds = _results.map((r) => r.id).toSet();
        _results = [..._results, ...more.where((r) => !existingIds.contains(r.id))];
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
    return RefreshIndicator(
      color: accent,
      onRefresh: () => _runSearch(_lastQuery),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        // عنصر إضافي بالنهاية: زر "تحميل المزيد"/مؤشّر تحميل/رسالة نهاية
        // النتائج (راجع `_loadMore`) — لا نعرضه لو صفحة واحدة فقط كافية.
        itemCount: _results.length + (_hasMorePages ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _results.length) {
            return _buildLoadMoreFooter(accent);
          }
          return DorarResultCard(
            result: _results[index],
            accent: accent,
            isDark: isDark,
            onOpenFullPage: () => _openFullPage(_results[index]),
            onShare: () => _shareResult(_results[index]),
          );
        },
      ),
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


