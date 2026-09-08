import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/platform/gallery_saver.dart';

class HumamWallpaperPreset {
  final String id;
  final String title;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;
  final String defaultText;
  final String defaultSubText;
  final Color textColor;
  final Color accentColor;

  const HumamWallpaperPreset({
    required this.id,
    required this.title,
    required this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    required this.defaultText,
    required this.defaultSubText,
    this.textColor = Colors.white,
    this.accentColor = const Color(0xFFD4AF37),
  });
}

const List<HumamWallpaperPreset> kHumamWallpapers = [
  HumamWallpaperPreset(
    id: 'night_sky',
    title: 'سماء هادئة',
    colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
    defaultText: 'وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لَا يَمُوتُ',
    defaultSubText: 'سورة الفرقان — آية ٥٨',
    textColor: Color(0xFFF1F5F9),
    accentColor: Color(0xFF93C5FD),
  ),
  HumamWallpaperPreset(
    id: 'emerald_peace',
    title: 'زمردي روحاني',
    colors: [Color(0xFF062A1A), Color(0xFF0F4A2C), Color(0xFF1E3A2B)],
    defaultText: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    defaultSubText: 'سورة الرعد — آية ٢٨',
    textColor: Color(0xFFECFDF5),
    accentColor: Color(0xFF6EE7B7),
  ),
  HumamWallpaperPreset(
    id: 'royal_gold',
    title: 'نور ذهبي',
    colors: [Color(0xFF1A140A), Color(0xFF2E2412), Color(0xFF4D3D1E)],
    defaultText: 'رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
    defaultSubText: 'سورة القصص — آية ٢٤',
    textColor: Color(0xFFFFFBEB),
    accentColor: Color(0xFFFCD34D),
  ),
  HumamWallpaperPreset(
    id: 'deep_purple',
    title: 'سكينة المساء',
    colors: [Color(0xFF1E102F), Color(0xFF3B1E54), Color(0xFF533B6D)],
    defaultText: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    defaultSubText: 'سورة آل عمران — آية ١٧٣',
    textColor: Color(0xFFFAF5FF),
    accentColor: Color(0xFFD8B4FE),
  ),
  HumamWallpaperPreset(
    id: 'ocean_depth',
    title: 'رحاب الأفق',
    colors: [Color(0xFF0A192F), Color(0xFF172A45), Color(0xFF203A43)],
    defaultText: 'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    defaultSubText: 'دعاء ذي النون عليه السلام',
    textColor: Color(0xFFF0FDF4),
    accentColor: Color(0xFF5EEAD4),
  ),
  HumamWallpaperPreset(
    id: 'desert_dusk',
    title: 'أصيل مذهب',
    colors: [Color(0xFF2B1810), Color(0xFF4A2810), Color(0xFF6E3B16)],
    defaultText: 'وَقُلْ رَبِّ زِدْنِي عِلْمًا',
    defaultSubText: 'سورة طه — آية ١١٤',
    textColor: Color(0xFFFFF7ED),
    accentColor: Color(0xFFFDBA74),
  ),
  HumamWallpaperPreset(
    id: 'pure_dark',
    title: 'سكون الليل',
    colors: [Color(0xFF0F0F10), Color(0xFF1A1A1E), Color(0xFF27272E)],
    defaultText: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
    defaultSubText: 'سورة البقرة — آية ١٥٢',
    textColor: Color(0xFFF8FAFC),
    accentColor: Color(0xFFCBD5E1),
  ),
];

class WallpapersScreen extends StatefulWidget {
  const WallpapersScreen({super.key});

  @override
  State<WallpapersScreen> createState() => _WallpapersScreenState();
}

class _WallpapersScreenState extends State<WallpapersScreen> {
  int _selectedPresetIndex = 0;
  late TextEditingController _textController;
  late TextEditingController _subTextController;
  final double _fontSize = 22.0;
  final bool _showBranding = true;
  bool _isSaving = false;
  final GlobalKey _wallpaperPreviewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final initial = kHumamWallpapers.first;
    _textController = TextEditingController(text: initial.defaultText);
    _subTextController = TextEditingController(text: initial.defaultSubText);
  }

  @override
  void dispose() {
    _textController.dispose();
    _subTextController.dispose();
    super.dispose();
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      _textController.text = kHumamWallpapers[index].defaultText;
      _subTextController.text = kHumamWallpapers[index].defaultSubText;
    });
  }

  Future<Uint8List?> _captureImageBytes() async {
    final boundary = _wallpaperPreviewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 4.0); // UHD
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) return;
      final filename = 'humam_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
      final res = await savePngToGallery(bytes, displayName: filename);
      if (!mounted) return;

      final message = (res.saved && res.inGallery)
          ? 'تم حفظ خلفية هُمَام في المعرض بنجاح 🖼️✨'
          : 'تم حفظ الخلفية بنجاح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر حفظ الخلفية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareWallpaper() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/humam_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: '${_textController.text}\n\nخلفيات تطبيق هُمَام 🌸',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر المشاركة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDhikrPickerSheet() {
    const dhikrPresets = [
      ('وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لَا يَمُوتُ', 'سورة الفرقان — آية ٥٨'),
      ('أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'سورة الرعد — آية ٢٨'),
      ('رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ', 'سورة القصص — آية ٢٤'),
      ('حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ', 'سورة آل عمران — آية ١٧٣'),
      ('لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ', 'دعاء ذي النون'),
      ('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ', 'كلمتان حبيبتان إلى الرحمن'),
      ('لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ', 'كنز من كنوز الجنة'),
      ('اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ', 'الصلاة على النبي ﷺ'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.separated(
          itemCount: dhikrPresets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final item = dhikrPresets[i];
            return ListTile(
              title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: Text(item.$2, style: const TextStyle(fontSize: 11.5)),
              onTap: () {
                setState(() {
                  _textController.text = item.$1;
                  _subTextController.text = item.$2;
                });
                Navigator.pop(ctx);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preset = kHumamWallpapers[_selectedPresetIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خلفيات هُمَام 🖼️'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.format_quote_rounded),
              tooltip: 'اختر ذكراً جاهزاً',
              onPressed: _showDhikrPickerSheet,
            ),
          ],
        ),
        body: Column(
          children: [
            // منطقة المعاينة (شاشة هاتف أنيقة 9:16)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: RepaintBoundary(
                    key: _wallpaperPreviewKey,
                    child: Container(
                      width: 270,
                      height: 480,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          colors: preset.colors,
                          begin: preset.begin,
                          end: preset.end,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: preset.accentColor.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // زخرفة خلفية هندسية رقيقة
                          Positioned(
                            top: 40,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 24,
                              color: preset.accentColor.withValues(alpha: 0.3),
                            ),
                          ),

                          // النص الرئيسي والفرعي
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _textController.text.trim().isEmpty ? 'اذكر الله' : _textController.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'AmiriQuran',
                                    fontSize: _fontSize,
                                    height: 1.8,
                                    color: preset.textColor,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_subTextController.text.trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: preset.accentColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _subTextController.text,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: preset.accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // شارة هُمَام بالأسفل
                          if (_showBranding)
                            Positioned(
                              bottom: 24,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 10,
                                    color: preset.accentColor.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'خلفيات هُمَام',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: preset.textColor.withValues(alpha: 0.65),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // لوحة التحكم السفلية بالخلفيات والتعديل
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2836) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // شريط اختيار ألوان الخلفيات الدائرية
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: kHumamWallpapers.length,
                        itemBuilder: (ctx, idx) {
                          final p = kHumamWallpapers[idx];
                          final isSelected = idx == _selectedPresetIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: InkWell(
                              onTap: () => _selectPreset(idx),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: p.colors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white24,
                                    width: isSelected ? 3 : 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: p.accentColor.withValues(alpha: 0.6),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(Icons.check_rounded, color: Colors.white, size: 22),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // حقل تعديل الذكر/الدعاء
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'اكتب ذكراً أو دعاءً أو آية...',
                        prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.format_quote_rounded, size: 18),
                          tooltip: 'أذكار مقترحة',
                          onPressed: _showDhikrPickerSheet,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // أزرار الحفظ والمشاركة
                    Row(
                      children: [
                        // حفظ بالمعرض
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D4C41),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.download_rounded, size: 20),
                            label: Text(
                              _isSaving ? 'جارٍ الحفظ...' : 'حفظ كخلفية',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isSaving ? null : _saveToGallery,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // مشاركة
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF4A3B2C),
                            side: BorderSide(
                              color: isDark ? Colors.white38 : const Color(0xFF8D6E63),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('مشاركة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          onPressed: _isSaving ? null : _shareWallpaper,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
