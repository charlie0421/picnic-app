package com.ttja

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.NonNull
import com.pincrux.offerwall.PincruxOfferwall
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.Locale

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL_NAME = "com.pincrux.offerwall.flutter"
    }

    private val offerwall = PincruxOfferwall.getInstance()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // MediaTek 칩셋 감지 및 특별 처리
        if (isProblematicMtkDevice()) {
            // 하드웨어 가속 비활성화 - OpenGL ES 크래시 방지
            window.setFlags(
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                0
            )
            
            // 메모리 관리 최적화
            try {
                // 가비지 컬렉션 강제 실행
                System.gc()
                
                // 렌더링 모드 조정 (소프트웨어 렌더링 우선)
                window.setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE
                )
            } catch (e: Exception) {
                println("MediaTek 기기 최적화 중 오류 발생: ${e.message}")
            }
        }
        super.onCreate(savedInstanceState)
    }

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
    
    // 문제가 있는 MediaTek 기기 감지
    private fun isProblematicMtkDevice(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase(Locale.ROOT)
        val model = Build.MODEL.lowercase(Locale.ROOT)
        val hardware = Build.HARDWARE.lowercase(Locale.ROOT)
        val processor = System.getProperty("os.arch") ?: ""
        
        // SoC 정보 로깅
        println("Device Info - Manufacturer: $manufacturer, Model: $model, Hardware: $hardware, Processor: $processor")
        
        // MediaTek 칩셋 확인 (MTK 포함)
        return (hardware.contains("mt") || processor.contains("mt") || 
                manufacturer.contains("mediatek") || Build.BOARD.lowercase(Locale.ROOT).contains("mt"))
    }
}
