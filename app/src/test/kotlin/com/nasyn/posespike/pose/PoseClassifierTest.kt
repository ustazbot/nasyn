package com.nasyn.posespike.pose

import org.junit.Assert.assertEquals
import org.junit.Test

class PoseClassifierTest {

    // Shoulder width = 0.2 in all fixtures, used as the scale reference.
    // headShoulderRatio = (shoulderY - headY) / shoulderWidth
    // Standing: head well above shoulders -> large positive ratio.
    // Sujud: head at/below shoulder line -> ratio near zero or negative.
    private fun landmarks(headY: Float, shoulderY: Float): PoseLandmarks {
        val nose = Point(0.5f, headY)
        val leftEar = Point(0.45f, headY)
        val rightEar = Point(0.55f, headY)
        val leftShoulder = Point(0.4f, shoulderY)
        val rightShoulder = Point(0.6f, shoulderY)
        return PoseLandmarks(nose, leftEar, rightEar, leftShoulder, rightShoulder)
    }

    private fun calibratedClassifier(): PoseClassifier {
        val calibration = CalibrationProfile()
        calibration.recordBaseline(PoseClass.QIYAM, landmarks(headY = 0.2f, shoulderY = 0.35f))
        calibration.recordBaseline(PoseClass.RUKUK, landmarks(headY = 0.35f, shoulderY = 0.40f))
        calibration.recordBaseline(PoseClass.SUJUD, landmarks(headY = 0.55f, shoulderY = 0.45f))
        calibration.recordBaseline(PoseClass.DUDUK, landmarks(headY = 0.30f, shoulderY = 0.42f))
        return PoseClassifier(calibration)
    }

    @Test
    fun `classifies exact QIYAM baseline as QIYAM with high confidence`() {
        val classifier = calibratedClassifier()
        val result = classifier.classify(landmarks(headY = 0.2f, shoulderY = 0.35f))
        assertEquals(PoseClass.QIYAM, result.poseClass)
    }

    @Test
    fun `classifies exact SUJUD baseline as SUJUD`() {
        val classifier = calibratedClassifier()
        val result = classifier.classify(landmarks(headY = 0.55f, shoulderY = 0.45f))
        assertEquals(PoseClass.SUJUD, result.poseClass)
    }

    @Test
    fun `classifies exact RUKUK baseline as RUKUK`() {
        val classifier = calibratedClassifier()
        val result = classifier.classify(landmarks(headY = 0.35f, shoulderY = 0.40f))
        assertEquals(PoseClass.RUKUK, result.poseClass)
    }

    @Test
    fun `classifies exact DUDUK baseline as DUDUK`() {
        val classifier = calibratedClassifier()
        val result = classifier.classify(landmarks(headY = 0.30f, shoulderY = 0.42f))
        assertEquals(PoseClass.DUDUK, result.poseClass)
    }

    @Test
    fun `returns UNKNOWN when calibration is incomplete`() {
        val classifier = PoseClassifier(CalibrationProfile())
        val result = classifier.classify(landmarks(headY = 0.2f, shoulderY = 0.35f))
        assertEquals(PoseClass.UNKNOWN, result.poseClass)
        assertEquals(0, result.confidence)
    }
}
