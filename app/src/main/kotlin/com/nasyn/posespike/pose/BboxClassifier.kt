package com.nasyn.posespike.pose

import kotlin.math.abs
import kotlin.math.log2

// Spike v3 (PRD §8.13, disahkan spike desktop 2026-07-05):
// signal = bounding-box muka (BlazeFace), BUKAN landmark.
// Data desktop: jauh (qiyam/duduk) ratio 0.03-0.08, sujud >0.15 saturate
// ~0.24-0.28; landmark collapse ke 0-2.8% bila dekat. Lihat SPIKE-RESULT.md
// bahagian "Spike Ulangan (Desktop)".

// Koordinat dinormalisasi [0..1] relatif kepada frame.
data class BboxSignal(
    val left: Float,
    val top: Float,
    val right: Float,
    val bottom: Float,
    val conf: Float,
) {
    val ratio: Float get() = (right - left) * (bottom - top)
    val centerY: Float get() = (top + bottom) / 2f
}

enum class PoseClass { QIYAM, RUKUK, SUJUD, DUDUK, UNKNOWN }

data class PoseClassification(val poseClass: PoseClass, val confidence: Int)

// Feature pose jauh: posisi menegak bbox + log2(saiz) — sama konsep spike v2
data class BboxFeature(val centerY: Float, val logRatio: Float)

fun bboxFeature(s: BboxSignal) =
    BboxFeature(s.centerY, log2(s.ratio.coerceAtLeast(0.0001f)))

// ponytail: pemberat 0.5 imbangkan skala log2(ratio) lwn centerY [0..1];
// tala ikut data device sebenar kalau pemisahan qiyam/rukuk/duduk lemah
private fun featureDistance(a: BboxFeature, b: BboxFeature): Float =
    abs(a.centerY - b.centerY) + abs(a.logRatio - b.logRatio) * 0.5f

class CalibrationProfile {
    private val baselines = mutableMapOf<PoseClass, BboxFeature>()

    fun recordBaseline(poseClass: PoseClass, signal: BboxSignal) {
        baselines[poseClass] = bboxFeature(signal)
    }

    // SUJUD tak perlu baseline — ia dikesan via threshold proximity, bukan
    // nearest-baseline (semasa sujud bbox intermittent, kalibrasi tak stabil)
    fun isComplete(): Boolean =
        baselines.keys.containsAll(setOf(PoseClass.QIYAM, PoseClass.RUKUK, PoseClass.DUDUK))

    fun baselineFeatures(): Map<PoseClass, BboxFeature> = baselines.toMap()
}

class BboxClassifier(
    private val calibration: CalibrationProfile,
    private val nowMs: () -> Long = { System.currentTimeMillis() },
) {
    companion object {
        // Dari data desktop: sujud >=0.19, jauh <=0.12 (max qiyam 0.120).
        // Device Redmi 9A: lonjakan turun-sujud capai 0.66-0.79 — threshold
        // 0.15 masih dilepasi dengan margin besar.
        const val SUJUD_ENTER_RATIO = 0.15f
        const val FAR_RATIO = 0.10f
        // Data device (2026-07-05): semasa tahan sujud kepala MENUTUP lens
        // sepenuhnya — detection hilang sampai 26s berterusan (desktop:
        // intermittent <2s). Jadi hold TAMAT bila detection KEMBALI (kepala
        // angkat = muka nampak semula), bukan timeout pendek. Siling 45s
        // sebagai sanity guard supaya tak latch selamanya.
        const val SUJUD_MAX_HOLD_MS = 45_000L
        // Ratio saturate ~0.28 pada desktop; skala confidence atas julat itu
        private const val SUJUD_SATURATE_RATIO = 0.28f
    }

    private var holdStartMs = Long.MIN_VALUE / 2
    private var inSujudHold = false

    fun classify(signal: BboxSignal?): PoseClassification {
        val now = nowMs()

        if (signal == null) {
            // Tiada detection: kalau baru masuk SUJUD, kepala sedang
            // menutup lens (fasa tahan) — kekal SUJUD sehingga detection
            // kembali atau siling keselamatan tercapai.
            return if (inSujudHold && now - holdStartMs < SUJUD_MAX_HOLD_MS) {
                PoseClassification(PoseClass.SUJUD, 60)
            } else {
                inSujudHold = false
                PoseClassification(PoseClass.UNKNOWN, 0)
            }
        }

        if (signal.ratio >= SUJUD_ENTER_RATIO) {
            if (!inSujudHold) {
                inSujudHold = true
                holdStartMs = now
            }
            val over = (signal.ratio - SUJUD_ENTER_RATIO) /
                (SUJUD_SATURATE_RATIO - SUJUD_ENTER_RATIO)
            return PoseClassification(PoseClass.SUJUD, (60 + 40 * over).toInt().coerceIn(60, 100))
        }

        // Detection kembali pada ratio bukan-dekat = kepala dah angkat,
        // keluar dari hold sujud
        inSujudHold = false

        if (signal.ratio > FAR_RATIO) {
            // Zon transisi 0.10-0.15 (jarang: 37/1787 frame desktop) —
            // sedang turun/bangun, jangan teka
            return PoseClassification(PoseClass.UNKNOWN, 0)
        }

        if (!calibration.isComplete()) {
            return PoseClassification(PoseClass.UNKNOWN, 0)
        }

        val feature = bboxFeature(signal)
        val sorted = calibration.baselineFeatures()
            .mapValues { (_, baseline) -> featureDistance(feature, baseline) }
            .entries.sortedBy { it.value }
        val nearest = sorted[0]
        val totalSpread = nearest.value + sorted[1].value
        val confidence = if (totalSpread == 0f) {
            100
        } else {
            (100 * (1f - nearest.value / totalSpread)).toInt().coerceIn(0, 100)
        }
        // ponytail: gate 55 (bukan 60) — data device 5 Julai: 3 baseline jauh
        // rapat dalam ruang feature, gate 60 buat majoriti frame UNKNOWN.
        // Formula conf sentiasa >=50, jadi 55 = "jelas lebih dekat sikit"
        val poseClass = if (confidence < 55) PoseClass.UNKNOWN else nearest.key
        return PoseClassification(poseClass, confidence)
    }
}
