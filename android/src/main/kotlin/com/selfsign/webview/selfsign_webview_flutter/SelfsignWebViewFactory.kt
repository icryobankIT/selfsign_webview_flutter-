package com.selfsign.webview.selfsign_webview_flutter

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class SelfsignWebViewFactory(
    private val activitySupplier: () -> Activity?,
    private val activityResultRegistrar: (PluginRegistry.ActivityResultListener) -> Unit,
    private val activityResultUnregistrar: (PluginRegistry.ActivityResultListener) -> Unit
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?>
        return SelfsignWebViewPlatformView(
            context = context,
            viewId = viewId,
            creationParams = params,
            activitySupplier = activitySupplier,
            activityResultRegistrar = activityResultRegistrar,
            activityResultUnregistrar = activityResultUnregistrar
        )
    }
}
