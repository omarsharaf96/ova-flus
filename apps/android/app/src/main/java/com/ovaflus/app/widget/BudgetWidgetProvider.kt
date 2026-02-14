package com.ovaflus.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.ovaflus.app.R

class BudgetWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_budget)
            views.setTextViewText(R.id.widget_title, "Budget Overview")
            views.setTextViewText(R.id.widget_amount, "Loading...")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
