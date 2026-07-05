package com.nasyn.nasyn_app.vision

import android.os.SystemClock

// Vision Mode (§8.13, spike v3 PARTIAL-GO): state machine SUJUD sahaja,
// dari BboxClassifier spike yang divalidasi 4 sesi pada Redmi 9A —
// pemisahan jauh (0.03-0.08) vs sujud (>0.15, lonjakan 0.60-0.89).
// Tiada klasifikasi pose lain (spike buktikan tak boleh diharap: muka
// hanya menghala lensa semasa rukuk).
class SujudDetector(private val nowMs: () -> Long = SystemClock::uptimeMillis) {

    companion object {
        const val SUJUD_ENTER_RATIO = 0.15f
        const val FAR_RATIO = 0.10f
        // Data device: kepala menutup lens sepenuhnya semasa tahan sujud
        // (detection hilang sampai 26s) — hold tamat bila muka jelas jauh
        // kembali, siling 45s sebagai sanity guard.
        const val SUJUD_MAX_HOLD_MS = 45_000L
    }

    private var holdStartMs = Long.MIN_VALUE / 2
    private var inSujud = false

    /** ratio = luas bbox muka / luas frame; null = tiada muka dikesan. */
    fun update(ratio: Float?): Boolean {
        val now = nowMs()

        if (ratio == null) {
            // Tiada detection semasa hold = kepala menutup lens, masih sujud
            if (inSujud && now - holdStartMs >= SUJUD_MAX_HOLD_MS) inSujud = false
            return inSujud
        }

        if (ratio >= SUJUD_ENTER_RATIO) {
            if (!inSujud) {
                inSujud = true
                holdStartMs = now
            }
            return true
        }

        if (ratio <= FAR_RATIO) {
            // Muka jelas jauh = kepala dah angkat
            inSujud = false
            return false
        }

        // Zon kelabu FAR..ENTER: detection separa semasa lens hampir
        // tertutup — kekalkan state semasa (jangan keluar hold)
        if (inSujud && now - holdStartMs >= SUJUD_MAX_HOLD_MS) inSujud = false
        return inSujud
    }
}
