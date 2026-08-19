import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_database.dart';
import '../../core/data/hadith/hadith_providers.dart';
import '../../core/theme/app_colors.dart';
import 'hadith_detail_screen.dart';

const _kPageSize = 40;

/// تصفّح أحاديث كتاب واحد بترقيم تدريجي (٤٠ حديثاً بكل دفعة) — الكتب هون
/// كبيرة (البخاري ٧٬٥٨٠ ومسلم ٧٬٣٦٠ حديثاً)، فتحميلها دفعة وحدة غير عملي.
class HadithBookScreen extends ConsumerStatefulWidget {
  const HadithBookScreen({super.key, required this.bookId, required this.bookNameAr});
  final int bookId;
  final String bookNameAr;

  @override
  ConsumerState<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends ConsumerState<HadithBookScreen> {
  final _scrollController = ScrollController();
  final List<Hadith> _loaded = [];
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final repo = ref.read(hadithRepositoryProvider);
    final page = await repo.hadithsForBook(widget.bookId, limit: _kPageSize, offset: _loaded.length);
    if (!mounted) return;
    setState(() {
      _loaded.addAll(page);
      _loading = false;
      _hasMore = page.length == _kPageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(widget.bookNameAr)),
      body: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _loaded.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i >= _loaded.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final h = _loaded[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.gold.withValues(alpha: 0.15),
              foregroundColor: AppColors.gold,
              child: Text('${h.hadithNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            title: Text(
              h.content,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: onSurface, height: 1.7),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HadithDetailScreen(hadithId: h.id)),
            ),
          );
        },
      ),
    );
  }
}
