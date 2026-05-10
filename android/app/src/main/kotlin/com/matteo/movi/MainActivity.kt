package com.matteo.movi

import android.app.UiModeManager
import android.app.PictureInPictureParams
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PIP_CHANNEL = "movi/native_pip"
    private val DEVICE_CAPABILITIES_CHANNEL = "movi/device_capabilities"
    private var pipChannel: MethodChannel? = null
    private var deviceCapabilitiesChannel: MethodChannel? = null
    private var isInPictureInPictureMode = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
        pipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                }
                "enter" -> {
                    enterPipMode()
                    result.success(null)
                }
                "exit" -> {
                    // Sur Android, on ne peut pas forcer la sortie du PiP depuis l'app
                    // L'utilisateur doit le faire manuellement
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        deviceCapabilitiesChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CAPABILITIES_CHANNEL
        )
        deviceCapabilitiesChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isTelevisionDevice" -> result.success(isTelevisionDevice())
                else -> result.notImplemented()
            }
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Notifier Flutter que l'utilisateur quitte l'app
        // Flutter décidera s'il faut entrer en PiP
        pipChannel?.invokeMethod("onUserLeaveHint", null)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration?
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        this.isInPictureInPictureMode = isInPictureInPictureMode
        // Notifier Flutter du changement d'état
        pipChannel?.invokeMethod(
            "onPipStateChanged",
            isInPictureInPictureMode
        )
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!isInPictureInPictureMode) {
                val aspectRatio = Rational(16, 9)
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(aspectRatio)
                    .build()
                enterPictureInPictureMode(params)
            }
        }
    }

    private fun isTelevisionDevice(): Boolean {
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        val isTelevisionUiMode =
            uiModeManager?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
        val hasLeanbackFeature =
            packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)

        return isTelevisionUiMode || hasLeanbackFeature
    }
}
