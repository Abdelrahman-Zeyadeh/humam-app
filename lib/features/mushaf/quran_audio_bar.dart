import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/quran/quran_database.dart';
import '../../core/data/quran/quran_providers.dart';
import '../../core/theme/app_colors.dart';
import '../audio/audio_download_service.dart';
import '../audio/quran_audio_controller.dart';
import '../audio/reciters.dart';

const List<double> _kSpeedSteps = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

final _barSurahProvider = FutureProvider.family<Surah, int>((ref, id) {
  return ref.watch(quranRepositoryProvider).surahById(id);
});

final _barAyahProvider = FutureProvider.family<Ayah, int>((ref, id) {
  return ref.watch(quranRepositoryProvider).ayahById(id);
});

/// شريط تشغيل ثابت أسفل شاشة المصحف، يظهر فقط أثناء تشغيل صوتي جارٍ.
/// يعرض القارئ والموضع الحالي، ويحكم بالتشغيل/التنقّل/التكرار/السرعة —
/// راجع `QuranAudioController` لمنطق التشغيل الفعلي.
class QuranAudioBar extends ConsumerWidget {
  const QuranAudioBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(quranAudioControllerProvider);
    if (!audio.isActive) return const SizedBox.shrink();

    final controller = ref.read(quranAudioControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.cream;
    final fg = isDark ? AppColors.inkOnDark : AppColors.ink;
    final reciter = reciterById(audio.reciterId);

    final accent = themeAccent(context);
    final dividerColor = isDark ? AppColors.lineDark : AppColors.line;

    // بطلب صاحب المشروع (٢٠٢٦-٠٩-٠١: "حاسها معجوقة، هات شكل حيوي وأسهل
    // وأجمل") — أعدنا تصميم محتوى الشريط بلا تغيير ارتفاعه العام (يبقى
    // مضغوطاً لتراص `_PageNavStrip` فوقه، القيد الأصلي الذي دفع للتصغير
    // أول مرة): فاصل رأسي يفصل بصرياً معلومات القارئ عن أزرار التشغيل،
    // وأزرار التشغيل صارت بكبسولة مستديرة خاصة بها مع فراغات حقيقية
    // بينها (كانت متلاصقة بلا أي `SizedBox` — هذا أكبر سبب "التعجيق")،
    // وزر التشغيل/الإيقاف صار دائرة معبّأة بلون التمييز (بؤرة العين
    // الواضحة) بدل أيقونة تغرق وسط بقية الأزرار.
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: dividerColor)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        // شاشات ضيّقة (أو تسمية تكرار طويلة، راجع `RepeatOption.labelAr`)
        // كانت تفيض بصمت (Row واحد بعشر عناصر ثابتة العرض تقريباً وعنصر
        // مرن وحيد بينها) — لُفّت بتمرير أفقي بدل تقييد/حذف أي زر، فتبقى
        // كل الأزرار وصولاً بسحبة بسيطة بدل فيضان مقصوص. `Expanded` تحوّل
        // لـ`SizedBox` عرض ثابت لأن الالتفاف داخل تمرير أفقي يجعل عرض
        // الـRow غير محدود (`Expanded` تفشل ببناء بلا عرض محدود).
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CompactIconButton(
                icon: Icons.close,
                color: fg.withValues(alpha: 0.6),
                onPressed: controller.stop,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 128,
                child: GestureDetector(
                  onTap: () => _showReciterPicker(context, ref),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AudioBarLabel(audio: audio, fg: fg),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              reciter.nameAr,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: fg.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          if (audio.liveListenEnabled) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'مباشر',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // زر "المزيد" الوحيد يجمع التنزيل/التكرار/السرعة/مؤقت النوم —
              // بدل أربعة أزرار دائمة الظهور بجانب أزرار التشغيل الأساسية
              // (بطلب صاحب المشروع تبسيط الشريط).
              _CompactIconButton(
                icon: Icons.more_horiz_rounded,
                color: fg,
                onPressed: () =>
                    _MoreOptionsSheet.show(context, audio: audio, fg: fg),
              ),
              const SizedBox(width: 6),
              Container(width: 1, height: 30, color: dividerColor),
              const SizedBox(width: 6),
              // مجموعة التشغيل: كبسولة مستديرة تفصلها بصرياً عن باقي
              // الشريط، وزر التشغيل بؤرتها الواضحة.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CompactIconButton(
                      icon: Icons.skip_previous_rounded,
                      color: fg,
                      size: 22,
                      onPressed: controller.previous,
                    ),
                    const SizedBox(width: 2),
                    if (audio.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(7),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    else
                      Material(
                        color: accent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: controller.togglePlayPause,
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Icon(
                              audio.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 2),
                    _CompactIconButton(
                      icon: Icons.skip_next_rounded,
                      color: fg,
                      size: 22,
                      onPressed: controller.next,
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

  void _showReciterPicker(BuildContext context, WidgetRef ref) {
    final audio = ref.read(quranAudioControllerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // `isScrollControlled` + ارتفاع نسبي + `Expanded`+`ListView` بدل
      // `Column(mainAxisSize: min)` بلا تمرير — عشرة قرّاء (راجع `kReciters`)
      // كانوا يفيضون أسفل الشيت بأكثر من ٧٠٠ بكسل على الشاشات العادية لأن
      // الشيت غير القابل للتمرير (`isScrollControlled` الافتراضي `false`)
      // يتقيّد بنحو ٩/١٦ من ارتفاع الشاشة بلا أي وسيلة لعرض الباقي. نفس
      // نمط `MushafSurahIndexSheet.show` بالضبط.
      isScrollControlled: true,
      builder: (sheetContext) {
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        final accent = themeAccent(sheetContext);
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'اختر القارئ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    children: [
                      for (final r in kReciters) ...[
                        _ReciterRow(
                          reciter: r,
                          selected: r.id == audio.reciterId,
                          accent: accent,
                          onTap: () {
                            ref
                                .read(quranAudioControllerProvider.notifier)
                                .setReciter(r.id);
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// صف قارئ واحد بقائمة الاختيار — بطاقة بدل `ListTile` مجرّد (بطلب صاحب
/// المشروع تسهيلها): أفاتار دائري بلون مشتق من معرّف القارئ (نفس فكرة
/// `_SurahThumbnail` بالحرف الأول)، خلفية القارئ المختار مصبوغة بلون
/// التمييز فعلياً لا مجرّد أيقونة راديو صغيرة، وقيد "لا تظليل متزامن"
/// أيقونة صغيرة بجانب الاسم بدل جملة كاملة تحته.
class _ReciterRow extends StatelessWidget {
  const _ReciterRow({
    required this.reciter,
    required this.selected,
    required this.accent,
    required this.onTap,
  });
  final Reciter reciter;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hue = (reciter.id.hashCode.abs() * 7) % 360;
    final avatarColor = HSLColor.fromAHSL(
      1,
      hue.toDouble(),
      0.5,
      isDark ? 0.32 : 0.45,
    ).toColor();

    return Material(
      color: selected
          ? accent.withValues(alpha: isDark ? 0.18 : 0.1)
          : (isDark ? const Color(0xFF1E2836) : Colors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent
                  : (isDark ? AppColors.lineDark : AppColors.line),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: avatarColor,
                child: Text(
                  reciter.nameAr.characters.first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        reciter.nameAr,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (reciter.mode == ReciterAudioMode.perSurahOnly) ...[
                      const SizedBox(width: 5),
                      Tooltip(
                        message: 'تشغيل السورة كاملة فقط — لا تظليل متزامن',
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 20)
              else
                Icon(
                  Icons.circle_outlined,
                  color: onSurface.withValues(alpha: 0.25),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شيت "المزيد" — يجمع التنزيل/التكرار/السرعة/مؤقت النوم بقائمة صفوف واضحة
/// بدل أربعة أزرار مضغوطة دائمة الظهور بشريط التشغيل (بطلب صاحب المشروع
/// تبسيطه). كل صف يعيد استخدام الودجت المستقل الأصلي نفسه (`_SmallTextButton`/
/// `_SleepTimerButton`/`_DownloadSurahButton`) كعنصر لمس طرفي — الحالة/المنطق
/// نفسها بلا تكرار، فقط عرض مختلف داخل قائمة بدل كبسولات متلاصقة.
class _MoreOptionsSheet extends ConsumerWidget {
  const _MoreOptionsSheet({required this.audio, required this.fg});
  final QuranAudioState audio;
  final Color fg;

  static void show(
    BuildContext context, {
    required QuranAudioState audio,
    required Color fg,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoreOptionsSheet(audio: audio, fg: fg),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quranAudioControllerProvider.notifier);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surahId = audio.currentSurah;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _MoreOptionRow(
              icon: Icons.repeat_rounded,
              label: 'التكرار',
              trailing: _SmallTextButton(
                label: audio.repeat.labelAr,
                fg: fg,
                onTap: () {
                  controller.setRepeat(audio.repeat.nextOption);
                  Navigator.of(context).pop();
                },
              ),
            ),
            _MoreOptionRow(
              icon: Icons.speed_rounded,
              label: 'سرعة التلاوة',
              trailing: _SmallTextButton(
                label: '${audio.speed}x'.replaceAll('.0x', 'x'),
                fg: fg,
                onTap: () {
                  final i = _kSpeedSteps.indexOf(audio.speed);
                  final next =
                      _kSpeedSteps[(i < 0 ? 0 : i + 1) % _kSpeedSteps.length];
                  controller.setSpeed(next);
                  Navigator.of(context).pop();
                },
              ),
            ),
            _MoreOptionRow(
              icon: Icons.bedtime_outlined,
              label: 'مؤقّت النوم',
              trailing: _SleepTimerButton(
                sleepTimerEndsAt: audio.sleepTimerEndsAt,
                fg: onSurface,
              ),
            ),
            // وضع "استماع فقط": انتقال تلقائي للسورة التالية عند الانتهاء —
            // بلا حاجة فتح المصحف أو التفاعل بالشاشة إطلاقاً، بطلب صريح
            // "تشغيل صوتي متسلسل للسور بلا تفاعل لمسي".
            _MoreOptionRow(
              icon: Icons.playlist_play_rounded,
              label: 'استماع فقط (تشغيل متسلسل للسور)',
              // نفس نمط بقية خيارات هالشيت (تكرار/سرعة) — قيمة لحظة الفتح
              // فقط (`audio` معطى ثابت لا مُراقَب)، وتُغلَق الشيت فور
              // التبديل بدل تحديثها حيّة بمكانها.
              trailing: Switch(
                value: audio.listenOnlyModeEnabled,
                onChanged: (v) {
                  controller.setListenOnlyModeEnabled(v);
                  Navigator.of(context).pop();
                },
              ),
            ),
            if (surahId != null)
              _MoreOptionRow(
                icon: Icons.download_outlined,
                label: 'تنزيل هذه السورة',
                trailing: _DownloadSurahButton(
                  reciterId: audio.reciterId,
                  surahId: surahId,
                  fg: onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoreOptionRow extends StatelessWidget {
  const _MoreOptionRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: onSurface.withValues(alpha: 0.65)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// زر مؤقّت النوم (١٥/٣٠/٤٥/٦٠ دقيقة) — يوقف `QuranAudioController` تلقائياً
/// عند انتهاء المدّة (راجع `setSleepTimer`)، ويعرض الدقائق المتبقّية فوق
/// أيقونة القمر كنص صغير حين مفعَّل، مع خيار "إلغاء" بأعلى القائمة.
class _SleepTimerButton extends ConsumerWidget {
  const _SleepTimerButton({required this.sleepTimerEndsAt, required this.fg});
  final DateTime? sleepTimerEndsAt;
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quranAudioControllerProvider.notifier);
    final active = sleepTimerEndsAt != null;
    final remainingMinutes = active
        ? (sleepTimerEndsAt!.difference(DateTime.now()).inSeconds / 60)
              .ceil()
              .clamp(0, 999)
        : null;

    return PopupMenuButton<int?>(
      tooltip: active ? 'مؤقّت النوم: باقي $remainingMinutes د' : 'مؤقّت نوم',
      onSelected: (minutes) {
        if (minutes == null) {
          controller.cancelSleepTimer();
        } else {
          controller.setSleepTimer(Duration(minutes: minutes));
        }
      },
      itemBuilder: (context) => [
        if (active)
          const PopupMenuItem(value: null, child: Text('إلغاء المؤقّت')),
        for (final minutes in const [15, 30, 45, 60])
          PopupMenuItem(value: minutes, child: Text('$minutes دقيقة')),
      ],
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.bedtime : Icons.bedtime_outlined,
              size: 20,
              color: active ? themeAccent(context) : fg,
            ),
            if (active)
              Text(
                '$remainingMinutesد',
                style: TextStyle(
                  fontSize: 8,
                  color: themeAccent(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudioBarLabel extends ConsumerWidget {
  const _AudioBarLabel({required this.audio, required this.fg});
  final QuranAudioState audio;
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahId = audio.currentSurah;
    if (surahId == null) {
      return Text(
        '—',
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w700),
      );
    }
    final surahAsync = ref.watch(_barSurahProvider(surahId));
    final surahName = surahAsync.value?.nameAr ?? '…';

    final ayahId = audio.currentAyahId;
    final ayahAsync = ayahId != null
        ? ref.watch(_barAyahProvider(ayahId))
        : null;
    final ayahNo = ayahAsync?.value?.ayah;
    final ayahCount = surahAsync.value?.ayahCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            surahName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (ayahNo != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: themeAccent(context).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ayahCount != null ? 'آية $ayahNo/$ayahCount' : 'آية $ayahNo',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: themeAccent(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// زر أيقونة مضغوط — نفس `IconButton` لكن بلا منطقة لمس ٤٨×٤٨ الافتراضية
/// (`constraints`/`padding` مصغَّرين) لتقليل ارتفاع/عرض الشريط الكلي.
class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 20,
  });
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: size,
      color: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      // منطقة لمس ٤٠×٤٠ فعلية (بدل الافتراضية ٤٨×٤٨) — أزرار متكررة الاستخدام
      // بشريط دائم الظهور، `BoxConstraints()` الفارغة كانت تُنزل المساحة
      // الفعلية لحجم الأيقونة+الحشوة فقط (~٢٨px)، خطر لمس خاطئ حقيقي.
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: onPressed,
    );
  }
}

/// زر "نزّل هذه السورة" مباشرة من شريط الاستماع — بدل الحاجة للذهاب
/// للإعدادات كل مرّة، بطلب صاحب المشروع. يستخدم نفس `AudioDownloadController`
/// المشترك مع شاشة `audio_downloads_screen.dart`؛ يبدّل قارئها الداخلي
/// لقارئ التشغيل الحالي أولاً لو مختلفاً (الشاشتان تتشاركان نفس الحالة،
/// راجع توثيق `switchReciter`).
class _DownloadSurahButton extends ConsumerWidget {
  const _DownloadSurahButton({
    required this.reciterId,
    required this.surahId,
    required this.fg,
  });
  final String reciterId;
  final int surahId;
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dlState = ref.watch(audioDownloadControllerProvider);
    final controller = ref.read(audioDownloadControllerProvider.notifier);
    final sameReciter = dlState.reciterId == reciterId;
    final downloaded =
        sameReciter && dlState.downloadedSurahs.contains(surahId);
    final downloading =
        sameReciter && dlState.isBulkRunning && dlState.currentSurah == surahId;

    if (downloading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return _CompactIconButton(
      icon: downloaded ? Icons.download_done : Icons.download_outlined,
      color: downloaded ? AppColors.tealDeep : fg.withValues(alpha: 0.7),
      onPressed: downloaded
          ? null
          : () async {
              if (!sameReciter) await controller.switchReciter(reciterId);
              await controller.downloadSurah(surahId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('نُزِّلت السورة للاستماع بلا إنترنت'),
                  ),
                );
              }
            },
    );
  }
}

class _SmallTextButton extends StatelessWidget {
  const _SmallTextButton({
    required this.label,
    required this.onTap,
    required this.fg,
  });
  final String label;
  final VoidCallback onTap;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: fg.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
