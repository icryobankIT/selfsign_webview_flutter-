import Flutter
import Foundation

/// Process-wide singleton fan-out from any WKWebView produced by the plugin
/// (full-screen view controller or embedded PlatformView) to a single
/// FlutterEventSink.
final class BridgeRegistry: NSObject, FlutterStreamHandler {
    static let shared = BridgeRegistry()
    private var sink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    func send(method: String, payload: String, sourceUrl: String?, viewId: String?) {
        let event: [String: Any?] = [
            "method": method,
            "payload": payload,
            "sourceUrl": sourceUrl as Any?,
            "viewId": viewId as Any?
        ]
        if Thread.isMainThread {
            sink?(event)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.sink?(event)
            }
        }
    }
}
