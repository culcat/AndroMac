package com.andromac.bridge

import android.app.NotificationManager
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Interface representing callbacks into Flutter (AndroidFlutterApi).
 */
interface AndroidFlutterCallback {
    fun onNotificationPosted(notification: Map<String, Any>)
    fun onNotificationDismissed(key: String)
    fun onSmsReceived(sms: Map<String, Any>)
    fun onClipboardCaptured(text: String)
    fun onBatteryChanged(level: Int, isCharging: Boolean)
}

/**
 * Native implementation of AndroidHostApi interacting with platform services
 * (telephony, clipboard, battery manager, system settings).
 */
class AndroidHostApiImpl(private val context: Context) {

    companion object {
        const val CHANNEL_NAME = "com.andromac.bridge/platform"
        var flutterApi: AndroidFlutterCallback? = null

        fun setup(binaryMessenger: BinaryMessenger, context: Context): AndroidHostApiImpl {
            val api = AndroidHostApiImpl(context)
            val channel = MethodChannel(binaryMessenger, CHANNEL_NAME)

            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundService" -> {
                        api.startForegroundService()
                        result.success(null)
                    }
                    "stopForegroundService" -> {
                        api.stopForegroundService()
                        result.success(null)
                    }
                    "sendSms" -> {
                        val address = call.argument<String>("address") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val simSlot = call.argument<Int>("simSlot") ?: 0
                        val clientMessageId = call.argument<String>("clientMessageId")
                        val success = api.sendSms(address, body, simSlot, clientMessageId)
                        result.success(success)
                    }
                    "copyToClipboard" -> {
                        val text = call.argument<String>("text") ?: ""
                        api.copyToClipboard(text)
                        result.success(null)
                    }
                    "openNotificationListenerSettings" -> {
                        api.openNotificationListenerSettings()
                        result.success(null)
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        api.requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }
                    "getBatteryStatus" -> {
                        val status = api.getBatteryStatus()
                        result.success(status)
                    }
                    else -> result.notImplemented()
                }
            }

            flutterApi = object : AndroidFlutterCallback {
                override fun onNotificationPosted(notification: Map<String, Any>) {
                    channel.invokeMethod("onNotificationPosted", notification)
                }
                override fun onNotificationDismissed(key: String) {
                    channel.invokeMethod("onNotificationDismissed", key)
                }
                override fun onSmsReceived(sms: Map<String, Any>) {
                    channel.invokeMethod("onSmsReceived", sms)
                }
                override fun onClipboardCaptured(text: String) {
                    channel.invokeMethod("onClipboardCaptured", text)
                }
                override fun onBatteryChanged(level: Int, isCharging: Boolean) {
                    channel.invokeMethod("onBatteryChanged", mapOf("level" to level, "isCharging" to isCharging))
                }
            }

            return api
        }
    }

    fun startForegroundService() {
        val intent = Intent(context, BridgeForegroundService::class.java).apply {
            action = BridgeForegroundService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    fun stopForegroundService() {
        val intent = Intent(context, BridgeForegroundService::class.java).apply {
            action = BridgeForegroundService.ACTION_STOP
        }
        context.stopService(intent)
    }

    fun sendSms(address: String, body: String, simSlot: Int, clientMessageId: String?): Boolean {
        if (address.isBlank() || body.isBlank()) return false

        return try {
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val subManager = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as? SubscriptionManager
                val subInfo = subManager?.activeSubscriptionInfoList?.getOrNull(simSlot)
                if (subInfo != null) {
                    context.getSystemService(SmsManager::class.java).createForSubscriptionId(subInfo.subscriptionId)
                } else {
                    context.getSystemService(SmsManager::class.java)
                }
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            val parts = smsManager.divideMessage(body)
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(address, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(address, null, body, null, null)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    fun copyToClipboard(text: String) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("AndroMac", text)
        clipboard.setPrimaryClip(clip)
    }

    fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(context.packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            }
        }
    }

    fun getBatteryStatus(): Map<String, Any> {
        val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = context.registerReceiver(null, ifilter)

        val level = batteryStatus?.let { intent ->
            val rawLevel = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            if (rawLevel >= 0 && scale > 0) (rawLevel * 100) / scale else 100
        } ?: 100

        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        val isDnd = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val filter = notificationManager?.currentInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
            filter != NotificationManager.INTERRUPTION_FILTER_ALL
        } else false

        return mapOf(
            "level" to level,
            "isCharging" to isCharging,
            "isDnd" to isDnd
        )
    }
}
