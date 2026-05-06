import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'selfsign_bridge_event.dart';
import 'selfsign_webview.dart';

/// Embeds the same hardened WebView that `SelfsignWebView.open(...)` uses,
/// but as a Flutter widget rendered via PlatformView.
///
/// Use this when you want the WebView to live inside an existing Flutter
/// page (for example, in a tab) instead of taking over the screen.
class SelfsignWebViewWidget extends StatefulWidget {
  /// The URL to load.
  final String url;

  /// Injected as `window.sessionStorage.APPtype` on every page start.
  final String appType;

  /// Allow the user to proceed on SSL errors via a dialog.
  final bool allowInsecureSsl;

  /// Called when the embedded page invokes the bridge:
  /// `window.SelfsignBridge.postMessage('SVSNative', json)` or, on Android,
  /// `window.android.SVSNative(json)`.
  final ValueChanged<SelfsignBridgeEvent>? onJsBridgeCall;

  /// Optional gesture recognizers, forwarded to the platform view so it can
  /// intercept gestures from a parent scroll view.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  const SelfsignWebViewWidget({
    super.key,
    required this.url,
    this.appType = 'PatientAPP02',
    this.allowInsecureSsl = true,
    this.onJsBridgeCall,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
  });

  @override
  State<SelfsignWebViewWidget> createState() => _SelfsignWebViewWidgetState();
}

class _SelfsignWebViewWidgetState extends State<SelfsignWebViewWidget> {
  static const _viewType = 'selfsign_webview_flutter/view';

  StreamSubscription<SelfsignBridgeEvent>? _sub;
  String? _viewId;

  @override
  void initState() {
    super.initState();
    if (widget.onJsBridgeCall != null) {
      _sub = SelfsignWebView.onJsBridgeCall.listen((event) {
        // Filter to events from this particular widget when possible.
        if (event.viewId != null &&
            _viewId != null &&
            event.viewId != _viewId) {
          return;
        }
        widget.onJsBridgeCall!(event);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      'url': widget.url,
      'appType': widget.appType,
      'allowInsecureSsl': widget.allowInsecureSsl,
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: _viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: widget.gestureRecognizers,
        onPlatformViewCreated: (id) => _viewId = id.toString(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: widget.gestureRecognizers,
        onPlatformViewCreated: (id) => _viewId = id.toString(),
      );
    }
    return const Center(
      child: Text('SelfsignWebViewWidget: unsupported platform'),
    );
  }
}
