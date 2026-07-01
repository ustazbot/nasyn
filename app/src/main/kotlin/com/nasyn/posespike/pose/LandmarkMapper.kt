package com.nasyn.posespike.pose

import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

private const val NOSE = 0
private const val LEFT_EAR = 7
private const val RIGHT_EAR = 8
private const val LEFT_SHOULDER = 11
private const val RIGHT_SHOULDER = 12

object LandmarkMapper {
    fun toPoseLandmarks(result: PoseLandmarkerResult): PoseLandmarks? {
        val landmarksList = result.landmarks()
        if (landmarksList.isEmpty()) return null
        val landmarks = landmarksList[0]
        if (landmarks.size <= RIGHT_SHOULDER) return null

        return PoseLandmarks(
            nose = Point(landmarks[NOSE].x(), landmarks[NOSE].y()),
            leftEar = Point(landmarks[LEFT_EAR].x(), landmarks[LEFT_EAR].y()),
            rightEar = Point(landmarks[RIGHT_EAR].x(), landmarks[RIGHT_EAR].y()),
            leftShoulder = Point(landmarks[LEFT_SHOULDER].x(), landmarks[LEFT_SHOULDER].y()),
            rightShoulder = Point(landmarks[RIGHT_SHOULDER].x(), landmarks[RIGHT_SHOULDER].y()),
        )
    }
}
