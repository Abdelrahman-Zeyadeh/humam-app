import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_colors.dart';
import '../audio/quran_audio_handler.dart';
import 'radio_audio_providers.dart';

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
    streamUrl: 'https://serverkw.quran-uni.com:8254/;',
    icon: Icons.school_outlined,
  ),
  QuranRadioStation(
    id: 'tafsir_scholars',
    name: 'إذاعة تفسير القرآن (تفسير السعدي وابن كثير)',
    category: 'scholars',
    streamUrl: 'https://backup.qurango.net/radio/tafseer',
    icon: Icons.auto_stories_outlined,
  ),

  // 2. أئمة الحرمين الشريفين
  QuranRadioStation(
    id: 'shuraim_radio',
    name: 'إذاعة الشيخ سعود الشريم (إمام الحرم المكي السابق)',
    category: 'haramain',
    streamUrl: 'https://backup.qurango.net/radio/saud_alshuraim',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'muaiqly_radio',
    name: 'إذاعة الشيخ ماهر المعيقلي (إمام الحرم المكي)',
    category: 'haramain',
    streamUrl: 'https://backup.qurango.net/radio/maher',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'dossari_radio',
    name: 'إذاعة الشيخ ياسر الدوسري (إمام الحرم المكي)',
    category: 'haramain',
    streamUrl: 'https://backup.qurango.net/radio/yasser_aldosari',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'juhaynee_radio',
    name: 'إذاعة الشيخ عبد الله عواد الجهني (إمام الحرم المكي)',
    category: 'haramain',
    streamUrl: 'https://backup.qurango.net/radio/abdullah_aljohany',
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
    streamUrl: 'https://backup.qurango.net/radio/ali_alhuthaifi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'qasim_radio',
    name: 'إذاعة الشيخ عبد المحسن القاسم (إمام الحرم النبوي)',
    category: 'haramain',
    streamUrl: 'https://backup.qurango.net/radio/abdulmohsen_alqasim',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'budair_radio',
    name: 'إذاعة الشيخ صلاح البدير (إمام الحرم النبوي)',
    category: 'haramain',
    streamUrl: 'https://backup.qurango.net/radio/salah_albudair',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'ayyoub_radio',
    name: 'إذاعة الشيخ محمد أيوب رحمه الله (إمام الحرم النبوي)',
    category: 'haramain',
    streamUrl: 'https://backup.qurango.net/radio/mohammed_ayyub',
    icon: Icons.record_voice_over_outlined,
  ),

  // 3. كبار القراء ومشاهير التلاوة
  QuranRadioStation(
    id: 'minshawy_mojawwad',
    name: 'إذاعة الشيخ محمد صديق المنشاوي (المجود الخالد)',
    category: 'reciters',
    streamUrl:
        'https://backup.qurango.net/radio/mohammed_siddiq_alminshawi_mojawwad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'minshawy_murattal',
    name: 'إذاعة الشيخ محمد صديق المنشاوي (المرتل)',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/mohammed_siddiq_alminshawi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'husary_murattal',
    name: 'إذاعة الشيخ محمود خليل الحصري (مرتل)',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/mahmoud_khalil_alhussary',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'husary_mojawwad',
    name: 'إذاعة الشيخ محمود خليل الحصري (المجود)',
    category: 'reciters',
    streamUrl:
        'https://backup.qurango.net/radio/mahmoud_khalil_alhussary_mojawwad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'abdulbasit_mojawwad',
    name: 'إذاعة الشيخ عبد الباسط عبد الصمد (المجود)',
    category: 'reciters',
    streamUrl:
        'https://backup.qurango.net/radio/abdulbasit_abdulsamad_mojawwad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'abdulbasit_murattal',
    name: 'إذاعة الشيخ عبد الباسط عبد الصمد (المرتل)',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/abdulbasit_abdulsamad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'mustafa_ismail',
    name: 'إذاعة الشيخ مصطفى إسماعيل (تلاوات نادرة)',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/mustafa_ismail',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'banna_radio',
    name: 'إذاعة الشيخ محمود علي البنا',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/mahmoud_ali__albanna',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'alafasy_radio',
    name: 'إذاعة الشيخ مشاري راشد العفاسي',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/mishary_alafasi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'qatami_radio',
    name: 'إذاعة الشيخ ناصر القطامي',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/nasser_alqatami',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'ajmy_radio',
    name: 'إذاعة الشيخ أحمد بن علي العجمي',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/ahmad_alajmy',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'ghamadi_radio',
    name: 'إذاعة الشيخ سعد الغامدي',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/saad_alghamdi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'fares_abbad',
    name: 'إذاعة الشيخ فارس عباد',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/fares_abbad',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'shatri_radio',
    name: 'إذاعة الشيخ أبو بكر الشاطري',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/shaik_abu_bakr_al_shatri',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'abkar_radio',
    name: 'إذاعة الشيخ إدريس أبكر',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/idrees_abkr',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'hazza_radio',
    name: 'إذاعة القارئ هزاع البلوشي',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/hazza_alblushi',
    icon: Icons.record_voice_over_outlined,
  ),
  QuranRadioStation(
    id: 'khalid_jileel',
    name: 'إذاعة الشيخ خالد الجليل',
    category: 'reciters',
    streamUrl: 'https://backup.qurango.net/radio/khalid_aljileel',
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
    streamUrl: 'https://backup.qurango.net/radio/roqiah',
    icon: Icons.healing_outlined,
  ),
  QuranRadioStation(
    id: 'athkar_radio',
    name: 'إذاعة أذكار اليوم والليلة وحصن المسلم',
    category: 'general',
    streamUrl: 'https://backup.qurango.net/radio/athkar_sabah_massa',
    icon: Icons.brightness_2_outlined,
  ),
  QuranRadioStation(
    id: 'tarateel_radio',
    name: 'إذاعة تراتيل قصار السور والتلاوات الهادئة',
    category: 'general',
    streamUrl: 'https://backup.qurango.net/radio/tarateel',
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
    streamUrl: 'https://backup.qurango.net/radio/saheh-bokharee',
    icon: Icons.menu_book_outlined,
  ),
  QuranRadioStation(
    id: 'muslim_radio',
    name: 'إذاعة صحيح مسلم',
    category: 'sunnah',
    streamUrl: 'https://backup.qurango.net/radio/saheh-muslim',
    icon: Icons.menu_book_outlined,
  ),
  QuranRadioStation(
    id: 'riyad_saliheen_radio',
    name: 'إذاعة رياض الصالحين',
    category: 'sunnah',
    streamUrl: 'https://backup.qurango.net/radio/riyad',
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
  const QuranRadioScreen({super.key});

  @override
  ConsumerState<QuranRadioScreen> createState() => _QuranRadioScreenState();
}

class _QuranRadioScreenState extends ConsumerState<QuranRadioScreen> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _isPlaying = false;
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';

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
    // لا نتخلّص من `_player` هنا — مشغّل مشترك بعمر التطبيق (راجع
    // radioAudioPlayerProvider) يستمر بالتشغيل بالخلفية حتى لو أُغلقت هذه
    // الشاشة بالذات؛ يُتخلَّص منه مرة واحدة فقط عبر `ref.onDispose` بذاك
    // الـprovider (تفكيك التطبيق نفسه).
    _playerStateSub?.cancel();
    super.dispose();
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

    // سيرفر الإذاعات المشترك (qurango.net) متقلّب فعلياً تحت الضغط — فحص
    // مباشر أثبت أن نفس الرابط يرجع خطأ ٥٠٠ بمحاولة ثم ينجح بمحاولة تانية
    // بعد ثوانٍ لنفس المحطة بلا أي تغيير — فشل عابر لا رابط ميت، يستاهل
    // إعادة محاولة صامتة قبل إظهار رسالة خطأ للمستخدم.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      // المستخدم بدّل لمحطة تانية أثناء إعادة المحاولة — توقّف فوراً، لا
      // داعي نكمل تشغيل محطة عاد ما عادت مطلوبة.
      if (ref.read(activeRadioStationProvider)?.id != station.id) return;

      try {
        if (isNewStation) {
          await _player.setUrl(station.streamUrl);
        }
        await _player.play();
        if (isNewStation && mounted) {
          // إشعار نظام حقيقي (تشغيل/إيقاف + شريط تقدّم على شاشة القفل) —
          // يتحوّل مؤقتاً عن تلاوة القرآن لهذه المحطة، ويستمر بالخلفية حتى
          // لو أُغلقت هذه الشاشة (مشغّل مشترك — راجع radioAudioPlayerProvider)؛
          // يعود لتلاوة القرآن فقط عند الإغلاق الصريح من الشريط السفلي (زر
          // ✕). راجع `attachExternalSession` بـ`quran_audio_handler.dart`.
          ref
              .read(quranAudioHandlerProvider)
              .attachExternalSession(
                _player,
                MediaItem(
                  id: 'radio-${station.id}',
                  title: station.name,
                  artist: 'إذاعات القرآن والعلماء وبث الحرمين',
                  duration: _player.duration,
                ),
              );
        }
        return;
      } catch (e) {
        if (attempt == maxAttempts) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذّر تشغيل الإذاعة: يرجى التحقق من اتصال الإنترنت',
              ),
            ),
          );
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // حالة مشتركة بين الشاشة وأي منطق آخر (إشعار النظام) — راجع
    // radio_audio_providers.dart.
    final activeStation = ref.watch(activeRadioStationProvider);

    final filtered = kQuranRadioStations.where((s) {
      final matchesCat =
          _selectedCategory == 'all' || s.category == _selectedCategory;
      final matchesQuery =
          _searchQuery.isEmpty || s.name.contains(_searchQuery.trim());
      return matchesCat && matchesQuery;
    }).toList();

    // بلا `AppBar` خاص بها عمداً — تُستخدَم كتبويب داخل `RadioAndDuroosScreen`
    // (راجع `radio_and_duroos_screen.dart`)، هي المزوِّد الوحيد للـ`AppBar`
    // الآن. `Scaffold` نفسه لسا لازم (يوفّر موضع `bottomSheet` للمشغّل
    // العائم أدناه) — Scaffold متداخل بلا AppBar سلوك مدعوم رسمياً بفلَتر.
    return Scaffold(
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: 'ابحث عن شيخ، إذاعة، فتاوى، أو بث الحرمين...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          // تصنيفات الإذاعات
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'الكل (${kQuranRadioStations.length})',
                  color: AppColors.navy,
                  isSelected: _selectedCategory == 'all',
                  onTap: () => setState(() => _selectedCategory = 'all'),
                ),
                for (final cat in [
                  'scholars',
                  'haramain',
                  'reciters',
                  'live',
                  'general',
                  'sunnah',
                ]) ...[
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: _categoryLabel(cat),
                    color: _categoryColor(cat),
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // قائمة الإذاعات
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                activeStation != null ? 100 : 16,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final station = filtered[index];
                final isActive = activeStation?.id == station.id;
                final catColor = _categoryColor(station.category);

                return Material(
                  color: isActive
                      ? catColor.withValues(alpha: 0.1)
                      : (isDark ? const Color(0xFF1B232E) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _togglePlay(station),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        // بوردر عادي موحّد فقط — **لا يجوز خلط بوردر بعروض
                        // غير موحّدة مع `borderRadius`** (فلَتر يرمي فعلياً
                        // "A borderRadius can only be given for uniform
                        // borders" وقت الرسم)، هذا بالضبط سبب اختفاء كل
                        // بطاقات المحطات ("القنوات ما بتظهر"). شريط اللون حسب
                        // التصنيف صار عنصراً منفصلاً بداخل الصف (`Container`
                        // ٤ بيكسل) بدل جزء من حدود البطاقة.
                        border: Border.all(
                          color: (isDark ? AppColors.lineDark : AppColors.line)
                              .withValues(alpha: 0.7),
                          width: isActive ? 1.6 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 36,
                            margin: const EdgeInsetsDirectional.only(end: 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? catColor
                                  : catColor.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? catColor
                                  : catColor.withValues(alpha: 0.13),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              station.icon,
                              color: isActive ? Colors.white : catColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.name,
                                  style: TextStyle(
                                    fontWeight: isActive
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 13.5,
                                    color: isActive ? catColor : onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _categoryLabel(station.category),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        _isPlaying ? 'جارٍ البث 🟢' : 'متوقف',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1B8A72),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: isActive
                                  ? themeAccent(context)
                                  : null,
                              foregroundColor: isActive ? Colors.white : null,
                            ),
                            icon: isActive && _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    isActive && _isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    size: 22,
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
      ),

      // المشغل السفلي العائم عند تشغيل محطة
      bottomSheet: activeStation == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141A23) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: (isDark ? AppColors.lineDark : AppColors.line),
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _player.stop();
                        ref
                            .read(quranAudioHandlerProvider)
                            .detachExternalSession();
                        ref.read(activeRadioStationProvider.notifier).set(null);
                      },
                    ),
                    const SizedBox(width: 8),
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
                          Text(
                            _isPlaying ? 'بث مباشر 🔴' : 'متوقف',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isPlaying
                                  ? Colors.redAccent
                                  : Colors.grey,
                            ),
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
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
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
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: isSelected
          ? null
          : CircleAvatar(backgroundColor: color, radius: 5),
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
