import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/quran/quran_database.dart';
import '../../../core/data/quran/quran_providers.dart';
import '../../../core/platform/gallery_saver.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../audio/reciters.dart';
import '../audio/ui/reciter_avatar.dart';
import '../story_maker/ui/ayah_story_maker_screen.dart';
import 'widgets/ayah_share_format.dart';
import 'widgets/ayah_share_pickers.dart';
import 'widgets/ayah_share_previews.dart';
import 'widgets/ayah_share_theme.dart';

enum ShareTab { text, image, audio }

enum ShareScopeMode {
  ayahs,
  fullPage,
}

class AyahShareSheet extends ConsumerStatefulWidget {
  final int? initialAyahId;
  final int? initialPage;
  final ShareScopeMode initialScopeMode;

  const AyahShareSheet({
    super.key,
    this.initialAyahId,
    this.initialPage,
    this.initialScopeMode = ShareScopeMode.ayahs,
  });

  /// فتح نافذة المشاركة لآية معيّنة بنمط الآيات المحددة (مع إمكانية التبديل لصفحة كاملة)
  static Future<void> show(BuildContext context, int ayahId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AyahShareSheet(
        initialAyahId: ayahId,
        initialScopeMode: ShareScopeMode.ayahs,
      ),
    );
  }

  /// فتح نافذة المشاركة لصفحة مصحف كاملة بنمط صفحة القرآن (مع إمكانية اختيار الخلفية)
  static Future<void> showForPage(BuildContext context, int page) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AyahShareSheet(
        initialPage: page,
        initialScopeMode: ShareScopeMode.fullPage,
      ),
    );
  }

  @override
  ConsumerState<AyahShareSheet> createState() => _AyahShareSheetState();
}

class _AyahShareSheetState extends ConsumerState<AyahShareSheet> {
  final GlobalKey _cardPreviewKey = GlobalKey();

  late ShareScopeMode _scopeMode = widget.initialScopeMode;
  ShareTab _selectedTab = ShareTab.image;

  // حالة الآيات المحددة
  late int _surahId = 1;
  late int _fromAyah = 1;
  late int _toAyah = 1;
  Surah? _surah;
  List<Ayah> _allSurahAyahs = [];

  // حالة الصفحة الكاملة
  late int _currentPageNumber = widget.initialPage ?? 1;
  int? _juzNumber;
  String? _hizbFraction;
  List<Ayah> _pageAyahs = [];
  Map<int, String> _surahNamesMap = {};

  // خلفية وتخصيص بطاقة المصحف
  String? _customBgPath;
  MushafShareBgTheme _selectedBgTheme = MushafShareBgTheme.parchment;
  double _overlayDarkness = 0.55;

  String _selectedTafsirKey = 'none';
  String _selectedReciterId = 'alafasy';

  double get _fontSize {
    final count = _scopeMode == ShareScopeMode.fullPage ? _pageAyahs.length : _selectedAyahs.length;
    if (count <= 3) return 18.0;
    if (count <= 6) return 15.0;
    if (count <= 10) return 13.0;
    if (count <= 18) return 11.5;
    return 10.5;
  }

  bool _isProcessing = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final repo = ref.read(quranRepositoryProvider);

    if (widget.initialAyahId != null) {
      final initialAyah = await repo.ayahById(widget.initialAyahId!);
      final surah = await repo.surahById(initialAyah.surah);
      final ayahs = await repo.ayahsForSurah(initialAyah.surah);

      _surahId = initialAyah.surah;
      _fromAyah = initialAyah.ayah;
      _toAyah = initialAyah.ayah;
      _surah = surah;
      _allSurahAyahs = ayahs;
      _currentPageNumber = initialAyah.page;
    }

    await _loadPageData(_currentPageNumber);

    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  Future<void> _loadPageData(int page) async {
    final repo = ref.read(quranRepositoryProvider);
    final ayahs = await repo.ayahsForPage(page);
    final juz = ayahs.isNotEmpty ? ayahs.first.juz : 1;
    final hizb = await repo.hizbForPage(page);
    final rub = await repo.rubForPage(page);
    final quarterInHizb = ((rub - 1) % 4) + 1;
    const fractionLabels = {1: 'ربع', 2: 'نصف', 3: 'ثلاثة أرباع'};
    final prefix = fractionLabels[quarterInHizb];
    final hizbStr = prefix == null ? 'الحزب $hizb' : '$prefix الحزب $hizb';

    final surahIds = ayahs.map((a) => a.surah).toSet();
    final namesMap = <int, String>{};
    for (final sId in surahIds) {
      final s = await repo.surahById(sId);
      namesMap[sId] = s.nameAr.replaceFirst('سورة ', '').replaceFirst('سُورَةُ ', '').trim();
    }

    Surah? currentSurah = _surah;
    if (ayahs.isNotEmpty) {
      currentSurah = await repo.surahById(ayahs.first.surah);
      if (_allSurahAyahs.isEmpty) {
        _allSurahAyahs = await repo.ayahsForSurah(ayahs.first.surah);
        _surahId = ayahs.first.surah;
        _fromAyah = ayahs.first.ayah;
        _toAyah = ayahs.last.ayah;
      }
    }

    if (mounted) {
      setState(() {
        _currentPageNumber = page;
        _pageAyahs = ayahs;
        _juzNumber = juz;
        _hizbFraction = hizbStr;
        _surahNamesMap = namesMap;
        _surah = currentSurah;
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
        _toAyah = ayahs.length > 5 ? 5 : ayahs.length;
      });
    }
  }

  List<Ayah> get _selectedAyahs {
    if (_allSurahAyahs.isEmpty) return [];
    return _allSurahAyahs.where((a) => a.ayah >= _fromAyah && a.ayah <= _toAyah).toList();
  }

  String get _cleanSurahName {
    if (_surah == null) return '';
    return _surah!.nameAr.replaceFirst('سورة ', '').replaceFirst('سُورَةُ ', '').trim();
  }

  Future<Uint8List?> _captureCardBytes() async {
    final boundary = _cardPreviewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 4.5); // دقة فائقة UHD
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _pickCustomBackground() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.image,
      );
      final path = picked?.path;
      if (path != null && mounted) {
        setState(() {
          _customBgPath = path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم اختيار الخلفية المخصصة بنجاح 🖼️✨'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر اختيار الصورة: $e')),
        );
      }
    }
  }

  Future<void> _executeShare() async {
    final isFull = _scopeMode == ShareScopeMode.fullPage;
    final ayahsToShare = isFull ? _pageAyahs : _selectedAyahs;
    if (ayahsToShare.isEmpty) return;

    if (_selectedTab == ShareTab.text) {
      final buffer = StringBuffer();
      for (final a in ayahsToShare) {
        buffer.write('${a.textUthmani} ﴿${toArabicDigits(a.ayah)}﴾ ');
      }
      final info = isFull
          ? '[ القرآن الكريم — صفحة $_currentPageNumber — الجزء ${toArabicDigits(_juzNumber ?? 1)} ]'
          : '[ سورة $_cleanSurahName : $_fromAyah - $_toAyah ]';
      final shareText = '﴿ ${buffer.toString().trim()} ﴾\n\n$info\nبواسطة تطبيق هُمَام ✨';

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
      final filename = isFull
          ? 'humam_quran_page_$_currentPageNumber.png'
          : 'humam_ayah_${_surahId}_${_fromAyah}_$_toAyah.png';
      final filePath = '${tempDir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final shareTitle = isFull
          ? 'صفحة $_currentPageNumber من المصحف الشريف — تطبيق هُمَام ✨'
          : 'سورة $_cleanSurahName ($_fromAyah - $_toAyah) — تطبيق هُمَام ✨';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: shareTitle,
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

      final isFull = _scopeMode == ShareScopeMode.fullPage;
      final displayName = isFull
          ? 'humam_page_${_currentPageNumber}_${DateTime.now().millisecondsSinceEpoch}.png'
          : 'humam_ayah_${_surahId}_${_fromAyah}_${_toAyah}_${DateTime.now().millisecondsSinceEpoch}.png';

      final result = await savePngToGallery(bytes, displayName: displayName);

      if (mounted) {
        final message = result.saved
            ? 'تم حفظ بطاقة المصحف في المعرض بنجاح 🖼️✨'
            : 'تم حفظ الصورة بنجاح';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF2E7D32),
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
    showAyahShareTafsirDialog(
      context,
      selectedKey: _selectedTafsirKey,
      onSelected: (key) => setState(() => _selectedTafsirKey = key),
    );
  }

  void _showSurahPicker() {
    showAyahShareSurahPicker(
      context,
      ref,
      currentSurahId: _surahId,
      onSurahSelected: _onSurahChanged,
    );
  }

  void _showAyahSearchPicker({required bool isFrom}) {
    showAyahShareSearchPicker(
      context,
      isFrom: isFrom,
      ayahs: _allSurahAyahs,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
      onRangeChanged: (newFrom, newTo) {
        setState(() {
          _fromAyah = newFrom;
          _toAyah = newTo;
        });
      },
    );
  }

  void _showPagePicker() {
    showAyahSharePagePicker(
      context,
      currentPage: _currentPageNumber,
      onPageSelected: (newPage) => _loadPageData(newPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isLoaded || _surah == null) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E28) : AyahShareColors.parchmentBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AyahShareColors.primaryGreen)),
      );
    }

    final isFull = _scopeMode == ShareScopeMode.fullPage;
    final activeAyahs = isFull ? _pageAyahs : _selectedAyahs;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.94,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E28) : AyahShareColors.parchmentBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. الترويسة العلوية الفاخرة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AyahShareColors.primaryGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    const Text(
                      'مشاركة القرآن الكريم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
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
                    // 2. محدد النطاق: [ 📖 صفحة كاملة ] | [ 📜 آيات محددة ]
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AyahShareColors.borderTan),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPillOption(
                              label: 'صفحة كاملة',
                              icon: Icons.menu_book_rounded,
                              selected: isFull,
                              onTap: () => setState(() => _scopeMode = ShareScopeMode.fullPage),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildPillOption(
                              label: 'آيات محددة',
                              icon: Icons.format_quote_rounded,
                              selected: !isFull,
                              onTap: () => setState(() => _scopeMode = ShareScopeMode.ayahs),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. شريط نوع المشاركة: [ 🖼️ بطاقة المصحف ] | [ 📝 نص ] | [ 🎧 صوت ]
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AyahShareColors.borderTan),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              label: 'بطاقة المصحف',
                              icon: Icons.image_outlined,
                              selected: _selectedTab == ShareTab.image,
                              onTap: () => setState(() => _selectedTab = ShareTab.image),
                            ),
                          ),
                          const SizedBox(width: 4),
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

                    // 4. خيارات التحديد حسب النطاق المختار
                    if (isFull) ...[
                      // شريط اختيار الصفحة والتنقل بين الصفحات
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AyahShareColors.borderTan),
                        ),
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_forward_ios, size: 14),
                              tooltip: 'الصفحة السابقة',
                              onPressed: _currentPageNumber > 1 ? () => _loadPageData(_currentPageNumber - 1) : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: _showPagePicker,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : const Color(0xFFF2ECE1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'صفحة المصحف رقم ( $_currentPageNumber )',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (_juzNumber != null)
                                        Text(
                                          'الجزء ${toArabicDigits(_juzNumber!)}${_hizbFraction != null ? ' · $_hizbFraction' : ''}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                              tooltip: 'الصفحة التالية',
                              onPressed: _currentPageNumber < 604 ? () => _loadPageData(_currentPageNumber + 1) : null,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // صف اختيار السورة ونطاق الآيات
                      Row(
                        children: [
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
                    ],
                    const SizedBox(height: 10),

                    // 5. قسم اختيار وتخصيص الخلفية (اختيار صورة من الجهاز أو قوالب فخمة)
                    if (_selectedTab == ShareTab.image) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AyahShareColors.borderTan),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.palette_outlined, size: 18, color: AyahShareColors.primaryGreen),
                                    SizedBox(width: 6),
                                    Text('خلفية البطاقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  ],
                                ),
                                // زر اختيار صورة من المعرض
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    side: const BorderSide(color: AyahShareColors.primaryGreen),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AyahShareColors.primaryGreen),
                                  label: const Text('صورة من جهازي', style: TextStyle(fontSize: 11.5, color: AyahShareColors.primaryGreen, fontWeight: FontWeight.bold)),
                                  onPressed: _pickCustomBackground,
                                ),
                              ],
                            ),

                            // شارة الصورة المخصصة إن وُجدت مع زر الإلغاء
                            if (_customBgPath != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AyahShareColors.primaryGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AyahShareColors.primaryGreen.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AyahShareColors.primaryGreen, size: 16),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Text(
                                        'تم تطبيق خلفية خاصة من جهازك',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AyahShareColors.primaryGreen),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => _customBgPath = null),
                                      child: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // درجات تعتيم الصورة المخصصة
                              Row(
                                children: [
                                  const Text('تعتيم الخلفية:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  for (final d in [
                                    (0.35, 'خفيفة'),
                                    (0.55, 'متوازنة'),
                                    (0.75, 'داكنة'),
                                  ]) ...[
                                    InkWell(
                                      onTap: () => setState(() => _overlayDarkness = d.$1),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        margin: const EdgeInsets.only(left: 6),
                                        decoration: BoxDecoration(
                                          color: _overlayDarkness == d.$1 ? AyahShareColors.primaryGreen : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: _overlayDarkness == d.$1 ? AyahShareColors.primaryGreen : Colors.grey.shade400),
                                        ),
                                        child: Text(
                                          d.$2,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: _overlayDarkness == d.$1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 10),
                              // شريط النماذج الجاهزة
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: MushafShareBgTheme.values.map((theme) {
                                    final isSel = _selectedBgTheme == theme;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: InkWell(
                                        onTap: () => setState(() => _selectedBgTheme = theme),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isSel ? AyahShareColors.primaryGreen.withValues(alpha: 0.15) : (isDark ? Colors.white10 : const Color(0xFFF7F4EE)),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSel ? AyahShareColors.primaryGreen : AyahShareColors.borderTan,
                                              width: isSel ? 1.8 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: theme.iconColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.black26),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                theme.label,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                                  color: isSel ? AyahShareColors.primaryGreen : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // 6. شريط التفسير والأدوات
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showTafsirDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AyahShareColors.borderTan),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.menu_book_rounded, color: AyahShareColors.primaryGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedTafsirKey == 'none' ? 'إضافة تفسير' : tafsirDisplayName(_selectedTafsirKey),
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
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.palette_outlined, size: 20),
                          tooltip: 'صانع بطاقات فذكّر المتقدم',
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AyahStoryMakerScreen(
                                  initialAyahId: activeAyahs.isNotEmpty ? activeAyahs.first.id : 255,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 7. قسم القارئ للصوت
                    if (_selectedTab == ShareTab.audio) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AyahShareColors.borderTan),
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
                                    ReciterAvatar(reciter: r, radius: 11),
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

                    // 8. المعاينة الحية المباشرة الفاخرة
                    Center(
                      child: RepaintBoundary(
                        key: _cardPreviewKey,
                        child: _selectedTab == ShareTab.text
                            ? AyahTextCardPreview(
                                isDark: isDark,
                                ayahs: activeAyahs,
                                cleanSurahName: _cleanSurahName,
                                fromAyah: _fromAyah,
                                toAyah: _toAyah,
                                selectedTafsirKey: _selectedTafsirKey,
                                ref: ref,
                              )
                            : AyahMushafImagePreview(
                                isDark: isDark,
                                ayahs: activeAyahs,
                                cleanSurahName: _cleanSurahName,
                                surahId: _surahId,
                                fromAyah: _fromAyah,
                                toAyah: _toAyah,
                                selectedTafsirKey: _selectedTafsirKey,
                                fontSize: _fontSize,
                                ref: ref,
                                isFullPage: isFull,
                                pageNumber: _currentPageNumber,
                                juzNumber: _juzNumber,
                                hizbFraction: _hizbFraction,
                                customBgPath: _customBgPath,
                                bgTheme: _selectedBgTheme,
                                overlayDarkness: _overlayDarkness,
                                surahNamesMap: _surahNamesMap,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // 9. الأزرار السفلية: [ حفظ في المعرض ] و [ مشاركة ]
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
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AyahShareColors.primaryGreen,
                          side: const BorderSide(color: AyahShareColors.primaryGreen, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('حفظ في المعرض', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        onPressed: _isProcessing ? null : _saveToGallery,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: AppPrimaryButton(
                        label: _isProcessing ? 'جارٍ المعالجة...' : 'مشاركة',
                        icon: Icons.share_rounded,
                        color: AyahShareColors.primaryGreen,
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
      ),
    );
  }

  Widget _buildPillOption({
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
          color: selected ? AyahShareColors.primaryGreen : Colors.transparent,
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
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? Colors.white : Colors.grey,
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
          color: selected ? AyahShareColors.primaryGreen.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AyahShareColors.primaryGreen : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? AyahShareColors.primaryGreen : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? AyahShareColors.primaryGreen : Colors.grey,
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
          color: isDark ? AppColors.surfaceDark : AyahShareColors.parchmentCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AyahShareColors.borderTan),
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
}
