package com.nasyn.nasyn_app.vision

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.util.Size
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facedetector.FaceDetector
import com.google.mediapipe.tasks.vision.facedetector.FaceDetectorResult
import com.google.mediapipe.framework.image.MPImage

// Kamera depan tanpa preview + BlazeFace bbox -> SujudDetector.
// Dipasang/dihenti per sesi solat sahaja (privasi + bateri).
// Semua kegagalan senyap — vision tak boleh block sesi solat.
class VisionSujudCamera(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val onSujudChanged: (Boolean) -> Unit,
) {
    private var faceDetector: FaceDetector? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private val sujudDetector = SujudDetector()
    private var lastSujud: Boolean? = null

    fun start() {
        if (faceDetector != null) return // idempotent
        try {
            val options = FaceDetector.FaceDetectorOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetPath("blaze_face_short_range.tflite")
                        .build()
                )
                .setRunningMode(RunningMode.LIVE_STREAM)
                // Spike: false positive conf <0.5, detection sebenar 0.58+
                .setMinDetectionConfidence(0.5f)
                .setResultListener(::handleResult)
                .setErrorListener { }
                .build()
            faceDetector = FaceDetector.createFromOptions(context, options)

            val providerFuture = ProcessCameraProvider.getInstance(context)
            providerFuture.addListener({
                try {
                    val provider = providerFuture.get()
                    cameraProvider = provider
                    val analysis = ImageAnalysis.Builder()
                        .setTargetResolution(Size(480, 640))
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                        .build()
                    analysis.setAnalyzer(ContextCompat.getMainExecutor(context)) { proxy ->
                        val bitmap = Bitmap.createBitmap(
                            proxy.width, proxy.height, Bitmap.Config.ARGB_8888,
                        )
                        bitmap.copyPixelsFromBuffer(proxy.planes[0].buffer)
                        val rotation = proxy.imageInfo.rotationDegrees
                        val frameTimeMs = proxy.imageInfo.timestamp / 1_000_000
                        proxy.close()

                        val matrix = Matrix().apply {
                            postRotate(rotation.toFloat())
                            postScale(-1f, 1f, bitmap.width / 2f, bitmap.height / 2f)
                        }
                        val rotated = Bitmap.createBitmap(
                            bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true,
                        )
                        faceDetector?.detectAsync(
                            BitmapImageBuilder(rotated).build(), frameTimeMs,
                        )
                    }
                    provider.unbindAll()
                    provider.bindToLifecycle(
                        lifecycleOwner, CameraSelector.DEFAULT_FRONT_CAMERA, analysis,
                    )
                } catch (e: Exception) {
                    android.util.Log.w("NASYN", "Vision camera gagal bind: $e")
                }
            }, ContextCompat.getMainExecutor(context))
        } catch (e: Exception) {
            android.util.Log.w("NASYN", "Vision init gagal: $e")
            faceDetector = null
        }
    }

    private fun handleResult(result: FaceDetectorResult, image: MPImage) {
        val detection = result.detections().maxByOrNull {
            it.boundingBox().width() * it.boundingBox().height()
        }
        val ratio = detection?.let {
            val box = it.boundingBox()
            (box.width() * box.height()) / (image.width * image.height).toFloat()
        }
        val sujud = sujudDetector.update(ratio)
        if (sujud != lastSujud) {
            lastSujud = sujud
            ContextCompat.getMainExecutor(context).execute { onSujudChanged(sujud) }
        }
    }

    fun stop() {
        try {
            cameraProvider?.unbindAll()
        } catch (_: Exception) {}
        cameraProvider = null
        faceDetector?.close()
        faceDetector = null
        lastSujud = null
    }
}
