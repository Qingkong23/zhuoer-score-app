import SwiftUI
import WebKit

// 成绩系统 App 壳：打开线上系统，数据与网页版完全共通（同一个服务器、同一个数据库）
private let homeURL = URL(string: "https://chengji.zhuoerx.cn")!
private let allowedHosts: Set<String> = ["chengji.zhuoerx.cn", "chengji.xmyiye.cn"]

struct ContentView: View {
    var body: some View {
        WebView(url: homeURL)
            .ignoresSafeArea(.container, edges: .bottom)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        // 标记为 App 内打开，方便以后区分来源
        if let ua = webView.value(forKey: "userAgent") as? String {
            webView.customUserAgent = ua + " ZhuoerApp/1.0"
        }
        // 下拉刷新
        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        context.coordinator.webView = webView
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    weak var webView: WKWebView?

    @objc func handleRefresh(_ sender: UIRefreshControl) {
        webView?.reload()
    }

    // 外链（非本站域名）交给 Safari 打开
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           let host = url.host, !allowedHosts.contains(host) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // 文件下载（Excel 导出/模板）：走系统下载，完成后弹分享面板，可存到「文件」或发微信
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let isAttachment = (navigationResponse.response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Disposition")?.contains("attachment") ?? false
        if isAttachment || !navigationResponse.canShowMIMEType {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)
        try? FileManager.default.removeItem(at: dest)
        completionHandler(dest)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let fileURL = download.progress.fileURL else { return }
        DispatchQueue.main.async {
            let vc = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first?.windows
                .first(where: { $0.isKeyWindow })?.rootViewController {
                vc.popoverPresentationController?.sourceView = root.view
                vc.popoverPresentationController?.sourceRect = CGRect(
                    x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
                root.present(vc, animated: true)
            }
        }
    }

    // target=_blank 的链接：本站在本页打开，外站去 Safari
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if let host = url.host, allowedHosts.contains(host) {
                webView.load(URLRequest(url: url))
            } else {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showErrorPage(webView, error: error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showErrorPage(webView, error: error)
    }

    private func showErrorPage(_ webView: WKWebView, error: Error) {
        webView.scrollView.refreshControl?.endRefreshing()
        if (error as NSError).code == NSURLErrorCancelled { return }
        let html = """
        <!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>body{font-family:-apple-system,sans-serif;text-align:center;padding:80px 24px;color:#333}
        a{display:inline-block;margin-top:20px;padding:12px 28px;background:#1f4e79;color:#fff;border-radius:10px;text-decoration:none;font-size:17px}</style></head>
        <body><h2>网络连接失败</h2><p>请检查网络后重试</p><a href="\(homeURL.absoluteString)">重新加载</a></body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
