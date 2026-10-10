package com.andromac.bridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Persistent Foreground Service maintaining local network connectivity,
 * mTLS WebSockets, and event dispatching.
 * Hosts a headless [FlutterEngine] running `backgroundMain`.
 */
class BridgeForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "andromac_foreground_service"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.andromac.bridge.START_SERVICE"
        const val ACTION_STOP = "com.andromac.bridge.STOP_SERVICE"

        var isRunning: Boolean = false
            private set
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var backgroundEngine: FlutterEngine? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        acquireWakeLock()
        startForegroundWithNotification()
        initializeBackgroundEngine()

        isRunning = true
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AndroMac Connection Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps connection alive between Android and macOS"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AndroMac")
            .setContentText("Connected and monitoring local sync")
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun initializeBackgroundEngine() {
        if (backgroundEngine == null) {
            val app = applicationContext
            val flutterLoader = FlutterInjector.instance().flutterLoader()
            flutterLoader.startInitialization(app)
            flutterLoader.ensureInitializationComplete(app, null)

            backgroundEngine = FlutterEngine(app).apply {
                val callback = DartExecutor.DartEntrypoint(
                    flutterLoader.findAppBundlePath(),
                    "backgroundMain"
                )
                dartExecutor.executeDartEntrypoint(callback)
            }
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "AndroMac::ForegroundServiceWakeLock"
            ).apply {
                acquire(24 * 60 * 60 * 1000L) // Safe 24-hour upper bound
            }
        }
    }

    override fun onDestroy() {
        isRunning = false
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null

        backgroundEngine?.destroy()
        backgroundEngine = null

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
