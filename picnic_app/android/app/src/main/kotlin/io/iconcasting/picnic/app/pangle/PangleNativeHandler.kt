package pangle.custom

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.bytedance.sdk.openadsdk.api.init.PAGConfig
import com.bytedance.sdk.openadsdk.api.init.PAGSdk
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardItem
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAd
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAdInteractionListener
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedAdLoadListener
import com.bytedance.sdk.openadsdk.api.reward.PAGRewardedRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** Pangle Android 네이티브 구현 */
class PangleNativeHandler : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private var activity: Activity? = null
    private var rewardedAd: PAGRewardedAd? = null
    private var isSDKInitialized = false
    private var appID: String? = null
    private var sandboxPlacementId: String? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pangle_native_channel")
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initPangle" -> {
                val appId = call.argument<String>("appId")
                val userId = call.argument<String>("userId")
                val environment = call.argument<String>("environment") ?: "prod"
                val productionAppId = call.argument<String>("productionAppId")
                val requestedSandboxPlacement = call.argument<String>("sandboxPlacementId")
                val productionPlacementId = call.argument<String>("productionPlacementId")
                val sandboxConfigValid = environment != "sandbox" ||
                    (appId != null &&
                        appId.isNotEmpty() &&
                        productionAppId != null &&
                        appId != productionAppId &&
                        !requestedSandboxPlacement.isNullOrEmpty() &&
                        requestedSandboxPlacement != productionPlacementId)
                if (appId != null &&
                    environment in setOf("prod", "sandbox") &&
                    sandboxConfigValid
                ) {
                    appID = appId
                    sandboxPlacementId =
                        if (environment == "sandbox") requestedSandboxPlacement else null
                    initPangle(appId, userId, result)
                } else {
                    result.error("InvalidParams", "Valid SDK configuration is required", null)
                }
            }
            "loadRewardedAd" -> {
                val placementId = call.argument<String>("placementId")
                    ?: return result.error("InvalidParams", "placementId is required", null)
                if (sandboxPlacementId != null && placementId != sandboxPlacementId) {
                    return result.error(
                        "InvalidSandboxPlacement",
                        "Sandbox placement rejected",
                        null,
                    )
                }
                val mediaExtra = call.argument<String>("mediaExtra")
                    ?: return result.error("InvalidParams", "mediaExtra is required", null)
                try {
                    val validated = PangleMediaExtra.requireV2(mediaExtra)
                    val configuredAppId = appID
                    if (!isSDKInitialized && configuredAppId == null) {
                        result.error("NotInitialized", "Pangle SDK가 초기화되지 않았습니다", null)
                        return
                    }
                    PangleLoadCoordinator.run(
                        initialized = isSDKInitialized,
                        initialize = { completion ->
                            initPangle(
                                configuredAppId!!,
                                null,
                                completion = completion,
                            )
                        },
                        placementId = placementId,
                        mediaExtra = validated,
                        load = { id, extra -> loadRewardedAd(id, extra, result) },
                        fail = { error -> result.error("InitFailed", error.message, null) },
                    )
                } catch (_: IllegalArgumentException) {
                    result.error("InvalidMediaExtra", "Signed v2 mediaExtra is required", null)
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun initPangle(
        appId: String,
        userId: String?,
        flutterResult: Result? = null,
        completion: ((kotlin.Result<Unit>) -> Unit)? = null,
    ) {
        println("Flutter에서 Pangle SDK 초기화 시작")

        if (isSDKInitialized && appID == appId) {
            println("Pangle SDK가 이미 초기화되어 있습니다.")
            flutterResult?.success(true)
            completion?.invoke(kotlin.Result.success(Unit))
            return
        }

        val pagConfig = PAGConfig.Builder()
            .appId(appId)
            .debugLog(true)
            .build()

        PAGSdk.init(applicationContext, pagConfig, object : PAGSdk.PAGInitCallback {
            override fun success() {
                println("Pangle SDK 초기화 성공")
                isSDKInitialized = true
                appID = appId
                flutterResult?.success(true)
                completion?.invoke(kotlin.Result.success(Unit))
            }

            override fun fail(code: Int, msg: String) {
                println("Pangle SDK 초기화 실패: $msg (코드: $code)")
                isSDKInitialized = false
                flutterResult?.error("InitFailed", msg, null)
                completion?.invoke(kotlin.Result.failure(IllegalStateException(msg)))
            }
        })
    }

    private fun loadRewardedAd(placementId: String, mediaExtra: String, result: Result) {
        println("리워드 광고 로드 시작 - placementId: $placementId")

        rewardedAd = null
        val request = PAGRewardedRequest()
        val extraInfo = hashMapOf<String, Any>()
        extraInfo["media_extra"] = mediaExtra
        request.extraInfo = extraInfo

        Handler(Looper.getMainLooper()).postDelayed({
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

    private fun showRewardedAd(result: Result) {
        if (rewardedAd != null) {
            println("리워드 광고 표시 시작")

            val currentActivity = activity
            if (currentActivity == null) {
                result.error("ShowFailed", "Activity가 없습니다", null)
                return
            }

            rewardedAd?.setAdInteractionListener(object : PAGRewardedAdInteractionListener {
                override fun onAdShowed() {
                    println("리워드 광고가 표시됨")
                    channel.invokeMethod(PangleEventNames.AD_SHOWN, null)
                }

                override fun onAdClicked() {
                    println("리워드 광고가 클릭됨")
                    channel.invokeMethod(PangleEventNames.AD_CLICKED, null)
                }

                override fun onAdDismissed() {
                    println("리워드 광고가 닫힘")
                    rewardedAd = null
                    channel.invokeMethod(PangleEventNames.AD_DISMISSED, null)
                }

                override fun onUserEarnedReward(item: PAGRewardItem) {
                    println("사용자가 보상을 받음: ${item.rewardAmount} ${item.rewardName}")
                    val rewardData = mapOf(
                        "amount" to item.rewardAmount,
                        "name" to item.rewardName
                    )
                    channel.invokeMethod(PangleEventNames.REWARD_EARNED, rewardData)
                }

                override fun onUserEarnedRewardFail(code: Int, msg: String) {
                    println("사용자 보상 획득 실패: $msg (코드: $code)")
                    val errorData = mapOf(
                        "code" to code,
                        "errorMessage" to msg
                    )
                    channel.invokeMethod(PangleEventNames.REWARD_FAILED, errorData)
                }
            })

            try {
                rewardedAd?.show(currentActivity)
                result.success(true)
            } catch (e: Exception) {
                println("광고 표시 중 예외 발생: ${e.message}")
                result.error("ShowFailed", "광고 표시 중 오류 발생: ${e.message}", null)
            }
        } else {
            result.error("ShowFailed", "리워드 광고가 준비되지 않았습니다", null)
        }
    }
}
