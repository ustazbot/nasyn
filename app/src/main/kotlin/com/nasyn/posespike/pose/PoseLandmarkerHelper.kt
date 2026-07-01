package com.nasyn.posespike.pose

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

class PoseLandmarkerHelper(
    context: Context,
    private val listener: Listener,
) {
    interface Listener {
        fun onResult(result: PoseLandmarkerResult, inferenceTimeMs: Long)
        fun onError(message: String)
    }

    private var poseLandmarker: PoseLandmarker? = null

    init {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("pose_landmarker_lite.task")
            .build()

        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumPoses(1)
            .setMinPoseDetectionConfidence(0.5f)
            .setMinPosePresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setResultListener(::handleResult)
            .setErrorListener { error -> listener.onError(error.message ?: "unknown MediaPipe error") }
            .build()

        poseLandmarker = PoseLandmarker.createFromOptions(context, options)
    }

    private var lastFrameStartMs = 0L

    fun detectAsync(bitmap: Bitmap, rotationDegrees: Int, isFrontCamera: Boolean, frameTimeMs: Long) {
        lastFrameStartMs = SystemClock.uptimeMillis()
        val matrix = Matrix().apply {
            postRotate(rotationDegrees.toFloat())
            if (isFrontCamera) postScale(-1f, 1f, bitmap.width.toFloat(), bitmap.height.toFloat())
        }
        val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        val mpImage = BitmapImageBuilder(rotated).build()
        poseLandmarker?.detectAsync(mpImage, frameTimeMs)
    }

    private fun handleResult(result: PoseLandmarkerResult, image: MPImage) {
        val inferenceTimeMs = SystemClock.uptimeMillis() - lastFrameStartMs
        listener.onResult(result, inferenceTimeMs)
    }

    fun close() {
        poseLandmarker?.close()
        poseLandmarker = null
    }
}
