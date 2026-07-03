package com.nasyn.posespike.pose

import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.log2

// Spike v2 (PRD §8.13, mounting rendah dekat sejadah menghala atas):
// feature 2D — headY (posisi menegak) + log2(headSize) (proximity).
// Saiz kepala dalam frame = proxy jarak kepala↔lens; jangkaan mounting
// baharu: Sujud = kepala PALING DEKAT dengan lens = saiz paling besar.
data class PoseFeature(val headY: Float, val logHeadSize: Float)

fun poseFeature(l: PoseLandmarks): PoseFeature {
    val headY = (l.nose.y + l.leftEar.y + l.rightEar.y) / 3f
    val earDist = hypot(l.rightEar.x - l.leftEar.x, l.rightEar.y - l.leftEar.y)
    val shoulderDist =
        hypot(l.rightShoulder.x - l.leftShoulder.x, l.rightShoulder.y - l.leftShoulder.y)
    // Telinga kadang tertutup (telekung/sudut rendah) — fallback lebar bahu
    val size = if (earDist > 0.01f) earDist else shoulderDist
    return PoseFeature(headY, log2(size.coerceAtLeast(0.001f)))
}

// ponytail: pemberat 0.5 imbangkan skala log2(saiz) lwn headY [0..1];
// tala semula ikut data spike sebenar kalau pemisahan kelas lemah
private fun featureDistance(a: PoseFeature, b: PoseFeature): Float =
    abs(a.headY - b.headY) + abs(a.logHeadSize - b.logHeadSize) * 0.5f

class CalibrationProfile {
    private val baselines = mutableMapOf<PoseClass, PoseFeature>()

    fun recordBaseline(poseClass: PoseClass, landmarks: PoseLandmarks) {
        baselines[poseClass] = poseFeature(landmarks)
    }

    fun isComplete(): Boolean {
        val required = setOf(PoseClass.QIYAM, PoseClass.RUKUK, PoseClass.SUJUD, PoseClass.DUDUK)
        return baselines.keys.containsAll(required)
    }

    fun baselineFeatures(): Map<PoseClass, PoseFeature> = baselines.toMap()
}

class PoseClassifier(private val calibration: CalibrationProfile) {

    fun classify(landmarks: PoseLandmarks): PoseClassification {
        if (!calibration.isComplete()) {
            return PoseClassification(PoseClass.UNKNOWN, 0)
        }

        val feature = poseFeature(landmarks)
        val distances = calibration.baselineFeatures()
            .mapValues { (_, baseline) -> featureDistance(feature, baseline) }
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
