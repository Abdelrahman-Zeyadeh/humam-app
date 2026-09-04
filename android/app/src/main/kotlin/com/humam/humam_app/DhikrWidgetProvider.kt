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

class DhikrWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    try {
      updateAllWidgets(context, appWidgetManager, appWidgetIds, widgetData)
    } catch (e: Exception) {
      android.util.Log.e("DhikrWidget", "onUpdate failed", e)
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
        val thisAppWidget = ComponentName(context, DhikrWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)
        val data = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        updateAllWidgets(context, appWidgetManager, appWidgetIds, data)
      }
    } catch (e: Exception) {
      android.util.Log.e("DhikrWidget", "onReceive failed", e)
    }
  }

  private fun updateAllWidgets(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    if (appWidgetIds.isEmpty()) return

    val dhikrText = widgetData.getString("dhikr_text", null)?.takeIf { it.isNotBlank() }
        ?: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ"

    val backgroundRes = WidgetAccentColors.backgroundRes(widgetData.getString("accent_id", null))

    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.dhikr_widget).apply {
        setInt(R.id.dhikr_widget_root, "setBackgroundResource", backgroundRes)
        setTextViewText(R.id.dhikr_widget_text, dhikrText)

        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("humam://azkar"),
        )
        setOnClickPendingIntent(R.id.dhikr_widget_root, pendingIntent)
      }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
