package com.nasyn.nasyn_app

import android.app.admin.DeviceAdminReceiver

// Sasaran `dpm set-device-owner` semasa provisioning unit refurb (rujuk
// docs/PROVISIONING-DEVICE-OWNER.md). Tiada logic — kehadiran receiver ini
// sahaja yang diperlukan; setup COSU dibuat dalam MainActivity.
class NasynDeviceAdminReceiver : DeviceAdminReceiver()
