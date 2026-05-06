package com.selfsign.webview.selfsign_webview_flutter

import android.webkit.JavascriptInterface
import android.webkit.WebView
import java.util.concurrent.atomic.AtomicReference

/**
 * The JavaScript interface attached to every WebView the plugin opens.
 *
 * Exposed in the page as:
 *   * `window.SelfsignBridge.postMessage(method, payload)` – preferred,
 *     cross-platform name.
 *   * `window.android.SVSNative(payload)` – preserved for backwards
 *     compatibility with the original Android `SimpleWebViewDemo`. It maps
 *     to method = `"SVSNative"`.
 */
internal class SelfsignJsBridge(
    private val webView: WebView,
    private val viewId: String?
) {

    /** Updated from the UI thread by the WebViewClient. */
    private val lastUrl = AtomicReference<String?>(null)

    fun setLastUrl(url: String?) {
        lastUrl.set(url)
    }

    @JavascriptInterface
    fun postMessage(method: String?, payload: String?) {
        val resolvedMethod = method ?: ""
        val resolvedPayload = payload ?: ""
        BridgeRegistry.send(resolvedMethod, resolvedPayload, lastUrl.get(), viewId)
    }

    @JavascriptInterface
    fun SVSNative(payload: String?) {
        val resolvedPayload = payload ?: ""
        BridgeRegistry.send("SVSNative", resolvedPayload, lastUrl.get(), viewId)
    }
}
