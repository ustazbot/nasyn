package com.nasyn.posespike

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Bundle
import android.util.Size
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import com.nasyn.posespike.pose.CalibrationProfile
import com.nasyn.posespike.pose.LandmarkMapper
import com.nasyn.posespike.pose.PoseClass
import com.nasyn.posespike.pose.PoseClassification
import com.nasyn.posespike.pose.PoseClassifier
import com.nasyn.posespike.pose.PoseLandmarkerHelper
import com.nasyn.posespike.pose.PoseLandmarks
import com.nasyn.posespike.ui.PoseOverlayView

interface ResultObserver {
    fun onClassification(classification: PoseClassification, landmarks: PoseLandmarks?, inferenceTimeMs: Long)
}

class MainActivity : AppCompatActivity(), PoseLandmarkerHelper.Listener {

    val calibration = CalibrationProfile()
    val classifier = PoseClassifier(calibration)

    private var observer: ResultObserver? = null
    private var poseLandmarkerHelper: PoseLandmarkerHelper? = null
    private lateinit var previewView: PreviewView
    private lateinit var rootLayout: FrameLayout

    private val requestCameraPermission = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted -> if (granted) startCamera() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        rootLayout = FrameLayout(this)
        previewView = PreviewView(this)
        rootLayout.addView(previewView)
        setContentView(rootLayout)

        val overlay = PoseOverlayView(this)
        rootLayout.addView(overlay, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        setResultObserver(object : ResultObserver {
            override fun onClassification(classification: PoseClassification, landmarks: PoseLandmarks?, inferenceTimeMs: Long) {
                overlay.update(classification, landmarks, inferenceTimeMs)
            }
        })

        poseLandmarkerHelper = PoseLandmarkerHelper(this, this)

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            == PackageManager.PERMISSION_GRANTED
        ) {
            startCamera()
        } else {
            requestCameraPermission.launch(Manifest.permission.CAMERA)
        }
    }

    fun setResultObserver(observer: ResultObserver) {
        this.observer = observer
    }

    fun getRootLayout(): FrameLayout = rootLayout

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }

            val imageAnalysis = ImageAnalysis.Builder()
                .setTargetResolution(Size(480, 640))
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                .build()

            imageAnalysis.setAnalyzer(ContextCompat.getMainExecutor(this)) { imageProxy ->
                val bitmap = Bitmap.createBitmap(imageProxy.width, imageProxy.height, Bitmap.Config.ARGB_8888)
                bitmap.copyPixelsFromBuffer(imageProxy.planes[0].buffer)
                val rotationDegrees = imageProxy.imageInfo.rotationDegrees
                val frameTimeMs = imageProxy.imageInfo.timestamp / 1_000_000
                imageProxy.close()

                poseLandmarkerHelper?.detectAsync(
                    bitmap = bitmap,
                    rotationDegrees = rotationDegrees,
                    isFrontCamera = true,
                    frameTimeMs = frameTimeMs,
                )
            }

            val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageAnalysis)
        }, ContextCompat.getMainExecutor(this))
    }

    override fun onResult(result: com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult, inferenceTimeMs: Long) {
        val landmarks = LandmarkMapper.toPoseLandmarks(result)
        val classification = if (landmarks != null) {
            classifier.classify(landmarks)
        } else {
            PoseClassification(PoseClass.UNKNOWN, 0)
        }
        observer?.onClassification(classification, landmarks, inferenceTimeMs)
    }

    override fun onError(message: String) {
        observer?.onClassification(PoseClassification(PoseClass.UNKNOWN, 0), null, 0)
    }

    override fun onDestroy() {
        super.onDestroy()
        poseLandmarkerHelper?.close()
    }
}
