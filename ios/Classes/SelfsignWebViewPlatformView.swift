import Flutter
import UIKit
import WebKit

/// Embedded WebView used by `SelfsignWebViewWidget` on iOS. Reuses the same
/// WKWebView configuration and bridge wiring as the full-screen view
/// controller.
final class SelfsignWebViewPlatformView: NSObject, FlutterPlatformView, WKNavigationDelegate, WKUIDelegate {

    private let viewId: Int64
    private let allowInsecureSsl: Bool
    private let webView: WKWebView
    private let messageHandler: SelfsignBridgeMessageHandler

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
        self.viewId = viewId

        let dict = (args as? [String: Any]) ?? [:]
        let url = (dict["url"] as? String) ?? ""
        let appType = (dict["appType"] as? String) ?? "PatientAPP02"
        self.allowInsecureSsl = (dict["allowInsecureSsl"] as? Bool) ?? true

        // Construct configuration with a placeholder, then swap it for the
        // real handler bound to the WKWebView instance. We use local
        // variables here because Swift forbids reading instance properties
        // before super.init() returns.
        let placeholder = TempEmbeddedHandler()
        let config = SelfsignWebViewBuilder.makeConfiguration(appType: appType,
                                                              messageHandler: placeholder)
        let webViewLocal = WKWebView(frame: frame, configuration: config)
        let handlerLocal = SelfsignBridgeMessageHandler(webView: webViewLocal,
                                                        viewId: String(viewId))
        self.webView = webViewLocal
        self.messageHandler = handlerLocal

        super.init()

        config.userContentController.removeScriptMessageHandler(forName: "SelfsignBridge")
        config.userContentController.add(handlerLocal, name: "SelfsignBridge")

        webViewLocal.navigationDelegate = self
        webViewLocal.uiDelegate = self
        webViewLocal.allowsBackForwardNavigationGestures = false

        if let target = URL(string: url) {
            webViewLocal.load(URLRequest(url: target))
        }
    }

    func view() -> UIView { webView }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "SelfsignBridge")
    }

    // MARK: - SSL handling

    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        if !allowInsecureSsl {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        // For embedded views we silently accept; the host app can override
        // via its own URLSessionDelegate if stricter handling is required.
        completionHandler(.useCredential, URLCredential(trust: trust))
    }

    // MARK: - JS alert/confirm replacement

    private var presentingController: UIViewController? {
        // Walk the responder chain to find a UIViewController to present from.
        var responder: UIResponder? = webView
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return UIApplication.shared.keyWindow?.rootViewController
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default) { _ in completionHandler() })
        presentingController?.present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "確認", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "是", style: .default) { _ in completionHandler(true) })
        alert.addAction(UIAlertAction(title: "否", style: .cancel) { _ in completionHandler(false) })
        presentingController?.present(alert, animated: true)
    }
}

private final class TempEmbeddedHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {}
}
