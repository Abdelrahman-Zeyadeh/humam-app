import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/quran/quran_database.dart';
import '../../../core/data/quran/quran_providers.dart';
import '../../../core/platform/gallery_saver.dart';
import '../models/story_content.dart';
import 'widgets/islamic_luxury_card.dart';

final _ayahByIdProvider = FutureProvider.family<Ayah, int>((ref, id) {
  return ref.watch(quranRepositoryProvider).ayahById(id);
});

final _surahByIdProvider = FutureProvider.family<Surah, int>((ref, id) {
  return ref.watch(quranRepositoryProvider).surahById(id);
});

enum StoryRatio { story, square }

enum StoryTab { content, theme, typography, layout }

class _InspiringPreset {
  final String title;
  final String badge;
  final String mainText;
  String get topTitle => 'فَذَكِّرْ';
  String get footer => 'ذكّر غيرك';

  const _InspiringPreset({
    required this.title,
    required this.badge,
    required this.mainText,
  });
}

const List<_InspiringPreset> _kPresets = [
  _InspiringPreset(
    title: 'آية الكرسي',
    badge: 'سورة البقرة — آية ٢٥٥',
    mainText:
        'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
  ),
  _InspiringPreset(
    title: 'فاذكروني',
    badge: 'سورة البقرة — آية ١٥٢',
    mainText: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
  ),
  _InspiringPreset(
    title: 'مع العسر يسراً',
    badge: 'سورة الشرح — آية ٦',
    mainText: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
  ),
  _InspiringPreset(
    title: 'وتوكل على الحي',
    badge: 'سورة الفرقان — آية ٥٨',
    mainText: 'وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لَا يَمُوتُ وَسَبِّحْ بِحَمْدِهِ',
  ),
  _InspiringPreset(
    title: 'ألا بذكر الله',
    badge: 'سورة الرعد — آية ٢٨',
    mainText: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
  ),
  _InspiringPreset(
    title: 'الصلاة على النبي',
    badge: 'كرر تؤجر',
    mainText: 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
  ),
  _InspiringPreset(
    title: 'سيد الاستغفار',
    badge: 'دعاء مأثور',
    mainText:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
  ),
  _InspiringPreset(
    title: 'كنز الجنة',
    badge: 'الباقيات الصالحات',
    mainText: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
  ),
];

/// صانع بطاقات «فَذَكِّرْ» الإسلامية الفاخرة بتصميم منظم وعصري
class AyahStoryMakerScreen extends ConsumerStatefulWidget {
  final int initialAyahId;
  final StoryContent? initialContent;

  const AyahStoryMakerScreen({
    super.key,
    this.initialAyahId = 255,
    this.initialContent,
  });

  @override
  ConsumerState<AyahStoryMakerScreen> createState() => _AyahStoryMakerScreenState();
}

class _AyahStoryMakerScreenState extends ConsumerState<AyahStoryMakerScreen> {
  final GlobalKey _previewKey = GlobalKey();

  late int _selectedAyahId;
  StoryRatio _ratio = StoryRatio.story;
  StoryTab _activeTab = StoryTab.theme;
  String _fontFamily = 'AmiriQuran';
  double _fontSize = 24.0;
  bool _isExporting = false;
  bool _showFrame = true;

  // سمات الألوان الملكية
  List<Color> _gradientColors = const [
    Color(0xFF1B0E06),
    Color(0xFF381F0D),
    Color(0xFF140A04),
  ];

  String? _customMainText;
  String? _customBadgeText;
  String? _customSubText;
  String _topTitle = 'فَذَكِّرْ';
  String _footerText = 'ذكّر غيرك';
  String? _customBgPath;

  static const List<({String name, List<Color> colors})> _kThemes = [
    (
      name: 'العنبر الملكي',
      colors: [Color(0xFF1B0E06), Color(0xFF381F0D), Color(0xFF140A04)],
    ),
    (
      name: 'الزمرد النبوي',
      colors: [Color(0xFF061A10), Color(0xFF0E3823), Color(0xFF05140C)],
    ),
    (
      name: 'الكحلي الفاخر',
      colors: [Color(0xFF081224), Color(0xFF122347), Color(0xFF050B16)],
    ),
    (
      name: 'الأسود المذهب',
      colors: [Color(0xFF111113), Color(0xFF22201C), Color(0xFF0C0C0D)],
    ),
    (
      name: 'عنابي وقار',
      colors: [Color(0xFF1F0814), Color(0xFF3B1228), Color(0xFF16050E)],
    ),
    (
      name: 'تركواز إسلامي',
      colors: [Color(0xFF092227), Color(0xFF11424C), Color(0xFF06181C)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedAyahId = widget.initialAyahId;

    if (widget.initialContent != null) {
      final c = widget.initialContent!;
      _customMainText = c.mainText;
      _customSubText = c.subText.isNotEmpty ? c.subText : null;
      _customBadgeText = c.sourceReference.isNotEmpty ? c.sourceReference : 'كرر تؤجر';
    }
  }

  Future<void> _pickCustomBackground() async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.image);
      final path = picked?.path;
      if (path != null && mounted) {
        setState(() => _customBgPath = path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تطبيق صورتك كخلفية للبطاقة 🖼️✨'),
            backgroundColor: Color(0xFF2E7D32),
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

  Future<Uint8List?> _captureImageBytes() async {
    final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) return;
      final filename = 'fathakkir_${DateTime.now().millisecondsSinceEpoch}.png';
      final res = await savePngToGallery(bytes, displayName: filename);
      if (!mounted) return;

      final message = (res.saved && res.inGallery)
          ? 'تم حفظ البطاقة في ألبوم الصور بجودة فائقة 🖼️✨'
          : 'تم حفظ البطاقة بنجاح';
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
          SnackBar(content: Text('تعذّر حفظ البطاقة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareCard(String textShare) async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) return;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/fathakkir_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: '$textShare\n\n﴿وَذَكِّرْ فَإِنَّ الذِّكْرَىٰ تَنفَعُ الْمُؤْمِنِينَ﴾ — عبر تطبيق هُمَام 🌸',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر مشاركة البطاقة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showTextEditorSheet(String currentMain, String currentBadge) {
    final textCtrl = TextEditingController(text: currentMain);
    final badgeCtrl = TextEditingController(text: currentBadge);
    final titleCtrl = TextEditingController(text: _topTitle);
    final footerCtrl = TextEditingController(text: _footerText);

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تعديل نصوص البطاقة',
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
                controller: textCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, height: 1.5),
                decoration: InputDecoration(
                  labelText: 'النص القرآني أو الدعاء الرئيسي',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: badgeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'الشارة أو المرجع (مثل: سورة الكهف أو كرر تؤجر)',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'الترويسة (فَذَكِّرْ)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: footerCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'التذييل (ذكّر غيرك)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _customMainText = textCtrl.text.trim();
                    _customBadgeText = badgeCtrl.text.trim();
                    _topTitle = titleCtrl.text.trim();
                    _footerText = footerCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ayahAsync = ref.watch(_ayahByIdProvider(_selectedAyahId));

    return ayahAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0F0A06),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0F0A06),
        body: Center(child: Text('تعذّر تحميل الآية: $e', style: const TextStyle(color: Colors.white))),
      ),
      data: (ayah) {
        final surahAsync = ref.watch(_surahByIdProvider(ayah.surah));
        final surahName = surahAsync.value?.nameAr ?? '';

        final defaultMainText = ayah.textUthmani;
        final defaultBadgeText = 'سورة $surahName — آية ${ayah.ayah}';
        final mainText = _customMainText ?? defaultMainText;
        final badgeText = _customBadgeText ?? defaultBadgeText;
        final subText = _customSubText;

        final isStory = _ratio == StoryRatio.story;
        final cardWidth = isStory ? 290.0 : 310.0;
        final cardHeight = isStory ? 510.0 : 330.0;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFF100C08),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                '«فَذَكِّرْ» — صانع البطاقات',
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Color(0xFFE5C378),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // زر التبديل السريع للمقاس ستوري / مربع
                IconButton(
                  icon: Icon(
                    isStory ? Icons.crop_portrait_rounded : Icons.crop_square_rounded,
                    color: const Color(0xFFD4AF37),
                  ),
                  tooltip: isStory ? 'التحويل لمقاس مربع (1:1)' : 'التحويل لمقاس ستوري (9:16)',
                  onPressed: () {
                    setState(() {
                      _ratio = isStory ? StoryRatio.square : StoryRatio.story;
                    });
                  },
                ),
                // زر تعديل النصوص المباشر
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFD4AF37)),
                  tooltip: 'تعديل النصوص',
                  onPressed: () => _showTextEditorSheet(mainText, badgeText),
                ),
              ],
            ),
            body: Column(
              children: [
                // 1. مساحة العرض والمعاينة المباشرة للبطاقة
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: GestureDetector(
                        onTap: () => _showTextEditorSheet(mainText, badgeText),
                        child: RepaintBoundary(
                          key: _previewKey,
                          child: IslamicLuxuryCard(
                            mainText: mainText,
                            badgeText: badgeText,
                            topTitle: _topTitle,
                            footerText: _footerText,
                            gradientColors: _gradientColors,
                            fontSize: _fontSize,
                            width: cardWidth,
                            height: cardHeight,
                            fontFamily: _fontFamily,
                            subText: subText,
                            customImagePath: _customBgPath,
                            showDecorativeFrame: _showFrame,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. الشريط التفاعلي المنظم للتحكم
                _buildControlDock(mainText, badgeText),

                // 3. شريط الحفظ والمشاركة الفوري
                _buildExportBar(mainText),
              ],
            ),
          ),
        );
      },
    );
  }

  /// شريط التحكم المقسم لتبويبات واضحة وأنيقة
  Widget _buildControlDock(String mainText, String badgeText) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16120D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.25))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط اختيار التبويب
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tabButton(StoryTab.theme, Icons.palette_outlined, 'السمات'),
                _tabButton(StoryTab.typography, Icons.text_fields_rounded, 'الخط والتنسيق'),
                _tabButton(StoryTab.content, Icons.auto_stories_outlined, 'نماذج ملهمة'),
                _tabButton(StoryTab.layout, Icons.aspect_ratio_rounded, 'القياس والإطار'),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // محتوى التبويب النشط
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: switch (_activeTab) {
              StoryTab.theme => _buildThemeControls(),
              StoryTab.typography => _buildTypographyControls(mainText, badgeText),
              StoryTab.content => _buildPresetControls(),
              StoryTab.layout => _buildLayoutControls(),
            },
          ),
        ],
      ),
    );
  }

  Widget _tabButton(StoryTab tab, IconData icon, String label) {
    final active = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD4AF37).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFFD4AF37) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? const Color(0xFFD4AF37) : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? const Color(0xFFE5C378) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // دوائر الألوان
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final theme in _kThemes)
                  GestureDetector(
                    onTap: () => setState(() {
                      _customBgPath = null;
                      _gradientColors = theme.colors;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _customBgPath == null && _gradientColors == theme.colors
                              ? const Color(0xFFD4AF37)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [theme.colors.first, theme.colors[1]],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),
        // زر اختيار صورة مخصصة
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
            foregroundColor: const Color(0xFFE5C378),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(
            _customBgPath != null ? Icons.photo_library : Icons.add_photo_alternate_outlined,
            size: 16,
          ),
          label: Text(
            _customBgPath != null ? 'تغيير صورتك' : 'خلفية من جهازي',
            style: const TextStyle(fontSize: 11),
          ),
          onPressed: _pickCustomBackground,
        ),
      ],
    );
  }

  Widget _buildTypographyControls(String mainText, String badgeText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // اختيار نوع الخط
        Row(
          children: [
            _fontChoiceChip('الأميري', 'AmiriQuran'),
            const SizedBox(width: 6),
            _fontChoiceChip('القاهرة', 'Cairo'),
          ],
        ),

        // تكبير وتصغير الخط
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFD4AF37), size: 22),
              tooltip: 'تصغير الخط',
              onPressed: () {
                if (_fontSize > 16) setState(() => _fontSize -= 2);
              },
            ),
            Text(
              '${_fontSize.round()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37), size: 22),
              tooltip: 'تكبير الخط',
              onPressed: () {
                if (_fontSize < 36) setState(() => _fontSize += 2);
              },
            ),
          ],
        ),

        // زر فتح محرر النصوص
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFD4AF37),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: const Icon(Icons.edit, size: 15),
          label: const Text('تحرير النص', style: TextStyle(fontSize: 11.5)),
          onPressed: () => _showTextEditorSheet(mainText, badgeText),
        ),
      ],
    );
  }

  Widget _fontChoiceChip(String label, String family) {
    final selected = _fontFamily == family;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFD4AF37),
      backgroundColor: Colors.white10,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: selected ? Colors.black : Colors.white70,
      ),
      onSelected: (_) => setState(() => _fontFamily = family),
    );
  }

  Widget _buildPresetControls() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final preset in _kPresets)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD4AF37)),
                label: Text(preset.title),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                side: const BorderSide(color: Color(0x55D4AF37)),
                labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _customMainText = preset.mainText;
                    _customBadgeText = preset.badge;
                    _topTitle = preset.topTitle;
                    _footerText = preset.footer;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayoutControls() {
    final isStory = _ratio == StoryRatio.story;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ChoiceChip(
          avatar: Icon(Icons.crop_portrait, size: 16, color: isStory ? Colors.black : Colors.white70),
          label: const Text('ستوري (9:16)'),
          selected: isStory,
          selectedColor: const Color(0xFFD4AF37),
          backgroundColor: Colors.white10,
          labelStyle: TextStyle(
            fontSize: 11,
            color: isStory ? Colors.black : Colors.white70,
          ),
          onSelected: (_) => setState(() => _ratio = StoryRatio.story),
        ),
        ChoiceChip(
          avatar: Icon(Icons.crop_square, size: 16, color: !isStory ? Colors.black : Colors.white70),
          label: const Text('مربع (1:1)'),
          selected: !isStory,
          selectedColor: const Color(0xFFD4AF37),
          backgroundColor: Colors.white10,
          labelStyle: TextStyle(
            fontSize: 11,
            color: !isStory ? Colors.black : Colors.white70,
          ),
          onSelected: (_) => setState(() => _ratio = StoryRatio.square),
        ),
        FilterChip(
          label: const Text('الإطار الزخرفي'),
          selected: _showFrame,
          selectedColor: const Color(0xFFD4AF37),
          backgroundColor: Colors.white10,
          labelStyle: TextStyle(
            fontSize: 11,
            color: _showFrame ? Colors.black : Colors.white70,
          ),
          onSelected: (v) => setState(() => _showFrame = v),
        ),
      ],
    );
  }

  Widget _buildExportBar(String mainText) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF1B0E06),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'حفظ في المعرض',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isExporting ? null : _saveToGallery,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                  foregroundColor: const Color(0xFFE5C378),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text(
                  'مشاركة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _isExporting ? null : () => _shareCard(mainText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
