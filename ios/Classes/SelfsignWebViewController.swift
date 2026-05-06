import UIKit
import WebKit

/// Full-screen view controller hosting a WKWebView for the e-signature flow.
/// Mirrors the responsibilities of the original Android `WebViewActivity`.
final class SelfsignWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    /// Updated by the plugin so close() can dismiss the visible controller.
    static weak var current: SelfsignWebViewController?

    private let url: String
    private let appType: String
    private let titleText: String
    private let confirmBeforeBack: Bool
    private let allowInsecureSsl: Bool

    private var webView: WKWebView!
    private var progress: UIActivityIndicatorView!
    private var messageHandler: SelfsignBridgeMessageHandler!

    init(url: String,
         appType: String,
         title: String,
         confirmBeforeBack: Bool,
         allowInsecureSsl: Bool) {
        self.url = url
        self.appType = appType
        self.titleText = title
        self.confirmBeforeBack = confirmBeforeBack
        self.allowInsecureSsl = allowInsecureSsl
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        SelfsignWebViewController.current = self
        view.backgroundColor = .white
        title = titleText

        let placeholderHandler = TempHandler()
        let config = SelfsignWebViewBuilder.makeConfiguration(appType: appType,
                                                              messageHandler: placeholderHandler)
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        // Replace placeholder handler with the real one bound to this webView.
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "SelfsignBridge")
        messageHandler = SelfsignBridgeMessageHandler(webView: webView, viewId: nil)
        webView.configuration.userContentController.add(messageHandler, name: "SelfsignBridge")

        progress = UIActivityIndicatorView(style: .gray)
        progress.hidesWhenStopped = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progress)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progress.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progress.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "返回",
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        if let target = URL(string: url) {
            progress.startAnimating()
            webView.load(URLRequest(url: target))
        }
    }

    @objc private func backTapped() {
        attemptBack()
    }

    private func attemptBack() {
        if !confirmBeforeBack {
            close()
            return
        }
        webView.evaluateJavaScript("(function(){try{return getStatus();}catch(e){return 'true';}})()") { [weak self] value, _ in
            guard let self = self else { return }
            let str: String
            if let s = value as? String { str = s }
            else if let b = value as? Bool { str = b ? "true" : "false" }
            else { str = "true" }
            if str.lowercased() == "true" {
                self.close()
            } else {
                let alert = UIAlertController(title: "提醒",
                                              message: "尚未完成簽署，是否離開？",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "離開", style: .destructive) { _ in self.close() })
                alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }

    func close() {
        if let nav = navigationController, nav.viewControllers.first !== self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    deinit {
        if SelfsignWebViewController.current === self {
            SelfsignWebViewController.current = nil
        }
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "SelfsignBridge")
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progress.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progress.stopAnimating()
    }

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
        // Mirror Android: ask the user whether to proceed with an invalid cert.
        let alert = UIAlertController(title: "SSL 錯誤",
                                      message: "網站憑證有問題，是否繼續？",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "繼續", style: .destructive) { _ in
            completionHandler(.useCredential, URLCredential(trust: trust))
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(.cancelAuthenticationChallenge, nil)
        })
        present(alert, animated: true)
    }

    // MARK: - WKUIDelegate (alert / confirm replacement)

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "確認", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "是", style: .default) { _ in completionHandler(true) })
        alert.addAction(UIAlertAction(title: "否", style: .cancel) { _ in completionHandler(false) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "輸入", message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "確定", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(nil) })
        present(alert, animated: true)
    }
}

/// Stand-in handler used only during initial WKWebView construction; it is
/// removed and replaced with the real handler that has a back-pointer to
/// the constructed WKWebView.
private final class TempHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {}
}
