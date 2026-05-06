package com.selfsign.webview.selfsign_webview_flutter

import android.Manifest
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.widget.ProgressBar
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * Full-screen Activity that hosts the WebView. Mirrors the original
 * `WebViewActivity.java` from `SimpleWebViewDemo` but routes JS bridge
 * events to Flutter.
 */
class SelfsignWebViewActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_URL = "selfsign.url"
        const val EXTRA_APP_TYPE = "selfsign.appType"
        const val EXTRA_TITLE = "selfsign.title"
        const val EXTRA_CONFIRM_BACK = "selfsign.confirmBack"
        const val EXTRA_ALLOW_INSECURE_SSL = "selfsign.allowInsecureSsl"

        private const val PERMISSION_REQUEST = 0xA001

        /** Updated by the plugin so close() can reach the visible Activity. */
        @Volatile
        internal var current: SelfsignWebViewActivity? = null
    }

    private lateinit var webView: WebView
    private lateinit var progress: ProgressBar
    private lateinit var toolbar: Toolbar
    private lateinit var fileChooser: SelfsignFileChooser
    private lateinit var jsBridge: SelfsignJsBridge

    private var appType: String = "PatientAPP02"
    private var confirmBeforeBack: Boolean = true
    private var allowInsecureSsl: Boolean = true
    private var pendingUrl: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        current = this

        setContentView(R.layout.selfsign_activity_web_view)
        toolbar = findViewById(R.id.selfsign_toolbar)
        webView = findViewById(R.id.selfsign_webview)
        progress = findViewById(R.id.selfsign_progress)

        val title = intent.getStringExtra(EXTRA_TITLE).orEmpty()
        appType = intent.getStringExtra(EXTRA_APP_TYPE) ?: "PatientAPP02"
        confirmBeforeBack = intent.getBooleanExtra(EXTRA_CONFIRM_BACK, true)
        allowInsecureSsl = intent.getBooleanExtra(EXTRA_ALLOW_INSECURE_SSL, true)
        pendingUrl = intent.getStringExtra(EXTRA_URL).orEmpty()

        setSupportActionBar(toolbar)
        supportActionBar?.title = title
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.setDisplayShowHomeEnabled(true)

        fileChooser = SelfsignFileChooser(this)
        jsBridge = SelfsignJsBridge(webView, viewId = null)

        SelfsignWebViewSetup.applyDefaultSettings(webView)
        webView.visibility = View.INVISIBLE

        webView.webViewClient = SelfsignWebViewSetup.buildWebViewClient(
            context = this,
            appType = appType,
            allowInsecureSsl = allowInsecureSsl,
            onProgressVisibilityChange = { visible ->
                progress.visibility = if (visible) View.VISIBLE else View.GONE
            },
            onUrlChanged = { url -> jsBridge.setLastUrl(url) }
        )
        webView.webChromeClient = SelfsignWebViewSetup.buildWebChromeClient(
            context = this,
            fileChooserHandler = object : SelfsignWebViewSetup.ShowFileChooserHandler {
                override fun handle(
                    filePathCallback: ValueCallback<Array<Uri>>,
                    params: WebChromeClient.FileChooserParams
                ): Boolean = fileChooser.show(filePathCallback, params)
            }
        )

        webView.addJavascriptInterface(jsBridge, "android")
        webView.addJavascriptInterface(jsBridge, "SelfsignBridge")

        requestPermissionsAndLoad()
    }

    private fun requestPermissionsAndLoad() {
        val needed = listOf(
            Manifest.permission.CAMERA,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.RECORD_AUDIO
        ).filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (needed.isEmpty()) {
            loadPendingUrl()
        } else {
            ActivityCompat.requestPermissions(this, needed.toTypedArray(), PERMISSION_REQUEST)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return

        val allGranted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }

        if (allGranted) {
            loadPendingUrl()
            return
        }

        for (i in permissions.indices) {
            if (grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                val msg = when (permissions[i]) {
                    Manifest.permission.CAMERA -> "本程式需要相機權限才能正常使用"
                    Manifest.permission.ACCESS_FINE_LOCATION -> "本程式需要定位權限才能正常使用"
                    Manifest.permission.RECORD_AUDIO -> "本程式需要麥克風權限才能正常使用"
                    else -> "缺少必要權限"
                }
                AlertDialog.Builder(this)
                    .setTitle("權限提醒")
                    .setMessage(msg)
                    .setCancelable(false)
                    .setPositiveButton(android.R.string.ok) { d, _ -> d.dismiss() }
                    .show()
                // Still attempt to load – the page may not require all of them.
                loadPendingUrl()
                return
            }
        }
    }

    private fun loadPendingUrl() {
        if (pendingUrl.isNotEmpty()) {
            webView.loadUrl(pendingUrl)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        fileChooser.onActivityResult(requestCode, resultCode, data)
    }

    override fun onSupportNavigateUp(): Boolean {
        attemptBack()
        return true
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            attemptBack()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun attemptBack() {
        if (!confirmBeforeBack) {
            finishCleanly()
            return
        }
        webView.evaluateJavascript("javascript:(function(){try{return getStatus();}catch(e){return 'true';}})()") { value ->
            // value is JSON-quoted: '"true"' or '"false"'
            val ok = value?.replace("\"", "")?.equals("true", ignoreCase = true) == true
            if (ok) {
                finishCleanly()
            } else {
                AlertDialog.Builder(this)
                    .setTitle("提醒")
                    .setMessage("尚未完成簽署，是否離開？")
                    .setCancelable(false)
                    .setPositiveButton(android.R.string.yes) { d, _ ->
                        d.dismiss()
                        finishCleanly()
                    }
                    .setNegativeButton(android.R.string.no) { d, _ -> d.dismiss() }
                    .show()
            }
        }
    }

    private fun finishCleanly() {
        if (!isFinishing) finish()
    }

    override fun onResume() {
        super.onResume()
        webView.onResume()
    }

    override fun onPause() {
        super.onPause()
        webView.onPause()
    }

    override fun onDestroy() {
        if (current === this) current = null
        try {
            webView.removeJavascriptInterface("android")
            webView.removeJavascriptInterface("SelfsignBridge")
            webView.destroy()
        } catch (_: Throwable) { /* ignore */ }
        super.onDestroy()
    }
}
