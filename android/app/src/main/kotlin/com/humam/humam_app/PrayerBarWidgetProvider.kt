package com.humam.humam_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.SystemClock
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerBarWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    try {
      updateAllWidgets(context, appWidgetManager, appWidgetIds, widgetData)
    } catch (e: Exception) {
      android.util.Log.e("PrayerBarWidget", "onUpdate failed", e)
    }
  }

  override fun onReceive(context: Context, intent: Intent) {
    super.onReceive(context, intent)
    try {
      if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
          intent.action == Intent.ACTION_TIME_CHANGED ||
          intent.action == Intent.ACTION_TIMEZONE_CHANGED ||
          intent.action == Intent.ACTION_BOOT_COMPLETED) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val thisAppWidget = ComponentName(context, PrayerBarWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)
        val data = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        updateAllWidgets(context, appWidgetManager, appWidgetIds, data)
      }
    } catch (e: Exception) {
      android.util.Log.e("PrayerBarWidget", "onReceive failed", e)
    }
  }

  private fun updateAllWidgets(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    if (appWidgetIds.isEmpty()) return

    val hijriDate = widgetData.getString("hijri_date", null)?.takeIf { it.isNotBlank() }
        ?: "هُمَام"

    val timeFajr = widgetData.getString("time_fajr", "4:42") ?: "4:42"
    val timeSunrise = widgetData.getString("time_sunrise", "6:07") ?: "6:07"
    val timeDhuhr = widgetData.getString("time_dhuhr", "12:40") ?: "12:40"
    val timeAsr = widgetData.getString("time_asr", "4:17") ?: "4:17"
    val timeMaghrib = widgetData.getString("time_maghrib", "7:13") ?: "7:13"
    val timeIsha = widgetData.getString("time_isha", "8:38") ?: "8:38"

    val fajrMs = getLongOrInt(widgetData, "time_fajr_ms", 0L)
    val sunriseMs = getLongOrInt(widgetData, "time_sunrise_ms", 0L)
    val dhuhrMs = getLongOrInt(widgetData, "time_dhuhr_ms", 0L)
    val asrMs = getLongOrInt(widgetData, "time_asr_ms", 0L)
    val maghribMs = getLongOrInt(widgetData, "time_maghrib_ms", 0L)
    val ishaMs = getLongOrInt(widgetData, "time_isha_ms", 0L)
    val tomorrowFajrMs = getLongOrInt(widgetData, "time_tomorrow_fajr_ms", 0L)

    val iqamahFajrMin = getLongOrInt(widgetData, "iqamah_fajr_min", 20L).toInt()
    val iqamahDhuhrMin = getLongOrInt(widgetData, "iqamah_dhuhr_min", 15L).toInt()
    val iqamahAsrMin = getLongOrInt(widgetData, "iqamah_asr_min", 15L).toInt()
    val iqamahMaghribMin = getLongOrInt(widgetData, "iqamah_maghrib_min", 10L).toInt()
    val iqamahIshaMin = getLongOrInt(widgetData, "iqamah_isha_min", 15L).toInt()

    val fajrIqamahMs = if (fajrMs > 0 && iqamahFajrMin > 0) fajrMs + iqamahFajrMin * 60_000L else 0L
    val dhuhrIqamahMs = if (dhuhrMs > 0 && iqamahDhuhrMin > 0) dhuhrMs + iqamahDhuhrMin * 60_000L else 0L
    val asrIqamahMs = if (asrMs > 0 && iqamahAsrMin > 0) asrMs + iqamahAsrMin * 60_000L else 0L
    val maghribIqamahMs = if (maghribMs > 0 && iqamahMaghribMin > 0) maghribMs + iqamahMaghribMin * 60_000L else 0L
    val ishaIqamahMs = if (ishaMs > 0 && iqamahIshaMin > 0) ishaMs + iqamahIshaMin * 60_000L else 0L

    val now = System.currentTimeMillis()

    var prayerName = widgetData.getString("next_prayer_name", "الفجر") ?: "الفجر"
    var prayerTime = widgetData.getString("next_prayer_time", timeFajr) ?: timeFajr
    var activeMoment = widgetData.getString("active_moment", "fajr") ?: "fajr"
    var nextTargetEpochMs = getLongOrInt(widgetData, "next_prayer_target_epoch", 0L)
    var isInIqamah = widgetData.getBoolean("is_in_iqamah", false)

    if (fajrMs > 0 && sunriseMs > 0 && dhuhrMs > 0 && asrMs > 0 && maghribMs > 0 && ishaMs > 0) {
      if (now < fajrMs) {
        prayerName = "الفجر"
        prayerTime = timeFajr
        activeMoment = "fajr"
        nextTargetEpochMs = fajrMs
        isInIqamah = false
      } else if (fajrIqamahMs > fajrMs && now < fajrIqamahMs) {
        prayerName = "إقامة الفجر"
        prayerTime = formatClockTime(fajrIqamahMs).ifEmpty { timeFajr }
        activeMoment = "fajr"
        nextTargetEpochMs = fajrIqamahMs
        isInIqamah = true
      } else if (now < sunriseMs) {
        prayerName = "الشروق"
        prayerTime = timeSunrise
        activeMoment = "fajr"
        nextTargetEpochMs = sunriseMs
        isInIqamah = false
      } else if (now < dhuhrMs) {
        prayerName = "الظهر"
        prayerTime = timeDhuhr
        activeMoment = "sunrise"
        nextTargetEpochMs = dhuhrMs
        isInIqamah = false
      } else if (dhuhrIqamahMs > dhuhrMs && now < dhuhrIqamahMs) {
        prayerName = "إقامة الظهر"
        prayerTime = formatClockTime(dhuhrIqamahMs).ifEmpty { timeDhuhr }
        activeMoment = "dhuhr"
        nextTargetEpochMs = dhuhrIqamahMs
        isInIqamah = true
      } else if (now < asrMs) {
        prayerName = "العصر"
        prayerTime = timeAsr
        activeMoment = "dhuhr"
        nextTargetEpochMs = asrMs
        isInIqamah = false
      } else if (asrIqamahMs > asrMs && now < asrIqamahMs) {
        prayerName = "إقامة العصر"
        prayerTime = formatClockTime(asrIqamahMs).ifEmpty { timeAsr }
        activeMoment = "asr"
        nextTargetEpochMs = asrIqamahMs
        isInIqamah = true
      } else if (now < maghribMs) {
        prayerName = "المغرب"
        prayerTime = timeMaghrib
        activeMoment = "asr"
        nextTargetEpochMs = maghribMs
        isInIqamah = false
      } else if (maghribIqamahMs > maghribMs && now < maghribIqamahMs) {
        prayerName = "إقامة المغرب"
        prayerTime = formatClockTime(maghribIqamahMs).ifEmpty { timeMaghrib }
        activeMoment = "maghrib"
        nextTargetEpochMs = maghribIqamahMs
        isInIqamah = true
      } else if (now < ishaMs) {
        prayerName = "العشاء"
        prayerTime = timeIsha
        activeMoment = "maghrib"
        nextTargetEpochMs = ishaMs
        isInIqamah = false
      } else if (ishaIqamahMs > ishaMs && now < ishaIqamahMs) {
        prayerName = "إقامة العشاء"
        prayerTime = formatClockTime(ishaIqamahMs).ifEmpty { timeIsha }
        activeMoment = "isha"
        nextTargetEpochMs = ishaIqamahMs
        isInIqamah = true
      } else {
        prayerName = "الفجر"
        prayerTime = timeFajr
        activeMoment = "isha"
        nextTargetEpochMs = if (tomorrowFajrMs > now) tomorrowFajrMs else (fajrMs + 24 * 3600 * 1000L)
        isInIqamah = false
      }
    }

    val activeNameColor = Color.parseColor("#F5D78E")
    val activeTimeColor = Color.parseColor("#FFFFFF")
    val inactiveNameColor = Color.parseColor("#B3FFFFFF")
    val inactiveTimeColor = Color.parseColor("#CCFFFFFF")
    val activeBoxRes = R.drawable.humam_widget_prayer_active
    val inactiveBoxRes = R.drawable.humam_widget_prayer_inactive
    val backgroundRes = WidgetAccentColors.backgroundRes(widgetData.getString("accent_id", null))

    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.prayer_bar_widget).apply {
        setInt(R.id.prayer_bar_root, "setBackgroundResource", backgroundRes)
        setTextViewText(R.id.prayer_bar_hijri_date, hijriDate)
        setTextViewText(R.id.prayer_bar_name, prayerName)
        setTextViewText(R.id.prayer_bar_time, prayerTime)

        val remainingMs = nextTargetEpochMs - now
        if (remainingMs > 0) {
          val base = SystemClock.elapsedRealtime() + remainingMs
          val formatStr = if (isInIqamah) "للإقامة %s" else "متبقي %s"
          setChronometer(R.id.prayer_bar_countdown, base, formatStr, true)
          setChronometerCountDown(R.id.prayer_bar_countdown, true)
        } else {
          setChronometer(R.id.prayer_bar_countdown, SystemClock.elapsedRealtime(), "حان الآن", false)
        }

        // تعبئة الأوقات الستة
        setTextViewText(R.id.pb_time_fajr, timeFajr)
        setTextViewText(R.id.pb_time_sunrise, timeSunrise)
        setTextViewText(R.id.pb_time_dhuhr, timeDhuhr)
        setTextViewText(R.id.pb_time_asr, timeAsr)
        setTextViewText(R.id.pb_time_maghrib, timeMaghrib)
        setTextViewText(R.id.pb_time_isha, timeIsha)

        // تلوين وتمييز الصلاة النشطة ككبسولة مضيئة
        setInt(R.id.pb_box_fajr, "setBackgroundResource", if (activeMoment == "fajr") activeBoxRes else inactiveBoxRes)
        setTextColor(R.id.pb_name_fajr, if (activeMoment == "fajr") activeNameColor else inactiveNameColor)
        setTextColor(R.id.pb_time_fajr, if (activeMoment == "fajr") activeTimeColor else inactiveTimeColor)

        setInt(R.id.pb_box_sunrise, "setBackgroundResource", if (activeMoment == "sunrise") activeBoxRes else inactiveBoxRes)
        setTextColor(R.id.pb_name_sunrise, if (activeMoment == "sunrise") activeNameColor else inactiveNameColor)
        setTextColor(R.id.pb_time_sunrise, if (activeMoment == "sunrise") activeTimeColor else inactiveTimeColor)

        setInt(R.id.pb_box_dhuhr, "setBackgroundResource", if (activeMoment == "dhuhr") activeBoxRes else inactiveBoxRes)
        setTextColor(R.id.pb_name_dhuhr, if (activeMoment == "dhuhr") activeNameColor else inactiveNameColor)
        setTextColor(R.id.pb_time_dhuhr, if (activeMoment == "dhuhr") activeTimeColor else inactiveTimeColor)

        setInt(R.id.pb_box_asr, "setBackgroundResource", if (activeMoment == "asr") activeBoxRes else inactiveBoxRes)
        setTextColor(R.id.pb_name_asr, if (activeMoment == "asr") activeNameColor else inactiveNameColor)
        setTextColor(R.id.pb_time_asr, if (activeMoment == "asr") activeTimeColor else inactiveTimeColor)

        setInt(R.id.pb_box_maghrib, "setBackgroundResource", if (activeMoment == "maghrib") activeBoxRes else inactiveBoxRes)
        setTextColor(R.id.pb_name_maghrib, if (activeMoment == "maghrib") activeNameColor else inactiveNameColor)
        setTextColor(R.id.pb_time_maghrib, if (activeMoment == "maghrib") activeTimeColor else inactiveTimeColor)

        setInt(R.id.pb_box_isha, "setBackgroundResource", if (activeMoment == "isha") activeBoxRes else inactiveBoxRes)
        setTextColor(R.id.pb_name_isha, if (activeMoment == "isha") activeNameColor else inactiveNameColor)
        setTextColor(R.id.pb_time_isha, if (activeMoment == "isha") activeTimeColor else inactiveTimeColor)

        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("humam://prayer"),
        )
        setOnClickPendingIntent(R.id.prayer_bar_root, pendingIntent)
      }
      appWidgetManager.updateAppWidget(widgetId, views)
    }

    scheduleNextAlarm(context, nextTargetEpochMs)
  }

  private fun scheduleNextAlarm(context: Context, targetMs: Long) {
    if (targetMs <= System.currentTimeMillis()) return
    try {
      val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
      val intent = Intent(context, PrayerBarWidgetProvider::class.java).apply {
        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
      }
      val pendingIntent = PendingIntent.getBroadcast(
          context,
          9877,
          intent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      )
      alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetMs, pendingIntent)
    } catch (e: Exception) {
      android.util.Log.e("PrayerBarWidget", "scheduleNextAlarm failed", e)
    }
  }

  private fun getLongOrInt(prefs: SharedPreferences, key: String, defaultVal: Long): Long {
    return try {
      prefs.getLong(key, defaultVal)
    } catch (e: Exception) {
      try {
        prefs.getInt(key, defaultVal.toInt()).toLong()
      } catch (e2: Exception) {
        defaultVal
      }
    }
  }

  private fun formatClockTime(epochMs: Long): String {
    if (epochMs <= 0L) return ""
    return try {
      val sdf = SimpleDateFormat("h:mm", Locale.US)
      sdf.format(Date(epochMs))
    } catch (e: Exception) {
      ""
    }
  }
}
