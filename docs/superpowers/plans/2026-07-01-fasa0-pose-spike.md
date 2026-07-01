# Fasa 0: Head-Based Pose Spike Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Android Kotlin app that classifies prayer pose
(QIYAM/RUKUK/SUJUD/DUDUK) from front-camera head+shoulder landmarks in
real time, and lets a tester record ✓/✗ accuracy + latency on the actual
Redmi 9A refurb device, producing data for a GO/PARTIAL/NO-GO call.

**Architecture:** CameraX (ImageAnalysis, RGBA_8888 output) feeds frames to
MediaPipe Tasks Vision `PoseLandmarker` (LITE model, LIVE_STREAM mode). A
pure-Kotlin `PoseClassifier` (no Android/MediaPipe deps, JVM-testable) maps
5 landmark points to a `PoseClass` + confidence using a per-user calibrated
baseline. A custom overlay `View` shows the live result; ✓/✗ buttons feed a
CSV `TallyLogger` for later analysis.

**Tech Stack:** Kotlin, Android Gradle Plugin 8.5, Gradle 8.7, CameraX 1.3.4,
MediaPipe Tasks Vision 0.10.14, JUnit4 (JVM unit tests only — no
instrumented tests for this spike).

## Global Constraints

- Target/min SDK: minSdk 29, targetSdk 34, compileSdk 34 (device is Android 10 / SDK 29 — PRD §5 requires 10+)
- Package name: `com.nasyn.posespike`
- No Flutter, no platform channel, no FSM, no audio, no kiosk lockdown — out of scope per spec
- No network calls at runtime (model asset is bundled at build time, not downloaded on-device)
- Confidence bands per spec: ≥80 ACCEPT, 60–79 HOLD, <60 REJECT/UNKNOWN
- Device under test: Xiaomi Redmi 9A, `adb` serial `9HJ7OZ55XSXOPVJZ`, already authorized

---

## Task 1: Environment setup + Gradle project scaffold

**Files:**
- Create: `settings.gradle.kts`
- Create: `build.gradle.kts`
- Create: `gradle.properties`
- Create: `app/build.gradle.kts`
- Create: `app/src/main/AndroidManifest.xml`
- Create: `app/src/main/res/values/strings.xml`
- Create: `app/src/main/res/values/themes.xml`
- Create: `app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt` (empty skeleton, real content in Task 4)

**Interfaces:**
- Produces: a working Gradle project buildable with `./gradlew assembleDebug`, package `com.nasyn.posespike`, so all later tasks can add files under `app/src/main/kotlin/com/nasyn/posespike/`.

- [ ] **Step 1: Install Android SDK cmdline-tools**

```bash
mkdir -p ~/Android/Sdk/cmdline-tools
cd /tmp
curl -sL -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q cmdline-tools.zip -d ~/Android/Sdk/cmdline-tools
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
export ANDROID_HOME=~/Android/Sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

Expected: `sdkmanager --list_installed` shows `platforms;android-34` and
`build-tools;34.0.0` installed, no errors.

- [ ] **Step 2: Install Gradle 8.7 and bootstrap the wrapper**

```bash
cd /tmp
curl -sL -o gradle-8.7-bin.zip https://services.gradle.org/distributions/gradle-8.7-bin.zip
unzip -q gradle-8.7-bin.zip -d ~/opt
cd /home/astro/claude-project/NASYN-v-Claude
~/opt/gradle-8.7/bin/gradle wrapper --gradle-version 8.7
```

Expected: `gradlew`, `gradlew.bat`, and `gradle/wrapper/` are created in the
project root.

- [ ] **Step 3: Write `settings.gradle.kts`**

```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "nasyn-pose-spike"
include(":app")
```

- [ ] **Step 4: Write root `build.gradle.kts`**

```kotlin
plugins {
    id("com.android.application") version "8.5.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}
```

- [ ] **Step 5: Write `gradle.properties`**

```properties
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
kotlin.code.style=official
```

- [ ] **Step 6: Write `app/build.gradle.kts`**

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.nasyn.posespike"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.nasyn.posespike"
        minSdk = 29
        targetSdk = 34
        versionCode = 1
        versionName = "0.1-spike"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        viewBinding = false
    }
    sourceSets {
        getByName("main") {
            kotlin.srcDirs("src/main/kotlin")
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")

    implementation("androidx.camera:camera-core:1.3.4")
    implementation("androidx.camera:camera-camera2:1.3.4")
    implementation("androidx.camera:camera-lifecycle:1.3.4")
    implementation("androidx.camera:camera-view:1.3.4")

    implementation("com.google.mediapipe:tasks-vision:0.10.14")

    testImplementation("junit:junit:4.13.2")
}
```

- [ ] **Step 7: Write `app/src/main/AndroidManifest.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="true" />
    <uses-feature android:name="android.hardware.camera.front" android:required="true" />

    <application
        android:allowBackup="false"
        android:label="NASYN Pose Spike"
        android:theme="@style/Theme.PoseSpike">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

- [ ] **Step 8: Write `app/src/main/res/values/strings.xml`**

```xml
<resources>
    <string name="app_name">NASYN Pose Spike</string>
</resources>
```

- [ ] **Step 9: Write `app/src/main/res/values/themes.xml`**

```xml
<resources>
    <style name="Theme.PoseSpike" parent="Theme.AppCompat.DayNight.NoActionBar" />
</resources>
```

- [ ] **Step 10: Write skeleton `MainActivity.kt`**

```kotlin
package com.nasyn.posespike

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
```

- [ ] **Step 11: Build and verify**

```bash
export ANDROID_HOME=~/Android/Sdk
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`, `app/build/outputs/apk/debug/app-debug.apk` exists.

- [ ] **Step 12: Commit**

```bash
git add settings.gradle.kts build.gradle.kts gradle.properties gradlew gradlew.bat gradle app/build.gradle.kts app/src .gitignore
git commit -m "Scaffold pose spike Android project"
```

(Add a `.gitignore` with `*.iml`, `.gradle/`, `build/`, `local.properties`, `.idea/` before this step if not already present.)

---

## Task 2: `PoseClassifier` — pure-Kotlin pose classification logic

**Files:**
- Create: `app/src/main/kotlin/com/nasyn/posespike/pose/PoseLandmarks.kt`
- Create: `app/src/main/kotlin/com/nasyn/posespike/pose/PoseClassifier.kt`
- Test: `app/src/test/kotlin/com/nasyn/posespike/pose/PoseClassifierTest.kt`

**Interfaces:**
- Produces:
  - `data class Point(val x: Float, val y: Float)`
  - `data class PoseLandmarks(val nose: Point, val leftEar: Point, val rightEar: Point, val leftShoulder: Point, val rightShoulder: Point)`
  - `enum class PoseClass { QIYAM, RUKUK, SUJUD, DUDUK, UNKNOWN }`
  - `data class PoseClassification(val poseClass: PoseClass, val confidence: Int)`
  - `class CalibrationProfile` with `fun recordBaseline(poseClass: PoseClass, landmarks: PoseLandmarks)` and `fun isComplete(): Boolean`
  - `class PoseClassifier(private val calibration: CalibrationProfile)` with `fun classify(landmarks: PoseLandmarks): PoseClassification`
- Consumes: nothing from other tasks (this is the foundational pure-logic layer).

- [ ] **Step 1: Write `PoseLandmarks.kt`**

```kotlin
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
```

- [ ] **Step 2: Write the failing test for the classifier ratio metric and calibration**

```kotlin
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
```

- [ ] **Step 3: Run test to verify it fails**

```bash
export ANDROID_HOME=~/Android/Sdk
./gradlew :app:testDebugUnitTest --tests "com.nasyn.posespike.pose.PoseClassifierTest"
```

Expected: FAIL — `CalibrationProfile` and `PoseClassifier` are unresolved references.

- [ ] **Step 4: Write `PoseClassifier.kt`**

```kotlin
package com.nasyn.posespike.pose

import kotlin.math.abs

private fun headShoulderRatio(landmarks: PoseLandmarks): Float {
    val headY = (landmarks.nose.y + landmarks.leftEar.y + landmarks.rightEar.y) / 3f
    val shoulderY = (landmarks.leftShoulder.y + landmarks.rightShoulder.y) / 2f
    val shoulderWidth = abs(landmarks.rightShoulder.x - landmarks.leftShoulder.x)
    if (shoulderWidth == 0f) return 0f
    return (shoulderY - headY) / shoulderWidth
}

class CalibrationProfile {
    private val baselines = mutableMapOf<PoseClass, Float>()

    fun recordBaseline(poseClass: PoseClass, landmarks: PoseLandmarks) {
        baselines[poseClass] = headShoulderRatio(landmarks)
    }

    fun isComplete(): Boolean {
        val required = setOf(PoseClass.QIYAM, PoseClass.RUKUK, PoseClass.SUJUD, PoseClass.DUDUK)
        return baselines.keys.containsAll(required)
    }

    fun baselineRatios(): Map<PoseClass, Float> = baselines.toMap()
}

class PoseClassifier(private val calibration: CalibrationProfile) {

    fun classify(landmarks: PoseLandmarks): PoseClassification {
        if (!calibration.isComplete()) {
            return PoseClassification(PoseClass.UNKNOWN, 0)
        }

        val ratio = headShoulderRatio(landmarks)
        val baselines = calibration.baselineRatios()

        val distances = baselines.mapValues { (_, baselineRatio) -> abs(ratio - baselineRatio) }
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
```

- [ ] **Step 5: Run test to verify it passes**

```bash
./gradlew :app:testDebugUnitTest --tests "com.nasyn.posespike.pose.PoseClassifierTest"
```

Expected: `BUILD SUCCESSFUL`, 5 tests passed.

- [ ] **Step 6: Commit**

```bash
git add app/src/main/kotlin/com/nasyn/posespike/pose app/src/test
git commit -m "Add pure-Kotlin PoseClassifier with calibration baseline logic"
```

---

## Task 3: MediaPipe `PoseLandmarker` integration wrapper

**Files:**
- Create: `app/src/main/assets/pose_landmarker_lite.task`
- Create: `app/src/main/kotlin/com/nasyn/posespike/pose/PoseLandmarkerHelper.kt`

**Interfaces:**
- Consumes: nothing new from Task 2 directly (this produces raw MediaPipe landmarks; mapping to `PoseLandmarks` happens in Task 4's `MainActivity`).
- Produces:
  - `class PoseLandmarkerHelper(context: Context, private val listener: Listener)` with `fun detectAsync(bitmap: Bitmap, rotationDegrees: Int, isFrontCamera: Boolean, frameTimeMs: Long)` and `fun close()`
  - `interface Listener { fun onResult(result: PoseLandmarkerResult, inferenceTimeMs: Long); fun onError(message: String) }`
  - Re-exports `com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult` as the result type consumers see.

- [ ] **Step 1: Download the MediaPipe pose landmarker LITE model**

```bash
mkdir -p app/src/main/assets
curl -sL -o app/src/main/assets/pose_landmarker_lite.task \
  https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task
ls -la app/src/main/assets/pose_landmarker_lite.task
```

Expected: file exists, several MB in size (not 0 bytes, not an HTML error page — run `file app/src/main/assets/pose_landmarker_lite.task` and confirm it is *not* reported as ASCII/HTML text).

- [ ] **Step 2: Write `PoseLandmarkerHelper.kt`**

```kotlin
package com.nasyn.posespike.pose

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

class PoseLandmarkerHelper(
    context: Context,
    private val listener: Listener,
) {
    interface Listener {
        fun onResult(result: PoseLandmarkerResult, inferenceTimeMs: Long)
        fun onError(message: String)
    }

    private var poseLandmarker: PoseLandmarker? = null

    init {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("pose_landmarker_lite.task")
            .build()

        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumPoses(1)
            .setMinPoseDetectionConfidence(0.5f)
            .setMinPosePresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setResultListener(::handleResult)
            .setErrorListener { error -> listener.onError(error.message ?: "unknown MediaPipe error") }
            .build()

        poseLandmarker = PoseLandmarker.createFromOptions(context, options)
    }

    private var lastFrameStartMs = 0L

    fun detectAsync(bitmap: Bitmap, rotationDegrees: Int, isFrontCamera: Boolean, frameTimeMs: Long) {
        lastFrameStartMs = SystemClock.uptimeMillis()
        val matrix = Matrix().apply {
            postRotate(rotationDegrees.toFloat())
            if (isFrontCamera) postScale(-1f, 1f, bitmap.width.toFloat(), bitmap.height.toFloat())
        }
        val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        val mpImage = BitmapImageBuilder(rotated).build()
        poseLandmarker?.detectAsync(mpImage, frameTimeMs)
    }

    private fun handleResult(result: PoseLandmarkerResult) {
        val inferenceTimeMs = SystemClock.uptimeMillis() - lastFrameStartMs
        listener.onResult(result, inferenceTimeMs)
    }

    fun close() {
        poseLandmarker?.close()
        poseLandmarker = null
    }
}
```

- [ ] **Step 3: Build to verify it compiles (no runtime test — this needs a device/camera, covered in Task 7)**

```bash
export ANDROID_HOME=~/Android/Sdk
./gradlew :app:compileDebugKotlin
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add app/src/main/assets/pose_landmarker_lite.task app/src/main/kotlin/com/nasyn/posespike/pose/PoseLandmarkerHelper.kt
git commit -m "Add MediaPipe PoseLandmarker LIVE_STREAM wrapper"
```

---

## Task 4: CameraX pipeline + landmark mapping in `MainActivity`

**Files:**
- Modify: `app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt`
- Create: `app/src/main/kotlin/com/nasyn/posespike/pose/LandmarkMapper.kt`

**Interfaces:**
- Consumes: `PoseLandmarkerHelper` and `PoseLandmarkerHelper.Listener` (Task 3), `PoseClassifier`, `CalibrationProfile`, `PoseLandmarks`, `Point`, `PoseClass`, `PoseClassification` (Task 2).
- Produces:
  - `object LandmarkMapper` with `fun toPoseLandmarks(result: PoseLandmarkerResult): PoseLandmarks?` (null if no pose detected in frame)
  - `MainActivity` holds `val calibration = CalibrationProfile()` and `val classifier = PoseClassifier(calibration)`, and exposes the latest `PoseClassification` + `inferenceTimeMs` via a `MutableState`-free simple callback interface `interface ResultObserver { fun onClassification(classification: PoseClassification, inferenceTimeMs: Long) }` that Task 5 (overlay) and Task 6 (tally) will register against.

- [ ] **Step 1: Write `LandmarkMapper.kt`**

```kotlin
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
```

- [ ] **Step 2: Write full `MainActivity.kt`**

```kotlin
package com.nasyn.posespike

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Bundle
import android.util.Size
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
```

- [ ] **Step 3: Build to verify it compiles**

```bash
export ANDROID_HOME=~/Android/Sdk
./gradlew :app:compileDebugKotlin
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add app/src/main/kotlin/com/nasyn/posespike/pose/LandmarkMapper.kt app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt
git commit -m "Wire CameraX ImageAnalysis into PoseLandmarkerHelper and classifier"
```

---

## Task 5: `PoseOverlayView` — live skeleton + text overlay

**Files:**
- Create: `app/src/main/kotlin/com/nasyn/posespike/ui/PoseOverlayView.kt`
- Modify: `app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt:onCreate` (add overlay, register as `ResultObserver`)

**Interfaces:**
- Consumes: `ResultObserver` interface, `PoseClassification`, `PoseLandmarks`, `PoseClass` (Task 2/4).
- Produces: `class PoseOverlayView(context: Context) : View(context)` with `fun update(classification: PoseClassification, landmarks: PoseLandmarks?, inferenceTimeMs: Long)`.

- [ ] **Step 1: Write `PoseOverlayView.kt`**

```kotlin
package com.nasyn.posespike.ui

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.View
import com.nasyn.posespike.pose.PoseClassification
import com.nasyn.posespike.pose.PoseLandmarks

class PoseOverlayView(context: Context) : View(context) {

    private val dotPaint = Paint().apply {
        color = Color.GREEN
        style = Paint.Style.FILL
    }
    private val textPaint = Paint().apply {
        color = Color.WHITE
        textSize = 48f
        isFakeBoldText = true
    }
    private val textBackgroundPaint = Paint().apply {
        color = Color.argb(180, 0, 0, 0)
        style = Paint.Style.FILL
    }

    private var classification: PoseClassification? = null
    private var landmarks: PoseLandmarks? = null
    private var inferenceTimeMs: Long = 0

    fun update(classification: PoseClassification, landmarks: PoseLandmarks?, inferenceTimeMs: Long) {
        this.classification = classification
        this.landmarks = landmarks
        this.inferenceTimeMs = inferenceTimeMs
        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        landmarks?.let { lm ->
            val points = listOf(lm.nose, lm.leftEar, lm.rightEar, lm.leftShoulder, lm.rightShoulder)
            for (point in points) {
                canvas.drawCircle(point.x * width, point.y * height, 12f, dotPaint)
            }
        }

        val result = classification ?: return
        val lines = listOf(
            "Pose: ${result.poseClass}",
            "Confidence: ${result.confidence}%",
            "Latency: ${inferenceTimeMs}ms",
        )
        canvas.drawRect(20f, 60f, 620f, 260f, textBackgroundPaint)
        lines.forEachIndexed { index, line ->
            canvas.drawText(line, 40f, 120f + index * 60f, textPaint)
        }
    }
}
```

- [ ] **Step 2: Wire the overlay into `MainActivity.onCreate`**

Modify `app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt`: add the
import, create the overlay, add it on top of `previewView`, and register
`MainActivity` as the observer that forwards results to it.

Add import:
```kotlin
import android.view.ViewGroup
import com.nasyn.posespike.ui.PoseOverlayView
```

Add a property and wire it at the end of `onCreate`, right after
`setContentView(rootLayout)`:
```kotlin
        val overlay = PoseOverlayView(this)
        rootLayout.addView(overlay, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        setResultObserver(object : ResultObserver {
            override fun onClassification(classification: PoseClassification, landmarks: PoseLandmarks?, inferenceTimeMs: Long) {
                overlay.update(classification, landmarks, inferenceTimeMs)
            }
        })
```

- [ ] **Step 3: Build to verify it compiles**

```bash
export ANDROID_HOME=~/Android/Sdk
./gradlew :app:compileDebugKotlin
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add app/src/main/kotlin/com/nasyn/posespike/ui/PoseOverlayView.kt app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt
git commit -m "Add live pose overlay (landmarks, class, confidence, latency)"
```

---

## Task 6: Calibration buttons + `TallyLogger` (✓/✗ CSV logging)

**Files:**
- Create: `app/src/main/kotlin/com/nasyn/posespike/tally/TallyLogger.kt`
- Create: `app/src/main/kotlin/com/nasyn/posespike/ui/ControlPanel.kt`
- Modify: `app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt:onCreate`

**Interfaces:**
- Consumes: `CalibrationProfile`, `PoseClass`, `PoseClassification`, `PoseLandmarks` (Task 2), `MainActivity.calibration`/`classifier` (Task 4).
- Produces:
  - `class TallyLogger(context: Context)` with `fun log(predictedClass: PoseClass, confidence: Int, inferenceTimeMs: Long, correct: Boolean)` and `fun logFilePath(): String`
  - `class ControlPanel(context: Context, private val calibration: CalibrationProfile, private val tallyLogger: TallyLogger)` — a `LinearLayout` subclass exposing `fun currentLandmarksProvider(provider: () -> PoseLandmarks?)` and `fun currentClassificationProvider(provider: () -> PoseClassification)`, containing 4 calibration buttons + 2 tally buttons + a live tally count `TextView`.

- [ ] **Step 1: Write `TallyLogger.kt`**

```kotlin
package com.nasyn.posespike.tally

import android.content.Context
import com.nasyn.posespike.pose.PoseClass
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TallyLogger(context: Context) {

    private val logFile: File = File(context.getExternalFilesDir(null), "pose_spike_tally.csv")
    private val counts = mutableMapOf<PoseClass, Pair<Int, Int>>() // class -> (correct, incorrect)

    init {
        if (!logFile.exists()) {
            logFile.writeText("timestamp,predictedClass,confidence,latencyMs,correct\n")
        }
    }

    fun log(predictedClass: PoseClass, confidence: Int, inferenceTimeMs: Long, correct: Boolean) {
        val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())
        logFile.appendText("$timestamp,$predictedClass,$confidence,$inferenceTimeMs,$correct\n")

        val (correctCount, incorrectCount) = counts.getOrDefault(predictedClass, 0 to 0)
        counts[predictedClass] = if (correct) {
            (correctCount + 1) to incorrectCount
        } else {
            correctCount to (incorrectCount + 1)
        }
    }

    fun summary(): String {
        return counts.entries.joinToString("\n") { (poseClass, tally) ->
            "$poseClass: ${tally.first} correct / ${tally.second} incorrect"
        }
    }

    fun logFilePath(): String = logFile.absolutePath
}
```

- [ ] **Step 2: Write `ControlPanel.kt`**

```kotlin
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
                tallyLogger.log(result.poseClass, result.confidence, 0, correct = true)
                refreshSummary()
            }
        })
        tallyRow.addView(Button(context).apply {
            text = "✗ Wrong"
            setOnClickListener {
                val result = classificationProvider()
                tallyLogger.log(result.poseClass, result.confidence, 0, correct = false)
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

    private fun refreshSummary() {
        summaryView.text = tallyLogger.summary()
    }
}
```

- [ ] **Step 3: Wire `ControlPanel` into `MainActivity`**

Modify `app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt`.

Add imports:
```kotlin
import android.view.Gravity
import com.nasyn.posespike.tally.TallyLogger
import com.nasyn.posespike.ui.ControlPanel
```

Add a property near the top of the class:
```kotlin
    private var latestLandmarks: PoseLandmarks? = null
    private var latestClassification: PoseClassification = PoseClassification(PoseClass.UNKNOWN, 0)
```

In the `ResultObserver` registered in Task 5, also store the latest values
before forwarding to the overlay — replace that block with:
```kotlin
        setResultObserver(object : ResultObserver {
            override fun onClassification(classification: PoseClassification, landmarks: PoseLandmarks?, inferenceTimeMs: Long) {
                latestLandmarks = landmarks
                latestClassification = classification
                overlay.update(classification, landmarks, inferenceTimeMs)
            }
        })
```

After that block, add the control panel:
```kotlin
        val tallyLogger = TallyLogger(this)
        val controlPanel = ControlPanel(this, calibration, tallyLogger)
        controlPanel.currentLandmarksProvider { latestLandmarks }
        controlPanel.currentClassificationProvider { latestClassification }
        rootLayout.addView(
            controlPanel,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                (this as? FrameLayout.LayoutParams)?.gravity = Gravity.BOTTOM
            },
        )
```

Note: `rootLayout.addView(controlPanel, params)` requires `params` to
already be a `FrameLayout.LayoutParams` for the gravity cast to apply —
construct it directly as `FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM)`
instead:
```kotlin
        rootLayout.addView(
            controlPanel,
            FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM),
        )
```

- [ ] **Step 4: Build to verify it compiles**

```bash
export ANDROID_HOME=~/Android/Sdk
./gradlew :app:compileDebugKotlin
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Commit**

```bash
git add app/src/main/kotlin/com/nasyn/posespike/tally app/src/main/kotlin/com/nasyn/posespike/ui/ControlPanel.kt app/src/main/kotlin/com/nasyn/posespike/MainActivity.kt
git commit -m "Add calibration buttons and correct/wrong tally logging"
```

---

## Task 7: Build, install to Redmi 9A, smoke test

**Files:**
- None created — this task verifies the app on-device. If any manifest/permission issue surfaces, fix in `app/src/main/AndroidManifest.xml`.

**Interfaces:**
- Consumes: the complete app from Tasks 1–6.
- Produces: a running app on-device and a confirmed non-empty tally CSV, ready for the manual test protocol described in the design spec.

- [ ] **Step 1: Build the debug APK**

```bash
export ANDROID_HOME=~/Android/Sdk
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`, `app/build/outputs/apk/debug/app-debug.apk` produced.

- [ ] **Step 2: Confirm device is connected and authorized**

```bash
adb devices -l
```

Expected: `9HJ7OZ55XSXOPVJZ  device` (not `unauthorized`, not empty).

- [ ] **Step 3: Install and launch**

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.nasyn.posespike/.MainActivity
```

Expected: no `INSTALL_FAILED_*` error; app launches on-device (camera
permission dialog appears on first launch — tap Allow).

- [ ] **Step 4: Confirm live classification and logging work**

On-device: tap Allow on the camera permission dialog, then tap each of the
4 calibration buttons (Berdiri/Rukuk/Sujud/Duduk) while holding the
matching pose, then tap ✓/✗ a few times and confirm the summary text
updates.

```bash
adb pull /sdcard/Android/data/com.nasyn.posespike/files/pose_spike_tally.csv /tmp/pose_spike_tally.csv
cat /tmp/pose_spike_tally.csv
```

Expected: header row plus one line per ✓/✗ tap, with non-empty
`predictedClass` and `confidence` values.

- [ ] **Step 5: Commit any manifest/permission fixes found during smoke test**

Only if changes were needed:
```bash
git add app/src/main/AndroidManifest.xml
git commit -m "Fix camera permission/manifest issue found during device smoke test"
```

If no changes were needed, skip this step — there is nothing to commit.

---

## Self-Review Notes

- **Spec coverage:** Architecture (CameraX→PoseLandmarker→Classifier→Overlay→TallyLogger) = Tasks 1–6. Calibration = Task 6. GO/NO-GO data collection = Task 7 (app-side) + manual protocol (spec, not code). JVM unit test on `PoseClassifier` = Task 2. Out-of-scope items (Flutter, FSM, audio, kiosk, telekung/low-light pass) are not present in any task — correct, they're explicitly deferred.
- **Type consistency:** `PoseClassification`, `PoseClass`, `PoseLandmarks`, `Point`, `CalibrationProfile`, `PoseClassifier`, `PoseLandmarkerHelper.Listener`, `ResultObserver`, `TallyLogger`, `ControlPanel` are each defined once (Task 2/3/4/5/6) and reused with identical signatures in later tasks.
- **No placeholders:** every step has runnable code and an exact expected result; no "TODO"/"handle appropriately" left in.

---

*After Task 7, the manual test protocol from the design spec (≥15–20 reps
per pose class, ✓/✗ tally, telekung/lighting follow-up) is a human
activity, not a coding task — its output (`SPIKE-RESULT.md` with the
GO/PARTIAL/NO-GO verdict) should be written up once that data is
collected.*
