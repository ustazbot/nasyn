package com.nasyn.posespike.tally

import android.content.Context
import com.nasyn.posespike.pose.BboxSignal
import com.nasyn.posespike.pose.PoseClass
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TallyLogger(context: Context) {

    // Spike v3: fail baru — jangan campur data landmark (v1/v2) dengan
    // data bbox proximity
    private val logFile: File =
        File(context.getExternalFilesDir(null), "pose_spike_v3_tally.csv")
    private val counts = mutableMapOf<PoseClass, Pair<Int, Int>>() // class -> (correct, incorrect)

    init {
        if (!logFile.exists()) {
            logFile.writeText(
                "timestamp,predictedClass,confidence,latencyMs,correct,ratio,centerY,detConf\n"
            )
        }
    }

    fun log(
        predictedClass: PoseClass,
        confidence: Int,
        inferenceTimeMs: Long,
        correct: Boolean,
        signal: BboxSignal? = null,
    ) {
        val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())
        // Signal mentah untuk analisis selepas sesi; kosong bila tiada
        // detection (itu sendiri data — fasa tahan sujud / kegagalan)
        val signalCols = signal?.let { "${it.ratio},${it.centerY},${it.conf}" } ?: ",,"
        logFile.appendText(
            "$timestamp,$predictedClass,$confidence,$inferenceTimeMs,$correct,$signalCols\n"
        )

        val (correctCount, incorrectCount) = counts.getOrDefault(predictedClass, 0 to 0)
        counts[predictedClass] = if (correct) {
            (correctCount + 1) to incorrectCount
        } else {
            correctCount to (incorrectCount + 1)
        }
    }

    fun summary(): String {
        return counts.entries.joinToString("\n") { (poseClass, tally) ->
            "$poseClass: ${tally.first} correct / ${tally.second} incorrect"
        }
    }

    fun logFilePath(): String = logFile.absolutePath
}
