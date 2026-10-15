import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/text/arabic_normalizer.dart';
import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../audio/quran_audio_handler.dart';
import 'duroos_audio_providers.dart';
import 'duroos_models.dart';
import 'duroos_repository.dart';

const _kDuroosSleepTimerMinutes = [10, 20, 30, 45, 60, 90];

/// شاشة تصفّح/تشغيل واحدة تخدم كِلا نوعي المصدر (islamweb وrss) —
/// islamweb قد يعطي تصنيفات فرعية (`lg`) تفتح نسخة جديدة من نفس
/// الشاشة، أو محاضرات مباشرة قابلة للتشغيل؛ rss يعطي محاضرات مباشرة
/// دائماً. **مشغّل صوت واحد مشترك بين كل نسخ الشاشة** (`duroosAudioPlayerProvider`
/// — راجعه لسبب هذا التصميم: منع تقاطع الصوت لو انتقلت بين شاشة عالِم
/// وتصنيفاته الفرعية أثناء التشغيل)، بنفس نمط تبديل التشغيل المستخدم
/// بـ`QuranRadioScreen` (`_togglePlay` + شريط سفلي عائم).
class DuroosLecturesScreen extends ConsumerStatefulWidget {
  const DuroosLecturesScreen({
    super.key,
    required this.source,
    required this.title,
    this.lg,
  });

  final DuroosSource source;
  final String title;

  /// التصنيف الحالي لـislamweb (يبدأ من `source.initialLg` عند أول فتح).
  final int? lg;

  @override
  ConsumerState<DuroosLecturesScreen> createState() => _DuroosLecturesScreenState();
}

class _DuroosLecturesScreenState extends ConsumerState<DuroosLecturesScreen> {
  final _repository = DuroosRepository();
  late final AudioPlayer _player;
  late Future<_LoadResult> _future;
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _isPlaying = false;
  bool _isLoading = false;

  // بحث محلي بعناوين محاضرات هذا العالِم/القسم — بطلب صريح ("ما ضفت قسم
  // البحث بالمحاضرات"). فلترة على القائمة المُحمَّلة أصلاً بلا أي طلب
  // شبكة إضافي (بعكس بحث عبر كل المشايخ معاً، يحتاج جلب قوائم الجميع
  // أولاً — خارج نطاق هذا الإصلاح، راجع التعليق أعلى `_buildSearchField`).
  final _lectureSearchCtrl = TextEditingController();
  String _lectureSearchQuery = '';

  @override
  void initState() {
    super.initState();
    // `ref` غير متاح بمُهيِّئ حقل (قبل ربط الودجت بالشجرة) — لازم تُقرأ
    // القيم من الـprovider هون بـinitState، لا بتعريف الحقل مباشرة.
    _player = ref.read(duroosAudioPlayerProvider);
    _future = _load();
    // المشغّل مشترك (راجع duroosAudioPlayerProvider) — حالته الحالية قد
    // تعكس محاضرة بدأت شاشة أخرى تشغيلها بالفعل، لذا نقرأها فوراً بدل
    // انتظار أول حدث بالبث فقط.
    _isPlaying = _player.playing && _player.processingState != ProcessingState.completed;
    _isLoading =
        _player.processingState == ProcessingState.loading ||
        _player.processingState == ProcessingState.buffering;
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing && state.processingState != ProcessingState.completed;
        _isLoading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
    });
  }

  @override
  void dispose() {
    // لا نتخلّص من `_player` هنا — مشغّل مشترك بين كل شاشات الدروس
    // المفتوحة (راجع `duroosAudioPlayerProvider`)، يستمر بالتشغيل
    // بالخلفية حتى لو أُغلقت هذه الشاشة بالذات؛ يُتخلَّص منه مرة واحدة
    // فقط عبر `ref.onDispose` بذاك الـprovider (تفكيك التطبيق نفسه).
    _playerStateSub?.cancel();
    _lectureSearchCtrl.dispose();
    super.dispose();
  }

  Future<_LoadResult> _load() async {
    try {
      switch (widget.source.kind) {
        case DuroosSourceKind.islamweb:
          final page = await _repository.fetchIslamweb(widget.source.sid!, widget.lg ?? widget.source.initialLg);
          return _LoadResult(categories: page.categories, lectures: page.lectures);
        case DuroosSourceKind.rss:
          final lectures = await _repository.fetchRss(widget.source.feedUrl!);
          return _LoadResult(categories: const [], lectures: lectures);
        case DuroosSourceKind.midad:
          final DuroosPage page;
          if (widget.lg != null && widget.lg != 0) {
            page = await _repository.fetchMidadCollection(widget.lg!);
          } else if (widget.source.midadScholarId != null) {
            page = await _repository.fetchMidadScholar(
              widget.source.midadScholarId!,
              isRecitation: widget.source.midadIsRecitation,
            );
          } else {
            page = await _repository.fetchMidadSearch(
              widget.source.midadQuery!,
              isRecitation: widget.source.midadIsRecitation,
            );
          }
          return _LoadResult(categories: page.categories, lectures: page.lectures);
      }
    } catch (e, st) {
      // تشخيص مؤقت: الرسالة العامة بالواجهة كانت تخفي السبب الحقيقي (قد
      // يكون خطأ شبكة فعلياً، أو خللاً بتحليل HTML/RSS لا علاقة له
      // بالاتصال) — راجع duroos_repository.dart قبل الشك بالسيرفر البعيد.
      debugPrint('DuroosLecturesScreen[${widget.source.id}, lg=${widget.lg}]: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// نفس شيت `QuranRadioScreen._showSleepTimerSheet` بالضبط (بنية/نصوص)،
  /// لكن يستدعي [duroosSleepTimerProvider] المشترك بدل حالة شاشة محلية —
  /// راجع توثيقه لسبب ذلك.
  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        final onSurface = Theme.of(sheetCtx).colorScheme.onSurface;
        final active = ref.read(duroosSleepTimerProvider) != null;
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
                      'مؤقّت النوم للدروس',
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
                  'يوقف المحاضرة تلقائياً بعد المدة المحددة لتوفير البطارية والبيانات',
                  style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in _kDuroosSleepTimerMinutes)
                      ChoiceChip(
                        label: Text('$m د'),
                        selected: false,
                        onSelected: (_) {
                          ref.read(duroosSleepTimerProvider.notifier).start(Duration(minutes: m));
                          Navigator.of(sheetCtx).pop();
                        },
                      ),
                  ],
                ),
                if (active) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(duroosSleepTimerProvider.notifier).cancel();
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

  Future<void> _togglePlay(DuroosLecture lecture) async {
    final activeNotifier = ref.read(activeDuroosLectureProvider.notifier);
    final active = ref.read(activeDuroosLectureProvider);
    if (active?.playbackKey == lecture.playbackKey && _isPlaying) {
      await _player.pause();
      return;
    }
    final isNewLecture = active?.playbackKey != lecture.playbackKey;
    try {
      setState(() => _isLoading = true);
      activeNotifier.set(lecture);
      if (isNewLecture) {
        // midad: الرابط المخزَّن بالمحاضرة/التلاوة `null` عمداً (موقّع
        // ومؤقت) — يُجلَب هنا لحظياً قبل التشغيل مباشرة (راجع توثيق
        // `DuroosSourceKind.midad` و`fetchMidadEntryAudio`).
        final audioUrl = widget.source.kind == DuroosSourceKind.midad
            ? await _repository.fetchMidadEntryAudio(
                lecture.midadLessonId!,
                entryType: lecture.midadEntryType,
                isRecitation: lecture.midadIsRecitation,
              )
            : lecture.audioUrl!;
        // CDN إسلام ويب (Azure) يحمي ملفاته من hotlinking — بلا Referer
        // صحيح يرجّع 307 لصفحة الموقع الرئيسية بدل الصوت (تحقّقت بـcurl:
        // 307 بلا الترويسة → 206 audio/mpeg معها). لا ضرر بإرسالها لمصادر
        // rss/midad أيضاً، لكنها غير ضرورية هناك.
        await _player.setUrl(
          audioUrl,
          headers: widget.source.kind == DuroosSourceKind.islamweb
              ? const {'Referer': 'https://audio.islamweb.net/'}
              : null,
        );
      }
      await _player.play();
      if (isNewLecture && mounted) {
        // إشعار نظام حقيقي (تشغيل/إيقاف/تقديم وترجيع ١٠ث + شريط تقدّم على
        // شاشة القفل) — يتحوّل الإشعار مؤقتاً عن تلاوة القرآن لهذه
        // المحاضرة، ويستمر بالخلفية حتى لو أُغلقت هذه الشاشة (مشغّل
        // مشترك — راجع duroosAudioPlayerProvider)؛ يعود لتلاوة القرآن
        // فقط عند الإغلاق الصريح من الشريط السفلي (زر ✕). راجع
        // `attachExternalSession` بـ`quran_audio_handler.dart`.
        ref.read(quranAudioHandlerProvider).attachExternalSession(
          _player,
          MediaItem(
            id: 'duroos-${widget.source.id}-${lecture.playbackKey.hashCode}',
            title: lecture.title,
            artist: widget.source.title,
            duration: _player.duration,
          ),
        );
      }
    } catch (e) {
      debugPrint('DuroosLecturesScreen[${widget.source.id}]: play failed for ${lecture.playbackKey}: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      final isNotFound = e.toString().contains('404') || e.toString().contains('Response code: 404');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNotFound
                ? 'عذراً، هذا التسجيل الصوتي غير متوفر على خادم المصدر حالياً'
                : 'تعذّر تشغيل المحاضرة: يرجى التحقق من اتصال الإنترنت',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // حالة مشتركة بين كل شاشات الدروس المفتوحة — راجع duroos_audio_providers.dart.
    final activeLecture = ref.watch(activeDuroosLectureProvider);
    final sleepEndsAt = ref.watch(duroosSleepTimerProvider);
    ref.watch(duroosSleepTimerTickProvider); // راجع توثيقه — يفرض تحديث العدّاد كل دقيقة
    final sleepRemainingMinutes = sleepEndsAt == null
        ? null
        : sleepEndsAt.difference(DateTime.now()).inMinutes + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'مؤقّت النوم',
            onPressed: () => _showSleepTimerSheet(context, ref),
            icon: sleepRemainingMinutes == null
                ? const Icon(Icons.bedtime_outlined)
                : Badge(
                    label: Text('$sleepRemainingMinutes'),
                    backgroundColor: AppColors.gold,
                    child: const Icon(Icons.bedtime),
                  ),
          ),
        ],
      ),
      body: FutureBuilder<_LoadResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            final isParse = err is DuroosParseException;
            final errorText = isParse
                ? err.message
                : 'تعذّر تحميل المحتوى: يرجى التحقق من اتصال الإنترنت والمحاولة مجدداً';
            final errorIcon = isParse ? Icons.cloud_off_outlined : Icons.wifi_off_outlined;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(errorIcon, size: 40, color: onSurface.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      errorText,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final result = snapshot.data!;
          if (result.categories.isEmpty && result.lectures.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              message: 'لا يوجد محتوى بهذا القسم حالياً',
            );
          }

          // فلترة ذكية ومطابقة معربة تبحث في التصنيفات والسلاسل والمحاضرات معاً
          final q = _lectureSearchQuery.trim();
          final normQ = normalizeArabicSearch(q);

          final filteredCategories = q.isEmpty
              ? result.categories
              : result.categories
                  .where((c) => normalizeArabicSearch(c.title).contains(normQ))
                  .toList();

          final filteredLectures = q.isEmpty
              ? result.lectures
              : result.lectures
                  .where((l) => normalizeArabicSearch(l.title).contains(normQ))
                  .toList();

          final totalItems = result.categories.length + result.lectures.length;

          return Column(
            children: [
              // شريط بحث مثبت بالأعلى دائماً وفعّال
              if (totalItems > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: TextField(
                    controller: _lectureSearchCtrl,
                    onChanged: (v) => setState(() => _lectureSearchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'ابحث في السلاسل والمحاضرات...',
                      hintStyle: TextStyle(fontSize: 12.5, color: onSurface.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _lectureSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _lectureSearchCtrl.clear();
                                setState(() => _lectureSearchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, activeLecture != null ? 100 : 16),
                  children: [
              if (q.isNotEmpty && filteredLectures.isEmpty && filteredCategories.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'لا توجد سلسلة أو محاضرة مطابقة للبحث',
                      style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13),
                    ),
                  ),
                ),
              for (final category in filteredCategories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ListTile(
                    isDark: isDark,
                    onSurface: onSurface,
                    icon: Icons.folder_outlined,
                    title: category.title,
                    subtitle: category.count != null ? '${category.count} محاضرة' : null,
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DuroosLecturesScreen(
                          source: widget.source,
                          title: category.title,
                          lg: category.lg,
                        ),
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < filteredLectures.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ListTile(
                    isDark: isDark,
                    onSurface: onSurface,
                    icon: Icons.play_circle_outline,
                    title: filteredLectures[i].title,
                    indexNumber: i + 1,
                    isActive: activeLecture?.playbackKey == filteredLectures[i].playbackKey,
                    isPlaying: activeLecture?.playbackKey == filteredLectures[i].playbackKey && _isPlaying,
                    isBuffering: activeLecture?.playbackKey == filteredLectures[i].playbackKey && _isLoading,
                    onTap: () => _togglePlay(filteredLectures[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
        },
      ),
      bottomSheet: activeLecture == null
          ? null
          : _PlayerBar(
              player: _player,
              lecture: activeLecture,
              isPlaying: _isPlaying,
              isLoading: _isLoading,
              isDark: isDark,
              sourceCredit: switch (widget.source.kind) {
                DuroosSourceKind.islamweb => 'محاضرات وفتاوى صوتية من أرشيف إسلام ويب',
                DuroosSourceKind.rss => 'بودكاست رسمي (روابط صوتية مباشرة)',
                DuroosSourceKind.midad => 'دروس ومحاضرات من موقع مِداد',
              },
              onTogglePlay: () => _togglePlay(activeLecture),
              onClose: () {
                _player.stop();
                ref.read(quranAudioHandlerProvider).detachExternalSession();
                ref.read(activeDuroosLectureProvider.notifier).set(null);
              },
            ),
    );
  }
}

/// شريط المشغّل السفلي العائم لدروس العلم — مزوّد بـ:
/// ١) التحكّم بسرعة التشغيل (1.0x, 1.25x, 1.5x, 1.75x, 2.0x) التي يحتاجها كل طالب علم
/// ٢) التقديم والتأخير ١٠ ثوانٍ
/// ٣) شريط تقدّم سلس بتصميم عصري عائم
class _PlayerBar extends StatefulWidget {
  const _PlayerBar({
    required this.player,
    required this.lecture,
    required this.isPlaying,
    required this.isLoading,
    required this.isDark,
    required this.sourceCredit,
    required this.onTogglePlay,
    required this.onClose,
  });

  final AudioPlayer player;
  final DuroosLecture lecture;
  final bool isPlaying;
  final bool isLoading;
  final bool isDark;
  final String sourceCredit;
  final VoidCallback onTogglePlay;
  final VoidCallback onClose;

  @override
  State<_PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<_PlayerBar> {
  double _speed = 1.0;

  static const List<double> _speeds = [1.0, 1.25, 1.5, 1.75, 2.0];

  void _cycleSpeed() {
    final idx = _speeds.indexOf(_speed);
    final next = _speeds[(idx + 1) % _speeds.length];
    setState(() => _speed = next);
    widget.player.setSpeed(next);
  }

  void _seekRelative(int seconds) {
    final pos = widget.player.position;
    final target = pos + Duration(seconds: seconds);
    widget.player.seek(target < Duration.zero ? Duration.zero : target);
  }

  static String _format(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF141E28) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.45 : 0.16),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (widget.isDark ? AppColors.lineDark : AppColors.gold.withValues(alpha: 0.35)),
          width: 1.2,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط التقديم والتأخير والوقت
            StreamBuilder<Duration?>(
              stream: widget.player.durationStream,
              builder: (context, durationSnap) {
                final duration = durationSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: widget.player.positionStream,
                  builder: (context, positionSnap) {
                    var position = positionSnap.data ?? Duration.zero;
                    if (duration > Duration.zero && position > duration) position = duration;
                    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: themeAccent(context),
                            inactiveTrackColor: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
                            thumbColor: themeAccent(context),
                          ),
                          child: Slider(
                            min: 0,
                            max: maxMs,
                            value: position.inMilliseconds.toDouble().clamp(0, maxMs),
                            onChanged: duration > Duration.zero
                                ? (v) => widget.player.seek(Duration(milliseconds: v.round()))
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format(position),
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.6)),
                              ),
                              Text(
                                duration > Duration.zero ? '-${_format(duration - position)}' : '--:--',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // عنوان المحاضرة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.lecture.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'إغلاق المشغل',
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),

            // أزرار التحكم الكاملة (سرعة التشغيل + تقديم/تأخير ١٠ث + تشغيل/إيقاف)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // زر سرعة التشغيل
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeAccent(context).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_speed}x',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: themeAccent(context),
                      ),
                    ),
                  ),
                ),

                // تأخير ١٠ ثوانٍ
                IconButton(
                  tooltip: 'تأخير ١٠ ثوانٍ',
                  icon: const Icon(Icons.replay_10_rounded, size: 24),
                  onPressed: () => _seekRelative(-10),
                ),

                // زر التشغيل/الإيقاف الرئيسي
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: themeAccent(context),
                    padding: const EdgeInsets.all(10),
                  ),
                  icon: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : Icon(
                          widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                  onPressed: widget.onTogglePlay,
                ),

                // تقديم ١٠ ثوانٍ
                IconButton(
                  tooltip: 'تقديم ١٠ ثوانٍ',
                  icon: const Icon(Icons.forward_10_rounded, size: 24),
                  onPressed: () => _seekRelative(10),
                ),
              ],
            ),

            // حقوق ومصدر المادة العلمية
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public, size: 10.5, color: onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.sourceCredit,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9.5, color: onSurface.withValues(alpha: 0.45)),
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
}

class _LoadResult {
  const _LoadResult({required this.categories, required this.lectures});
  final List<DuroosCategory> categories;
  final List<DuroosLecture> lectures;
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.isDark,
    required this.onSurface,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.indexNumber,
    this.isActive = false,
    this.isPlaying = false,
    this.isBuffering = false,
    required this.onTap,
  });

  final bool isDark;
  final Color onSurface;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final int? indexNumber;
  final bool isActive;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = themeAccent(context);

    return Material(
      color: isActive ? accent.withValues(alpha: isDark ? 0.18 : 0.08) : (isDark ? const Color(0xFF1B232E) : Colors.white),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? accent.withValues(alpha: 0.6)
                  : (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8),
              width: isActive ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              // رقم الدرس أو أيقونة التصنيف
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? accent : accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: indexNumber != null
                    ? Text(
                        '$indexNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : accent,
                        ),
                      )
                    : Icon(icon, color: isActive ? Colors.white : accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                        color: isActive ? accent : onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5))),
                    ],
                  ],
                ),
              ),
              if (isBuffering)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else if (trailing != null)
                trailing!
              else
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isActive ? accent : null,
                    foregroundColor: isActive ? Colors.white : null,
                  ),
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 22,
                  ),
                  onPressed: onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
