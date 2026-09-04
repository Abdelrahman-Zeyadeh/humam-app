import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_card.dart';
import '../../core/theme/app_colors.dart';
import '../audio/quran_audio_handler.dart';
import 'duroos_audio_providers.dart';
import 'duroos_models.dart';
import 'duroos_repository.dart';

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

  Future<void> _togglePlay(DuroosLecture lecture) async {
    final activeNotifier = ref.read(activeDuroosLectureProvider.notifier);
    final active = ref.read(activeDuroosLectureProvider);
    if (active?.audioUrl == lecture.audioUrl && _isPlaying) {
      await _player.pause();
      return;
    }
    final isNewLecture = active?.audioUrl != lecture.audioUrl;
    try {
      setState(() => _isLoading = true);
      activeNotifier.set(lecture);
      if (isNewLecture) {
        // CDN إسلام ويب (Azure) يحمي ملفاته من hotlinking — بلا Referer
        // صحيح يرجّع 307 لصفحة الموقع الرئيسية بدل الصوت (تحقّقت بـcurl:
        // 307 بلا الترويسة → 206 audio/mpeg معها). لا ضرر بإرسالها لمصادر
        // rss أيضاً، لكنها غير ضرورية هناك.
        await _player.setUrl(
          lecture.audioUrl,
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
            id: 'duroos-${widget.source.id}-${lecture.audioUrl.hashCode}',
            title: lecture.title,
            artist: widget.source.title,
            duration: _player.duration,
          ),
        );
      }
    } catch (e) {
      debugPrint('DuroosLecturesScreen[${widget.source.id}]: play failed for ${lecture.audioUrl}: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تشغيل المحاضرة: يرجى التحقق من اتصال الإنترنت')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // حالة مشتركة بين كل شاشات الدروس المفتوحة — راجع duroos_audio_providers.dart.
    final activeLecture = ref.watch(activeDuroosLectureProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis), elevation: 0),
      body: FutureBuilder<_LoadResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_outlined, size: 40, color: onSurface.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text(
                      'تعذّر تحميل المحتوى: يرجى التحقق من اتصال الإنترنت والمحاولة مجدداً',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // تشخيص مؤقت: نص الاستثناء الفعلي — يوضّح إذا كان
                    // السبب شبكياً حقاً أو خللاً بالتحليل، بلا حاجة لـlogcat.
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 12),
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

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, activeLecture != null ? 100 : 16),
            children: [
              for (final category in result.categories)
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
              for (final lecture in result.lectures)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ListTile(
                    isDark: isDark,
                    onSurface: onSurface,
                    icon: Icons.play_circle_outline,
                    title: lecture.title,
                    isActive: activeLecture?.audioUrl == lecture.audioUrl,
                    isPlaying: activeLecture?.audioUrl == lecture.audioUrl && _isPlaying,
                    isBuffering: activeLecture?.audioUrl == lecture.audioUrl && _isLoading,
                    onTap: () => _togglePlay(lecture),
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
              sourceCredit: widget.source.kind == DuroosSourceKind.islamweb
                  ? 'محاضرات وفتاوى صوتية من أرشيف إسلام ويب'
                  : 'بودكاست رسمي (روابط صوتية مباشرة)',
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

/// شريط المشغّل السفلي — منفصل بودجت خاص به عشان تحديث الموضع (عدة مرات
/// بالثانية عبر `positionStream`) يعيد بناء نفسه فقط، لا كل الشاشة
/// (القائمة الطويلة فوقه ما تنعاد كتابتها).
class _PlayerBar extends StatelessWidget {
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

  static String _format(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A23) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, -4)),
        ],
        border: Border(top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Duration?>(
              stream: player.durationStream,
              builder: (context, durationSnap) {
                final duration = durationSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, positionSnap) {
                    var position = positionSnap.data ?? Duration.zero;
                    if (duration > Duration.zero && position > duration) position = duration;
                    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                    final onSurface = Theme.of(context).colorScheme.onSurface;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          child: Slider(
                            min: 0,
                            max: maxMs,
                            value: position.inMilliseconds.toDouble().clamp(0, maxMs),
                            activeColor: themeAccent(context),
                            onChanged: duration > Duration.zero
                                ? (v) => player.seek(Duration(milliseconds: v.round()))
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format(position),
                                style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.55)),
                              ),
                              Text(
                                duration > Duration.zero ? '-${_format(duration - position)}' : '--:--',
                                style: TextStyle(fontSize: 10.5, color: onSurface.withValues(alpha: 0.55)),
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
            Row(
              children: [
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: onClose),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lecture.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: themeAccent(context)),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                  onPressed: onTogglePlay,
                ),
              ],
            ),
            // إسناد مضمّن بمصدر المحتوى المعاد بثّه — بواجهة المستخدم
            // نفسها، لا بملف نصي بعيد لا يراه المستخدم (راجع الملاحظة
            // الشرعية بمقدمة `duroos_repository.dart`).
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public, size: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      sourceCredit,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
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
  final bool isActive;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? themeAccent(context).withValues(alpha: 0.1) : (isDark ? const Color(0xFF1B232E) : Colors.white),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? themeAccent(context)
                  : (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.7),
              width: isActive ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? themeAccent(context) : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isActive ? Colors.white : themeAccent(context), size: 20),
              ),
              const SizedBox(width: 14),
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
                        color: isActive ? themeAccent(context) : onSurface,
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
                Icon(isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline, color: onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
