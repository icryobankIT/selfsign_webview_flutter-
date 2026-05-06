# selfsign_webview_flutter

English | [繁體中文](#繁體中文)

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
- Back-press confirmation: asks the page (`window.getStatus()`) whether it is
  safe to leave; otherwise pops a confirmation dialog.
- JavaScript bridge: webpages can call
  `window.SelfsignBridge.postMessage(method, payload)` (or the legacy
  `window.android.SVSNative(payload)` on Android) and Flutter receives the call
  via a stream.

## Install

```yaml
dependencies:
  selfsign_webview_flutter:
    path: ../selfsign_webview_flutter # or git/hosted version
```

Or install from Git:

```yaml
dependencies:
  selfsign_webview_flutter:
    git:
      url: https://github.com/your-org/selfsign_webview_flutter.git
      ref: v0.1.0 # tag, branch, or commit hash
```

### Android Setup

The plugin's `AndroidManifest.xml` already declares the camera / mic / location
permissions and registers a `FileProvider`. The host app must:

1. Set `compileSdk >= 34` and `minSdk >= 21`.
2. Allow cleartext traffic if your sign page is served over HTTP. In
   `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <application
       android:usesCleartextTraffic="true"
       ... >
   ```

3. Request runtime permissions yourself if you want to ask before opening the
   WebView. The plugin will request them again when the Activity opens if they
   are not granted.

### iOS Setup

Add the following keys to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for signing.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for signing video.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required for file upload.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required during signing.</string>
```

If your sign page is served over HTTP, also enable App Transport Security
exceptions in `Info.plist`.

Minimum iOS deployment target: **12.0**.

## Usage

### 1. Open as a Full-Screen WebView

```dart
import 'package:selfsign_webview_flutter/selfsign_webview_flutter.dart';

await SelfsignWebView.open(
  url: 'https://your.sign.page/abc',
  appType: 'PatientAPP02', // injected to sessionStorage.APPtype
  title: 'Sign',
  confirmBeforeBack: true, // prompt if getStatus() != 'true'
  allowInsecureSsl: true, // popup on SSL errors
);
```

To programmatically close the visible WebView:

```dart
await SelfsignWebView.close();
```

### 2. Embed the WebView Inside a Flutter Page

```dart
SelfsignWebViewWidget(
  url: 'https://your.sign.page/abc',
  appType: 'PatientAPP02',
  onJsBridgeCall: (event) {
    debugPrint('Bridge call: ${event.method} -> ${event.payload}');
  },
);
```

### 3. Listen to JS Bridge Calls Globally

```dart
final sub = SelfsignWebView.onJsBridgeCall.listen((event) {
  // event.method  : e.g. "SVSNative"
  // event.payload : raw JSON string the page passed in
  // event.sourceUrl, event.viewId
});
```

### 4. JavaScript Side

Inside the page, call:

```js
// Cross-platform (recommended):
window.SelfsignBridge.postMessage('SVSNative', JSON.stringify({
  taskId: 1541492025490,
  recordtip: 'Please start recording',
  second: 45,
  noCamera: false,
  hashCode: 'xxx'
}));

// Legacy Android-only:
window.android.SVSNative(JSON.stringify({...}));
```

The page can also expose `window.getStatus()` returning `"true"` to allow the
user to leave without confirmation, or `"false"` to trigger the confirmation
dialog when the user presses back.

## Notes and Differences from the Original Android Project

- The original `MainActivity` URL-input screen is **not** part of the plugin.
  Developers pass the URL directly to `SelfsignWebView.open(...)`.
- The original `SVSNative()` Android JavaScript interface, which used to show a
  static native-camera dialog, now forwards every call to Flutter through
  `SelfsignWebView.onJsBridgeCall`. The host app decides what to do.
- iOS uses `WKWebView`; the JS injection layer makes
  `window.android.SVSNative` and `window.SelfsignBridge.postMessage` available
  on both platforms via the same code path.
- File/camera chooser on iOS is delegated to `WKWebView`'s default behavior;
  the embedded mode does not implement custom dialogs.
- On Android, the embedded `SelfsignWebViewWidget` requires the host Activity to
  be available (it normally is when used from a Flutter page) for the file
  chooser to work.

## License

MIT - see `LICENSE`.

---

## 繁體中文

[English](#selfsign_webview_flutter) | 繁體中文

`selfsign_webview_flutter` 是一個 Flutter plugin，用於包裝強化設定後的原生
WebView（Android `WebView` / iOS `WKWebView`），適合承載電子簽署頁面。本套件
從 Java 版 `SimpleWebViewDemo` Android 專案移植而來，並加入 iOS 支援。

## 功能

- 使用 `SelfsignWebView.open(url: ...)` 開啟全螢幕原生 WebView。
- 使用 `SelfsignWebViewWidget(...)` 將 WebView 嵌入 Flutter 頁面。
- 自動注入 `sessionStorage.APPtype`，讓網頁端可辨識目前宿主 App。
- 檔案 / 相機選擇器串接原生檔案選取流程（Android）。
- 權限提示（相機 / 麥克風 / 位置）。
- 將 JS `alert()` / `confirm()` 改由原生對話框呈現。
- SSL 錯誤確認對話框（可選）。
- 返回鍵確認：離開前詢問頁面 `window.getStatus()` 是否可安全離開；否則顯示確認
  對話框。
- JavaScript bridge：網頁可呼叫
  `window.SelfsignBridge.postMessage(method, payload)`，或在 Android 使用舊版
  `window.android.SVSNative(payload)`；Flutter 端會透過 stream 收到事件。

## 安裝

```yaml
dependencies:
  selfsign_webview_flutter:
    path: ../selfsign_webview_flutter # 或改用 git/hosted 版本
```

或從 Git 安裝：

```yaml
dependencies:
  selfsign_webview_flutter:
    git:
      url: https://github.com/your-org/selfsign_webview_flutter.git
      ref: v0.1.0 # tag、branch 或 commit hash
```

### Android 設定

Plugin 的 `AndroidManifest.xml` 已宣告相機 / 麥克風 / 位置權限，並註冊
`FileProvider`。宿主 App 需完成以下設定：

1. 設定 `compileSdk >= 34` 且 `minSdk >= 21`。
2. 若簽署頁面使用 HTTP，請在 `android/app/src/main/AndroidManifest.xml` 允許
   cleartext traffic：

   ```xml
   <application
       android:usesCleartextTraffic="true"
       ... >
   ```

3. 若希望在開啟 WebView 前先詢問權限，請由宿主 App 自行請求 runtime
   permissions。若尚未授權，plugin 在 Activity 開啟後仍會再次請求。

### iOS 設定

請在 `ios/Runner/Info.plist` 加入以下 key：

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

若簽署頁面使用 HTTP，也需要在 `Info.plist` 設定 App Transport Security 例外。

最低 iOS deployment target：**12.0**。

## 使用方式

### 1. 開啟全螢幕 WebView

```dart
import 'package:selfsign_webview_flutter/selfsign_webview_flutter.dart';

await SelfsignWebView.open(
  url: 'https://your.sign.page/abc',
  appType: 'PatientAPP02', // 注入至 sessionStorage.APPtype
  title: '簽署',
  confirmBeforeBack: true, // getStatus() != 'true' 時提示確認
  allowInsecureSsl: true, // SSL 錯誤時跳出確認視窗
);
```

若要透過程式關閉目前顯示中的 WebView：

```dart
await SelfsignWebView.close();
```

### 2. 將 WebView 嵌入 Flutter 頁面

```dart
SelfsignWebViewWidget(
  url: 'https://your.sign.page/abc',
  appType: 'PatientAPP02',
  onJsBridgeCall: (event) {
    debugPrint('Bridge call: ${event.method} -> ${event.payload}');
  },
);
```

### 3. 全域監聽 JS Bridge 呼叫

```dart
final sub = SelfsignWebView.onJsBridgeCall.listen((event) {
  // event.method  : 例如 "SVSNative"
  // event.payload : 網頁傳入的原始 JSON 字串
  // event.sourceUrl, event.viewId
});
```

### 4. JavaScript 端呼叫方式

在網頁內呼叫：

```js
// 跨平台，建議使用：
window.SelfsignBridge.postMessage('SVSNative', JSON.stringify({
  taskId: 1541492025490,
  recordtip: '請開始錄影',
  second: 45,
  noCamera: false,
  hashCode: 'xxx'
}));

// 舊版 Android-only：
window.android.SVSNative(JSON.stringify({...}));
```

網頁也可以提供 `window.getStatus()`。回傳 `"true"` 時允許使用者直接離開；
回傳 `"false"` 時，使用者按返回鍵會觸發確認對話框。

## 與原 Android 專案的差異

- 原本 `MainActivity` 的 URL 輸入畫面**不包含**在 plugin 內。開發者需直接將 URL
  傳給 `SelfsignWebView.open(...)`。
- 原本 Android JavaScript interface `SVSNative()` 會顯示固定的原生相機提示；現在
  所有呼叫都會透過 `SelfsignWebView.onJsBridgeCall` 轉發給 Flutter，由宿主 App
  自行決定後續處理。
- iOS 使用 `WKWebView`；JS injection layer 讓 `window.android.SVSNative` 與
  `window.SelfsignBridge.postMessage` 在兩個平台都可透過相同流程使用。
- iOS 的檔案 / 相機選擇器交由 `WKWebView` 預設行為處理；嵌入模式不實作自訂
  dialog。
- Android 的嵌入式 `SelfsignWebViewWidget` 需要宿主 Activity 可用，檔案選擇器才
  能正常運作。一般從 Flutter 頁面使用時會符合此條件。

## 授權

MIT - 請見 `LICENSE`。
