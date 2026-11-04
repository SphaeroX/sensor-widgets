package io.github.sphaerox.influx_sensor_widgets.alerts

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.github.sphaerox.influx_sensor_widgets.MainActivity
import io.github.sphaerox.influx_sensor_widgets.R
import io.github.sphaerox.influx_sensor_widgets.l10n.WidgetTexts
import io.github.sphaerox.influx_sensor_widgets.model.WidgetDefinition

/** Posts threshold notifications; silently skips them while the permission is missing. */
object AlertNotifier {
    const val CHANNEL_ID = "threshold_alerts"

    fun notify(
        context: Context,
        widget: WidgetDefinition,
        hit: AlertHit,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.alert_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = context.getString(R.string.alert_channel_description)
            },
        )
        val openApp =
            PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        val notification =
            Notification
                .Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_alert)
                .setContentTitle(AlertMessage.title(widget))
                .setContentText(AlertMessage.body(widget, hit, WidgetTexts.of(context)))
                .setContentIntent(openApp)
                .setAutoCancel(true)
                .build()
        // One notification per widget and target: a new crossing replaces the old one.
        manager.notify("${widget.id}|${hit.rule.target}".hashCode(), notification)
    }
}
