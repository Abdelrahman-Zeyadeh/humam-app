import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user/location_prefs.dart';
import '../../../core/data/user/user_prefs.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/adhan_notification_prefs.dart';
import '../adhan_voices.dart' show adhanVoiceById;
import '../prayer_countdown_card.dart' show prayerTickProvider;
import '../prayer_location_controller.dart' show rescheduleAdhanNotifications;
import '../prayer_times_service.dart';
import 'prayer_display_helpers.dart';
import 'prayer_voice_picker_sheet.dart';

/// نصوص فضل كل صلاة — تُعرض بأعلى ورقة تفاصيل الصلاة (بطاقة اقتباس).
const Map<PrayerMoment, String> kPrayerVirtues = {
  PrayerMoment.fajr:
      'صلاة الفجر أو صلاة الصبح ركعتان يُجهر بهما، وفي الحديث: «من صلى العشاء في جماعة فكأنما قام نصف الليل، ومن صلى الصبح في جماعة فكأنما صلى الليل كله» [أخرجه مسلم]، وقال صلى الله عليه وسلم أيضًا: «من صلى الصبح فهو في ذمة الله» [أخرجه مسلم]. وراتبتها ركعتان قبلها؛ قال صلى الله عليه وسلم في فضلهما: «ركعتا الفجر خير من الدنيا وما فيها» [أخرجه مسلم].',
  PrayerMoment.dhuhr:
      'صلاة الظهر أربع ركعات يُسرّ بها، وهي أول صلاة صلاها جبريل بالنبي ﷺ. وفي الحديث: «تلك ساعة تُفتح فيها أبواب السماء، فأحب أن يصعد لي فيها عمل صالح» [أخرجه الترمذي]. وسنتها أربع ركعات قبلها وركعتان بعدها.',
  PrayerMoment.asr:
      'صلاة العصر أربع ركعات يُسرّ بها، وهي الصلاة الوسطى المذكورة في القرآن: ﴿حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَى﴾. وفي الحديث: «من صلى البردين دخل الجنة» [متفق عليه]، والبردان هما الفجر والعصر. وسنتها أربع ركعات قبلها.',
  PrayerMoment.maghrib:
      'صلاة المغرب ثلاث ركعات، ركعتان يُجهر بهما وثالثة يُسرّ بها. وهي وتر النهار، وفي الحديث: «لا تزال أمتي بخير - أو على الفطرة - ما لم يؤخروا المغرب حتى تشتبك النجوم» [أخرجه أبو داود]. وسنتها ركعتان بعدها.',
  PrayerMoment.isha:
      'صلاة العشاء أربع ركعات، ركعتان يُجهر بهما وركعتان يُسرّ بهما. وفي الحديث: «من صلى العشاء في جماعة فكأنما قام نصف الليل» [أخرجه مسلم]. وسنتها ركعتان بعدها، ويُشرع بعدها صلاة الوتر.',
};

/// ورقة سفلية بتفاصيل صلاة واحدة: فضلها، عدّاد مضى/متبقٍ، وضبط إزاحة
/// الوقت/الإقامة/التنبيه المبكر/المؤذن/نمط التنبيه لهذه الصلاة تحديداً.
void showPrayerDetailBottomSheet(
  BuildContext context,
  WidgetRef ref,
  LocationPrefs prefs,
  PrayerMoment moment,
  DateTime time,
  List<PrayerMomentTime> dayTimes,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final userPrefs = ref.watch(userPrefsProvider);
          final notifPrefs = ref.watch(adhanNotificationPrefsProvider);
          final now = ref.watch(prayerTickProvider).value ?? DateTime.now();
          final accent = themeAccent(context);
          final onSurface = Theme.of(context).colorScheme.onSurface;

          final offset = userPrefs.prayerOffsetFor(moment.name);
          final adjustedTime = time.add(Duration(minutes: offset));
          final iqamahMins = userPrefs.iqamahMinutesFor(moment.name);
          final preMins = userPrefs.preAdhanMinutes;

          final currentVoiceId = userPrefs.adhanVoiceFor(moment.name);
          final currentVoice = adhanVoiceById(currentVoiceId);
          final currentMode = notifPrefs.notificationModeFor(moment);

          final diff = now.difference(adjustedTime);
          final isPast = !diff.isNegative;
          final absDiff = diff.abs();

          final hours = absDiff.inHours.toString().padLeft(2, '0');
          final mins = (absDiff.inMinutes % 60).toString().padLeft(2, '0');
          final secs = (absDiff.inSeconds % 60).toString().padLeft(2, '0');
          final timerString = '$hours:$mins:$secs';

          final virtueText = kPrayerVirtues[moment] ?? '';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          prayerMomentIcon(moment),
                          color: accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'صلاة ${moment.nameAr}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            Text(
                              'وقت الأذان: ${formatPrayerTime12h(adjustedTime)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (virtueText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              virtueText,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.55,
                                color: onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.9),
                          HSVColor.fromColor(accent)
                              .withValue(
                                (HSVColor.fromColor(accent).value * 0.6).clamp(
                                  0.1,
                                  1.0,
                                ),
                              )
                              .toColor(),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPast ? 'مضي على الأذان' : 'متبقي على الأذان',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timerString,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'إقامة: $iqamahMins دقيقة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'إعدادات الأوقات والإقامة والتنبيه',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'تعديل وقت الأذان (دقائق):',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 22,
                                    ),
                                    color: accent,
                                    onPressed: () async {
                                      await userPrefs.setPrayerOffsetFor(
                                        moment.name,
                                        offset - 1,
                                      );
                                      ref
                                          .read(
                                            adhanNotificationVersionProvider
                                                .notifier,
                                          )
                                          .bump();
                                      if (prefs.hasLocation)
                                        unawaited(
                                          rescheduleAdhanNotifications(
                                            ref,
                                            prefs,
                                          ),
                                        );
                                    },
                                  ),
                                  Text(
                                    '${offset >= 0 ? "+$offset" : offset} دقيقة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 22,
                                    ),
                                    color: accent,
                                    onPressed: () async {
                                      await userPrefs.setPrayerOffsetFor(
                                        moment.name,
                                        offset + 1,
                                      );
                                      ref
                                          .read(
                                            adhanNotificationVersionProvider
                                                .notifier,
                                          )
                                          .bump();
                                      if (prefs.hasLocation)
                                        unawaited(
                                          rescheduleAdhanNotifications(
                                            ref,
                                            prefs,
                                          ),
                                        );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'مدة الإقامة في المسجد:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 22,
                                    ),
                                    color: accent,
                                    onPressed: () async {
                                      if (iqamahMins > 1) {
                                        await userPrefs.setIqamahMinutesFor(
                                          moment.name,
                                          iqamahMins - 1,
                                        );
                                        ref
                                            .read(
                                              adhanNotificationVersionProvider
                                                  .notifier,
                                            )
                                            .bump();
                                        if (prefs.hasLocation)
                                          unawaited(
                                            rescheduleAdhanNotifications(
                                              ref,
                                              prefs,
                                            ),
                                          );
                                      }
                                    },
                                  ),
                                  Text(
                                    '$iqamahMins دقيقة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 22,
                                    ),
                                    color: accent,
                                    onPressed: () async {
                                      if (iqamahMins < 60) {
                                        await userPrefs.setIqamahMinutesFor(
                                          moment.name,
                                          iqamahMins + 1,
                                        );
                                        ref
                                            .read(
                                              adhanNotificationVersionProvider
                                                  .notifier,
                                            )
                                            .bump();
                                        if (prefs.hasLocation)
                                          unawaited(
                                            rescheduleAdhanNotifications(
                                              ref,
                                              prefs,
                                            ),
                                          );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 12),

                          Text(
                            'تنبيه مبكر قبل الأذان:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final m in [5, 10, 15, 20, 30])
                                ChoiceChip(
                                  label: Text(
                                    '$m دقائق',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: preMins == m
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: preMins == m,
                                  selectedColor: accent.withValues(alpha: 0.2),
                                  onSelected: (_) async {
                                    await userPrefs.setPreAdhanMinutes(m);
                                    ref
                                        .read(
                                          adhanNotificationVersionProvider
                                              .notifier,
                                        )
                                        .bump();
                                    if (prefs.hasLocation)
                                      unawaited(
                                        rescheduleAdhanNotifications(
                                          ref,
                                          prefs,
                                        ),
                                      );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'الصوت والتنبيه',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: onSurface.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.record_voice_over_outlined,
                            color: accent,
                          ),
                          title: const Text(
                            'المؤذن المفصل لهذه الصلاة',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            currentVoice.label,
                            style: TextStyle(fontSize: 11.5, color: accent),
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () {
                            showVoicePickerForMoment(
                              context,
                              ref,
                              prefs,
                              moment,
                            );
                          },
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نمط التنبيه للصلاة:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _modeChip(
                                    context,
                                    ref,
                                    prefs,
                                    moment,
                                    'adhan',
                                    '🔊 أذان',
                                    currentMode,
                                  ),
                                  const SizedBox(width: 6),
                                  _modeChip(
                                    context,
                                    ref,
                                    prefs,
                                    moment,
                                    'tone',
                                    '🔔 نغمة',
                                    currentMode,
                                  ),
                                  const SizedBox(width: 6),
                                  _modeChip(
                                    context,
                                    ref,
                                    prefs,
                                    moment,
                                    'silent',
                                    '🔕 صامت',
                                    currentMode,
                                  ),
                                  const SizedBox(width: 6),
                                  _modeChip(
                                    context,
                                    ref,
                                    prefs,
                                    moment,
                                    'off',
                                    '🚫 إيقاف',
                                    currentMode,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // بطلب صاحب المشروع: أُزيلت بطاقة الأوقات المستحبة/الكراهة
                  // الثابتة من تفاصيل الفجر بالكامل — الاتفاق إنه أوقات
                  // كهذي تظهر بشاشة الصلاة فقط لمّا يجي وقتها فعلاً (زي
                  // `PrayerCountdownCard` أعلى الشاشة)، لا كقائمة ثابتة دوماً.
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: AppPrimaryButton(
                      label: 'تم الحفظ',
                      color: accent,
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _modeChip(
  BuildContext context,
  WidgetRef ref,
  LocationPrefs prefs,
  PrayerMoment moment,
  String modeKey,
  String label,
  String currentMode,
) {
  final notifPrefs = ref.watch(adhanNotificationPrefsProvider);
  final isSelected = currentMode == modeKey;
  final accent = themeAccent(context);

  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await notifPrefs.setNotificationModeFor(moment, modeKey);
        ref.read(adhanNotificationVersionProvider.notifier).bump();
        if (prefs.hasLocation) await rescheduleAdhanNotifications(ref, prefs);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accent : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? accent
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ),
  );
}
