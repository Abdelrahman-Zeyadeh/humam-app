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
import 'widgets/ayah_share_format.dart';
import 'widgets/ayah_share_pickers.dart';
import 'widgets/ayah_share_previews.dart';
import 'widgets/ayah_share_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isLoaded || _surah == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E28) : AyahShareColors.parchmentBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AyahShareColors.primaryGreen)),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : AyahShareColors.parchmentBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. الرأس الأخضر (مشاركة + X) - مطابق لصور وحي
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
                      border: Border.all(color: AyahShareColors.borderTan),
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
                                  const Icon(Icons.mic_none_rounded, color: AyahShareColors.primaryGreen, size: 18),
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
                          ? AyahTextCardPreview(
                              isDark: isDark,
                              ayahs: _selectedAyahs,
                              cleanSurahName: _cleanSurahName,
                              fromAyah: _fromAyah,
                              toAyah: _toAyah,
                              selectedTafsirKey: _selectedTafsirKey,
                              ref: ref,
                            )
                          : AyahMushafImagePreview(
                              isDark: isDark,
                              ayahs: _selectedAyahs,
                              cleanSurahName: _cleanSurahName,
                              surahId: _surahId,
                              fromAyah: _fromAyah,
                              selectedTafsirKey: _selectedTafsirKey,
                              fontSize: _fontSize,
                              ref: ref,
                            ),
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
                        foregroundColor: AyahShareColors.primaryGreen,
                        side: const BorderSide(color: AyahShareColors.primaryGreen, width: 1.5),
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
