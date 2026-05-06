/// An event delivered from the WebView's JavaScript bridge to Flutter.
///
/// Webpages running inside the plugin's WebView can talk to Flutter via:
///
/// ```js
/// window.SelfsignBridge.postMessage('SVSNative', JSON.stringify({...}));
/// ```
///
/// Or, for backwards compatibility with the original Android implementation:
///
/// ```js
/// window.android.SVSNative(JSON.stringify({...}));
/// ```
///
/// Both routes produce a [SelfsignBridgeEvent] with `method = "SVSNative"` and
/// `payload` set to the raw string passed by the page.
class SelfsignBridgeEvent {
  /// The bridge method name (e.g. `"SVSNative"`).
  final String method;

  /// The raw payload string the webpage passed in. Usually JSON.
  final String payload;

  /// The URL of the page that triggered the call, when available.
  final String? sourceUrl;

  /// Identifier of the WebView that produced the event. Useful when multiple
  /// embedded `SelfsignWebViewWidget`s are alive at once. `null` for the
  /// full-screen `SelfsignWebView.open(...)` path.
  final String? viewId;

  const SelfsignBridgeEvent({
    required this.method,
    required this.payload,
    this.sourceUrl,
    this.viewId,
  });

  factory SelfsignBridgeEvent.fromMap(Map<dynamic, dynamic> map) {
    return SelfsignBridgeEvent(
      method: map['method'] as String? ?? '',
      payload: map['payload'] as String? ?? '',
      sourceUrl: map['sourceUrl'] as String?,
      viewId: map['viewId']?.toString(),
    );
  }

  @override
  String toString() =>
      'SelfsignBridgeEvent(method: $method, payload: $payload, '
      'sourceUrl: $sourceUrl, viewId: $viewId)';
}
