package com.example.splitico

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.splitico/upi_pay"
    private val UPI_PAY_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchUpiChooser") {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriString))
                        val chooserIntent = Intent.createChooser(intent, "Pay via UPI")
                        pendingResult = result
                        startActivityForResult(chooserIntent, UPI_PAY_REQUEST_CODE)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("UNAVAILABLE", "No UPI app found: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_URI", "URI string is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == UPI_PAY_REQUEST_CODE) {
            pendingResult?.let { result ->
                result.success(true)
                pendingResult = null
            }
        }
    }
}
