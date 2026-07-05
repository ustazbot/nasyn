package com.nasyn.posespike.pose

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BboxClassifierTest {

    // Bbox segi empat sama berpusat, ratio = size^2
    private fun signal(size: Float, centerY: Float = 0.5f, conf: Float = 0.8f): BboxSignal {
        val half = size / 2f
        return BboxSignal(0.5f - half, centerY - half, 0.5f + half, centerY + half, conf)
    }

    private fun calibrated(): CalibrationProfile {
        val c = CalibrationProfile()
        // Dari data desktop: qiyam ~0.043 (kepala atas frame), rukuk lebih
        // besar & rendah, duduk sederhana
        c.recordBaseline(PoseClass.QIYAM, signal(size = 0.20f, centerY = 0.2f)) // ratio 0.04
        c.recordBaseline(PoseClass.RUKUK, signal(size = 0.28f, centerY = 0.5f)) // ratio 0.078
        c.recordBaseline(PoseClass.DUDUK, signal(size = 0.24f, centerY = 0.35f)) // ratio 0.058
        return c
    }

    @Test
    fun `ratio melebihi threshold = SUJUD walau tanpa kalibrasi`() {
        val classifier = BboxClassifier(CalibrationProfile())
        val result = classifier.classify(signal(size = 0.45f)) // ratio 0.2
        assertEquals(PoseClass.SUJUD, result.poseClass)
        assertTrue(result.confidence >= 60)
    }

    @Test
    fun `ratio saturate = confidence 100`() {
        val classifier = BboxClassifier(CalibrationProfile())
        val result = classifier.classify(signal(size = 0.6f)) // ratio 0.36 > saturate
        assertEquals(PoseClass.SUJUD, result.poseClass)
        assertEquals(100, result.confidence)
    }

    @Test
    fun `detection hilang selepas masuk SUJUD = kekal SUJUD sepanjang tahan`() {
        var now = 0L
        val classifier = BboxClassifier(CalibrationProfile()) { now }
        classifier.classify(signal(size = 0.45f)) // masuk SUJUD
        // Data device: kepala tutup lens sampai 26s — mesti kekal SUJUD
        now = 26_000L
        assertEquals(PoseClass.SUJUD, classifier.classify(null).poseClass)
    }

    @Test
    fun `hold melebihi siling keselamatan = UNKNOWN`() {
        var now = 0L
        val classifier = BboxClassifier(CalibrationProfile()) { now }
        classifier.classify(signal(size = 0.45f))
        now = BboxClassifier.SUJUD_MAX_HOLD_MS + 1
        assertEquals(PoseClass.UNKNOWN, classifier.classify(null).poseClass)
    }

    @Test
    fun `detection hilang TANPA proximity dahulu = UNKNOWN bukan SUJUD`() {
        val classifier = BboxClassifier(calibrated())
        assertEquals(PoseClass.UNKNOWN, classifier.classify(null).poseClass)
    }

    @Test
    fun `detection kembali pada ratio jauh = keluar hold`() {
        var now = 0L
        val classifier = BboxClassifier(calibrated()) { now }
        classifier.classify(signal(size = 0.45f)) // masuk SUJUD
        now = 10_000L
        // Kepala angkat — muka nampak semula pada saiz qiyam
        assertEquals(PoseClass.QIYAM, classifier.classify(signal(0.20f, centerY = 0.2f)).poseClass)
        // Hold dah tamat: detection hilang selepas ini BUKAN sujud
        now = 11_000L
        assertEquals(PoseClass.UNKNOWN, classifier.classify(null).poseClass)
    }

    @Test
    fun `siling hold dikira dari MASUK sujud - detection dekat berulang tak reset`() {
        var now = 0L
        val classifier = BboxClassifier(CalibrationProfile()) { now }
        classifier.classify(signal(size = 0.45f)) // masuk SUJUD pada t=0
        now = 40_000L
        classifier.classify(signal(size = 0.45f)) // masih dekat — TIDAK reset siling
        now = BboxClassifier.SUJUD_MAX_HOLD_MS + 1
        assertEquals(PoseClass.UNKNOWN, classifier.classify(null).poseClass)
    }

    @Test
    fun `zon transisi antara FAR dan SUJUD_ENTER = UNKNOWN`() {
        val classifier = BboxClassifier(calibrated())
        val result = classifier.classify(signal(size = 0.35f)) // ratio 0.1225
        assertEquals(PoseClass.UNKNOWN, result.poseClass)
    }

    @Test
    fun `pose jauh tepat pada baseline diklasifikasi betul`() {
        val classifier = BboxClassifier(calibrated())
        assertEquals(PoseClass.QIYAM, classifier.classify(signal(0.20f, centerY = 0.2f)).poseClass)
        assertEquals(PoseClass.RUKUK, classifier.classify(signal(0.28f, centerY = 0.5f)).poseClass)
        assertEquals(PoseClass.DUDUK, classifier.classify(signal(0.24f, centerY = 0.35f)).poseClass)
    }

    @Test
    fun `pose jauh tanpa kalibrasi = UNKNOWN`() {
        val classifier = BboxClassifier(CalibrationProfile())
        val result = classifier.classify(signal(size = 0.20f, centerY = 0.2f))
        assertEquals(PoseClass.UNKNOWN, result.poseClass)
        assertEquals(0, result.confidence)
    }
}
