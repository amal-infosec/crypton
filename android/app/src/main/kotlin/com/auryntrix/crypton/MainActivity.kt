package com.auryntrix.crypton

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Build
import android.view.WindowManager

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.configureFlutterEngine(flutterEngine)
        
        // Request high refresh rate for 120Hz devices (Android 11+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val display = display
            if (display != null) {
                val modes = display.supportedModes
                var highestRefreshRateMode = if (modes.isNotEmpty()) modes[0] else null
                for (mode in modes) {
                    if (highestRefreshRateMode == null || mode.refreshRate > highestRefreshRateMode.refreshRate) {
                        highestRefreshRateMode = mode
                    }
                }
                
                if (highestRefreshRateMode != null) {
                    val attrs = window.attributes
                    attrs.preferredDisplayModeId = highestRefreshRateMode.modeId
                    window.attributes = attrs
                }
            }
        }
    }
}
