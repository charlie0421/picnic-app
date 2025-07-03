package io.iconcasting.picnic.app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.Locale
import pangle.custom.PangleNativeHandler
import com.pincrux.offerwall.PincruxOfferwall

class MainActivity : FlutterActivity() {
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Pangle 네이티브 핸들러 등록
        flutterEngine.plugins.add(PangleNativeHandler())
        
        // Pincrux 오퍼월 초기화 (플러그인 등록 대신 초기화만)
        // PincruxOfferwall는 Flutter 플러그인이 아니라 네이티브 SDK이므로 
        // 별도 초기화가 필요한 경우 여기서 처리
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
