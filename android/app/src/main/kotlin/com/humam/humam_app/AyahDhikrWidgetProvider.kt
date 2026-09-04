package com.humam.humam_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class AyahDhikrWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    try {
      updateAllWidgets(context, appWidgetManager, appWidgetIds, widgetData)
    } catch (e: Exception) {
      android.util.Log.e("AyahDhikrWidget", "onUpdate failed", e)
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
        val thisAppWidget = ComponentName(context, AyahDhikrWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)
        val data = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        updateAllWidgets(context, appWidgetManager, appWidgetIds, data)
      }
    } catch (e: Exception) {
      android.util.Log.e("AyahDhikrWidget", "onReceive failed", e)
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
    val ayahText = widgetData.getString("ayah_text", null)?.takeIf { it.isNotBlank() }
        ?: "﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾"
    val ayahRef = widgetData.getString("ayah_ref", null)?.takeIf { it.isNotBlank() }
        ?: "سورة الرعد · آية 28"
    val dhikrText = widgetData.getString("dhikr_text", null)?.takeIf { it.isNotBlank() }
        ?: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ"

    val backgroundRes = WidgetAccentColors.backgroundRes(widgetData.getString("accent_id", null))

    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.ayah_dhikr_widget).apply {
        setInt(R.id.ayah_dhikr_widget_root, "setBackgroundResource", backgroundRes)
        setTextViewText(R.id.widget_hijri_date, hijriDate)
        setTextViewText(R.id.widget_ayah_text, ayahText)
        setTextViewText(R.id.widget_ayah_ref, ayahRef)
        setTextViewText(R.id.widget_dhikr_text, dhikrText)

        // النقر على الآية يفتح المصحف
        val quranIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("humam://quran"),
        )
        setOnClickPendingIntent(R.id.widget_ayah_section, quranIntent)

        // النقر على الذكر يفتح المسبحة والأذكار
        val azkarIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("humam://azkar"),
        )
        setOnClickPendingIntent(R.id.widget_dhikr_section, azkarIntent)

        // النقر على الخلفية العامة يفتح التطبيق
        val rootIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("humam://widget"),
        )
        setOnClickPendingIntent(R.id.ayah_dhikr_widget_root, rootIntent)
      }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
