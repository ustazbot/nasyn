package com.nasyn.posespike.ui

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.View
import com.nasyn.posespike.pose.PoseClassification
import com.nasyn.posespike.pose.PoseLandmarks

class PoseOverlayView(context: Context) : View(context) {

    private val dotPaint = Paint().apply {
        color = Color.GREEN
        style = Paint.Style.FILL
    }
    private val textPaint = Paint().apply {
        color = Color.WHITE
        textSize = 48f
        isFakeBoldText = true
    }
    private val textBackgroundPaint = Paint().apply {
        color = Color.argb(180, 0, 0, 0)
        style = Paint.Style.FILL
    }

    private var classification: PoseClassification? = null
    private var landmarks: PoseLandmarks? = null
    private var inferenceTimeMs: Long = 0
    private var debugInfo: String = ""

    fun update(
        classification: PoseClassification,
        landmarks: PoseLandmarks?,
        inferenceTimeMs: Long,
        debugInfo: String = "",
    ) {
        this.classification = classification
        this.landmarks = landmarks
        this.inferenceTimeMs = inferenceTimeMs
        this.debugInfo = debugInfo
        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        landmarks?.let { lm ->
            val points = listOf(lm.nose, lm.leftEar, lm.rightEar, lm.leftShoulder, lm.rightShoulder)
            for (point in points) {
                canvas.drawCircle(point.x * width, point.y * height, 12f, dotPaint)
            }
        }

        val result = classification ?: return
        val lines = listOf(
            "Pose: ${result.poseClass}",
            "Confidence: ${result.confidence}%",
            "Latency: ${inferenceTimeMs}ms",
            debugInfo,
        )
        canvas.drawRect(20f, 60f, 620f, 320f, textBackgroundPaint)
        lines.forEachIndexed { index, line ->
            canvas.drawText(line, 40f, 120f + index * 60f, textPaint)
        }
    }
}
