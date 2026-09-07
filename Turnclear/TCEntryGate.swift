import SwiftUI

/// Launch check.
///
/// The gate closes because the marker domain was actually seen, never because the network was
/// slow. Anything that is not "I saw the marker" stays recoverable: one immediate retry, then
/// the native app straight away while the check carries on quietly in the background.
@MainActor
final class TCEntryGate: ObservableObject {
    /// nil = still deciding · false = native app · true = web panel
    @Published private(set) var tcPanelReady: Bool? = nil

    let tcSourceLink: String
    private let tcMarkerDomain: String
    private let tcOwnHost: String

    /// Stall limit while the splash is up. Short on purpose — a late verdict can still swap the
    /// panel in, so there is nothing to gain by making anyone wait here.
    private let splashStall: TimeInterval = 3
    /// Stall limit once the native app is already on screen. Nobody is waiting now.
    private let quietStall: TimeInterval = 8
    /// Ceiling for a single attempt, so an endless trickle of redirects cannot hang the launch.
    private let attemptCeiling: TimeInterval = 30
    /// How long after launch a late verdict may still replace the native app.
    private let swapWindow: TimeInterval = 25
    private let quietRetryDelay: TimeInterval = 3

    private var settled = false
    private var attemptToken = 0
    private var startedAt = Date()
    private var lastProgress = Date()
    private var stallTimer: Timer?
    private var probe: URLSessionTask?

    init(tcSourceLink: String, tcMarkerDomain: String) {
        self.tcSourceLink = tcSourceLink
        self.tcMarkerDomain = tcMarkerDomain
        self.tcOwnHost = URL(string: tcSourceLink)?.host ?? ""
    }

    func begin() {
        guard attemptToken == 0 else { return }   // onAppear can fire more than once
        startedAt = Date()
        runAttempt(1)
    }

    private func runAttempt(_ number: Int) {
        guard !settled else { return }
        guard let target = URL(string: tcSourceLink) else { settle(false); return }

        attemptToken += 1
        let token = attemptToken

        var request = URLRequest(url: target)
        // HEAD, never GET: a default GET pulls down the whole page and the panel then fetches
        // the very same page again from scratch, doubling the launch cost for nothing.
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        let configuration = URLSessionConfiguration.default
        // No attempt may sit waiting for the radio while the splash is up.
        configuration.waitsForConnectivity = (tcPanelReady != nil)
        configuration.timeoutIntervalForResource = attemptCeiling

        let watcher = TCHopWatcher(markerDomain: tcMarkerDomain, ownHost: tcOwnHost)
        watcher.onProgress = { [weak self] in
            Task { @MainActor in self?.noteProgress() }
        }
        watcher.onEarlyVerdict = { [weak self] verdict in
            Task { @MainActor in self?.settle(verdict) }
        }

        let session = URLSession(configuration: configuration, delegate: watcher, delegateQueue: nil)
        lastProgress = Date()
        armStallWatch(attempt: number, token: token)

        probe = session.dataTask(with: request) { [weak self] _, response, error in
            Task { @MainActor in
                guard let self = self, !self.settled, self.attemptToken == token else { return }
                if watcher.sawMarker { self.settle(false); return }
                if let landed = watcher.resolvedURL?.absoluteString,
                   landed.contains(self.tcMarkerDomain) { self.settle(false); return }
                if let http = response as? HTTPURLResponse,
                   let address = http.url?.absoluteString,
                   address.contains(self.tcMarkerDomain) { self.settle(false); return }
                if error != nil { self.attemptFailed(attempt: number, token: token); return }
                self.settle(true)
            }
        }
        probe?.resume()
    }

    private func noteProgress() {
        lastProgress = Date()
    }

    /// Watches progress, not the clock: every hop re-arms it, so a chain that is merely slow is
    /// never killed. The absolute ceiling only stops a server that never finishes.
    private func armStallWatch(attempt number: Int, token: Int) {
        stallTimer?.invalidate()
        stallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self, !self.settled, self.attemptToken == token else {
                    timer.invalidate()
                    return
                }
                let limit = self.tcPanelReady == nil ? self.splashStall : self.quietStall
                let stalled = Date().timeIntervalSince(self.lastProgress) > limit
                let overCeiling = Date().timeIntervalSince(self.startedAt) > self.attemptCeiling
                guard stalled || overCeiling else { return }   // still moving, keep waiting
                timer.invalidate()
                self.probe?.cancel()
                self.attemptFailed(attempt: number, token: token)
            }
        }
    }

    private func attemptFailed(attempt number: Int, token: Int) {
        // The cancelled task's completion handler and the stall watch both land here; the token
        // makes whichever arrives second a no-op.
        guard !settled, attemptToken == token else { return }
        attemptToken += 1
        stallTimer?.invalidate()

        // One immediate retry. Most mobile failures are transient — a connection lost on a cell
        // handoff, a timeout, no connectivity yet.
        if number == 1 { runAttempt(2); return }

        // Out of fast options: show the native app now and keep looking quietly.
        if tcPanelReady == nil { tcPanelReady = false }
        scheduleQuietAttempt(next: number + 1)
    }

    private func scheduleQuietAttempt(next number: Int) {
        guard !settled, Date().timeIntervalSince(startedAt) < swapWindow else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + quietRetryDelay) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.settled,
                      Date().timeIntervalSince(self.startedAt) < self.swapWindow else { return }
                self.runAttempt(number)
            }
        }
    }

    private func settle(_ verdict: Bool) {
        guard !settled else { return }
        // A late verdict may still close the gate, but must never pull someone who has been
        // using the app for half a minute into a web panel.
        if verdict, tcPanelReady == false, Date().timeIntervalSince(startedAt) > swapWindow {
            settled = true
            stallTimer?.invalidate()
            return
        }
        settled = true
        stallTimer?.invalidate()
        tcPanelReady = verdict
    }
}

/// Reads the redirect chain and decides at the first hop that carries information. Everything
/// after that hop is downstream and cannot change the answer.
final class TCHopWatcher: NSObject, URLSessionTaskDelegate {
    /// Fires on every observed hop and re-arms the stall watch.
    var onProgress: (() -> Void)?
    /// Fires at most once, the moment the chain becomes decidable.
    var onEarlyVerdict: ((Bool) -> Void)?

    private(set) var resolvedURL: URL?
    private(set) var sawMarker = false

    private let markerDomain: String
    private let ownHost: String
    private var decided = false

    init(markerDomain: String, ownHost: String) {
        self.markerDomain = markerDomain
        self.ownHost = ownHost
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        resolvedURL = request.url
        onProgress?()

        if let address = request.url?.absoluteString {
            if address.contains(markerDomain) {
                sawMarker = true
                decide(false)
            } else if let host = request.url?.host, !hostIsOurs(host) {
                decide(true)
            }
            // A hop that stays on our own host decides nothing.
        }
        completionHandler(request)   // never stop the chain
    }

    private func hostIsOurs(_ host: String) -> Bool {
        !ownHost.isEmpty && (host == ownHost || host.hasSuffix("." + ownHost))
    }

    private func decide(_ verdict: Bool) {
        guard !decided else { return }
        decided = true
        onEarlyVerdict?(verdict)
    }
}
