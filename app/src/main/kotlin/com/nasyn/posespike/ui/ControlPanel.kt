package com.nasyn.posespike.ui

import android.content.Context
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.nasyn.posespike.pose.CalibrationProfile
import com.nasyn.posespike.pose.PoseClass
import com.nasyn.posespike.pose.PoseClassification
import com.nasyn.posespike.pose.PoseLandmarks
import com.nasyn.posespike.tally.TallyLogger

class ControlPanel(
    context: Context,
    private val calibration: CalibrationProfile,
    private val tallyLogger: TallyLogger,
) : LinearLayout(context) {

    private var landmarksProvider: () -> PoseLandmarks? = { null }
    private var classificationProvider: () -> PoseClassification = { PoseClassification(PoseClass.UNKNOWN, 0) }
    private var inferenceTimeMsProvider: () -> Long = { 0L }
    private val summaryView: TextView

    init {
        orientation = VERTICAL

        val calibrationRow = LinearLayout(context).apply { orientation = HORIZONTAL }
        listOf(
            "Berdiri" to PoseClass.QIYAM,
            "Rukuk" to PoseClass.RUKUK,
            "Sujud" to PoseClass.SUJUD,
            "Duduk" to PoseClass.DUDUK,
        ).forEach { (label, poseClass) ->
            calibrationRow.addView(Button(context).apply {
                text = label
                setOnClickListener {
                    landmarksProvider()?.let { calibration.recordBaseline(poseClass, it) }
                }
            })
        }
        addView(calibrationRow)

        val tallyRow = LinearLayout(context).apply { orientation = HORIZONTAL }
        tallyRow.addView(Button(context).apply {
            text = "✓ Correct"
            setOnClickListener {
                val result = classificationProvider()
                tallyLogger.log(
                    result.poseClass, result.confidence, inferenceTimeMsProvider(),
                    correct = true, landmarks = landmarksProvider(),
                )
                refreshSummary()
            }
        })
        tallyRow.addView(Button(context).apply {
            text = "✗ Wrong"
            setOnClickListener {
                val result = classificationProvider()
                tallyLogger.log(
                    result.poseClass, result.confidence, inferenceTimeMsProvider(),
                    correct = false, landmarks = landmarksProvider(),
                )
                refreshSummary()
            }
        })
        addView(tallyRow)

        summaryView = TextView(context)
        addView(summaryView)
    }

    fun currentLandmarksProvider(provider: () -> PoseLandmarks?) {
        landmarksProvider = provider
    }

    fun currentClassificationProvider(provider: () -> PoseClassification) {
        classificationProvider = provider
    }

    fun currentInferenceTimeMsProvider(provider: () -> Long) {
        inferenceTimeMsProvider = provider
    }

    private fun refreshSummary() {
        summaryView.text = tallyLogger.summary()
    }
}
