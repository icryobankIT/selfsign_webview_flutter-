import Flutter
import UIKit

public class SelfsignWebviewFlutterPlugin: NSObject, FlutterPlugin {

    private static let channelName = "selfsign_webview_flutter"
    private static let eventChannelName = "selfsign_webview_flutter/events"
    private static let viewType = "selfsign_webview_flutter/view"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SelfsignWebviewFlutterPlugin()

        let channel = FlutterMethodChannel(name: channelName,
                                           binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: eventChannelName,
                                               binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(BridgeRegistry.shared)

        let factory = SelfsignWebViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: viewType)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "open":
            handleOpen(call: call, result: result)
        case "close":
            handleClose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleOpen(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = (call.arguments as? [String: Any]) ?? [:]
        guard let url = args["url"] as? String, !url.isEmpty else {
            result(FlutterError(code: "invalid_url", message: "url is required", details: nil))
            return
        }
        let appType = (args["appType"] as? String) ?? "PatientAPP02"
        let title = (args["title"] as? String) ?? ""
        let confirmBeforeBack = (args["confirmBeforeBack"] as? Bool) ?? true
        let allowInsecureSsl = (args["allowInsecureSsl"] as? Bool) ?? true

        DispatchQueue.main.async {
            guard let host = SelfsignWebviewFlutterPlugin.topMostViewController() else {
                result(FlutterError(code: "no_host", message: "No view controller available", details: nil))
                return
            }

            let vc = SelfsignWebViewController(
                url: url,
                appType: appType,
                title: title,
                confirmBeforeBack: confirmBeforeBack,
                allowInsecureSsl: allowInsecureSsl
            )

            if let nav = host.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                host.present(nav, animated: true)
            }
            result(true)
        }
    }

    private func handleClose(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            SelfsignWebViewController.current?.close()
            result(nil)
        }
    }

    private static func topMostViewController() -> UIViewController? {
        guard var top = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
