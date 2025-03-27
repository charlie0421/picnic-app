package io.iconcasting.picnic.app

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

class PincruxPlugin: FlutterPlugin, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var pincruxHandler: PincruxHandler

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, PincruxHandler.METHOD_CHANNEL_NAME)
        context = binding.applicationContext
        pincruxHandler = PincruxHandler(context)
        channel.setMethodCallHandler { call, result ->
            pincruxHandler.handleMethodCall(call, result)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        context = binding.activity
        pincruxHandler = PincruxHandler(context)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // No-op
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        context = binding.activity
        pincruxHandler = PincruxHandler(context)
    }

    override fun onDetachedFromActivity() {
        // No-op
    }
} 