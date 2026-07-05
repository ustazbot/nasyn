package com.nasyn.posespike.tally

import android.content.Context
import android.os.SystemClock
import com.nasyn.posespike.pose.BboxSignal
import com.nasyn.posespike.pose.PoseClassification
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter

// Log berterusan SETIAP frame (macam burst.py spike desktop) — analisis
// pemisahan tak bergantung pada tekan butang tally. ~30fps, jadi guna
// BufferedWriter kekal terbuka + flush berkala, bukan appendText per frame.
class FrameLogger(context: Context) {

    private val logFile = File(context.getExternalFilesDir(null), "pose_spike_v3_frames.csv")
    private val writer: BufferedWriter
    private var linesSinceFlush = 0

    init {
        val isNew = !logFile.exists()
        writer = BufferedWriter(FileWriter(logFile, true))
        if (isNew) {
            writer.write("uptimeMs,detected,ratio,centerY,detConf,predictedClass,confidence,latencyMs\n")
        }
    }

    fun log(signal: BboxSignal?, classification: PoseClassification, inferenceTimeMs: Long) {
        val signalCols = signal?.let { "true,${it.ratio},${it.centerY},${it.conf}" } ?: "false,,,"
        writer.write(
            "${SystemClock.uptimeMillis()},$signalCols," +
                "${classification.poseClass},${classification.confidence},$inferenceTimeMs\n"
        )
        if (++linesSinceFlush >= 30) {
            writer.flush()
            linesSinceFlush = 0
        }
    }

    fun close() {
        writer.flush()
        writer.close()
    }
}
