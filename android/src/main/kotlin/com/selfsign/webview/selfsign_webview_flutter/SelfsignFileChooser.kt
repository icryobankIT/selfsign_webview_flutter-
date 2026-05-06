package com.selfsign.webview.selfsign_webview_flutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import androidx.core.content.FileProvider
import java.io.File

/**
 * Encapsulates the camera + content picker chooser used by [WebChromeClient.onShowFileChooser].
 *
 * The caller is responsible for delivering the activity result back via
 * [onActivityResult]; this class handles building the Intent and decoding
 * the response into a `Uri[]` that the WebView expects.
 */
internal class SelfsignFileChooser(private val activity: Activity) {

    companion object {
        const val REQUEST_CODE = 0xC001
    }

    private var callback: ValueCallback<Array<Uri>>? = null
    private var cameraImageUri: Uri? = null

    fun show(
        filePathCallback: ValueCallback<Array<Uri>>,
        params: WebChromeClient.FileChooserParams
    ): Boolean {
        // Cancel any previous pending callback.
        callback?.onReceiveValue(null)
        callback = filePathCallback

        var cameraIntent: Intent? = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (cameraIntent?.resolveActivity(activity.packageManager) != null) {
            try {
                val photoFile = File.createTempFile("IMG_", ".jpg", activity.cacheDir)
                cameraImageUri = FileProvider.getUriForFile(
                    activity,
                    activity.packageName + ".selfsign.fileprovider",
                    photoFile
                )
                cameraIntent.putExtra(MediaStore.EXTRA_OUTPUT, cameraImageUri)
            } catch (t: Throwable) {
                cameraIntent = null
                cameraImageUri = null
            }
        } else {
            cameraIntent = null
        }

        val contentIntent = params.createIntent()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            params.mode == WebChromeClient.FileChooserParams.MODE_OPEN_MULTIPLE
        ) {
            contentIntent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }

        val chooser = Intent(Intent.ACTION_CHOOSER).apply {
            putExtra(Intent.EXTRA_INTENT, contentIntent)
            putExtra(Intent.EXTRA_TITLE, "選擇檔案")
            if (cameraIntent != null) {
                putExtra(Intent.EXTRA_INITIAL_INTENTS, arrayOf(cameraIntent))
            }
        }

        return try {
            activity.startActivityForResult(chooser, REQUEST_CODE)
            true
        } catch (t: Throwable) {
            callback?.onReceiveValue(null)
            callback = null
            false
        }
    }

    /** Returns true if the result was handled. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false

        var results: Array<Uri>? = null
        if (resultCode == Activity.RESULT_OK) {
            if (data != null) {
                if (data.clipData != null) {
                    val clip = data.clipData!!
                    results = Array(clip.itemCount) { clip.getItemAt(it).uri }
                } else if (data.data != null) {
                    results = arrayOf(data.data!!)
                }
            } else if (cameraImageUri != null) {
                results = arrayOf(cameraImageUri!!)
            }
        }

        callback?.onReceiveValue(results)
        callback = null
        cameraImageUri = null
        return true
    }
}
