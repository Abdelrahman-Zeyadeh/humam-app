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
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../models/story_content.dart';
import '../models/story_theme.dart';
import 'widgets/ayah_end_circle.dart';
import 'widgets/story_panel_controls.dart';

enum StoryRatio { story, square, banner }

class AyahStoryMakerScreen extends ConsumerStatefulWidget {
  final int initialAyahId;
  final StoryContent? initialContent;

  const AyahStoryMakerScreen({
    super.key,
    this.initialAyahId = 255, // آية الكرسي افتراضياً
    this.initialContent,
  });

  @override
  ConsumerState<AyahStoryMakerScreen> createState() => _AyahStoryMakerScreenState();
}

class _AyahStoryMakerScreenState extends ConsumerState<AyahStoryMakerScreen> {
  final GlobalKey _previewKey = GlobalKey();

  late int _selectedAyahId;
  // نطاق آيات اختياري ("من — إلى") — null يعني آية واحدة فقط
  // (`_selectedAyahId`). لو محدَّد، يمثّل معرّف صف آخر آية بالنطاق (شامل)،
  // وتُجلَب كل الآيات بينهما عبر `ayahsInIdRange`.
  int? _selectedAyahIdTo;
  StoryTheme _selectedTheme = StoryTheme.presets.first;
  StoryRatio _selectedRatio = StoryRatio.story;
  String? _customImagePath;
  double _overlayOpacity = 0.55;
  double _fontSize = 22.0;
  bool _isMushafMode = false;
  bool _showBasmalah = false;
  bool _showTafsir = false;
  String _selectedTafsirEdition = 'muyassar';
  bool _showReference = true;
  bool _showBranding = true;
  bool _isExporting = false;

  String _tafsirName(String key) {
    switch (key) {
      case 'muyassar':
        return 'الميسر';
      case 'saadi':
        return 'السعدي';
      case 'jalalayn':
        return 'الجلالين';
      case 'mukhtasar':
        return 'المختصر';
      default:
        return 'الميسر';
    }
  }

  void _showTafsirEditionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختر كتاب التفسير',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final entry in [
              ('muyassar', 'التفسير الميسر', 'موجز وواضح ومناسب للبطاقات'),
              ('saadi', 'تفسير السعدي', 'إيماني وتربوي رائع'),
              ('jalalayn', 'تفسير الجلالين', 'مختصر لغوي دقيق'),
              ('mukhtasar', 'المختصر في التفسير', 'مركّز وسلس العبارة'),
            ])
              ListTile(
                title: Text(entry.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(entry.$3, style: const TextStyle(fontSize: 11)),
                selected: _selectedTafsirEdition == entry.$1,
                trailing: _selectedTafsirEdition == entry.$1
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.goldDeep)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTafsirEdition = entry.$1;
                    _showTafsir = true;
                  });
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedAyahId = widget.initialAyahId;
  }

  Future<void> _pickCustomImage() async {
    try {
      final res = await FilePicker.pickFile(type: FileType.image);
      if (res != null && res.path != null) {
        setState(() {
          _customImagePath = res.path;
          _isMushafMode = false;
        });
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
    final image = await boundary.toImage(pixelRatio: 4.5); // دقة فائقة UHD 4.5x
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _exportAndShare(List<Ayah> ayahs, Surah surah) async {
    setState(() => _isExporting = true);
    try {
      final buffer = await _captureImageBytes();
      if (buffer == null) return;

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/humam_ayah_story_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      final versesText = ayahs.map((a) => a.textUthmani).join(' ');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: '﴿$versesText﴾\n${surah.nameAr} — ${_referenceSuffix(ayahs)}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر تصدير الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) return;

      final filename = 'humam_story_${_selectedAyahId}_${DateTime.now().millisecondsSinceEpoch}.png';
      // الحفظ عبر MediaStore (أندرويد 10+) بدل كتابة مسار صريح كان يفشل
      // بالتخزين المقصّى Scoped Storage. النتيجة تعكس أين حُفظت فعلاً.
      final res = await savePngToGallery(bytes, displayName: filename);
      if (!mounted) return;

      final String message;
      final Color? backgroundColor;
      if (res.saved && res.inGallery) {
        message = 'تم حفظ الصورة بنجاح في مجلد الصور (Pictures/Humam) 📷✨';
        backgroundColor = const Color(0xFF2E7D32);
      } else if (res.saved) {
        message = 'حُفظت الصورة بمجلد خاص بالتطبيق (هذا الجهاز يمنع الكتابة المباشرة للمعرض)';
        backgroundColor = const Color(0xFFF57C00);
      } else {
        message = 'تعذّر حفظ الصورة على هذا الجهاز — شاركها من زر المشاركة بدلاً من ذلك';
        backgroundColor = const Color(0xFFB3261E);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر حفظ الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// الآية المختارة، أو نطاق الآيات كاملاً لو حُدِّد طرف "إلى".
  Future<List<Ayah>> _fetchSelectedAyahs() {
    final repo = ref.read(quranRepositoryProvider);
    final toId = _selectedAyahIdTo;
    if (toId == null || toId == _selectedAyahId) {
      return repo.ayahById(_selectedAyahId).then((a) => [a]);
    }
    return repo.ayahsInIdRange(_selectedAyahId, toId);
  }

  void _showAyahPicker(BuildContext context) {
    final surahsAsync = ref.read(allSurahsProvider);
    surahsAsync.whenData((surahs) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر سورة وآية لتصميمها',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: surahs.length,
                  itemBuilder: (ctx, i) {
                    final s = surahs[i];
                    return ListTile(
                      title: Text(s.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${s.ayahCount} آية • ${s.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final ayahs = await ref.read(quranRepositoryProvider).ayahsForSurah(s.id);
                        if (!context.mounted || ayahs.isEmpty) return;
                        _showAyahNumberPicker(context, s, ayahs);
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

  /// اختيار آية واحدة، أو نطاق آيات ("من — إلى") ضمن نفس السورة — تبديل
  /// عبر `SegmentedButton` أعلى اللوح، والنطاق يُطبَّق بزر صريح بدل تحديد
  /// تلقائي عند كل تغيير (يمنع رجفة الشاشة أثناء تجربة الأطراف).
  void _showAyahNumberPicker(BuildContext context, Surah surah, List<Ayah> ayahs) {
    var fromIndex = ayahs.indexWhere((a) => a.id == _selectedAyahId);
    if (fromIndex < 0) fromIndex = 0;
    final toId = _selectedAyahIdTo;
    var toIndex = toId == null ? fromIndex : ayahs.indexWhere((a) => a.id == toId);
    if (toIndex < fromIndex) toIndex = fromIndex;
    var isRangeMode = toId != null && toIndex != fromIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اختر آية من ${surah.nameAr}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('آية واحدة')),
                      ButtonSegment(value: true, label: Text('نطاق (من — إلى)')),
                    ],
                    selected: {isRangeMode},
                    onSelectionChanged: (set) => setSheetState(() => isRangeMode = set.first),
                    style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (isRangeMode) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AyahNumberDropdown(
                          label: 'من الآية',
                          ayahs: ayahs,
                          value: fromIndex,
                          onChanged: (v) => setSheetState(() {
                            fromIndex = v;
                            if (toIndex < fromIndex) toIndex = fromIndex;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AyahNumberDropdown(
                          label: 'إلى الآية',
                          ayahs: ayahs,
                          value: toIndex,
                          minIndex: fromIndex,
                          onChanged: (v) => setSheetState(() => toIndex = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppPrimaryButton(
                    label: 'تطبيق',
                    expanded: true,
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedAyahId = ayahs[fromIndex].id;
                        _selectedAyahIdTo = fromIndex == toIndex ? null : ayahs[toIndex].id;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: ayahs.length,
                    itemBuilder: (ctx, i) {
                      final a = ayahs[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: themeAccent(context).withValues(alpha: 0.15),
                          child: Text('${a.ayah}', style: TextStyle(color: themeAccent(context), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          a.textUthmani,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedAyahId = a.id;
                            _selectedAyahIdTo = null;
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ayahsFuture = _fetchSelectedAyahs();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('استوديو بطاقات الآيات 🎨'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'تغيير الآية',
            onPressed: () => _showAyahPicker(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Ayah>>(
        future: ayahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('تعذّر تحميل الآية: ${snapshot.error}'));
          }

          final ayahs = snapshot.data!;
          return FutureBuilder<Surah?>(
            future: ref.read(quranRepositoryProvider).surahById(ayahs.first.surah),
            builder: (context, surahSnap) {
              final surah = surahSnap.data ??
                  const Surah(
                    id: 1,
                    nameAr: 'سورة',
                    nameEn: 'Surah',
                    nameArPlain: 'سورة',
                    revelationPlace: 'makkah',
                    ayahCount: 7,
                    startPage: 1,
                    bismillahPre: 1,
                  );

              return Column(
                children: [
                  // معاينة البطاقة / الستوري
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: _buildCardPreview(ayahs, surah),
                      ),
                    ),
                  ),

                  // شريط التحكم بالخيارات
                  _buildControlsPanel(context, ayahs, surah, isDark),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// "آية ٢٥٥" لآية واحدة، أو "الآيات ٢٥٥-٢٦٠" لنطاق مختار — بلا اسم سورة.
  String _referenceSuffix(List<Ayah> ayahs) {
    final first = ayahs.first;
    final last = ayahs.last;
    return first.id == last.id ? 'آية ${first.ayah}' : 'الآيات ${first.ayah}-${last.ayah}';
  }

  /// نص شارة المصدر — "سورة • آية ٢٥٥" لآية واحدة، أو "سورة • الآيات ٢٥٥-٢٦٠"
  /// لنطاق مختار.
  String _referenceLabel(List<Ayah> ayahs, Surah surah) => '${surah.nameAr} • ${_referenceSuffix(ayahs)}';

  /// بناء محتوى نص الآية (أو نطاق الآيات) مع علامة نهاية كل آية الدائرية.
  List<InlineSpan> _ayahRichSpans(List<Ayah> ayahs, {required double markerSize}) {
    final spans = <InlineSpan>[];
    for (final a in ayahs) {
      spans.add(TextSpan(text: '${a.textUthmani} '));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: AyahEndCircle(
          ayahId: a.id,
          ayahNumber: a.ayah,
          pageNumber: a.page,
          size: markerSize,
        ),
      ));
      if (a.id != ayahs.last.id) spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }

  Widget _buildCardPreview(List<Ayah> ayahs, Surah surah) {
    final isStory = _selectedRatio == StoryRatio.story;
    final double width;
    final double height;
    switch (_selectedRatio) {
      case StoryRatio.story:
        width = 280.0;
        height = 490.0;
        break;
      case StoryRatio.square:
        width = 310.0;
        height = 310.0;
        break;
      case StoryRatio.banner:
        width = 330.0;
        height = 190.0;
        break;
    }

    if (_isMushafMode) {
      return _buildMushafStylePreview(ayahs, surah, width, height, isStory);
    }

    return RepaintBoundary(
      key: _previewKey,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: _customImagePath == null
              ? LinearGradient(
                  colors: _selectedTheme.backgroundColors,
                  begin: _selectedTheme.beginAlignment,
                  end: _selectedTheme.endAlignment,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // إذا اختار صورة خاصة من المعرض
            if (_customImagePath != null) ...[
              Positioned.fill(
                child: Image.file(
                  File(_customImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: _overlayOpacity),
                ),
              ),
            ],

            // إطار زخرفي هادئ
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _customImagePath != null ? Colors.white24 : _selectedTheme.frameColor,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // محتوى الآية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // رأس البطاقة (البسملة أو شارة السورة)
                  Column(
                    children: [
                      if (_showBasmalah) ...[
                        Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 16,
                            color: (_customImagePath != null ? Colors.white : _selectedTheme.textColor)
                                .withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_showReference)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _customImagePath != null
                                ? Colors.black45
                                : _selectedTheme.badgeBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _customImagePath != null
                                  ? AppColors.gold.withValues(alpha: 0.4)
                                  : _selectedTheme.accentColor.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            _referenceLabel(ayahs, surah),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _customImagePath != null
                                  ? const Color(0xFFFFE082)
                                  : _selectedTheme.badgeTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // نص الآية الكريمة مع علامة نهاية الآية الدائرية
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text.rich(
                          TextSpan(
                            children: _ayahRichSpans(ayahs, markerSize: 24),
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: _fontSize,
                            height: 2.3,
                            leadingDistribution: TextLeadingDistribution.even,
                            color: _customImagePath != null ? Colors.white : _selectedTheme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // أسفل البطاقة: التفسير أو التوقيع
                  Column(
                    children: [
                      if (_showTafsir) ...[
                        FutureBuilder<Tafsir?>(
                          future: ref.read(quranRepositoryProvider).tafsirForAyah(ayahs.first.id, edition: _selectedTafsirEdition),
                          builder: (context, snap) {
                            final tafsirText = snap.data?.content ?? '';
                            if (tafsirText.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'تفسير الآية (${_tafsirName(_selectedTafsirEdition)})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: (_customImagePath != null ? Colors.white70 : _selectedTheme.textColor).withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _customImagePath != null ? Colors.black45 : _selectedTheme.badgeBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tafsirText,
                                maxLines: isStory ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.4,
                                  color: (_customImagePath != null
                                          ? Colors.white
                                          : _selectedTheme.textColor)
                                      .withValues(alpha: 0.88),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      if (_showBranding)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 10,
                              color: _customImagePath != null
                                  ? AppColors.gold
                                  : _selectedTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                              Text(
                                'تطبيق هُمَام',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (_customImagePath != null
                                          ? Colors.white
                                          : _selectedTheme.textColor)
                                      .withValues(alpha: 0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

  String _cleanSurahName(Surah surah) {
    return surah.nameAr.replaceFirst('سورة ', '').replaceFirst('سُورَةُ ', '').trim();
  }

  /// مظهر المصحف الشريف الأصيل (إطار سورة مزخرف وترقيم مصحفي)
  Widget _buildMushafStylePreview(List<Ayah> ayahs, Surah surah, double width, double height, bool isStory) {
    final cleanName = _cleanSurahName(surah);
    final firstAyah = ayahs.first;
    final lastAyah = ayahs.last;

    return RepaintBoundary(
      key: _previewKey,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4EA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC5A059), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 1.2),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // لافتة اسم السورة المزخرفة (مطابقة لترويسة المصحف)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE3D0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF8D7344), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'آيَاتُهَا ${_toArabicDigits(surah.ayahCount)}',
                        style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                      ),
                      Text(
                        'سُورَةُ $cleanName',
                        style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2416),
                        ),
                      ),
                      Text(
                        surah.revelationPlace == 'makkah' ? 'مَكِّيَّة' : 'مَدَنِيَّة',
                        style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // البسملة الشريفة
                if (_showBasmalah || firstAyah.ayah == 1)
                  const Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 15,
                      color: Color(0xFF4A3B2C),
                    ),
                  ),

                // نص الآية مع علامة نهاية الآية الدائرية المطابقة للمصحف
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text.rich(
                        TextSpan(
                          children: _ayahRichSpans(ayahs, markerSize: 26),
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
                    ),
                  ),
                ),

                // أسفل صفحة المصحف
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تطبيق هُمَام',
                      style: TextStyle(fontSize: 9.5, color: Color(0xFF8D7344), fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8DECA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'الجزء ${lastAyah.juz} • الحزب ${lastAyah.hizb}',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF5D4037), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _toArabicDigits(int num) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

  Widget _buildControlsPanel(BuildContext context, List<Ayah> ayahs, Surah surah, bool isDark) {
    final accent = themeAccent(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B232E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الآية المختارة — عرض مباشر + اختصار لتغييرها (نفس شاشة
            // "من — إلى" بزر شريط العنوان)، بدل الاكتفاء بأيقونة AppBar
            // بعيدة عن بقية عناصر التحكم.
            PanelLabel('الآية المختارة'),
            InkWell(
              onTap: () => _showAyahPicker(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _referenceLabel(ayahs, surah),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('تغيير', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: accent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // النمط (بطاقة فنية / مظهر المصحف) والمقاس — صفّان منفصلان
            // بعرض كامل كل واحد (كانا يتشاركان صفاً واحداً بـ`Expanded` +
            // زر مقاس بعرضه الذاتي، فيضغط زر النمط الطويل النص لعرض ضيّق
            // جداً ويتكسّر شكله لدائرة متراكبة بشاشات عادية — شكوى صريحة
            // "شكله عجقة").
            PanelLabel('النمط'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('بطاقة فنية 🎨')),
                  ButtonSegment(value: true, label: Text('مظهر المصحف 📖')),
                ],
                selected: {_isMushafMode},
                onSelectionChanged: (set) => setState(() {
                  _isMushafMode = set.first;
                  if (_isMushafMode) _customImagePath = null;
                }),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 10),
            PanelLabel('المقاس'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<StoryRatio>(
                segments: const [
                  ButtonSegment(value: StoryRatio.story, label: Text('9:16')),
                  ButtonSegment(value: StoryRatio.square, label: Text('1:1')),
                  ButtonSegment(value: StoryRatio.banner, label: Text('16:9')),
                ],
                selected: {_selectedRatio},
                onSelectionChanged: (set) => setState(() => _selectedRatio = set.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // شريط اختيار الثيمات والصورة المخصصة (إذا لم يكن في وضع المصحف)
            if (!_isMushafMode) ...[
              PanelLabel('الخلفية'),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // زر اختيار صورة من المعرض
                    InkWell(
                      onTap: _pickCustomImage,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        margin: const EdgeInsets.only(left: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _customImagePath != null ? accent.withValues(alpha: 0.2) : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _customImagePath != null ? accent : Colors.grey.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 16, color: _customImagePath != null ? accent : null),
                            const SizedBox(width: 5),
                            Text(
                              _customImagePath != null ? 'تغيير صورتي' : 'صورة من المعرض',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _customImagePath != null ? accent : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    for (final t in StoryTheme.presets) ...[
                      InkWell(
                        onTap: () => setState(() {
                          _selectedTheme = t;
                          _customImagePath = null;
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          margin: const EdgeInsets.only(left: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: t.backgroundColors),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (_selectedTheme.id == t.id && _customImagePath == null) ? accent : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            t.name,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: (_selectedTheme.id == t.id && _customImagePath == null) ? FontWeight.bold : FontWeight.w600,
                              color: t.textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // خيارات الصورة الخاصة إن وُجدت
            if (_customImagePath != null) ...[
              Row(
                children: [
                  const Icon(Icons.brightness_6_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('تعتيم الصورة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Slider(
                      value: _overlayOpacity,
                      min: 0.15,
                      max: 0.85,
                      divisions: 7,
                      label: '${(_overlayOpacity * 100).round()}%',
                      activeColor: accent,
                      onChanged: (val) => setState(() => _overlayOpacity = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // حجم الخط — صف مستقل بعرض كامل (كان يتشارك الصف مع ٤ شرائح
            // فلتر معاً، بلا التفاف، فيضغط على بعضه بشاشات ضيّقة)
            PanelLabel('حجم الخط'),
            Row(
              children: [
                const Icon(Icons.format_size, size: 16),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 16.0,
                    max: 32.0,
                    divisions: 8,
                    label: '${_fontSize.round()}',
                    activeColor: accent,
                    onChanged: (val) => setState(() => _fontSize = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // عناصر إضافية — شرائح قابلة للالتفاف (`Wrap` بدل `Row`) عشان
            // ما تنضغط ببعضها بشاشات ضيّقة
            PanelLabel('عناصر إضافية'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                FilterChip(
                  label: const Text('البسملة', style: TextStyle(fontSize: 11)),
                  selected: _showBasmalah,
                  onSelected: (val) => setState(() => _showBasmalah = val),
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: Text(_showTafsir ? 'تفسير ${_tafsirName(_selectedTafsirEdition)}' : 'التفسير', style: const TextStyle(fontSize: 11)),
                  selected: _showTafsir,
                  onSelected: (val) {
                    if (_showTafsir) {
                      _showTafsirEditionPicker(context);
                    } else {
                      setState(() => _showTafsir = true);
                    }
                  },
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: const Text('المصدر', style: TextStyle(fontSize: 11)),
                  selected: _showReference,
                  onSelected: (val) => setState(() => _showReference = val),
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: const Text('الشعار', style: TextStyle(fontSize: 11)),
                  selected: _showBranding,
                  onSelected: (val) => setState(() => _showBranding = val),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            const SizedBox(height: 10),

            // أزرار التصدير والمشاركة والحفظ
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('حفظ بالصور', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    onPressed: _isExporting ? null : _saveToGallery,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: AppPrimaryButton(
                    label: _isExporting ? 'جارٍ التصدير...' : 'مشاركة الستوري 🚀',
                    icon: Icons.share_rounded,
                    color: accent,
                    loading: _isExporting,
                    onPressed: _isExporting ? null : () => _exportAndShare(ayahs, surah),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// راجع lib/features/story_maker/ui/widgets/story_panel_controls.dart
// (PanelLabel، AyahNumberDropdown) وwidgets/ayah_end_circle.dart
// (AyahEndCircle والرسّام الزخرفي) — استُخرجت من هون أثناء تفكيك الملف
// بلا أي تغيير سلوكي.
