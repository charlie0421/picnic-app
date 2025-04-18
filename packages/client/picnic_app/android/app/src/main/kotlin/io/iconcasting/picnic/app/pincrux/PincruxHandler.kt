package io.iconcasting.picnic.app

import android.content.Context
import com.pincrux.offerwall.PincruxOfferwall
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PincruxHandler(private val context: Context) {
    companion object {
        const val METHOD_CHANNEL_NAME = "com.pincrux.offerwall.flutter"
    }

    private val offerwall = PincruxOfferwall.getInstance()

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                val pubkey: String? = call.argument("pubkey")
                val usrkey: String? = call.argument("usrkey")
                offerwall.init(pubkey, usrkey)
                result.success(null)
            }
            "startOfferwall" -> {
                offerwall.startPincruxOfferwallActivity(context)
                result.success(null)
            }
            "startPincruxOfferwallAdDetail" -> {
                val appkey: String? = call.argument("appkey")
                offerwall.startPincruxOfferwallDetailActivity(context, appkey)
                result.success(null)
            }
            "startPincruxOfferwallContact" -> {
                offerwall.startPincruxContactActivity(context)
                result.success(null)
            }
            "setOfferwallType" -> {
                val type: Int? = call.argument("type")
                if (type != null) {
                    offerwall.setOfferwallType(type)
                }
                result.success(null)
            }
            "setEnableTab" -> {
                val isEnable: Boolean? = call.argument("isEnable")
                if (isEnable != null) {
                    offerwall.setEnableTab(isEnable)
                }
                result.success(null)
            }
            "setOfferwallTitle" -> {
                val title: String? = call.argument("title")
                offerwall.setOfferwallTitle(title)
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
} 