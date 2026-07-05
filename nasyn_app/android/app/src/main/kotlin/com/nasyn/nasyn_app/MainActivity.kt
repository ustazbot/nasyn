package com.nasyn.nasyn_app

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import com.nasyn.nasyn_app.vision.VisionSujudCamera
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var visionCamera: VisionSujudCamera? = null
    private var visionEventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupCosuIfDeviceOwner()
    }

    // Bila app jadi device owner (dpm set-device-owner semasa provisioning):
    // 1. Whitelist lock task — startLockTask() jadi full lock tanpa dialog pin
    // 2. NASYN jadi HOME kekal — auto-relaunch lepas reboot
    // Idempotent & senyap bila bukan device owner (dev/emulator biasa).
    private fun setupCosuIfDeviceOwner() {
        try {
            val dpm =
                getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            if (!dpm.isDeviceOwnerApp(packageName)) return
            val admin = ComponentName(this, NasynDeviceAdminReceiver::class.java)
            dpm.setLockTaskPackages(admin, arrayOf(packageName))
            val homeFilter = IntentFilter(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addCategory(Intent.CATEGORY_DEFAULT)
            }
            dpm.addPersistentPreferredActivity(
                admin,
                homeFilter,
                ComponentName(this, MainActivity::class.java),
            )
            // Vision Mode: auto-grant CAMERA — kiosk tak boleh tunjuk
            // dialog permission (tiada siapa nak tekan Allow)
            dpm.setPermissionGrantState(
                admin,
                packageName,
                android.Manifest.permission.CAMERA,
                DevicePolicyManager.PERMISSION_GRANT_STATE_GRANTED,
            )
        } catch (e: Exception) {
            // Kegagalan setup kiosk tak boleh block app — log sahaja
            android.util.Log.w("NASYN", "COSU setup gagal: $e")
        }
    }

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

        // Vision Mode (§8.13): pengesahan SUJUD sahaja. Gagal = false/senyap,
        // Guided Mode berjalan tanpa vision.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nasyn/vision")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> result.success(
                        try {
                            if (checkSelfPermission(android.Manifest.permission.CAMERA) ==
                                android.content.pm.PackageManager.PERMISSION_GRANTED
                            ) {
                                if (visionCamera == null) {
                                    visionCamera = VisionSujudCamera(this, this) { sujud ->
                                        visionEventSink?.success(sujud)
                                    }
                                }
                                visionCamera?.start()
                                true
                            } else {
                                false
                            }
                        } catch (e: Exception) {
                            false
                        }
                    )
                    "stop" -> result.success(
                        try {
                            visionCamera?.stop()
                            true
                        } catch (e: Exception) {
                            false
                        }
                    )
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "nasyn/vision/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    visionEventSink = sink
                }

                override fun onCancel(args: Any?) {
                    visionEventSink = null
                }
            })
    }

    override fun onDestroy() {
        visionCamera?.stop()
        super.onDestroy()
    }
}
