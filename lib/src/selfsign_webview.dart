import 'dart:async';

import 'package:flutter/services.dart';

import 'selfsign_bridge_event.dart';

/// Public API for opening a hardened native WebView used to host e-signature
/// pages.
///
/// Only the full-screen `open` mode is exposed here. To embed the same
/// WebView inside a Flutter page, use `SelfsignWebViewWidget`.
class SelfsignWebView {
  SelfsignWebView._();

  /// The single MethodChannel used for both the full-screen Activity/
  /// ViewController and the embedded PlatformView. Native side must use the
  /// same name.
  static const MethodChannel _channel =
      MethodChannel('selfsign_webview_flutter');

  /// Broadcast event channel used to forward JS bridge events back to Flutter.
  static const EventChannel _eventChannel =
      EventChannel('selfsign_webview_flutter/events');

  static Stream<SelfsignBridgeEvent>? _events;

  /// A broadcast stream of events posted from inside the WebView via
  /// `window.SelfsignBridge.postMessage(...)` (and the legacy
  /// `window.android.SVSNative(...)` on Android).
  ///
  /// Multiple listeners are allowed; each receives the same events.
  static Stream<SelfsignBridgeEvent> get onJsBridgeCall {
    _events ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic raw) => SelfsignBridgeEvent.fromMap(raw as Map));
    return _events!;
  }

  /// Opens a full-screen WebView and loads [url].
  ///
  /// * [appType] – injected into the page via
  ///   `window.sessionStorage.setItem('APPtype', appType)` on every page
  ///   start. Mirrors the original Android implementation.
  /// * [title] – the toolbar title shown above the WebView.
  /// * [confirmBeforeBack] – when `true`, pressing back asks the page (via
  ///   `window.getStatus()`) whether it is safe to leave; if the page
  ///   responds with anything other than `"true"` a confirmation dialog is
  ///   shown. Set to `false` to leave immediately.
  /// * [allowInsecureSsl] – when `true` the user is asked whether to proceed
  ///   on SSL errors (mirroring the original behaviour). When `false` the
  ///   page is blocked silently.
  ///
  /// Returns `true` if the WebView was opened successfully. The future
  /// completes after `open` returns from the platform side; it does not wait
  /// for the user to close the WebView.
  static Future<bool> open({
    required String url,
    String appType = 'PatientAPP02',
    String title = '',
    bool confirmBeforeBack = true,
    bool allowInsecureSsl = true,
  }) async {
    assert(url.isNotEmpty, 'url must not be empty');

    final result = await _channel.invokeMethod<bool>('open', <String, dynamic>{
      'url': url,
      'appType': appType,
      'title': title,
      'confirmBeforeBack': confirmBeforeBack,
      'allowInsecureSsl': allowInsecureSsl,
    });
    return result ?? false;
  }

  /// Closes the currently visible full-screen WebView, if any.
  static Future<void> close() async {
    await _channel.invokeMethod<void>('close');
  }
}
