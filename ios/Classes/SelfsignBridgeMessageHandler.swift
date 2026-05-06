import Foundation
import WebKit

/// Receives `window.webkit.messageHandlers.SelfsignBridge.postMessage({method, payload})`
/// from the JS bootstrap and forwards them through `BridgeRegistry`.
final class SelfsignBridgeMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var webView: WKWebView?
    let viewId: String?

    init(webView: WKWebView?, viewId: String?) {
        self.webView = webView
        self.viewId = viewId
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "SelfsignBridge" else { return }

        var method = ""
        var payload = ""
        if let body = message.body as? [String: Any] {
            method = (body["method"] as? String) ?? ""
            payload = (body["payload"] as? String) ?? ""
        } else if let str = message.body as? String {
            payload = str
        }

        let url = webView?.url?.absoluteString
        BridgeRegistry.shared.send(
            method: method,
            payload: payload,
            sourceUrl: url,
            viewId: viewId
        )
    }
}
