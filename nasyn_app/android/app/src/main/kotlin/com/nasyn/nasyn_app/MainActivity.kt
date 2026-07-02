package com.nasyn.nasyn_app

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Basic screen pinning (bukan Device Owner). Semua method return
        // false bila gagal — pinning gagal TIDAK boleh block sesi solat.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nasyn/kiosk")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startPinning" -> result.success(
                        try {
                            startLockTask()
                            true
                        } catch (e: Exception) {
                            false
                        }
                    )
                    "stopPinning" -> result.success(
                        try {
                            stopLockTask()
                            true
                        } catch (e: Exception) {
                            false
                        }
                    )
                    "isPinned" -> result.success(
                        try {
                            val am =
                                getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
                        } catch (e: Exception) {
                            false
                        }
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
