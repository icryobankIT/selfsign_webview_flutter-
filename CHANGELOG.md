## 0.1.0

* Initial release.
* `SelfsignWebView.open(url: ...)` opens a full-screen native WebView Activity / ViewController.
* `SelfsignWebViewWidget` embeds the same hardened WebView inside a Flutter page via PlatformView.
* JS bridge: webpages can call `window.SelfsignBridge.postMessage(method, payload)` (and the legacy `window.android.SVSNative(payload)` on Android) — events are forwarded to Flutter via a stream.
* Built-in file/camera chooser, permission handling, SSL error dialog, JS Alert/Confirm and back-press confirmation when signing is in progress.
