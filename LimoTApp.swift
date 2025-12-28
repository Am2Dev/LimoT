import SwiftUI
import WebKit

// MARK: - App Einstiegspunkt

/// Haupteinstiegspunkt der LimoT App
/// Lädt das Deutsch-Persische Wörterbuch loghatnameh.de
@main
struct LimoTApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Konstanten

/// Zentrale Konfiguration der App
enum AppConfig {
    static let homeURL = URL(string: "https://loghatnameh.de")!
    static let appName = "LimoT"

    /// JSON-Regeln für den Werbeblocker (blockiert Google Ads und gängige Werbenetzwerke)
    static let adBlockRulesJSON = """
    [
        {
            "trigger": {
                "url-filter": ".*",
                "if-domain": ["*googlesyndication.com", "*doubleclick.net", "*googleadservices.com", "*google-analytics.com", "*googletagmanager.com", "*googletagservices.com"]
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*ads.*",
                "resource-type": ["script", "image", "style-sheet", "raw"]
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*pagead.*"
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*adservice.*"
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*adsense.*"
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": ".*adsbygoogle.*"
            },
            "action": {
                "type": "block"
            }
        }
    ]
    """
}

// MARK: - ViewModel

/// ViewModel für die WebView-Steuerung nach MVVM-Pattern
/// Verwaltet den Ladezustand, Navigation und Werbeblocker
@MainActor
final class WebViewModel: ObservableObject {

    // MARK: - Veröffentlichte Eigenschaften

    /// Zeigt an, ob die Seite gerade lädt
    @Published private(set) var isLoading: Bool = false

    /// Zeigt an, ob Zurück-Navigation möglich ist
    @Published private(set) var canGoBack: Bool = false

    /// Zeigt an, ob Vorwärts-Navigation möglich ist
    @Published private(set) var canGoForward: Bool = false

    /// Aktueller Seitentitel
    @Published private(set) var pageTitle: String = AppConfig.appName

    /// Ladefortschritt (0.0 bis 1.0)
    @Published private(set) var loadingProgress: Double = 0.0

    /// Fehlermeldung falls vorhanden
    @Published var errorMessage: String? = nil

    // MARK: - Private Eigenschaften

    /// Referenz zur WKWebView (schwach um Retain-Cycles zu vermeiden)
    private weak var webView: WKWebView?

    /// Task für die Initialisierung der Content-Regeln
    private var contentRuleListTask: Task<WKContentRuleList?, Never>?

    /// Gecachte Content-Regel-Liste
    private var cachedContentRuleList: WKContentRuleList?

    /// Flag um Race Conditions zu vermeiden
    private var isInitializingRules: Bool = false

    // MARK: - Initialisierung

    init() {
        // Starte die Kompilierung der Werbeblock-Regeln im Hintergrund
        startContentRuleListCompilation()
    }

    // MARK: - Öffentliche Methoden

    /// Setzt die WebView-Referenz und wendet Werbeblock-Regeln an
    func setWebView(_ webView: WKWebView) {
        self.webView = webView
        applyContentRulesIfReady()
    }

    /// Aktualisiert den Ladezustand
    func updateLoadingState(isLoading: Bool) {
        self.isLoading = isLoading
    }

    /// Aktualisiert den Navigationszustand
    func updateNavigationState(canGoBack: Bool, canGoForward: Bool) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }

    /// Aktualisiert den Seitentitel
    func updateTitle(_ title: String?) {
        self.pageTitle = title?.isEmpty == false ? title! : AppConfig.appName
    }

    /// Aktualisiert den Ladefortschritt
    func updateProgress(_ progress: Double) {
        self.loadingProgress = progress
    }

    /// Navigiert zur vorherigen Seite
    func goBack() {
        webView?.goBack()
    }

    /// Navigiert zur nächsten Seite
    func goForward() {
        webView?.goForward()
    }

    /// Lädt die aktuelle Seite neu
    func reload() {
        webView?.reload()
    }

    /// Navigiert zur Startseite
    func goHome() {
        webView?.load(URLRequest(url: AppConfig.homeURL))
    }

    // MARK: - Private Methoden

    /// Startet die asynchrone Kompilierung der Werbeblock-Regeln
    /// Verwendet Task um Race Conditions zu vermeiden
    private func startContentRuleListCompilation() {
        guard !isInitializingRules else { return }
        isInitializingRules = true

        contentRuleListTask = Task { [weak self] in
            do {
                // Kompiliere die JSON-Regeln zu einer WKContentRuleList
                let ruleList = try await WKContentRuleListStore.default()
                    .compileContentRuleList(
                        forIdentifier: "AdBlockRules",
                        encodedContentRuleList: AppConfig.adBlockRulesJSON
                    )

                await MainActor.run {
                    self?.cachedContentRuleList = ruleList
                    self?.isInitializingRules = false
                    self?.applyContentRulesIfReady()
                }

                return ruleList
            } catch {
                await MainActor.run {
                    self?.errorMessage = "Werbeblocker-Fehler: \(error.localizedDescription)"
                    self?.isInitializingRules = false
                }
                return nil
            }
        }
    }

    /// Wendet die Werbeblock-Regeln auf die WebView an, falls beide bereit sind
    private func applyContentRulesIfReady() {
        guard let webView = webView,
              let ruleList = cachedContentRuleList else {
            return
        }

        // Prüfe ob die Regel bereits angewendet wurde
        let configuration = webView.configuration
        if !configuration.userContentController.userContentRuleListsDescription.contains("AdBlockRules") {
            configuration.userContentController.add(ruleList)
        }
    }
}

// MARK: - WebView UIViewRepresentable

/// SwiftUI-Wrapper für WKWebView
struct WebView: UIViewRepresentable {

    /// ViewModel für die Steuerung
    @ObservedObject var viewModel: WebViewModel

    /// Zu ladende URL
    let url: URL

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        // Konfiguration erstellen
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        // WebView erstellen
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // ViewModel mit WebView verbinden
        Task { @MainActor in
            viewModel.setWebView(webView)
        }

        // KVO-Observer für Eigenschaften hinzufügen
        context.coordinator.setupObservers(for: webView)

        // Startseite laden
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Keine Updates nötig - Navigation wird über ViewModel gesteuert
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator

    /// Coordinator für WKWebView Delegation und KVO
    final class Coordinator: NSObject, WKNavigationDelegate {

        private let viewModel: WebViewModel
        private var observations: [NSKeyValueObservation] = []

        init(viewModel: WebViewModel) {
            self.viewModel = viewModel
            super.init()
        }

        deinit {
            // Observer automatisch entfernt durch NSKeyValueObservation
            observations.removeAll()
        }

        /// Richtet KVO-Observer für WebView-Eigenschaften ein
        func setupObservers(for webView: WKWebView) {
            // Lade-Status beobachten
            let loadingObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.updateLoadingState(isLoading: webView.isLoading)
                }
            }
            observations.append(loadingObservation)

            // Zurück-Navigation beobachten
            let backObservation = webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.updateNavigationState(
                        canGoBack: webView.canGoBack,
                        canGoForward: webView.canGoForward
                    )
                }
            }
            observations.append(backObservation)

            // Vorwärts-Navigation beobachten
            let forwardObservation = webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.updateNavigationState(
                        canGoBack: webView.canGoBack,
                        canGoForward: webView.canGoForward
                    )
                }
            }
            observations.append(forwardObservation)

            // Titel beobachten
            let titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.updateTitle(webView.title)
                }
            }
            observations.append(titleObservation)

            // Ladefortschritt beobachten
            let progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.updateProgress(webView.estimatedProgress)
                }
            }
            observations.append(progressObservation)
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.updateLoadingState(isLoading: true)
                viewModel.errorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.updateLoadingState(isLoading: false)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                viewModel.updateLoadingState(isLoading: false)
                // Ignoriere abgebrochene Navigationen
                if (error as NSError).code != NSURLErrorCancelled {
                    viewModel.errorMessage = "Ladefehler: \(error.localizedDescription)"
                }
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                viewModel.updateLoadingState(isLoading: false)
                if (error as NSError).code != NSURLErrorCancelled {
                    viewModel.errorMessage = "Verbindungsfehler: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Hilfs-Extension für Content Rule List Beschreibung

extension WKUserContentController {
    /// Gibt eine Beschreibung der aktiven Content Rule Lists zurück
    var userContentRuleListsDescription: String {
        // Diese Eigenschaft wird verwendet um zu prüfen ob Regeln bereits hinzugefügt wurden
        return String(describing: self)
    }
}

// MARK: - Navigationsleiste

/// Untere Navigationsleiste mit Zurück, Vor, Neu laden und Home Buttons
struct NavigationBar: View {

    @ObservedObject var viewModel: WebViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Zurück-Button
            NavigationButton(
                systemImage: "chevron.left",
                label: "Zurück",
                isEnabled: viewModel.canGoBack
            ) {
                viewModel.goBack()
            }

            Spacer()

            // Vorwärts-Button
            NavigationButton(
                systemImage: "chevron.right",
                label: "Vor",
                isEnabled: viewModel.canGoForward
            ) {
                viewModel.goForward()
            }

            Spacer()

            // Neu laden Button
            NavigationButton(
                systemImage: viewModel.isLoading ? "xmark" : "arrow.clockwise",
                label: viewModel.isLoading ? "Stopp" : "Laden",
                isEnabled: true
            ) {
                viewModel.reload()
            }

            Spacer()

            // Home-Button
            NavigationButton(
                systemImage: "house",
                label: "Start",
                isEnabled: true
            ) {
                viewModel.goHome()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
}

/// Einzelner Navigationsbutton
struct NavigationButton: View {

    let systemImage: String
    let label: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .medium))
                Text(label)
                    .font(.caption2)
            }
        }
        .foregroundColor(isEnabled ? .accentColor : .gray)
        .disabled(!isEnabled)
        .frame(minWidth: 60)
    }
}

// MARK: - Ladeindikator

/// Ladefortschrittsanzeige am oberen Bildschirmrand
struct LoadingIndicator: View {

    let progress: Double
    let isLoading: Bool

    var body: some View {
        GeometryReader { geometry in
            if isLoading {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress, height: 3)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Fehleranzeige

/// Banner für Fehlermeldungen
struct ErrorBanner: View {

    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

            Text(message)
                .font(.footnote)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Hauptansicht

/// Hauptansicht der App mit WebView und Navigation
struct ContentView: View {

    /// ViewModel für die WebView-Steuerung
    @StateObject private var viewModel = WebViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Ladeindikator oben
            LoadingIndicator(
                progress: viewModel.loadingProgress,
                isLoading: viewModel.isLoading
            )

            // Fehlerbanner falls vorhanden
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // WebView
            WebView(viewModel: viewModel, url: AppConfig.homeURL)
                .ignoresSafeArea(edges: .horizontal)

            // Trennlinie
            Divider()

            // Navigationsleiste unten
            NavigationBar(viewModel: viewModel)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage != nil)
    }
}

// MARK: - Preview Provider

/// Preview für Xcode/Swift Playgrounds
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("LimoT - Wörterbuch")
    }
}

// MARK: - Zusätzliche Preview für NavigationBar

struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBar(viewModel: WebViewModel())
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Navigationsleiste")
    }
}
