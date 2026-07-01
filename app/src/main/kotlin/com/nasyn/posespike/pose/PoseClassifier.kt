package com.nasyn.posespike.pose

import kotlin.math.abs

private fun headShoulderRatio(landmarks: PoseLandmarks): Float {
    val headY = (landmarks.nose.y + landmarks.leftEar.y + landmarks.rightEar.y) / 3f
    val shoulderY = (landmarks.leftShoulder.y + landmarks.rightShoulder.y) / 2f
    val shoulderWidth = abs(landmarks.rightShoulder.x - landmarks.leftShoulder.x)
    if (shoulderWidth == 0f) return 0f
    return (shoulderY - headY) / shoulderWidth
}

class CalibrationProfile {
    private val baselines = mutableMapOf<PoseClass, Float>()

    fun recordBaseline(poseClass: PoseClass, landmarks: PoseLandmarks) {
        baselines[poseClass] = headShoulderRatio(landmarks)
    }

    fun isComplete(): Boolean {
        val required = setOf(PoseClass.QIYAM, PoseClass.RUKUK, PoseClass.SUJUD, PoseClass.DUDUK)
        return baselines.keys.containsAll(required)
    }

    fun baselineRatios(): Map<PoseClass, Float> = baselines.toMap()
}

class PoseClassifier(private val calibration: CalibrationProfile) {

    fun classify(landmarks: PoseLandmarks): PoseClassification {
        if (!calibration.isComplete()) {
            return PoseClassification(PoseClass.UNKNOWN, 0)
        }

        val ratio = headShoulderRatio(landmarks)
        val baselines = calibration.baselineRatios()

        val distances = baselines.mapValues { (_, baselineRatio) -> abs(ratio - baselineRatio) }
        val sortedByDistance = distances.entries.sortedBy { it.value }
        val nearest = sortedByDistance[0]
        val secondNearest = sortedByDistance[1]

        val totalSpread = nearest.value + secondNearest.value
        val confidence = if (totalSpread == 0f) {
            100
        } else {
            (100 * (1f - nearest.value / totalSpread)).toInt().coerceIn(0, 100)
        }

        val poseClass = if (confidence < 60) PoseClass.UNKNOWN else nearest.key
        return PoseClassification(poseClass, confidence)
    }
}
