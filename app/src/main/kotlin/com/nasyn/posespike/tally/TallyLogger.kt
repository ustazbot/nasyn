package com.nasyn.posespike.tally

import android.content.Context
import com.nasyn.posespike.pose.PoseClass
import com.nasyn.posespike.pose.PoseLandmarks
import com.nasyn.posespike.pose.poseFeature
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TallyLogger(context: Context) {

    // Spike v2: fail baru — jangan campur data mounting lama (front, paras
    // dada) dengan mounting §8.13 (belakang, rendah hadap atas)
    private val logFile: File =
        File(context.getExternalFilesDir(null), "pose_spike_v2_tally.csv")
    private val counts = mutableMapOf<PoseClass, Pair<Int, Int>>() // class -> (correct, incorrect)

    init {
        if (!logFile.exists()) {
            logFile.writeText(
                "timestamp,predictedClass,confidence,latencyMs,correct,headY,logHeadSize\n"
            )
        }
    }

    fun log(
        predictedClass: PoseClass,
        confidence: Int,
        inferenceTimeMs: Long,
        correct: Boolean,
        landmarks: PoseLandmarks? = null,
    ) {
        val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())
        // Feature mentah untuk analisis pemisahan kelas selepas sesi;
        // kosong bila tiada landmark (itu sendiri data — kegagalan detect)
        val feature = landmarks?.let { poseFeature(it) }
        val featureCols = feature?.let { "${it.headY},${it.logHeadSize}" } ?: ","
        logFile.appendText(
            "$timestamp,$predictedClass,$confidence,$inferenceTimeMs,$correct,$featureCols\n"
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
