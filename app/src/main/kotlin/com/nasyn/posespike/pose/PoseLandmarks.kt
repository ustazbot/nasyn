package com.nasyn.posespike.pose

data class Point(val x: Float, val y: Float)

data class PoseLandmarks(
    val nose: Point,
    val leftEar: Point,
    val rightEar: Point,
    val leftShoulder: Point,
    val rightShoulder: Point,
)

enum class PoseClass { QIYAM, RUKUK, SUJUD, DUDUK, UNKNOWN }

data class PoseClassification(val poseClass: PoseClass, val confidence: Int)
