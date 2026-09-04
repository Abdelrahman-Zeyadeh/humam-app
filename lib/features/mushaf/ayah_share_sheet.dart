import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/quran/quran_database.dart';
import '../../../core/data/quran/quran_providers.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../audio/reciters.dart';
import '../story_maker/ui/ayah_story_maker_screen.dart';
import 'mushaf_font_service.dart';

enum ShareTab { text, image, audio }

class AyahShareSheet extends ConsumerStatefulWidget {
  final int initialAyahId;

  const AyahShareSheet({
    super.key,
    required this.initialAyahId,
  });

  static Future<void> show(BuildContext context, int ayahId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AyahShareSheet(initialAyahId: ayahId),
    );
  }

  @override
  ConsumerState<AyahShareSheet> createState() => _AyahShareSheetState();
}

class _AyahShareSheetState extends ConsumerState<AyahShareSheet> {
  final GlobalKey _cardPreviewKey = GlobalKey();

  ShareTab _selectedTab = ShareTab.image;
  late int _surahId = 1;
  late int _fromAyah = 1;
  late int _toAyah = 1;
  String _selectedTafsirKey = 'none'; // 'none', 'mukhtasar', 'saadi', 'muyassar', 'jalalayn', 'en_sahih'
  String _selectedReciterId = 'alafasy';

  /// حجم خط بطاقة "صورة المصحف" — يتقلّص تدريجياً كل ما زاد عدد الآيات
  /// المختارة (بطلب صريح: "الصورة بتكون طويلة كتير") بدل حجم ثابت واحد
  /// يخلي البطاقة تطول بلا حد مع نطاقات آيات كبيرة. **ثابت (لا يتقلّص أكتر)
  /// بعد أعلى عتبة** بدل تصغير خطي بلا حد يوصل لخط غير مقروء — يحافظ على
  /// وضوح نص الآية والتفسير معاً.
  double get _fontSize {
    final count = _selectedAyahs.length;
    if (count <= 3) return 18.0;
    if (count <= 6) return 15.0;
    if (count <= 10) return 13.0;
    return 11.0;
  }
  bool _isProcessing = false;
  bool _isLoaded = false;
  Surah? _surah;
  List<Ayah> _allSurahAyahs = [];

  static const _kPrimaryGreen = Color(0xFF437A4D);
  static const _kParchmentBg = Color(0xFFF9F6EE);
  static const _kParchmentCard = Color(0xFFFAF7F0);
  static const _kBorderTan = Color(0xFFE2D8C3);
  static const _kGoldMushaf = Color(0xFFC5A059);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final repo = ref.read(quranRepositoryProvider);
    final initialAyah = await repo.ayahById(widget.initialAyahId);
    final surah = await repo.surahById(initialAyah.surah);
    final ayahs = await repo.ayahsForSurah(initialAyah.surah);

    if (mounted) {
      setState(() {
        _surahId = initialAyah.surah;
        _fromAyah = initialAyah.ayah;
        _toAyah = initialAyah.ayah;
        _surah = surah;
        _allSurahAyahs = ayahs;
        _isLoaded = true;
      });
    }
  }

  Future<void> _onSurahChanged(int newSurahId) async {
    final repo = ref.read(quranRepositoryProvider);
    final surah = await repo.surahById(newSurahId);
    final ayahs = await repo.ayahsForSurah(newSurahId);

    if (mounted) {
      setState(() {
        _surahId = newSurahId;
        _surah = surah;
        _allSurahAyahs = ayahs;
        _fromAyah = 1;
        _toAyah = 1;
      });
    }
  }

  List<Ayah> get _selectedAyahs {
    if (_allSurahAyahs.isEmpty) return [];
    return _allSurahAyahs.where((a) => a.ayah >= _fromAyah && a.ayah <= _toAyah).toList();
  }

  static String toArabicDigits(int num) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  String get _cleanSurahName {
    if (_surah == null) return '';
    return _surah!.nameAr.replaceFirst('سورة ', '').replaceFirst('سُورَةُ ', '').trim();
  }

  String _tafsirDisplayName(String key) {
    switch (key) {
      case 'mukhtasar':
        return 'تفسير المختصر';
      case 'saadi':
        return 'تفسير السعدي';
      case 'muyassar':
        return 'التفسير الميسر';
      case 'jalalayn':
        return 'تفسير الجلالين';
      case 'asbab':
        return 'أسباب النزول';
      case 'en_sahih':
        return 'English (Sahih)';
      default:
        return 'بدون تفسير';
    }
  }

  Future<Uint8List?> _captureCardBytes() async {
    final boundary = _cardPreviewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 4.5); // دقة فائقة UHD
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _executeShare() async {
    if (_surah == null || _selectedAyahs.isEmpty) return;

    if (_selectedTab == ShareTab.text) {
      final buffer = StringBuffer();
      for (final a in _selectedAyahs) {
        buffer.write('${a.textUthmani} ﴿${toArabicDigits(a.ayah)}﴾ ');
      }
      final rangeStr = _fromAyah == _toAyah ? '$_fromAyah' : '$_fromAyah - $_toAyah';
      final shareText = '﴿ ${buffer.toString().trim()} ﴾\n\n[ سورة $_cleanSurahName : $rangeStr ]\nبواسطة تطبيق هُمَام ✨';

      await SharePlus.instance.share(ShareParams(text: shareText));
      if (mounted) Navigator.pop(context);
      return;
    }

    if (_selectedTab == ShareTab.audio) {
      final reciter = reciterById(_selectedReciterId);
      final rangeStr = _fromAyah == _toAyah ? 'آية $_fromAyah' : 'الآيات $_fromAyah - $_toAyah';
      String audioUrl;
      try {
        if (_fromAyah == _toAyah && reciter.mode == ReciterAudioMode.perAyah) {
          audioUrl = ayahAudioUrl(_selectedReciterId, _surahId, _fromAyah);
        } else {
          audioUrl = surahAudioUrl(_selectedReciterId, _surahId);
        }
      } catch (_) {
        audioUrl = ayahAudioUrl('alafasy', _surahId, _fromAyah);
      }

      final shareText = '🎧 تلاوة سورة $_cleanSurahName ($rangeStr)\nبصوت القارئ: ${reciter.nameAr}\n\n$audioUrl\n\nعبر تطبيق هُمَام ✨';
      await SharePlus.instance.share(ShareParams(text: shareText));
      if (mounted) Navigator.pop(context);
      return;
    }

    // ShareTab.image
    setState(() => _isProcessing = true);
    try {
      final bytes = await _captureCardBytes();
      if (bytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/humam_${_surahId}_${_fromAyah}_$_toAyah.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final rangeStr = _fromAyah == _toAyah ? 'آية $_fromAyah' : 'الآيات $_fromAyah - $_toAyah';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'سورة $_cleanSurahName ($rangeStr) — تطبيق هُمَام ✨',
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر مشاركة الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _captureCardBytes();
      if (bytes == null) return;

      final filename = 'humam_ayah_${_surahId}_${_fromAyah}_${_toAyah}_${DateTime.now().millisecondsSinceEpoch}.png';
      Directory? dir;
      if (Platform.isAndroid) {
        final publicPictures = Directory('/storage/emulated/0/Pictures/Humam');
        if (await publicPictures.exists() || (await publicPictures.create(recursive: true).then((_) => true).catchError((_) => false))) {
          dir = publicPictures;
        } else {
          final picturesDirs = await getExternalStorageDirectories(type: StorageDirectory.pictures);
          if (picturesDirs != null && picturesDirs.isNotEmpty) {
            dir = picturesDirs.first;
          }
        }
      }
      dir ??= await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الصورة بنجاح في مجلد الصور (Pictures/Humam) 📷✨'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر حفظ الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showTafsirDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: _kPrimaryGreen,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('اختر كتاب التفسير', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(ctx),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in [
              ('none', 'بدون تفسير', ''),
              ('mukhtasar', 'تفسير المختصر', 'المختصر في تفسير القرآن الكريم'),
              ('saadi', 'تفسير السعدي', 'تيسير الكريم الرحمن في تفسير كلام المنان'),
              ('muyassar', 'التفسير الميسر', 'مجمع الملك فهد لطباعة المصحف الشريف'),
              ('jalalayn', 'تفسير الجلالين', 'للإمامين المحلي والسيوطي'),
              ('en_sahih', 'English', 'Sahih International Translation'),
            ])
              ListTile(
                leading: Icon(
                  _selectedTafsirKey == entry.$1 ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: _selectedTafsirKey == entry.$1 ? _kPrimaryGreen : Colors.grey,
                ),
                title: Text(entry.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: entry.$3.isNotEmpty ? Text(entry.$3, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
                onTap: () {
                  setState(() => _selectedTafsirKey = entry.$1);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSurahPicker() {
    final surahsAsync = ref.read(allSurahsProvider);
    surahsAsync.whenData((surahs) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              const Text('اختر السورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: surahs.length,
                  itemBuilder: (ctx, i) {
                    final s = surahs[i];
                    final isSel = s.id == _surahId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSel ? _kPrimaryGreen : Colors.grey.withValues(alpha: 0.15),
                        child: Text('${s.id}', style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      title: Text(s.nameAr, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
                      subtitle: Text('${s.ayahCount} آية • ${s.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'}'),
                      selected: isSel,
                      onTap: () {
                        Navigator.pop(ctx);
                        _onSurahChanged(s.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showAyahSearchPicker({required bool isFrom}) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = _allSurahAyahs.where((a) {
            if (searchQuery.isEmpty) return true;
            return a.ayah.toString().contains(searchQuery) ||
                toArabicDigits(a.ayah).contains(searchQuery) ||
                a.textUthmani.contains(searchQuery);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: _kPrimaryGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isFrom ? 'اختر آية البداية' : 'اختر آية النهاية', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 380,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: TextField(
                      onChanged: (val) => setDialogState(() => searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'ابحث برقم الآية أو كلماتها...',
                        prefixIcon: const Icon(Icons.search, color: _kPrimaryGreen, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final a = filtered[i];
                        final isSel = isFrom ? a.ayah == _fromAyah : a.ayah == _toAyah;
                        return ListTile(
                          leading: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel ? _kPrimaryGreen : const Color(0xFFE8F3EB),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              toArabicDigits(a.ayah),
                              style: TextStyle(
                                color: isSel ? Colors.white : _kPrimaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            a.textUthmani,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 15),
                          ),
                          onTap: () {
                            setState(() {
                              if (isFrom) {
                                _fromAyah = a.ayah;
                                if (_toAyah < _fromAyah) _toAyah = _fromAyah;
                              } else {
                                _toAyah = a.ayah;
                                if (_fromAyah > _toAyah) _fromAyah = _toAyah;
                              }
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isLoaded || _surah == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E28) : _kParchmentBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Center(child: CircularProgressIndicator(color: _kPrimaryGreen)),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : _kParchmentBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. الرأس الأخضر (مشاركة + X) - مطابق لصور وحي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: _kPrimaryGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  const Text(
                    'مشاركة',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 2. شريط التبديل: [ نص ] | [ صورة ] | [ صوت ]
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kBorderTan),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            label: 'نص',
                            icon: Icons.description_outlined,
                            selected: _selectedTab == ShareTab.text,
                            onTap: () => setState(() => _selectedTab = ShareTab.text),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildTabButton(
                            label: 'صورة',
                            icon: Icons.image_outlined,
                            selected: _selectedTab == ShareTab.image,
                            onTap: () => setState(() => _selectedTab = ShareTab.image),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildTabButton(
                            label: 'صوت',
                            icon: Icons.graphic_eq_rounded,
                            selected: _selectedTab == ShareTab.audio,
                            onTap: () => setState(() => _selectedTab = ShareTab.audio),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. صف اختيار السورة ونطاق الآيات (مطابق تماماً لصورة 1 وصورة 3)
                  Row(
                    children: [
                      // إلى آية
                      Expanded(
                        flex: 2,
                        child: _buildSelectorBox(
                          label: 'إلى',
                          value: '$_toAyah',
                          onTap: () => _showAyahSearchPicker(isFrom: false),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // من آية
                      Expanded(
                        flex: 2,
                        child: _buildSelectorBox(
                          label: 'من',
                          value: '$_fromAyah',
                          onTap: () => _showAyahSearchPicker(isFrom: true),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // السورة
                      Expanded(
                        flex: 4,
                        child: _buildSelectorBox(
                          label: 'سورة',
                          value: '${_surah!.id}. سُورَةُ $_cleanSurahName',
                          onTap: _showSurahPicker,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. شريط اختيار التفسير والأدوات المساعدة
                  Row(
                    children: [
                      // زر اختيار التفسير
                      Expanded(
                        child: InkWell(
                          onTap: _showTafsirDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kBorderTan),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book_rounded, color: _kPrimaryGreen, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedTafsirKey == 'none' ? 'إضافة تفسير' : _tafsirDisplayName(_selectedTafsirKey),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // زر الانتقال لاستوديو الستوري المتقدم
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.palette_outlined, size: 20),
                        tooltip: 'استوديو البطاقات والستوري',
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AyahStoryMakerScreen(initialAyahId: _selectedAyahs.first.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5. قسم اختيار القارئ عند اختيار الصوت
                  if (_selectedTab == ShareTab.audio) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorderTan),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReciterId,
                          isExpanded: true,
                          items: kReciters.take(20).map((r) {
                            return DropdownMenuItem(
                              value: r.id,
                              child: Row(
                                children: [
                                  const Icon(Icons.mic_none_rounded, color: _kPrimaryGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Text(r.nameAr, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedReciterId = val ?? 'alafasy'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 6. المعاينة الحية المباشرة (مطابقة تماماً للصور 1 و 3)
                  Center(
                    child: RepaintBoundary(
                      key: _cardPreviewKey,
                      child: _selectedTab == ShareTab.text
                          ? _buildTextCardPreview(isDark)
                          : _buildMushafImagePreview(isDark),
                    ),
                  ),
                ],
              ),
            ),

            // 7. أزرار الإجراءات السفلية: [ مشاركة ] و [ حفظ كصورة ]
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B232E) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  // زر حفظ كصورة في المعرض
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimaryGreen,
                        side: const BorderSide(color: _kPrimaryGreen, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('حفظ كصورة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: _isProcessing ? null : _saveToGallery,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // زر مشاركة
                  Expanded(
                    flex: 2,
                    child: AppPrimaryButton(
                      label: _isProcessing ? 'جارٍ المعالجة...' : 'مشاركة',
                      icon: Icons.share_rounded,
                      color: _kPrimaryGreen,
                      loading: _isProcessing,
                      onPressed: _isProcessing ? null : _executeShare,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _kPrimaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorBox({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : _kParchmentCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorderTan),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF8D7344), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// معاينة بطاقة النص (مطابقة تماماً للصورة 1)
  Widget _buildTextCardPreview(bool isDark) {
    final ayahs = _selectedAyahs;
    final rangeStr = _fromAyah == _toAyah ? '$_fromAyah' : '$_fromAyah - $_toAyah';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorderTan),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // أيقونة النسخ السريعة في زاوية البطاقة
          Align(
            alignment: Alignment.topLeft,
            child: InkWell(
              onTap: () async {
                final buffer = StringBuffer();
                for (final a in ayahs) {
                  buffer.write('${a.textUthmani} ﴿${toArabicDigits(a.ayah)}﴾ ');
                }
                await Clipboard.setData(ClipboardData(text: '{ ${buffer.toString().trim()} }\n[ سورة $_cleanSurahName : $rangeStr ]'));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص الآية بنجاح 📋')));
                }
              },
              child: const Icon(Icons.copy_rounded, color: _kPrimaryGreen, size: 20),
            ),
          ),
          const SizedBox(height: 6),

          // نص الآيات
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '{ '),
                for (final a in ayahs) ...[
                  TextSpan(text: '${a.textUthmani} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _AyahEndCircle(
                      ayahId: a.id,
                      ayahNumber: a.ayah,
                      pageNumber: a.page,
                      size: 24,
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
                const TextSpan(text: '}'),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: 18,
              height: 2.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // توثيق السورة والآية
          Text(
            '[ سورة $_cleanSurahName : $rangeStr ]',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
          ),

          // التفسير المختار إن وُجد
          if (_selectedTafsirKey != 'none' && ayahs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            FutureBuilder<Tafsir?>(
              future: ref.read(quranRepositoryProvider).tafsirForAyah(ayahs.first.id, edition: _selectedTafsirKey),
              builder: (ctx, snap) {
                final content = snap.data?.content ?? '';
                if (content.isEmpty) return const SizedBox.shrink();
                return Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF5D4037)),
                );
              },
            ),
          ],

          const SizedBox(height: 10),
          const Text(
            'بواسطة تطبيق هُمَام',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// معاينة بطاقة المصحف الشريف الأصيلة (مطابقة تماماً للصورة 3 بدائرة نهاية الآيات المصحفية)
  Widget _buildMushafImagePreview(bool isDark) {
    final ayahs = _selectedAyahs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGoldMushaf, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // لافتة اسم السورة المزخرفة بالألوان العثمانية (مطابقة لصور وحي)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECE3D0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8D7344), width: 1.2),
            ),
            child: Text(
              'سُورَةُ $_cleanSurahName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2416),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // البسملة إن كانت البداية
          if (_fromAyah == 1 && _surahId != 9 && _surahId != 1) ...[
            const Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 16.5, color: Color(0xFF2C2416)),
            ),
            const SizedBox(height: 8),
          ],

          // نص الآيات القرآنية مع رقم الآية الدائري المصحفي الأصيل
          Text.rich(
            TextSpan(
              children: [
                for (final a in ayahs) ...[
                  TextSpan(text: '${a.textUthmani} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _AyahEndCircle(
                      ayahId: a.id,
                      ayahNumber: a.ayah,
                      pageNumber: a.page,
                      size: 26,
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: _fontSize,
              height: 2.3,
              leadingDistribution: TextLeadingDistribution.even,
              color: const Color(0xFF1E1912),
            ),
          ),

          // التفسير المختار إن وُجد
          if (_selectedTafsirKey != 'none' && ayahs.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: _kGoldMushaf, height: 1),
            const SizedBox(height: 6),
            FutureBuilder<Tafsir?>(
              future: ref.read(quranRepositoryProvider).tafsirForAyah(ayahs.first.id, edition: _selectedTafsirKey),
              builder: (ctx, snap) {
                final content = snap.data?.content ?? '';
                if (content.isEmpty) return const SizedBox.shrink();
                return Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF5D4037)),
                );
              },
            ),
          ],

          const SizedBox(height: 8),
          const Text(
            'بواسطة تطبيق هُمَام',
            style: TextStyle(fontSize: 9.5, color: Color(0xFF8D7344), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

final _ayahGlyphProvider = FutureProvider.family<String?, int>((ref, ayahId) {
  return ref.watch(quranRepositoryProvider).ayahMarkerGlyph(ayahId);
});

/// علامة نهاية الآية الدائرية المطابقة تماماً للمصحف الشريف (زهرة المصحف الأصلية بـ QCF V2 أو الرسم المتجهي الدقيق)
class _AyahEndCircle extends ConsumerWidget {
  final int ayahId;
  final int ayahNumber;
  final int pageNumber;
  final double size;

  const _AyahEndCircle({
    required this.ayahId,
    required this.ayahNumber,
    required this.pageNumber,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontAsync = ref.watch(pageFontFamilyProvider(pageNumber));
    final glyphAsync = ref.watch(_ayahGlyphProvider(ayahId));

    if (fontAsync.hasValue && glyphAsync.hasValue && glyphAsync.value != null && glyphAsync.value!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Text(
          glyphAsync.value!,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: fontAsync.value,
            fontSize: size * 1.05,
            color: const Color(0xFF1E1912),
            height: 1.0,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: CustomPaint(
        size: Size(size, size * 1.15),
        painter: _AyahEndCirclePainter(color: const Color(0xFF1E1912)),
        child: SizedBox(
          width: size,
          height: size * 1.15,
          child: Center(
            child: Text(
              _AyahShareSheetState.toArabicDigits(ayahNumber),
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: size * 0.40,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E1912),
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AyahEndCirclePainter extends CustomPainter {
  final Color color;

  _AyahEndCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. الإطار البيضاوي المركزي
    final ovalRect = Rect.fromCenter(center: Offset(cx, cy), width: w * 0.76, height: h * 0.76);
    canvas.drawOval(ovalRect, paint);

    // 2. التاج الزخرفي العلوي (3 فصوص مصحفية متناسقة)
    final topY = cy - h * 0.38;
    final topPath = Path();
    topPath.moveTo(cx - w * 0.22, topY + h * 0.08);
    topPath.quadraticBezierTo(cx - w * 0.18, topY - h * 0.06, cx - w * 0.08, topY - h * 0.08);
    topPath.quadraticBezierTo(cx - w * 0.03, topY - h * 0.16, cx, topY - h * 0.18);
    topPath.quadraticBezierTo(cx + w * 0.03, topY - h * 0.16, cx + w * 0.08, topY - h * 0.08);
    topPath.quadraticBezierTo(cx + w * 0.18, topY - h * 0.06, cx + w * 0.22, topY + h * 0.08);
    canvas.drawPath(topPath, paint);

    canvas.drawCircle(Offset(cx, topY - h * 0.08), 0.9, fillPaint);

    // 3. الزخرفتان السفليتان المنحنيتان (أجنحة زهرة المصحف)
    final bottomY = cy + h * 0.38;
    final bottomPath = Path();
    bottomPath.moveTo(cx - w * 0.25, bottomY - h * 0.10);
    bottomPath.cubicTo(
      cx - w * 0.28, bottomY + h * 0.08,
      cx - w * 0.12, bottomY + h * 0.16,
      cx, bottomY + h * 0.18,
    );
    bottomPath.cubicTo(
      cx + w * 0.12, bottomY + h * 0.16,
      cx + w * 0.28, bottomY + h * 0.08,
      cx + w * 0.25, bottomY - h * 0.10,
    );
    canvas.drawPath(bottomPath, paint);

    // حلقتان زخرفيتان سفليتان
    final scrollPath = Path();
    scrollPath.moveTo(cx - w * 0.18, bottomY - h * 0.02);
    scrollPath.quadraticBezierTo(cx - w * 0.08, bottomY + h * 0.07, cx, bottomY + h * 0.07);
    scrollPath.quadraticBezierTo(cx + w * 0.08, bottomY + h * 0.07, cx + w * 0.18, bottomY - h * 0.02);
    canvas.drawPath(scrollPath, paint..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
