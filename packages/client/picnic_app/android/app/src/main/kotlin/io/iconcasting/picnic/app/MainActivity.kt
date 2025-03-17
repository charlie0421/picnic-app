package io.iconcasting.picnic.app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.NonNull
import com.bytedance.sdk.openadsdk.api.init.PAGConfig
import com.bytedance.sdk.openadsdk.api.init.PAGSdk
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardItem
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAd
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAdInteractionListener
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAdLoadListener
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pangle_native_channel"
    private var rewardedAd: PAGRewardedAd? = null
    private var isSDKInitialized = false
    private var appID: String? = null

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
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initPangle" -> {
                    val appId = call.argument<String>("appId")
                    if (appId != null) {
                        appID = appId
                        initPangle(appId, result)
                    } else {
                        result.error("InvalidParams", "App ID is null", null)
                    }
                }
                "loadRewardedAd" -> {
                    val placementId = call.argument<String>("placementId")
                    if (placementId != null) {
                        if (isSDKInitialized) {
                            loadRewardedAd(placementId, result)
                        } else if (appID != null) {
                            // SDK가 초기화되지 않았다면 다시 초기화 시도 후 광고 로드
                            println("SDK가 초기화되지 않았습니다. 재초기화 시도 중...")
                            initPangle(appID!!) { success, errorMessage ->
                                if (success) {
                                    loadRewardedAd(placementId, result)
                                } else {
                                    result.error("InitFailed", "Pangle SDK 초기화 실패: $errorMessage", null)
                                }
                            }
                        } else {
                            result.error("NotInitialized", "Pangle SDK가 초기화되지 않았습니다", null)
                        }
                    } else {
                        result.error("InvalidParams", "Placement ID is null", null)
                    }
                }
                "showRewardedAd" -> {
                    showRewardedAd(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun initPangle(appId: String, flutterResult: MethodChannel.Result? = null) {
        println("Flutter에서 Pangle SDK 초기화 시작 - appId: $appId")
        
        // 이미 초기화된 상태면 바로 성공 반환
        if (isSDKInitialized && appID == appId) {
            println("Pangle SDK가 이미 초기화되어 있습니다.")
            flutterResult?.success(true)
            return
        }
        
        val pagConfig = PAGConfig.Builder()
            .appId(appId)
            .debugLog(BuildConfig.DEBUG)
            .build()
        
        PAGSdk.init(this, pagConfig, object : PAGSdk.PAGInitCallback {
            override fun success() {
                println("Pangle SDK 초기화 성공")
                isSDKInitialized = true
                appID = appId
                flutterResult?.success(true)
            }
            
            override fun fail(code: Int, msg: String) {
                println("Pangle SDK 초기화 실패: $msg (코드: $code)")
                isSDKInitialized = false
                flutterResult?.error("InitFailed", msg, null)
            }
        })
    }
    
    private fun initPangle(appId: String, callback: (Boolean, String) -> Unit) {
        println("Flutter에서 Pangle SDK 초기화 시작 - appId: $appId")
        
        // 이미 초기화된 상태면 바로 성공 반환
        if (isSDKInitialized && appID == appId) {
            println("Pangle SDK가 이미 초기화되어 있습니다.")
            callback(true, "이미 초기화됨")
            return
        }
        
        val pagConfig = PAGConfig.Builder()
            .appId(appId)
            .debugLog(BuildConfig.DEBUG)
            .build()
        
        PAGSdk.init(this, pagConfig, object : PAGSdk.PAGInitCallback {
            override fun success() {
                println("Pangle SDK 초기화 성공")
                isSDKInitialized = true
                appID = appId
                callback(true, "성공")
            }
            
            override fun fail(code: Int, msg: String) {
                println("Pangle SDK 초기화 실패: $msg (코드: $code)")
                isSDKInitialized = false
                callback(false, msg)
            }
        })
    }
    
    private fun loadRewardedAd(placementId: String, result: MethodChannel.Result) {
        println("리워드 광고 로드 시작 - placementId: $placementId")
        
        // SDK가 초기화되지 않았으면 초기화 상태를 확인
        if (!isSDKInitialized) {
            result.error("NotInitialized", "Pangle SDK가 초기화되지 않았습니다", null)
            return
        }
        
        // 이전 광고 객체 정리
        rewardedAd = null
        
        val request = PAGRewardedRequest()
        
        // 안전 장치: 광고 로드 시도 전 약간의 지연 추가
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            PAGRewardedAd.loadAd(placementId, request, object : PAGRewardedAdLoadListener {
                override fun onError(code: Int, msg: String) {
                    println("리워드 광고 로드 실패: $msg (코드: $code)")
                    result.error("LoadFailed", msg, null)
                }
                
                override fun onAdLoaded(ad: PAGRewardedAd) {
                    println("리워드 광고 로드 성공")
                    rewardedAd = ad
                    result.success(true)
                }
            })
        }, 500)
    }
    
    private fun showRewardedAd(result: MethodChannel.Result) {
        if (rewardedAd != null) {
            println("리워드 광고 표시 시작")
            
            rewardedAd?.setAdInteractionListener(object : PAGRewardedAdInteractionListener {
                override fun onAdShowed() {
                    println("리워드 광고가 표시됨")
                }
                
                override fun onAdClicked() {
                    println("리워드 광고가 클릭됨")
                }
                
                override fun onAdDismissed() {
                    println("리워드 광고가 닫힘")
                    rewardedAd = null
                }
                
                override fun onUserEarnedReward(item: PAGRewardItem) {
                    println("사용자가 보상을 받음: ${item.rewardAmount} ${item.rewardName}")
                }
                
                override fun onUserEarnedRewardFail(code: Int, msg: String) {
                    println("사용자 보상 획득 실패: $msg (코드: $code)")
                }
            })
            
            rewardedAd?.show(this)
            result.success(true)
        } else {
            result.error("ShowFailed", "리워드 광고가 준비되지 않았습니다", null)
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