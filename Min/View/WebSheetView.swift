import SwiftUI
import WebKit

// URL 遵从 Identifiable，用于 .sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - WKWebView 预热池（app 启动时预先创建，消除首次 2-3 秒冷启动延迟）
final class WebViewPool {
    static let shared = WebViewPool()
    private var pool: [WKWebView] = []
    private let lock = NSLock()

    private init() {}

    /// App 启动后尽早调用，在后台预热 1 个 WKWebView
    func warmUp() {
        DispatchQueue.main.async {
            let wv = Self.makeWebView()
            // 加载空白页触发 WebKit 进程启动
            wv.load(URLRequest(url: URL(string: "about:blank")!))
            self.lock.lock()
            self.pool.append(wv)
            self.lock.unlock()
        }
    }

    /// 取出一个预热好的 WKWebView；池空时同步新建
    func dequeue() -> WKWebView {
        lock.lock()
        let wv = pool.isEmpty ? nil : pool.removeLast()
        lock.unlock()
        return wv ?? Self.makeWebView()
    }

    /// 用完后归还，供下次复用
    func enqueue(_ webView: WKWebView) {
        webView.load(URLRequest(url: URL(string: "about:blank")!))
        lock.lock()
        if pool.count < 2 { pool.append(webView) }
        lock.unlock()
    }

    private static func makeWebView() -> WKWebView {
        let wv = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        wv.isOpaque = false
        return wv
    }
}

// MARK: - WebSheetView

struct WebSheetView: View {
    let url: URL

    var body: some View {
        PooledWebView(url: url)
            .ignoresSafeArea(edges: .bottom)
            .background(Color.clear)
    }
}

// MARK: - PooledWebView（复用预热池中的 WKWebView）

private struct PooledWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let wv = WebViewPool.shared.dequeue()
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        // url 变化时重新加载
        if wv.url != url {
            wv.load(URLRequest(url: url))
        }
    }

    static func dismantleUIView(_ wv: WKWebView, coordinator: ()) {
        WebViewPool.shared.enqueue(wv)
    }
}
