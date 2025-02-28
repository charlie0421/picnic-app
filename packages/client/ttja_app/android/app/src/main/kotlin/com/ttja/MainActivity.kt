package com.ttja

import android.content.Intent
import androidx.annotation.NonNull
import com.pincrux.offerwall.PincruxOfferwall
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL_NAME = "com.pincrux.offerwall.flutter"
    }

    private val offerwall = PincruxOfferwall.getInstance()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register generated plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Set up the method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "init" -> {
                        val pubkey: String? = call.argument("pubkey")
                        val usrkey: String? = call.argument("usrkey")
                        offerwall.init(this, pubkey, usrkey)
                    }

                    "startOfferwall" -> {
                        offerwall.startPincruxOfferwallActivity(this)
                    }

                    "startPincruxOfferwallAdDetail" -> {
                        val appkey: String? = call.argument("appkey")
                        offerwall.startPincruxOfferwallDetailActivity(this, appkey)
                    }

                    "startPincruxOfferwallContact" -> {
                        offerwall.startPincruxContactActivity(this)
                    }

                    "setOfferwallType" -> {
                        val type: Int? = call.argument("type")
                        if (type != null) {
                            offerwall.setOfferwallType(type)
                        }
                    }

                    "setEnableTab" -> {
                        val isEnable: Boolean? = call.argument("isEnable")
                        if (isEnable != null) {
                            offerwall.setEnableTab(isEnable)
                        }
                    }

                    "setOfferwallTitle" -> {
                        val title: String? = call.argument("title")
                        offerwall.setOfferwallTitle(title)
                    }

                    "setOfferwallThemeColor" -> {
                        val color: String? = call.argument("color")
                        offerwall.setOfferwallThemeColor(color)
                    }

                    "setEnableScrollTopButton" -> {
                        val isEnable: Boolean? = call.argument("isEnable")
                        if (isEnable != null) {
                            offerwall.setEnableScrollTopButton(isEnable)
                        }
                    }

                    "setAdDetail" -> {
                        val isEnable: Boolean? = call.argument("isEnable")
                        if (isEnable != null) {
                            offerwall.setAdDetail(isEnable)
                        }
                    }

                    "setDisableCPS" -> {
                        val isDisable: Boolean? = call.argument("isDisable")
                        if (isDisable != null) {
                            offerwall.setDisableCPS(isDisable)
                        }
                    }

                    "setDarkMode" -> {
                        val darkmode: Int? = call.argument("mode")
                        if (darkmode != null) {
                            offerwall.setDarkMode(darkmode)
                        }
                    }

                    else -> {
                        throw IllegalStateException("Unexpected value: ${call.method}")
                    }
                }
            }
    }
}
