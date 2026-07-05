package com.nasyn.posespike.ui

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.View
import com.nasyn.posespike.pose.BboxSignal
import com.nasyn.posespike.pose.PoseClassification

class PoseOverlayView(context: Context) : View(context) {

    private val boxPaint = Paint().apply {
        color = Color.GREEN
        style = Paint.Style.STROKE
        strokeWidth = 6f
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
    private var signal: BboxSignal? = null
    private var inferenceTimeMs: Long = 0
    private var debugInfo: String = ""

    fun update(
        classification: PoseClassification,
        signal: BboxSignal?,
        inferenceTimeMs: Long,
        debugInfo: String = "",
    ) {
        this.classification = classification
        this.signal = signal
        this.inferenceTimeMs = inferenceTimeMs
        this.debugInfo = debugInfo
        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        signal?.let { s ->
            canvas.drawRect(
                s.left * width, s.top * height, s.right * width, s.bottom * height, boxPaint,
            )
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
