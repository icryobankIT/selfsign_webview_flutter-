package com.selfsign.webview.selfsign_webview_flutter

import android.app.AlertDialog
import android.content.Context
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.net.http.SslError
import android.os.Build
import android.webkit.GeolocationPermissions
import android.webkit.JsResult
import android.webkit.PermissionRequest
import android.webkit.SslErrorHandler
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient

/** Shared WebView configuration code used by both the full-screen Activity
 *  and the embedded PlatformView.
 */
internal object SelfsignWebViewSetup {

    @Suppress("SetJavaScriptEnabled")
    fun applyDefaultSettings(webView: WebView) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            val flags = webView.context.applicationInfo.flags
            if ((flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                WebView.setWebContentsDebuggingEnabled(true)
            }
        }
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccessFromFileURLs = true
            allowFileAccess = true
            setSupportZoom(true)
            builtInZoomControls = true
            displayZoomControls = false
            javaScriptCanOpenWindowsAutomatically = true
            blockNetworkImage = true
            mediaPlaybackRequiresUserGesture = false
            defaultTextEncodingName = "utf-8"
            cacheMode = WebSettings.LOAD_DEFAULT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            }
        }
    }

    /**
     * Build a WebViewClient that:
     *  - Injects `APPtype` into sessionStorage on every page start.
     *  - Toggles a progress bar via [onProgressVisibilityChange].
     *  - Optionally pops a confirmation dialog on SSL errors.
     */
    fun buildWebViewClient(
        context: Context,
        appType: String,
        allowInsecureSsl: Boolean,
        onProgressVisibilityChange: (Boolean) -> Unit,
        onUrlChanged: (String?) -> Unit
    ): WebViewClient = object : WebViewClient() {

        override fun onPageStarted(view: WebView, url: String?, favicon: Bitmap?) {
            super.onPageStarted(view, url, favicon)
            onUrlChanged(url)
            val js = "window.sessionStorage.setItem('APPtype','$appType')"
            view.loadUrl("javascript:$js")
        }

        override fun onPageFinished(view: WebView, url: String?) {
            super.onPageFinished(view, url)
            onProgressVisibilityChange(false)
            view.visibility = WebView.VISIBLE
            view.settings.blockNetworkImage = false
            onUrlChanged(url)
        }

        override fun onReceivedSslError(
            view: WebView,
            handler: SslErrorHandler,
            error: SslError
        ) {
            if (!allowInsecureSsl) {
                handler.cancel()
                return
            }
            AlertDialog.Builder(context)
                .setTitle("SSL 錯誤")
                .setMessage("網站憑證有問題，是否繼續？")
                .setCancelable(false)
                .setPositiveButton("繼續") { d, _ ->
                    handler.proceed()
                    d.dismiss()
                }
                .setNegativeButton("取消") { d, _ ->
                    handler.cancel()
                    d.dismiss()
                }
                .show()
        }
    }

    /**
     * Build a WebChromeClient that:
     *  - Replaces JS alert/confirm with native AlertDialog.
     *  - Auto-grants WebRTC permission requests.
     *  - Auto-grants geolocation prompts.
     *  - Delegates `onShowFileChooser` to [fileChooserHandler].
     */
    fun buildWebChromeClient(
        context: Context,
        fileChooserHandler: ShowFileChooserHandler
    ): WebChromeClient = object : WebChromeClient() {

        override fun onJsAlert(
            view: WebView,
            url: String,
            message: String,
            result: JsResult
        ): Boolean {
            AlertDialog.Builder(context)
                .setTitle("提示")
                .setMessage(message)
                .setCancelable(false)
                .setPositiveButton(android.R.string.ok) { d, _ ->
                    result.confirm()
                    d.dismiss()
                }
                .show()
            return true
        }

        override fun onJsConfirm(
            view: WebView,
            url: String,
            message: String,
            result: JsResult
        ): Boolean {
            AlertDialog.Builder(context)
                .setTitle("確認")
                .setMessage(message)
                .setCancelable(false)
                .setPositiveButton(android.R.string.yes) { d, _ ->
                    result.confirm()
                    d.dismiss()
                }
                .setNegativeButton(android.R.string.no) { d, _ ->
                    result.cancel()
                    d.dismiss()
                }
                .show()
            return true
        }

        override fun onPermissionRequest(request: PermissionRequest) {
            request.grant(request.resources)
        }

        override fun onGeolocationPermissionsShowPrompt(
            origin: String,
            callback: GeolocationPermissions.Callback
        ) {
            callback.invoke(origin, true, false)
            super.onGeolocationPermissionsShowPrompt(origin, callback)
        }

        override fun onShowFileChooser(
            webView: WebView,
            filePathCallback: android.webkit.ValueCallback<Array<android.net.Uri>>,
            fileChooserParams: FileChooserParams
        ): Boolean {
            return fileChooserHandler.handle(filePathCallback, fileChooserParams)
        }
    }

    /** A small contract so both Activity and PlatformView can supply the
     *  Activity context they have available to start an Intent for result. */
    interface ShowFileChooserHandler {
        fun handle(
            filePathCallback: android.webkit.ValueCallback<Array<android.net.Uri>>,
            params: WebChromeClient.FileChooserParams
        ): Boolean
    }
}
