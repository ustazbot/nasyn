package com.nasyn.posespike.pose

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facedetector.FaceDetector
import com.google.mediapipe.tasks.vision.facedetector.FaceDetectorResult
import java.util.concurrent.ConcurrentHashMap

// Spike v3: BlazeFace short-range bounding-box — model sama yang
// divalidasi pada spike desktop (SPIKE-RESULT.md).
class FaceDetectorHelper(
    context: Context,
    private val listener: Listener,
) {
    interface Listener {
        // signal null = tiada muka dikesan (itu sendiri data — fasa tahan sujud)
        fun onResult(signal: BboxSignal?, inferenceTimeMs: Long)
        fun onError(message: String)
    }

    private var faceDetector: FaceDetector? = null

    init {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("blaze_face_short_range.tflite")
            .build()

        val options = FaceDetector.FaceDetectorOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            // Desktop: false positive (bbox pada baju) conf <0.5,
            // detection sebenar conf 0.58+ — 0.5 menapis kebanyakannya
            .setMinDetectionConfidence(0.5f)
            .setResultListener(::handleResult)
            .setErrorListener { error -> listener.onError(error.message ?: "unknown MediaPipe error") }
            .build()

        faceDetector = FaceDetector.createFromOptions(context, options)
    }

    // LIVE_STREAM mode is asynchronous: CameraX keeps calling detectAsync (~every 33ms) even
    // while a previous frame's inference is still running. Track submit time per frame
    // timestamp so each result is matched back to the call that produced it (see
    // PoseLandmarkerHelper history for the corruption this prevents).
    private val frameSubmitTimes = ConcurrentHashMap<Long, Long>()

    fun detectAsync(bitmap: Bitmap, rotationDegrees: Int, isFrontCamera: Boolean, frameTimeMs: Long) {
        frameSubmitTimes[frameTimeMs] = SystemClock.uptimeMillis()
        val matrix = Matrix().apply {
            postRotate(rotationDegrees.toFloat())
            if (isFrontCamera) postScale(-1f, 1f, bitmap.width.toFloat(), bitmap.height.toFloat())
        }
        val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        val mpImage = BitmapImageBuilder(rotated).build()
        faceDetector?.detectAsync(mpImage, frameTimeMs)
    }

    private fun handleResult(result: FaceDetectorResult, image: MPImage) {
        val submitTime = frameSubmitTimes.remove(result.timestampMs())
        val inferenceTimeMs = if (submitTime != null) SystemClock.uptimeMillis() - submitTime else 0L

        // Ambil bbox terbesar — pengguna solat ialah yang paling dekat lens
        val detection = result.detections().maxByOrNull {
            it.boundingBox().width() * it.boundingBox().height()
        }
        val signal = detection?.let {
            val box = it.boundingBox()
            BboxSignal(
                left = box.left / image.width,
                top = box.top / image.height,
                right = box.right / image.width,
                bottom = box.bottom / image.height,
                conf = it.categories().firstOrNull()?.score() ?: 0f,
            )
        }
        listener.onResult(signal, inferenceTimeMs)
    }

    fun close() {
        faceDetector?.close()
        faceDetector = null
        frameSubmitTimes.clear()
    }
}
