import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/hadith/hadith_providers.dart';
import '../../core/data/hadith/hadith_repository.dart';
import '../../core/theme/app_colors.dart';
import 'hadith_detail_screen.dart';

/// بحث نصي بكل كتب الأحاديث عبر فهرس FTS5 — نفس نمط `MushafSearchScreen`.
class HadithSearchScreen extends ConsumerStatefulWidget {
  const HadithSearchScreen({super.key});

  @override
  ConsumerState<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends ConsumerState<HadithSearchScreen> {
  final _controller = TextEditingController();
  List<HadithSearchResult>? _results;
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(hadithRepositoryProvider);
    final results = await repo.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'ابحث بالأحاديث…',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: _search,
          onChanged: _search,
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_loading) return const Center(child: CircularProgressIndicator());
          final results = _results;
          if (results == null) {
            return Center(
              child: Text('اكتب كلمة أو أكثر للبحث بالأحاديث', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
            );
          }
          if (results.isEmpty) {
            return Center(child: Text('لا نتائج', style: TextStyle(color: onSurface.withValues(alpha: 0.6))));
          }
          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = results[i];
              return ListTile(
                title: Text(
                  r.hadith.content,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface, fontSize: 15, height: 1.6),
                ),
                subtitle: Text(
                  '${r.bookNameAr} · حديث ${r.hadith.hadithNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HadithDetailScreen(hadithId: r.hadith.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
