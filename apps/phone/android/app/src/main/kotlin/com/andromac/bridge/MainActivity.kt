package com.andromac.bridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Main Android application activity hosting the Flutter UI.
 * Binds [AndroidHostApiImpl] and monitors dynamic system battery broadcasts.
 */
class MainActivity : FlutterActivity() {

    private var batteryReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize AndroidHostApi Pigeon / MethodChannel bindings
        AndroidHostApiImpl.setup(flutterEngine.dartExecutor.binaryMessenger, applicationContext)

        // Register dynamic battery status broadcast receiver
        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                    val rawLevel = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    val level = if (rawLevel >= 0 && scale > 0) (rawLevel * 100) / scale else 100

                    val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                    val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                            status == BatteryManager.BATTERY_STATUS_FULL

                    AndroidHostApiImpl.flutterApi?.onBatteryChanged(level, isCharging)
                }
            }
        }

        registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    }

    override fun onDestroy() {
        batteryReceiver?.let { unregisterReceiver(it) }
        batteryReceiver = null
        super.onDestroy()
    }
}
