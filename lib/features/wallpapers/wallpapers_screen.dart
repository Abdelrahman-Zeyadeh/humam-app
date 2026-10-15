import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/platform/gallery_saver.dart';
import '../story_maker/ui/widgets/islamic_luxury_card.dart';

/// نموذج خلفية فذكّر الفاخرة
class FathakkirWallpaperItem {
  final String id;
  final String title;
  final String caption;
  final String badgeText;
  final String mainText;
  final String topTitle;
  final String footerText;
  final List<Color> colors;
  final Color textColor;
  final Color accentColor;

  const FathakkirWallpaperItem({
    required this.id,
    required this.title,
    required this.caption,
    required this.badgeText,
    required this.mainText,
    this.topTitle = 'هُمَام',
    this.footerText = 'ذكّر غيرك',
    required this.colors,
    this.textColor = const Color(0xFFE5C378),
    this.accentColor = const Color(0xFFD4AF37),
  });
}

const List<List<Color>> kLuxuryColorThemes = [
  // 1. عنبر فذكّر (المعتمد في صورة المستخدم)
  [Color(0xFF1B0E06), Color(0xFF381F0D), Color(0xFF140A04)],
  // 2. زمردي ملكي
  [Color(0xFF061A10), Color(0xFF0E3823), Color(0xFF05140C)],
  // 3. كحلي عميق
  [Color(0xFF081224), Color(0xFF122347), Color(0xFF050B16)],
  // 4. أسود مذهب
  [Color(0xFF111113), Color(0xFF22201C), Color(0xFF0C0C0D)],
  // 5. عنابي وقار
  [Color(0xFF1F0814), Color(0xFF3B1228), Color(0xFF16050E)],
];

const List<FathakkirWallpaperItem> kFathakkirWallpapers = [
  FathakkirWallpaperItem(
    id: 'salawat',
    title: 'الصلاة على النبي',
    caption: 'كرر تؤجر "الصلاة على النبي"',
    badgeText: 'كرر تؤجر',
    mainText: 'اللهم صل\nو سلمــــ\nعلى نبينا\nمحمـــــد',
    colors: [Color(0xFF1B0E06), Color(0xFF381F0D), Color(0xFF140A04)],
  ),
  FathakkirWallpaperItem(
    id: 'istighfar',
    title: 'الاستغفار',
    caption: 'كرر تؤجر "الاستغفار"',
    badgeText: 'كرر تؤجر',
    mainText: 'أستغفـــــر\nالله وأتوب\nإليــــــــه',
    colors: [Color(0xFF1B0E06), Color(0xFF381F0D), Color(0xFF140A04)],
  ),
  FathakkirWallpaperItem(
    id: 'hawqalah',
    title: 'الحوقلة',
    caption: 'كنز من كنوز الجنة "الحوقلة"',
    badgeText: 'كنز الجنة',
    mainText: 'لا حـــول\nولا قـــوة\nإلا بالله\nالعلي العظيم',
    colors: [Color(0xFF061A10), Color(0xFF0E3823), Color(0xFF05140C)],
  ),
  FathakkirWallpaperItem(
    id: 'tasbih',
    title: 'التسبيح',
    caption: 'كرر تؤجر "التسبيح والتحميد"',
    badgeText: 'كرر تؤجر',
    mainText: 'سبحان الله\nوبحمــــده\nسبحان الله\nالعظيــــم',
    colors: [Color(0xFF111113), Color(0xFF22201C), Color(0xFF0C0C0D)],
  ),
  FathakkirWallpaperItem(
    id: 'tawakkul',
    title: 'التوكل',
    caption: 'سورة الفرقان — آية ٥٨',
    badgeText: 'آية وسكينة',
    mainText: 'وَتَوَكَّلْ\nعَلَى الْحَيِّ\nالَّذِي\nلَا يَمُوتُ',
    colors: [Color(0xFF081224), Color(0xFF122347), Color(0xFF050B16)],
  ),
  FathakkirWallpaperItem(
    id: 'itmeenan',
    title: 'طمأنينة القلب',
    caption: 'سورة الرعد — آية ٢٨',
    badgeText: 'آية وتدبر',
    mainText: 'أَلَا بِذِكْرِ\nاللَّهِ تَطْمَئِنُّ\nالْقُلُــــوبُ',
    colors: [Color(0xFF1B0E06), Color(0xFF381F0D), Color(0xFF140A04)],
  ),
  FathakkirWallpaperItem(
    id: 'faraj',
    title: 'دعاء الكرب والفرج',
    caption: 'دعاء ذي النون عليه السلام',
    badgeText: 'دعاء الفرج',
    mainText: 'لَا إِلَهَ إِلَّا أَنْتَ\nسُبْحَانَكَ إِنِّي\nكُنْتُ مِنَ\nالظَّالِمِينَ',
    colors: [Color(0xFF1F0814), Color(0xFF3B1228), Color(0xFF16050E)],
  ),
  FathakkirWallpaperItem(
    id: 'hasbi',
    title: 'الحسبلة',
    caption: 'سورة آل عمران — آية ١٧٣',
    badgeText: 'أمان الخائفين',
    mainText: 'حَسْبُنَا اللَّهُ\nوَنِعْمَ\nالْوَكِيــــلُ',
    colors: [Color(0xFF081224), Color(0xFF122347), Color(0xFF050B16)],
  ),
  FathakkirWallpaperItem(
    id: 'ilm',
    title: 'طلب العلم',
    caption: 'سورة طه — آية ١١٤',
    badgeText: 'دعاء قرآني',
    mainText: 'وَقُلْ رَبِّ\nزِدْنِي\nعِلْمًـــــا',
    colors: [Color(0xFF1B0E06), Color(0xFF381F0D), Color(0xFF140A04)],
  ),
  FathakkirWallpaperItem(
    id: 'shukr',
    title: 'ذكر وشكر',
    caption: 'سورة البقرة — آية ١٥٢',
    badgeText: 'عهد ووعد',
    mainText: 'فَاذْكُرُونِي\nأَذْكُرْكُـــمْ\nوَاشْكُرُوا لِي\nوَلَا تَكْفُرُونِ',
    colors: [Color(0xFF111113), Color(0xFF22201C), Color(0xFF0C0C0D)],
  ),
];

/// شاشة خلفيات فذكّر بتصميم أنيق ومطابق للصورة
class WallpapersScreen extends StatefulWidget {
  const WallpapersScreen({super.key});

  @override
  State<WallpapersScreen> createState() => _WallpapersScreenState();
}

class _WallpapersScreenState extends State<WallpapersScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121214) : const Color(0xFFFAF7F0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: const Text(
            'خلفيات هُمَام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: scaffoldBg,
          elevation: 0,
        ),
        body: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: 0.52,
          ),
          itemCount: kFathakkirWallpapers.length,
          itemBuilder: (context, index) {
            final item = kFathakkirWallpapers[index];
            return InkWell(
              onTap: () => _openWallpaperDetail(context, item),
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بطاقة المعاينة المصغرة الفاخرة
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: IslamicLuxuryCard(
                          mainText: item.mainText,
                          badgeText: item.badgeText,
                          topTitle: item.topTitle,
                          footerText: item.footerText,
                          gradientColors: item.colors,
                          fontSize: 26,
                          width: 260,
                          height: 480,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // التعليق أسفل البطاقة كالصورة تماماً
                  Text(
                    item.caption,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF2C2416),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openWallpaperDetail(BuildContext context, FathakkirWallpaperItem initialItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WallpaperDetailViewer(item: initialItem),
      ),
    );
  }
}

/// عارض ومحرر الخلفية الفاخر بملء الشاشة مع التصدير بجودة فائقة
class _WallpaperDetailViewer extends StatefulWidget {
  final FathakkirWallpaperItem item;

  const _WallpaperDetailViewer({required this.item});

  @override
  State<_WallpaperDetailViewer> createState() => _WallpaperDetailViewerState();
}

class _WallpaperDetailViewerState extends State<_WallpaperDetailViewer> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  late String _mainText;
  late String _badgeText;
  late String _topTitle;
  late String _footerText;
  late List<Color> _colors;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _mainText = widget.item.mainText;
    _badgeText = widget.item.badgeText;
    _topTitle = widget.item.topTitle;
    _footerText = widget.item.footerText;
    _colors = widget.item.colors;
  }

  Future<Uint8List?> _captureImageBytes() async {
    final boundary = _cardBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 4.0); // UHD
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) return;
      final filename = 'fathakkir_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
      final res = await savePngToGallery(bytes, displayName: filename);
      if (!mounted) return;

      final message = (res.saved && res.inGallery)
          ? 'تم حفظ خلفية فذكّر في المعرض بنجاح 🖼️✨'
          : 'تم حفظ الخلفية بنجاح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareWallpaper() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/fathakkir_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'خلفية إسلامية من تطبيق هُمَام ✨\n$_mainText',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر المشاركة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showCustomizeDialog() {
    final textCtrl = TextEditingController(text: _mainText);
    final badgeCtrl = TextEditingController(text: _badgeText);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1A16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تخصيص عبارة الخلفية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE5C378),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: badgeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'نص الإطار العلوي (مثل: كرر تؤجر)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, height: 1.5),
              decoration: InputDecoration(
                labelText: 'النص الرئيسي (قسّم الأسطر حسب رغبتك)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _badgeText = badgeCtrl.text.trim();
                  _mainText = textCtrl.text.trim();
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تطبيق التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0A06),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFD4AF37)),
              tooltip: 'تعديل العبارة',
              onPressed: _showCustomizeDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // معاينة البطاقة بحجمها الطبيعي الفاخر
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: RepaintBoundary(
                    key: _cardBoundaryKey,
                    child: IslamicLuxuryCard(
                      mainText: _mainText,
                      badgeText: _badgeText,
                      topTitle: _topTitle,
                      footerText: _footerText,
                      gradientColors: _colors,
                      fontSize: 27,
                      width: 290,
                      height: 520,
                    ),
                  ),
                ),
              ),
            ),

            // شريط اختيار ألوان الثيم الفاخرة
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final themeColors in kLuxuryColorThemes)
                    GestureDetector(
                      onTap: () => setState(() => _colors = themeColors),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [themeColors.first, themeColors[1]],
                          ),
                          border: Border.all(
                            color: _colors == themeColors
                                ? const Color(0xFFD4AF37)
                                : Colors.white24,
                            width: _colors == themeColors ? 2.5 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // شريط الإجراءات السفلي (حفظ في المعرض + مشاركة)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.download_rounded, size: 20),
                        label: const Text(
                          'حفظ في المعرض (UHD)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        onPressed: _isExporting ? null : _saveToGallery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text(
                          'مشاركة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: _isExporting ? null : _shareWallpaper,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE5C378),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
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
