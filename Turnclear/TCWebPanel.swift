import SwiftUI
import WebKit

/// The panel used both for the full-screen launch branch and for the Privacy Policy sheet.
///
/// The frame is what guards the top edge: the caller ignores only the bottom safe area, so the
/// panel can never draw under the clock. `.always` is what keeps scrollable content clear of the
/// home indicator once the frame does extend past the bottom.
struct TCWebPanel: UIViewRepresentable {
    let address: String
    /// Called once, as soon as the page starts rendering, so the caller can lift its splash.
    var onFirstPaint: (() -> Void)? = nil

    final class Coordinator: NSObject, WKNavigationDelegate {
        var onFirstPaint: (() -> Void)?
        private var alreadyFired = false

        // didCommit, not didFinish: on a heavy page didFinish lands seconds after the content is
        // already on screen and usable.
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            release()
        }

        // A real failure must release the splash too, or it becomes a permanent hang.
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            let failure = error as NSError
            // A cancelled load is just an ordinary redirect.
            if failure.domain == NSURLErrorDomain && failure.code == NSURLErrorCancelled { return }
            release()
        }

        private func release() {
            guard !alreadyFired else { return }
            alreadyFired = true
            onFirstPaint?()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let settings = WKWebViewConfiguration()
        settings.allowsInlineMediaPlayback = true
        let panel = WKWebView(frame: .zero, configuration: settings)

        context.coordinator.onFirstPaint = onFirstPaint
        panel.navigationDelegate = context.coordinator
        panel.allowsBackForwardNavigationGestures = true
        panel.scrollView.bounces = true
        // Required, never .never: this is what insets scrollable content out of the home
        // indicator zone once the frame runs past the bottom safe area.
        panel.scrollView.contentInsetAdjustmentBehavior = .always
        // Opaque, so the safe-area band never flashes white.
        panel.isOpaque = true
        panel.backgroundColor = .black
        panel.scrollView.backgroundColor = .black
        // The launch branch runs in the dark scheme so the status bar glyphs come out white.
        // Pin the page itself back to light so that trait never reaches the site.
        panel.overrideUserInterfaceStyle = .light

        if let target = URL(string: address) {
            panel.load(URLRequest(url: target))
        }
        return panel
    }

    // Must never reload — doing so restarts the page on every SwiftUI re-render. Refreshing the
    // callback is the only thing that belongs here.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onFirstPaint = onFirstPaint
    }
}
