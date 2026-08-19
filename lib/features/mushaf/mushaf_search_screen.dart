import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_providers.dart';
import '../../core/data/quran/quran_repository.dart';
import '../../core/theme/app_colors.dart';

/// بحث نصي بالمصحف عبر فهرس FTS5 (`QuranRepository.search`، يتجاهل
/// التشكيل تلقائياً). النتيجة تُرجع رقم صفحة للقفز إليها من `MushafScreen`.
class MushafSearchScreen extends ConsumerStatefulWidget {
  const MushafSearchScreen({super.key});

  @override
  ConsumerState<MushafSearchScreen> createState() => _MushafSearchScreenState();
}

class _MushafSearchScreenState extends ConsumerState<MushafSearchScreen> {
  final _controller = TextEditingController();
  List<AyahSearchResult>? _results;
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(quranRepositoryProvider);
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
            hintText: 'ابحث بالمصحف…',
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
              child: Text('اكتب كلمة أو أكثر للبحث بالنص القرآني', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
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
                  r.ayah.textUthmani,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface, fontSize: 16, height: 1.6),
                ),
                subtitle: Text(
                  '${r.surahNameAr} · آية ${r.ayah.ayah} · صفحة ${r.ayah.page}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                onTap: () => Navigator.of(context).pop(r.ayah.page),
              );
            },
          );
        },
      ),
    );
  }
}
