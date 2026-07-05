package com.nasyn.posespike

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Bundle
import android.util.Size
import android.view.Gravity
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
import com.nasyn.posespike.pose.BboxClassifier
import com.nasyn.posespike.pose.BboxSignal
import com.nasyn.posespike.pose.CalibrationProfile
import com.nasyn.posespike.pose.FaceDetectorHelper
import com.nasyn.posespike.pose.PoseClass
import com.nasyn.posespike.pose.PoseClassification
import com.nasyn.posespike.tally.FrameLogger
import com.nasyn.posespike.tally.TallyLogger
import com.nasyn.posespike.ui.ControlPanel
import com.nasyn.posespike.ui.PoseOverlayView

interface ResultObserver {
    fun onClassification(classification: PoseClassification, signal: BboxSignal?, inferenceTimeMs: Long)
}

// Spike v3 (§8.13): bounding-box proximity — pendekatan divalidasi pada
// spike desktop 2026-07-05 (SPIKE-RESULT.md "Spike Ulangan (Desktop)").
// Landmark & luma fallback v2 digantikan sepenuhnya dengan bbox BlazeFace.
class MainActivity : AppCompatActivity(), FaceDetectorHelper.Listener {

    val calibration = CalibrationProfile()
    val classifier = BboxClassifier(calibration)

    private var observer: ResultObserver? = null
    private var faceDetectorHelper: FaceDetectorHelper? = null
    private var frameLogger: FrameLogger? = null
    private lateinit var previewView: PreviewView
    private lateinit var rootLayout: FrameLayout

    private var latestSignal: BboxSignal? = null
    private var latestClassification: PoseClassification = PoseClassification(PoseClass.UNKNOWN, 0)
    private var latestInferenceTimeMs: Long = 0

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
            override fun onClassification(classification: PoseClassification, signal: BboxSignal?, inferenceTimeMs: Long) {
                latestSignal = signal
                latestClassification = classification
                latestInferenceTimeMs = inferenceTimeMs
                val debugInfo = signal?.let {
                    "ratio %.3f  conf %.2f  cy %.2f".format(it.ratio, it.conf, it.centerY)
                } ?: "no detection"
                overlay.update(classification, signal, inferenceTimeMs, debugInfo)
            }
        })

        // Kalibrasi persist merentas restart — tanpa ini setiap reinstall
        // memaksa kalibrasi semula dan pose jauh semua UNKNOWN
        val prefs = getSharedPreferences("spike", MODE_PRIVATE)
        prefs.getString("calibration", null)?.let { calibration.restore(it) }
        calibration.onChanged = {
            prefs.edit().putString("calibration", calibration.serialize()).apply()
        }

        val tallyLogger = TallyLogger(this)
        frameLogger = FrameLogger(this)
        val controlPanel = ControlPanel(this, calibration, tallyLogger)
        controlPanel.currentSignalProvider { latestSignal }
        controlPanel.currentClassificationProvider { latestClassification }
        controlPanel.currentInferenceTimeMsProvider { latestInferenceTimeMs }
        rootLayout.addView(
            controlPanel,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM),
        )

        faceDetectorHelper = FaceDetectorHelper(this, this)

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

                faceDetectorHelper?.detectAsync(
                    bitmap = bitmap,
                    rotationDegrees = rotationDegrees,
                    isFrontCamera = true,
                    frameTimeMs = frameTimeMs,
                )
            }

            // §8.13: kamera depan gaya "video-call" — phone diletak RENDAH
            // dekat sejadah, skrin+lens menghala atas ke arah pengguna
            val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageAnalysis)
        }, ContextCompat.getMainExecutor(this))
    }

    override fun onResult(signal: BboxSignal?, inferenceTimeMs: Long) {
        val classification = classifier.classify(signal)
        frameLogger?.log(signal, classification, inferenceTimeMs)
        observer?.onClassification(classification, signal, inferenceTimeMs)
    }

    override fun onError(message: String) {
        observer?.onClassification(PoseClassification(PoseClass.UNKNOWN, 0), null, 0)
    }

    override fun onDestroy() {
        super.onDestroy()
        faceDetectorHelper?.close()
        frameLogger?.close()
    }
}
