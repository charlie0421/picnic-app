package com.ttja

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.Locale
import pangle.custom.PangleNativeHandler

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
    }

    // 문제가 있는 MediaTek 기기 감지
    private fun isProblematicMtkDevice(): Boolean {
        return Build.MANUFACTURER.equals("MediaTek", ignoreCase = true)
    }
} 