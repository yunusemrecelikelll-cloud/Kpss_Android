package com.kpsshazirlik.kpss_telefon

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * "Günün Kilit Ekranı Kodu" ana ekran widget'ı.
 *
 * Flutter tarafı (`lib/services/lock_widget_service.dart`) her uygulama
 * açılışında `HomeWidget.saveWidgetData` ile aşağıdaki anahtarları yazar ve
 * `HomeWidget.updateWidget(androidName: "LockWidgetProvider")` çağırarak bu
 * provider'ın yeniden çizilmesini tetikler:
 *   - lock_widget_eyebrow  → "Ders • Konu"
 *   - lock_widget_text     → asıl akılda kalıcı kodlama metni
 *
 * Sınıf adı `LockWidgetService.androidWidgetName` ile ve
 * AndroidManifest.xml'deki <receiver android:name> ile birebir aynı olmalı.
 */
class LockWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.lock_widget_layout).apply {
                val eyebrow = widgetData.getString("lock_widget_eyebrow", null)
                val text = widgetData.getString("lock_widget_text", null)

                setTextViewText(
                    R.id.lock_widget_eyebrow,
                    eyebrow ?: "KPSS Hazırlık",
                )
                setTextViewText(
                    R.id.lock_widget_text,
                    text ?: "Bugünün kodunu görmek için uygulamayı bir kez aç.",
                )

                // Widget'a dokununca uygulamayı aç.
                val pendingIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.lock_widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
