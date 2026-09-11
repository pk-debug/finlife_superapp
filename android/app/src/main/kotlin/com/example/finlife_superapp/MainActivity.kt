package com.example.finlife_superapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val deviceInfoChannel = "com.finlife.superapp/device_info"
    private val batteryEventsChannel = "com.finlife.superapp/battery_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceInfoChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getDeviceInfo") {
                    result.success(
                        mapOf(
                            "batteryLevel" to getBatteryLevel(),
                            "androidId" to getAndroidId(),
                            "installUuid" to getInstallUuid(),
                        ),
                    )
                } else {
                    result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, batteryEventsChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var batteryReceiver: BroadcastReceiver? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            getBatteryLevel(intent)?.let { level ->
                                events?.success(level)
                            }
                        }
                    }
                    batteryReceiver = receiver
                    registerReceiver(receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                }

                override fun onCancel(arguments: Any?) {
                    batteryReceiver?.let(::unregisterReceiver)
                    batteryReceiver = null
                }
            })
    }

    private fun getBatteryLevel(): Int? {
        val batteryStatus: Intent? = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        )
        return getBatteryLevel(batteryStatus)
    }

    private fun getBatteryLevel(batteryStatus: Intent?): Int? {
        val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

        return if (level >= 0 && scale > 0) level * 100 / scale else null
    }

    private fun getAndroidId(): String? = Settings.Secure.getString(
        contentResolver,
        Settings.Secure.ANDROID_ID,
    )

    private fun getInstallUuid(): String {
        val preferences = getSharedPreferences("device_info", Context.MODE_PRIVATE)
        val existingUuid = preferences.getString("install_uuid", null)
        if (existingUuid != null) return existingUuid

        return UUID.randomUUID().toString().also { newUuid ->
            preferences.edit().putString("install_uuid", newUuid).apply()
        }
    }
}
