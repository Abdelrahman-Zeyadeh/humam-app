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

    val fajrMs = widgetData.getLong("time_fajr_ms", 0L)
    val sunriseMs = widgetData.getLong("time_sunrise_ms", 0L)
    val dhuhrMs = widgetData.getLong("time_dhuhr_ms", 0L)
    val asrMs = widgetData.getLong("time_asr_ms", 0L)
    val maghribMs = widgetData.getLong("time_maghrib_ms", 0L)
    val ishaMs = widgetData.getLong("time_isha_ms", 0L)
    val tomorrowFajrMs = widgetData.getLong("time_tomorrow_fajr_ms", 0L)

    val now = System.currentTimeMillis()

    var prayerName = widgetData.getString("next_prayer_name", "الفجر") ?: "الفجر"
    var prayerTime = widgetData.getString("next_prayer_time", timeFajr) ?: timeFajr
    var activeMoment = widgetData.getString("active_moment", "fajr") ?: "fajr"
    var nextTargetEpochMs = widgetData.getLong("next_prayer_target_epoch", 0L)

    if (fajrMs > 0 && sunriseMs > 0 && dhuhrMs > 0 && asrMs > 0 && maghribMs > 0 && ishaMs > 0) {
      if (now < fajrMs) {
        prayerName = "الفجر"
        prayerTime = timeFajr
        activeMoment = "fajr"
        nextTargetEpochMs = fajrMs
      } else if (now < sunriseMs) {
        prayerName = "الشروق"
        prayerTime = timeSunrise
        activeMoment = "fajr"
        nextTargetEpochMs = sunriseMs
      } else if (now < dhuhrMs) {
        prayerName = "الظهر"
        prayerTime = timeDhuhr
        activeMoment = "sunrise"
        nextTargetEpochMs = dhuhrMs
      } else if (now < asrMs) {
        prayerName = "العصر"
        prayerTime = timeAsr
        activeMoment = "dhuhr"
        nextTargetEpochMs = asrMs
      } else if (now < maghribMs) {
        prayerName = "المغرب"
        prayerTime = timeMaghrib
        activeMoment = "asr"
        nextTargetEpochMs = maghribMs
      } else if (now < ishaMs) {
        prayerName = "العشاء"
        prayerTime = timeIsha
        activeMoment = "maghrib"
        nextTargetEpochMs = ishaMs
      } else {
        prayerName = "الفجر"
        prayerTime = timeFajr
        activeMoment = "isha"
        nextTargetEpochMs = if (tomorrowFajrMs > now) tomorrowFajrMs else (fajrMs + 24 * 3600 * 1000L)
      }
    }

    val activeColor = Color.parseColor("#E7D2A0")
    val inactiveColor = Color.parseColor("#80FFFFFF")
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
          setChronometer(R.id.prayer_bar_countdown, base, "%s", true)
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

        // تلوين الصلاة النشطة
        setTextColor(R.id.pb_name_fajr, if (activeMoment == "fajr") activeColor else inactiveColor)
        setTextColor(R.id.pb_time_fajr, if (activeMoment == "fajr") activeColor else inactiveColor)

        setTextColor(R.id.pb_name_sunrise, if (activeMoment == "sunrise") activeColor else inactiveColor)
        setTextColor(R.id.pb_time_sunrise, if (activeMoment == "sunrise") activeColor else inactiveColor)

        setTextColor(R.id.pb_name_dhuhr, if (activeMoment == "dhuhr") activeColor else inactiveColor)
        setTextColor(R.id.pb_time_dhuhr, if (activeMoment == "dhuhr") activeColor else inactiveColor)

        setTextColor(R.id.pb_name_asr, if (activeMoment == "asr") activeColor else inactiveColor)
        setTextColor(R.id.pb_time_asr, if (activeMoment == "asr") activeColor else inactiveColor)

        setTextColor(R.id.pb_name_maghrib, if (activeMoment == "maghrib") activeColor else inactiveColor)
        setTextColor(R.id.pb_time_maghrib, if (activeMoment == "maghrib") activeColor else inactiveColor)

        setTextColor(R.id.pb_name_isha, if (activeMoment == "isha") activeColor else inactiveColor)
        setTextColor(R.id.pb_time_isha, if (activeMoment == "isha") activeColor else inactiveColor)

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
}
