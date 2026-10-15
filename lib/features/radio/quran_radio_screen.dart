import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../audio/quran_audio_handler.dart';
import 'radio_audio_providers.dart';

/// خيارات مدة مؤقّت النوم
const List<int> _kRadioSleepTimerMinutes = [10, 20, 30, 45, 60, 90];

/// نموذج بيانات محطة إذاعية قرآنية
class QuranRadioStation {
  const QuranRadioStation({
    required this.id,
    required this.name,
    required this.category,
    required this.streamUrl,
    required this.icon,
  });

  final String id;
  final String name;
  final String category; // 'live' | 'reciters' | 'general'
  final String streamUrl;
  final IconData icon;
}

const List<QuranRadioStation> kQuranRadioStations = [
  // 1. العلماء والدعاة والفتاوى
  QuranRadioStation(
    id: 'uthaymeen_fatwa',
    name: 'إذاعة فتاوى الشيخ محمد بن صالح العثيمين رحمه الله',
    category: 'scholars',
    streamUrl: 'https://qurango.net/radio/fatwa',
    icon: Icons.school_outlined,
  ),
  QuranRadioStation(
    id: 'tafsir_scholars',
    name: 'إذاعة تفسير القرآن (تفسير السعدي وابن كثير)',
    category: 'scholars',
    streamUrl: 'https://qurango.net/radio/tafseer',
    icon: Icons.auto_stories_outlined,
  ),

  // 2. أئمة الحرمين الشريفين
  QuranRadioStation(
    id: 'shuraim_radio',
    name: 'إذاعة الشيخ سعود الشريم (إمام الحرم المكي السابق)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/saud_alshuraim',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'muaiqly_radio',
    name: 'إذاعة الشيخ ماهر المعيقلي (إمام الحرم المكي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/maher',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'dossari_radio',
    name: 'إذاعة الشيخ ياسر الدوسري (إمام الحرم المكي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/yasser_aldosari',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'juhaynee_radio',
    name: 'إذاعة الشيخ عبد الله عواد الجهني (إمام الحرم المكي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/abdullah_aljohany',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'balilah_radio',
    name: 'إذاعة الشيخ بندر بليلة (إمام الحرم المكي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/bandar_balilah',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'ali_jaber_radio',
    name: 'إذاعة الشيخ علي عبد الله جابر رحمه الله (إمام الحرم المكي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/ali_jaber',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'hudhaify_radio',
    name: 'إذاعة الشيخ علي الحذيفي (إمام الحرم النبوي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/ali_alhuthaifi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'qasim_radio',
    name: 'إذاعة الشيخ عبد المحسن القاسم (إمام الحرم النبوي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/abdulmohsen_alqasim',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'budair_radio',
    name: 'إذاعة الشيخ صلاح البدير (إمام الحرم النبوي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/salah_albudair',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'ayyoub_radio',
    name: 'إذاعة الشيخ محمد أيوب رحمه الله (إمام الحرم النبوي)',
    category: 'haramain',
    streamUrl: 'https://qurango.net/radio/mohammed_ayyub',
    icon: Icons.record_voice_over_outlined,
  ),

  // 3. كبار القراء ومشاهير التلاوة
  QuranRadioStation(
    id: 'minshawy_mojawwad',
    name: 'إذاعة الشيخ محمد صديق المنشاوي (المجود الخالد)',
    category: 'reciters',
    streamUrl:
        'https://qurango.net/radio/mohammed_siddiq_alminshawi_mojawwad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'minshawy_murattal',
    name: 'إذاعة الشيخ محمد صديق المنشاوي (المرتل)',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/mohammed_siddiq_alminshawi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'husary_murattal',
    name: 'إذاعة الشيخ محمود خليل الحصري (مرتل)',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/mahmoud_khalil_alhussary',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'husary_mojawwad',
    name: 'إذاعة الشيخ محمود خليل الحصري (المجود)',
    category: 'reciters',
    streamUrl:
        'https://qurango.net/radio/mahmoud_khalil_alhussary_mojawwad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'abdulbasit_mojawwad',
    name: 'إذاعة الشيخ عبد الباسط عبد الصمد (المجود)',
    category: 'reciters',
    streamUrl:
        'https://qurango.net/radio/abdulbasit_abdulsamad_mojawwad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'abdulbasit_murattal',
    name: 'إذاعة الشيخ عبد الباسط عبد الصمد (المرتل)',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/abdulbasit_abdulsamad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'mustafa_ismail',
    name: 'إذاعة الشيخ مصطفى إسماعيل (تلاوات نادرة)',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/mustafa_ismail',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'banna_radio',
    name: 'إذاعة الشيخ محمود علي البنا',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/mahmoud_ali__albanna',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'alafasy_radio',
    name: 'إذاعة الشيخ مشاري راشد العفاسي',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/mishary_alafasi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'qatami_radio',
    name: 'إذاعة الشيخ ناصر القطامي',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/nasser_alqatami',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'ajmy_radio',
    name: 'إذاعة الشيخ أحمد بن علي العجمي',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/ahmad_alajmy',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'ghamadi_radio',
    name: 'إذاعة الشيخ سعد الغامدي',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/saad_alghamdi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'fares_abbad',
    name: 'إذاعة الشيخ فارس عباد',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/fares_abbad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'shatri_radio',
    name: 'إذاعة الشيخ أبو بكر الشاطري',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/shaik_abu_bakr_al_shatri',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'abkar_radio',
    name: 'إذاعة الشيخ إدريس أبكر',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/idrees_abkr',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'hazza_radio',
    name: 'إذاعة القارئ هزاع البلوشي',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/hazza_alblushi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'khalid_jileel',
    name: 'إذاعة الشيخ خالد الجليل',
    category: 'reciters',
    streamUrl: 'https://qurango.net/radio/khalid_aljileel',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'wadih_yamani',
    name: 'إذاعة القارئ وديع اليمني',
    category: 'reciters',
    streamUrl: 'https://serverkw.quran-uni.com:8226/;',
    icon: Icons.record_voice_over_outlined,
  ),

  // 4. البث المباشر والإذاعات الرسمية
  QuranRadioStation(
    id: 'saudi_radio',
    name: 'إذاعة القرآن الكريم من المملكة العربية السعودية',
    category: 'live',
    streamUrl: 'https://stream.radiojar.com/0tpy1h0kxtzuv',
    icon: Icons.radio_outlined,
  ),
  QuranRadioStation(
    id: 'cairo_radio',
    name: 'إذاعة القرآن الكريم من القاهرة (مصر)',
    category: 'live',
    streamUrl: 'https://stream.radiojar.com/8s5u5tpdtwzuv',
    icon: Icons.radio_outlined,
  ),

  // 5. تدبر وأذكار ورقيا
  QuranRadioStation(
    id: 'roqiah_radio',
    name: 'إذاعة الرقية الشرعية على مدار 24 ساعة',
    category: 'general',
    streamUrl: 'https://qurango.net/radio/roqiah',
    icon: Icons.healing_outlined,
  ),
  QuranRadioStation(
    id: 'athkar_radio',
    name: 'إذاعة أذكار اليوم والليلة وحصن المسلم',
    category: 'general',
    streamUrl: 'https://qurango.net/radio/athkar_sabah_massa',
    icon: Icons.brightness_2_outlined,
  ),
  QuranRadioStation(
    id: 'tarateel_radio',
    name: 'إذاعة تراتيل قصار السور والتلاوات الهادئة',
    category: 'general',
    streamUrl: 'https://qurango.net/radio/tarateel',
    icon: Icons.music_note_outlined,
  ),

  // 6. السنة والحديث النبوي الشريف
  QuranRadioStation(
    id: 'sunnah_saudi_radio',
    name: 'إذاعة السنة النبوية (السعودية)',
    category: 'sunnah',
    streamUrl: 'https://radiosunna.radioca.st/stream',
    icon: Icons.menu_book_outlined,
  ),
  QuranRadioStation(
    id: 'bukhari_radio',
    name: 'إذاعة صحيح البخاري',
    category: 'sunnah',
    streamUrl: 'https://qurango.net/radio/saheh-bokharee',
    icon: Icons.menu_book_outlined,
  ),
  QuranRadioStation(
    id: 'muslim_radio',
    name: 'إذاعة صحيح مسلم',
    category: 'sunnah',
    streamUrl: 'https://qurango.net/radio/saheh-muslim',
    icon: Icons.menu_book_outlined,
  ),
  QuranRadioStation(
    id: 'riyad_saliheen_radio',
    name: 'إذاعة رياض الصالحين',
    category: 'sunnah',
    streamUrl: 'https://qurango.net/radio/riyad',
    icon: Icons.menu_book_outlined,
  ),
];

/// لون هوية كل تصنيف إذاعة — يُستخدَم بشارة التصنيف داخل كل بطاقة وبأيقونة
/// المحطة، بدل استخدام نفس لون التمييز (`themeAccent`) للجميع (بطلب صاحب
/// المشروع "القوائم كثير بدائية").
Color _categoryColor(String category) => switch (category) {
  'scholars' => AppColors.purple,
  'haramain' => AppColors.goldDeep,
  'reciters' => AppColors.tealDeep,
  'live' => const Color(0xFFE74C3C),
  'general' => const Color(0xFF2E7D32),
  'sunnah' => AppColors.blue,
  _ => AppColors.navy,
};

String _categoryLabel(String category) => switch (category) {
  'scholars' => 'العلماء والفتاوى',
  'haramain' => 'أئمة الحرمين',
  'reciters' => 'مشاهير القراء',
  'live' => 'البث المباشر',
  'general' => 'رقية وتدبر',
  'sunnah' => 'السنة والحديث',
  _ => 'إذاعة',
};

class QuranRadioScreen extends ConsumerStatefulWidget {
  const QuranRadioScreen({super.key, this.isStandalone = true});

  /// إذا كانت الشاشة بمفردها (مع AppBar ومؤقت نوم) أو داخل تبويب مدمج
  final bool isStandalone;

  @override
  ConsumerState<QuranRadioScreen> createState() => _QuranRadioScreenState();
}

class _QuranRadioScreenState extends ConsumerState<QuranRadioScreen> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  Timer? _sleepFireTimer;
  Timer? _sleepTickTimer;
  DateTime? _sleepEndsAt;
  bool _isPlaying = false;
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final Set<String> _favoriteStationIds = {};

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteStationIds.contains(id)) {
        _favoriteStationIds.remove(id);
      } else {
        _favoriteStationIds.add(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // `ref` غير متاح بمُهيِّئ حقل — لازم تُقرأ القيمة من الـprovider هون
    // بـinitState، لا بتعريف الحقل مباشرة (نفس تحفّظ duroos_lectures_screen.dart).
    _player = ref.read(radioAudioPlayerProvider);
    // المشغّل مشترك بعمر التطبيق (راجع radioAudioPlayerProvider) — حالته
    // الحالية قد تعكس محطة بدأت تشغيلها زيارة سابقة لهذه الشاشة واستمرت
    // بالخلفية، لذا نقرأها فوراً بدل انتظار أول حدث بالبث فقط.
    _isPlaying =
        _player.playing && _player.processingState != ProcessingState.completed;
    _isLoading =
        _player.processingState == ProcessingState.loading ||
        _player.processingState == ProcessingState.buffering;
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying =
            state.playing && state.processingState != ProcessingState.completed;
        _isLoading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
    });
  }

  @override
  void dispose() {
    _sleepFireTimer?.cancel();
    _sleepTickTimer?.cancel();
    // لا نتخلّص من `_player` هنا — مشغّل مشترك بعمر التطبيق (راجع
    // radioAudioPlayerProvider) يستمر بالتشغيل بالخلفية حتى لو أُغلقت هذه
    // الشاشة بالذات؛ يُتخلَّص منه مرة واحدة فقط عبر `ref.onDispose` بذاك
    // الـprovider (تفكيك التطبيق نفسه).
    _playerStateSub?.cancel();
    super.dispose();
  }

  void _startSleepTimer(int minutes) {
    _sleepFireTimer?.cancel();
    _sleepTickTimer?.cancel();
    setState(() => _sleepEndsAt = DateTime.now().add(Duration(minutes: minutes)));

    _sleepFireTimer = Timer(Duration(minutes: minutes), () {
      ref.read(radioAudioPlayerProvider).pause();
      if (mounted) setState(() => _sleepEndsAt = null);
    });

    _sleepTickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _cancelSleepTimer() {
    _sleepFireTimer?.cancel();
    _sleepTickTimer?.cancel();
    setState(() => _sleepEndsAt = null);
  }

  void _showSleepTimerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        final onSurface = Theme.of(sheetCtx).colorScheme.onSurface;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bedtime_outlined, color: themeAccent(sheetCtx)),
                    const SizedBox(width: 10),
                    Text(
                      'مؤقّت النوم للإذاعة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'يوقف البث المباشر تلقائياً بعد المدة المحددة لتوفير البطارية والبيانات',
                  style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in _kRadioSleepTimerMinutes)
                      ChoiceChip(
                        label: Text('$m د'),
                        selected: false,
                        onSelected: (_) {
                          _startSleepTimer(m);
                          Navigator.of(sheetCtx).pop();
                        },
                      ),
                  ],
                ),
                if (_sleepEndsAt != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      _cancelSleepTimer();
                      Navigator.of(sheetCtx).pop();
                    },
                    icon: const Icon(Icons.timer_off_outlined, size: 18),
                    label: const Text('إلغاء المؤقّت الحالي'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                      side: const BorderSide(color: Color(0xFFC0392B)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _togglePlay(QuranRadioStation station) async {
    final activeNotifier = ref.read(activeRadioStationProvider.notifier);
    final active = ref.read(activeRadioStationProvider);
    if (active?.id == station.id && _isPlaying) {
      await _player.pause();
      return;
    }

    final isNewStation = active?.id != station.id;
    setState(() => _isLoading = true);
    activeNotifier.set(station);

    // قائمة الروابط المرشحة للبث (الرابط الأساسي السريع + الرابط الاحتياطي التلقائي)
    final candidateUrls = <String>[station.streamUrl];
    if (station.streamUrl.contains('qurango.net/radio/')) {
      if (station.streamUrl.contains('backup.qurango.net')) {
        candidateUrls.add(station.streamUrl.replaceAll('backup.qurango.net', 'qurango.net'));
      } else {
        candidateUrls.add(station.streamUrl.replaceAll('https://qurango.net', 'https://backup.qurango.net'));
      }
    } else if (station.id == 'uthaymeen_fatwa') {
      candidateUrls.add('https://backup.qurango.net/radio/fatwa');
    }

    for (final url in candidateUrls) {
      // المستخدم بدّل لمحطة ثانية أثناء المحاولة — توقّف فوراً
      if (ref.read(activeRadioStationProvider)?.id != station.id) return;

      try {
        if (isNewStation) {
          await _player.setUrl(url);
        }
        await _player.play();
        if (isNewStation && mounted) {
          ref.read(quranAudioHandlerProvider).attachExternalSession(
            _player,
            MediaItem(
              id: 'radio-${station.id}',
              title: station.name,
              artist: 'إذاعات القرآن والعلماء وبث الحرمين',
              duration: _player.duration,
            ),
          );
        }
        return; // نجح التشغيل بنجاح وفوراً
      } catch (e) {
        debugPrint('Radio play failed for $url: $e');
        // انتقال مباشر وفوري للرابط البديل دون تجميد أو تأخير ثانيتين
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تعذّر تشغيل الإذاعة: يرجى التحقق من اتصال الإنترنت',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // حالة مشتركة بين الشاشة وأي منطق آخر (إشعار النظام) — راجع
    // radio_audio_providers.dart.
    final activeStation = ref.watch(activeRadioStationProvider);

    final filtered = kQuranRadioStations.where((s) {
      final matchesCat = _selectedCategory == 'all'
          ? true
          : _selectedCategory == 'favorites'
              ? _favoriteStationIds.contains(s.id)
              : s.category == _selectedCategory;
      final matchesQuery =
          _searchQuery.isEmpty || s.name.contains(_searchQuery.trim());
      return matchesCat && matchesQuery;
    }).toList();

    final remaining = _sleepEndsAt?.difference(DateTime.now());
    final remainingMinutes = remaining == null
        ? null
        : (remaining.inSeconds / 60).ceil().clamp(0, 999);

    final content = Column(
      children: [
        // 1. البطاقة التفاعلية العلوية (Hero Banner)
        if (activeStation != null)
          // بطاقة المحطة النشطة قيد الاستماع حالياً مع موجات صوتية حية
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [const Color(0xFF132A25), const Color(0xFF0F1E2E)]
                    : [const Color(0xFF0D473B), const Color(0xFF0B2545)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF0D473B)).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF5252),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isPlaying ? 'بث مباشر الآن' : 'البث متوقف مؤقتاً',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (remainingMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsetsDirectional.only(end: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bedtime, size: 12, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              '$remainingMinutes د',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'إيقاف وإغلاق البث',
                      onPressed: () {
                        _player.stop();
                        ref.read(quranAudioHandlerProvider).detachExternalSession();
                        ref.read(activeRadioStationProvider.notifier).set(null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Icon(activeStation.icon, color: AppColors.gold, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeStation.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _categoryLabel(activeStation.category),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // زر التشغيل الفخم الكبير
                    Material(
                      color: AppColors.gold,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _togglePlay(activeStation),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.black87,
                                  ),
                                )
                              : Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 26,
                                  color: Colors.black87,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isPlaying) ...[
                  const SizedBox(height: 10),
                  _HeroEqualizerVisualizer(color: AppColors.gold.withValues(alpha: 0.85)),
                ],
              ],
            ),
          )
        else
          // بطاقة التعريف الفخمة عند عدم تشغيل أي إذاعة مع خيار التشغيل السريع
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [const Color(0xFF1A2634), const Color(0xFF0F172A)]
                    : [AppColors.navy.withValues(alpha: 0.08), AppColors.tealDeep.withValues(alpha: 0.08)],
              ),
              border: Border.all(
                color: (isDark ? AppColors.lineDark : AppColors.tealDeep.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.tealDeep, AppColors.navy],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tealDeep.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.radio_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2ECC71),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'إذاعات القرآن الكريم المباشرة',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'أكثر من 30 إذاعة وبث حي من الحرمين الشريفين وكبار القراء',
                        style: TextStyle(
                          fontSize: 11,
                          color: onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: themeAccent(context).withValues(alpha: 0.15),
                    foregroundColor: themeAccent(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // تشغيل فوري لإذاعة السعودية الرسمية كإذاعة افتراضية
                    final defaultStation = kQuranRadioStations.firstWhere(
                      (s) => s.id == 'saudi_radio',
                      orElse: () => kQuranRadioStations.first,
                    );
                    _togglePlay(defaultStation);
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('تشغيل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

        // 2. شريط المفضلة السريع إن وجد
        if (_favoriteStationIds.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, size: 15, color: Color(0xFFE91E63)),
                const SizedBox(width: 6),
                Text(
                  'محطاتي المفضلة (${_favoriteStationIds.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: kQuranRadioStations.where((s) => _favoriteStationIds.contains(s.id)).length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final favStation = kQuranRadioStations.where((s) => _favoriteStationIds.contains(s.id)).toList()[i];
                final isCurrent = activeStation?.id == favStation.id;
                return Material(
                  color: isCurrent
                      ? themeAccent(context).withValues(alpha: 0.18)
                      : (isDark ? const Color(0xFF1E2836) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _togglePlay(favStation),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent ? themeAccent(context) : (isDark ? AppColors.lineDark : AppColors.line),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCurrent && _isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_fill_rounded,
                            size: 18,
                            color: isCurrent ? themeAccent(context) : const Color(0xFFE91E63),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              favStation.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                color: isCurrent ? themeAccent(context) : onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // 3. شريط البحث المنظّم
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: TextField(
            onChanged: (q) => setState(() => _searchQuery = q),
            decoration: InputDecoration(
              hintText: 'ابحث عن إذاعة، شيخ، بث مباشر، فتاوى...',
              hintStyle: TextStyle(fontSize: 12.5, color: onSurface.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // 4. تصنيفات الإذاعات بأيقونات واضحة
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _CategoryChip(
                label: 'الكل (${kQuranRadioStations.length})',
                icon: Icons.all_inclusive_rounded,
                color: AppColors.navy,
                isSelected: _selectedCategory == 'all',
                onTap: () => setState(() => _selectedCategory = 'all'),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: 'المفضلة ❤️ (${_favoriteStationIds.length})',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFE91E63),
                isSelected: _selectedCategory == 'favorites',
                onTap: () => setState(() => _selectedCategory = 'favorites'),
              ),
              for (final cat in [
                'haramain',
                'live',
                'reciters',
                'scholars',
                'sunnah',
                'general',
              ]) ...[
                const SizedBox(width: 8),
                _CategoryChip(
                  label: _categoryLabel(cat),
                  icon: switch (cat) {
                    'haramain' => Icons.mosque_rounded,
                    'live' => Icons.podcasts_rounded,
                    'reciters' => Icons.record_voice_over_rounded,
                    'scholars' => Icons.school_rounded,
                    'sunnah' => Icons.menu_book_rounded,
                    _ => Icons.spa_rounded,
                  },
                  color: _categoryColor(cat),
                  isSelected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 5. قائمة الإذاعات بتصميم بطاقات فخم وعصري
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.radio_outlined,
                  message: 'لا توجد إذاعة مطابقة للبحث أو التصنيف',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    6,
                    16,
                    activeStation != null ? 95 : 20,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final station = filtered[index];
                    final isActive = activeStation?.id == station.id;
                    final catColor = _categoryColor(station.category);

                    return Material(
                      color: isActive
                          ? catColor.withValues(alpha: isDark ? 0.18 : 0.08)
                          : (isDark ? const Color(0xFF1B2430) : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _togglePlay(station),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isActive
                                  ? catColor.withValues(alpha: 0.6)
                                  : (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
                              width: isActive ? 1.6 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? Colors.black : catColor).withValues(
                                  alpha: isDark ? 0.25 : 0.04,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // أيقونة المحطة الدائرية الفخمة
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isActive
                                        ? [catColor, catColor.withValues(alpha: 0.75)]
                                        : [
                                            catColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                            catColor.withValues(alpha: isDark ? 0.12 : 0.05),
                                          ],
                                  ),
                                ),
                                child: Icon(
                                  station.icon,
                                  color: isActive ? Colors.white : catColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      station.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 13.5,
                                        height: 1.25,
                                        color: isActive ? catColor : onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _categoryLabel(station.category),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: catColor,
                                            ),
                                          ),
                                        ),
                                        if (isActive) ...[
                                          const SizedBox(width: 8),
                                          Row(
                                            children: [
                                              _MiniSoundWave(color: catColor),
                                              const SizedBox(width: 5),
                                              Text(
                                                _isPlaying ? 'بث حي' : 'متوقف',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: catColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _favoriteStationIds.contains(station.id)
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: _favoriteStationIds.contains(station.id)
                                      ? const Color(0xFFE91E63)
                                      : Colors.grey.withValues(alpha: 0.6),
                                ),
                                tooltip: _favoriteStationIds.contains(station.id)
                                    ? 'إزالة من المفضلة'
                                    : 'إضافة للمفضلة',
                                onPressed: () => _toggleFavorite(station.id),
                              ),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: isActive ? catColor : null,
                                  foregroundColor: isActive ? Colors.white : null,
                                ),
                                icon: isActive && _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        isActive && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        size: 24,
                                      ),
                                onPressed: () => _togglePlay(station),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    return Scaffold(
      appBar: widget.isStandalone
          ? GradientAppBar(
              title: 'إذاعات القرآن والبث المباشر',
              colors: const [AppColors.tealDeep, AppColors.navy],
              actions: [
                IconButton(
                  tooltip: 'مؤقّت النوم',
                  onPressed: _showSleepTimerSheet,
                  icon: remainingMinutes == null
                      ? const Icon(Icons.bedtime_outlined)
                      : Badge(
                          label: Text('$remainingMinutes'),
                          backgroundColor: AppColors.gold,
                          child: const Icon(Icons.bedtime),
                        ),
                ),
              ],
            )
          : null,
      body: content,

      // المشغل السفلي العائم الراقي (Floating Dock)
      bottomSheet: activeStation == null
          ? null
          : Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141E28) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: (isDark ? AppColors.lineDark : AppColors.gold.withValues(alpha: 0.35)),
                  width: 1.2,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'إغلاق',
                      onPressed: () {
                        _player.stop();
                        ref.read(quranAudioHandlerProvider).detachExternalSession();
                        ref.read(activeRadioStationProvider.notifier).set(null);
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeStation.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                _isPlaying ? 'بث مباشر 🔴' : 'متوقف',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _isPlaying ? Colors.redAccent : Colors.grey,
                                ),
                              ),
                              if (_isPlaying) ...[
                                const SizedBox(width: 8),
                                _MiniSoundWave(color: themeAccent(context)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: themeAccent(context),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                      onPressed: () => _togglePlay(activeStation),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            )
          : (isSelected
              ? null
              : CircleAvatar(backgroundColor: color, radius: 4)),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: color,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : null,
      ),
      side: BorderSide(color: color.withValues(alpha: isSelected ? 1 : 0.4)),
      onSelected: (_) => onTap(),
    );
  }
}

class _MiniSoundWave extends StatefulWidget {
  const _MiniSoundWave({required this.color});
  final Color color;

  @override
  State<_MiniSoundWave> createState() => _MiniSoundWaveState();
}

class _MiniSoundWaveState extends State<_MiniSoundWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final v = _anim.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(5 + v * 9),
            const SizedBox(width: 2.2),
            _bar(13 - v * 8),
            const SizedBox(width: 2.2),
            _bar(7 + v * 7),
            const SizedBox(width: 2.2),
            _bar(4 + (1 - v) * 10),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2.6,
      height: height.clamp(4.0, 16.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// عارض موجات صوتية حي ومتجاوب لبطاقة المشغل العلوية
class _HeroEqualizerVisualizer extends StatefulWidget {
  const _HeroEqualizerVisualizer({required this.color});
  final Color color;

  @override
  State<_HeroEqualizerVisualizer> createState() => _HeroEqualizerVisualizerState();
}

class _HeroEqualizerVisualizerState extends State<_HeroEqualizerVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final v = _anim.value;
        return SizedBox(
          height: 22,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(6 + v * 12),
              const SizedBox(width: 3.5),
              _bar(18 - v * 11),
              const SizedBox(width: 3.5),
              _bar(9 + (1 - v) * 10),
              const SizedBox(width: 3.5),
              _bar(20 * v),
              const SizedBox(width: 3.5),
              _bar(7 + v * 13),
              const SizedBox(width: 3.5),
              _bar(16 - v * 8),
              const SizedBox(width: 3.5),
              _bar(5 + (1 - v) * 12),
              const SizedBox(width: 3.5),
              _bar(12 + v * 7),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3.5,
      height: height.clamp(4.0, 22.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
