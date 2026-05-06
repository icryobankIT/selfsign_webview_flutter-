package com.selfsign.webview.selfsign_webview_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class SelfsignWebviewFlutterPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {

    private lateinit var applicationContext: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var activityBinding: ActivityPluginBinding? = null
    private val activeActivityResultListeners = mutableSetOf<PluginRegistry.ActivityResultListener>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(BridgeRegistry)

        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            SelfsignWebViewFactory(
                activitySupplier = { activityBinding?.activity },
                activityResultRegistrar = { listener ->
                    activityBinding?.addActivityResultListener(listener)
                    activeActivityResultListeners.add(listener)
                },
                activityResultUnregistrar = { listener ->
                    activityBinding?.removeActivityResultListener(listener)
                    activeActivityResultListeners.remove(listener)
                }
            )
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        // Re-register any pending listeners (PlatformView creation order may
        // race the ActivityAware lifecycle).
        for (listener in activeActivityResultListeners) {
            binding.addActivityResultListener(listener)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        clearActivityListeners()
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        clearActivityListeners()
        activityBinding = null
    }

    private fun clearActivityListeners() {
        val binding = activityBinding ?: return
        for (listener in activeActivityResultListeners) {
            binding.removeActivityResultListener(listener)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "open" -> handleOpen(call, result)
            "close" -> handleClose(result)
            else -> result.notImplemented()
        }
    }

    private fun handleOpen(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url")
        if (url.isNullOrEmpty()) {
            result.error("invalid_url", "url is required", null)
            return
        }
        val appType = call.argument<String>("appType") ?: "PatientAPP02"
        val title = call.argument<String>("title") ?: ""
        val confirmBeforeBack = call.argument<Boolean>("confirmBeforeBack") ?: true
        val allowInsecureSsl = call.argument<Boolean>("allowInsecureSsl") ?: true

        val launchContext: Context = activityBinding?.activity ?: applicationContext
        val intent = Intent(launchContext, SelfsignWebViewActivity::class.java).apply {
            putExtra(SelfsignWebViewActivity.EXTRA_URL, url)
            putExtra(SelfsignWebViewActivity.EXTRA_APP_TYPE, appType)
            putExtra(SelfsignWebViewActivity.EXTRA_TITLE, title)
            putExtra(SelfsignWebViewActivity.EXTRA_CONFIRM_BACK, confirmBeforeBack)
            putExtra(SelfsignWebViewActivity.EXTRA_ALLOW_INSECURE_SSL, allowInsecureSsl)
            if (launchContext !is Activity) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        launchContext.startActivity(intent)
        result.success(true)
    }

    private fun handleClose(result: MethodChannel.Result) {
        SelfsignWebViewActivity.current?.finish()
        result.success(null)
    }

    companion object {
        private const val CHANNEL_NAME = "selfsign_webview_flutter"
        private const val EVENT_CHANNEL_NAME = "selfsign_webview_flutter/events"
        private const val VIEW_TYPE = "selfsign_webview_flutter/view"
    }
}
