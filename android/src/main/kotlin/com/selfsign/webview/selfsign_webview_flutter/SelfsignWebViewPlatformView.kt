package com.selfsign.webview.selfsign_webview_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebView
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView

/**
 * Embedded WebView used by `SelfsignWebViewWidget`. Reuses the same setup
 * helpers as the full-screen Activity.
 */
internal class SelfsignWebViewPlatformView(
    private val context: Context,
    private val viewId: Int,
    creationParams: Map<String, Any?>?,
    private val activitySupplier: () -> Activity?,
    private val activityResultRegistrar: (PluginRegistry.ActivityResultListener) -> Unit,
    private val activityResultUnregistrar: (PluginRegistry.ActivityResultListener) -> Unit
) : PlatformView, PluginRegistry.ActivityResultListener {

    private val webView: WebView = WebView(context)
    private val jsBridge: SelfsignJsBridge
    private var fileChooser: SelfsignFileChooser? = null

    init {
        val url = creationParams?.get("url") as? String ?: ""
        val appType = creationParams?.get("appType") as? String ?: "PatientAPP02"
        val allowInsecureSsl = (creationParams?.get("allowInsecureSsl") as? Boolean) ?: true

        SelfsignWebViewSetup.applyDefaultSettings(webView)

        jsBridge = SelfsignJsBridge(webView, viewId = viewId.toString())

        webView.webViewClient = SelfsignWebViewSetup.buildWebViewClient(
            context = context,
            appType = appType,
            allowInsecureSsl = allowInsecureSsl,
            onProgressVisibilityChange = { /* no progress widget in embedded mode */ },
            onUrlChanged = { jsBridge.setLastUrl(it) }
        )
        webView.webChromeClient = SelfsignWebViewSetup.buildWebChromeClient(
            context = context,
            fileChooserHandler = object : SelfsignWebViewSetup.ShowFileChooserHandler {
                override fun handle(
                    filePathCallback: ValueCallback<Array<Uri>>,
                    params: WebChromeClient.FileChooserParams
                ): Boolean {
                    val activity = activitySupplier()
                    if (activity == null) {
                        filePathCallback.onReceiveValue(null)
                        return false
                    }
                    if (fileChooser == null) {
                        fileChooser = SelfsignFileChooser(activity)
                        activityResultRegistrar(this@SelfsignWebViewPlatformView)
                    }
                    return fileChooser!!.show(filePathCallback, params)
                }
            }
        )

        webView.addJavascriptInterface(jsBridge, "android")
        webView.addJavascriptInterface(jsBridge, "SelfsignBridge")

        if (url.isNotEmpty()) {
            webView.loadUrl(url)
        }
    }

    override fun getView(): View = webView

    override fun dispose() {
        try {
            activityResultUnregistrar(this)
            webView.removeJavascriptInterface("android")
            webView.removeJavascriptInterface("SelfsignBridge")
            webView.destroy()
        } catch (_: Throwable) { /* ignore */ }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return fileChooser?.onActivityResult(requestCode, resultCode, data) ?: false
    }
}
