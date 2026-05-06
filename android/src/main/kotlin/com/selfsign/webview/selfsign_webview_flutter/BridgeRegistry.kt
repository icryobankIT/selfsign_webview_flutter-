package com.selfsign.webview.selfsign_webview_flutter

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Process-wide singleton that fans bridge events from any active WebView
 * (full-screen Activity or embedded PlatformView) to the single Flutter
 * EventChannel sink.
 */
internal object BridgeRegistry : EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    /**
     * Forward a bridge event to Flutter on the main thread.
     */
    fun send(method: String, payload: String, sourceUrl: String?, viewId: String?) {
        mainHandler.post {
            val map = HashMap<String, Any?>()
            map["method"] = method
            map["payload"] = payload
            map["sourceUrl"] = sourceUrl
            map["viewId"] = viewId
            sink?.success(map)
        }
    }
}
