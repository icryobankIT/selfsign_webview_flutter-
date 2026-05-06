# selfsign_webview_flutter

A Flutter plugin that wraps a hardened native WebView (Android `WebView` /
iOS `WKWebView`) for hosting e-signature pages. Ported from the Java
`SimpleWebViewDemo` Android project, with iOS support added.

## Features

- Full-screen native WebView via `SelfsignWebView.open(url: ...)`.
- Embeddable PlatformView via `SelfsignWebViewWidget(...)`.
- Auto-injects `sessionStorage.APPtype` so the page can detect the host app.
- File / camera chooser plumbed through the native file picker (Android).
- Permission prompts (camera / microphone / location).
- JS `alert()` / `confirm()` replaced with native dialogs.
- SSL error confirmation dialog (optional).
- Back-press confirmation: asks the page (`window.getStatus()`) whether it
  is safe to leave; otherwise pops a confirmation dialog.
- JavaScript bridge: webpages can call
  `window.SelfsignBridge.postMessage(method, payload)` (or the legacy
  `window.android.SVSNative(payload)` on Android) and Flutter receives the
  call via a stream.

## Install

```yaml
dependencies:
  selfsign_webview_flutter:
    path: ../selfsign_webview_flutter   # or git/hosted version
```

### Android setup

The plugin's `AndroidManifest.xml` already declares the camera / mic /
location permissions and registers a `FileProvider`. The host app must:

1. Set `compileSdk >= 34` and `minSdk >= 21`.
2. Allow cleartext traffic if your sign page is served over HTTP. In
   `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <application
       android:usesCleartextTraffic="true"
       ... >
   ```

3. Request runtime permissions yourself if you want to ask before opening
   the WebView. The plugin will request them again when the Activity opens
   if they are not granted.

### iOS setup

Add the following keys to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>需要相機以拍照進行簽署</string>
<key>NSMicrophoneUsageDescription</key>
<string>需要麥克風進行簽署錄影</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要存取相片以上傳檔案</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>簽署過程需要您的位置資訊</string>
```

If your sign page is served over HTTP, also enable App Transport Security
exceptions in `Info.plist`.

Minimum iOS deployment target: **12.0**.

## Usage

### 1. Open as a full-screen WebView

```dart
import 'package:selfsign_webview_flutter/selfsign_webview_flutter.dart';

await SelfsignWebView.open(
  url: 'https://your.sign.page/abc',
  appType: 'PatientAPP02',     // injected to sessionStorage.APPtype
  title: '簽署',
  confirmBeforeBack: true,     // prompt if getStatus() != 'true'
  allowInsecureSsl: true,      // popup on SSL errors
);
```

To programmatically close the visible WebView:

```dart
await SelfsignWebView.close();
```

### 2. Embed the WebView inside a Flutter page

```dart
SelfsignWebViewWidget(
  url: 'https://your.sign.page/abc',
  appType: 'PatientAPP02',
  onJsBridgeCall: (event) {
    debugPrint('Bridge call: ${event.method} -> ${event.payload}');
  },
);
```

### 3. Listen to JS bridge calls globally

```dart
final sub = SelfsignWebView.onJsBridgeCall.listen((event) {
  // event.method  : e.g. "SVSNative"
  // event.payload : raw JSON string the page passed in
  // event.sourceUrl, event.viewId
});
```

### 4. JavaScript side

Inside the page, call:

```js
// Cross-platform (recommended):
window.SelfsignBridge.postMessage('SVSNative', JSON.stringify({
  taskId: 1541492025490,
  recordtip: '請開始錄影',
  second: 45,
  noCamera: false,
  hashCode: 'xxx'
}));

// Legacy Android-only:
window.android.SVSNative(JSON.stringify({...}));
```

The page can also expose `window.getStatus()` returning `"true"` to allow
the user to leave without confirmation, or `"false"` to trigger the
confirmation dialog when the user presses back.

## Notes & differences from the original Android project

- The original `MainActivity` URL-input screen is **not** part of the
  plugin. Developers pass the URL directly to `SelfsignWebView.open(...)`.
- The original `SVSNative()` Android JavaScript interface, which used to
  show a static "送子鳥客製不須呼叫源生相機" dialog, now forwards every call
  to Flutter through `SelfsignWebView.onJsBridgeCall`. The host app
  decides what to do.
- iOS uses `WKWebView`; the JS injection layer makes
  `window.android.SVSNative` and `window.SelfsignBridge.postMessage`
  available on both platforms via the same code path.
- File/camera chooser on iOS is delegated to `WKWebView`'s default
  behavior; the embedded mode does not implement custom dialogs.
- On Android, the embedded `SelfsignWebViewWidget` requires the host
  Activity to be available (it normally is, when used from a Flutter
  page) for the file chooser to work.

## License

MIT — see `LICENSE`.
