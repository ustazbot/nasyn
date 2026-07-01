package com.nasyn.posespike.tally

import android.content.Context
import com.nasyn.posespike.pose.PoseClass
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TallyLogger(context: Context) {

    private val logFile: File = File(context.getExternalFilesDir(null), "pose_spike_tally.csv")
    private val counts = mutableMapOf<PoseClass, Pair<Int, Int>>() // class -> (correct, incorrect)

    init {
        if (!logFile.exists()) {
            logFile.writeText("timestamp,predictedClass,confidence,latencyMs,correct\n")
        }
    }

    fun log(predictedClass: PoseClass, confidence: Int, inferenceTimeMs: Long, correct: Boolean) {
        val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())
        logFile.appendText("$timestamp,$predictedClass,$confidence,$inferenceTimeMs,$correct\n")

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
