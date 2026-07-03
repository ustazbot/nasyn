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
import com.nasyn.posespike.pose.CalibrationProfile
import com.nasyn.posespike.pose.LandmarkMapper
import com.nasyn.posespike.pose.PoseClass
import com.nasyn.posespike.pose.PoseClassification
import com.nasyn.posespike.pose.PoseClassifier
import com.nasyn.posespike.pose.PoseLandmarkerHelper
import com.nasyn.posespike.pose.PoseLandmarks
import com.nasyn.posespike.tally.TallyLogger
import com.nasyn.posespike.ui.ControlPanel
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

    private var latestLandmarks: PoseLandmarks? = null
    private var latestClassification: PoseClassification = PoseClassification(PoseClass.UNKNOWN, 0)
    private var latestInferenceTimeMs: Long = 0

    // §8.13 proximity signal untuk SUJUD: kepala rapat lens menutup cahaya
    // → luma frame jatuh mendadak + landmark hilang serentak = SUJUD.
    // Baseline = EMA luma semasa landmark visible (frame tak terlindung).
    @Volatile private var latestLuma = 0f
    @Volatile private var lumaBaseline = 0f

    private fun meanLuma(bitmap: Bitmap): Float {
        val stepX = (bitmap.width / 16).coerceAtLeast(1)
        val stepY = (bitmap.height / 16).coerceAtLeast(1)
        var sum = 0L
        var count = 0
        var y = 0
        while (y < bitmap.height) {
            var x = 0
            while (x < bitmap.width) {
                val p = bitmap.getPixel(x, y)
                sum += (android.graphics.Color.red(p) +
                    android.graphics.Color.green(p) +
                    android.graphics.Color.blue(p)) / 3
                count++
                x += stepX
            }
            y += stepY
        }
        return sum.toFloat() / count
    }

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
                latestLandmarks = landmarks
                latestClassification = classification
                latestInferenceTimeMs = inferenceTimeMs
                val feature = landmarks?.let { com.nasyn.posespike.pose.poseFeature(it) }
                val debugInfo = buildString {
                    append("luma %.0f / base %.0f".format(latestLuma, lumaBaseline))
                    feature?.let { append("  y%.2f sz%.2f".format(it.headY, it.logHeadSize)) }
                }
                overlay.update(classification, landmarks, inferenceTimeMs, debugInfo)
            }
        })

        val tallyLogger = TallyLogger(this)
        val controlPanel = ControlPanel(this, calibration, tallyLogger)
        controlPanel.currentLandmarksProvider { latestLandmarks }
        controlPanel.currentClassificationProvider { latestClassification }
        controlPanel.currentInferenceTimeMsProvider { latestInferenceTimeMs }
        rootLayout.addView(
            controlPanel,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM),
        )

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

                latestLuma = meanLuma(bitmap)

                poseLandmarkerHelper?.detectAsync(
                    bitmap = bitmap,
                    rotationDegrees = rotationDegrees,
                    isFrontCamera = true,
                    frameTimeMs = frameTimeMs,
                )
            }

            // Spike v2 (§8.13): kamera depan gaya "video-call" — phone
            // diletak RENDAH dekat sejadah, skrin+lens menghala atas ke
            // arah pengguna (bukan paras dada macam spike v1)
            val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageAnalysis)
        }, ContextCompat.getMainExecutor(this))
    }

    override fun onResult(result: com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult, inferenceTimeMs: Long) {
        val landmarks = LandmarkMapper.toPoseLandmarks(result)
        val luma = latestLuma
        val classification = if (landmarks != null) {
            // Frame tak terlindung — kemaskini baseline cahaya
            lumaBaseline =
                if (lumaBaseline == 0f) luma else 0.9f * lumaBaseline + 0.1f * luma
            classifier.classify(landmarks)
        } else if (lumaBaseline > 0f && luma < lumaBaseline * 0.45f) {
            // §8.13: tiada landmark + frame gelap mendadak (<45% baseline)
            // = kepala menutup lens = SUJUD proximity.
            // ponytail: threshold 0.45 tekaan awal — tala ikut data spike
            val darkness = 1f - (luma / (lumaBaseline * 0.45f))
            PoseClassification(PoseClass.SUJUD, (60 + 40 * darkness).toInt().coerceIn(60, 100))
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
