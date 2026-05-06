import Foundation
import WebKit

/// Shared helpers used by both the full-screen view controller and the
/// embedded PlatformView to build a configured WKWebView.
enum SelfsignWebViewBuilder {

    /// JS injected at document start that:
    ///   1. Sets `sessionStorage.APPtype` so the page can detect the host app.
    ///   2. Defines `window.SelfsignBridge.postMessage(method, payload)` and
    ///      `window.android.SVSNative(payload)` as wrappers around the
    ///      WKScriptMessageHandler the native side installs.
    static func bootstrapScript(appType: String) -> WKUserScript {
        let escapedAppType = appType
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        let source = """
        (function() {
            try {
                window.sessionStorage.setItem('APPtype', '\(escapedAppType)');
            } catch (e) {}
            function postToNative(method, payload) {
                try {
                    if (window.webkit &&
                        window.webkit.messageHandlers &&
                        window.webkit.messageHandlers.SelfsignBridge) {
                        window.webkit.messageHandlers.SelfsignBridge.postMessage({
                            method: String(method == null ? '' : method),
                            payload: String(payload == null ? '' : payload)
                        });
                    }
                } catch (e) {}
            }
            window.SelfsignBridge = window.SelfsignBridge || {
                postMessage: function(method, payload) {
                    postToNative(method, payload);
                }
            };
            window.android = window.android || {
                SVSNative: function(payload) {
                    postToNative('SVSNative', payload);
                }
            };
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    static func makeConfiguration(appType: String, messageHandler: WKScriptMessageHandler) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }

        let userContent = WKUserContentController()
        userContent.addUserScript(bootstrapScript(appType: appType))
        userContent.add(messageHandler, name: "SelfsignBridge")
        config.userContentController = userContent

        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs

        return config
    }
}
