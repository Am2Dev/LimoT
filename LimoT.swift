// LimoT - iOS SwiftUI App für Swift Playgrounds
// Deutsch-Persisch Wörterbuch App mit WKWebView
// iOS 16+ kompatibel

import SwiftUI
import WebKit
import Combine

// MARK: - WebView ViewModel (MVVM Pattern)

/// ViewModel zur Verwaltung des WebView-Status und der Navigation
/// Verwendet ObservableObject für reaktive Updates
class WebViewModel: ObservableObject {
    // Published Properties für UI-Updates
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var currentURL: URL?
    
    // WebView-Referenz
    var webView: WKWebView?
    
    // Haupt-URL der Webseite
    let homeURL = URL(string: "https://www.loghatnameh.de")!
    
    // Content Rule List für Werbeblocker (wird asynchron geladen)
    private var contentRuleList: WKContentRuleList?
    
    // Flag zur Vermeidung von Race Conditions
    private var isRuleListLoading = false
    private var ruleListLoadCompletion: (() -> Void)?
    
    init() {
        setupContentRuleList()
    }
    
    /// Initialisiert die Content Rule List für den Werbeblocker
    /// Vermeidet Race Conditions durch Flag-basierte Synchronisation
    private func setupContentRuleList() {
        // Verhindere mehrfaches gleichzeitiges Laden
        guard !isRuleListLoading else { return }
        isRuleListLoading = true
        
        // JSON-Regeln für das Blockieren von Google Ads
        let blockRules = """
        [
            {
                "trigger": {
                    "url-filter": ".*",
                    "resource-type": ["script", "image"],
                    "if-domain": ["*googlesyndication.com", "*doubleclick.net", "*googleadservices.com", "*google-analytics.com"]
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "pagead2.googlesyndication.com"
                },
                "action": {
                    "type": "block"
                }
            },
            {
                "trigger": {
                    "url-filter": "adservice.google.com"
                },
                "action": {
                    "type": "block"
                }
            }
        ]
        """
        
        // Kompiliere die Content Rule List asynchron
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "AdBlockRules",
            encodedContentRuleList: blockRules
        ) { [weak self] ruleList, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Fehler beim Laden der Content Rule List: \(error.localizedDescription)")
            } else if let ruleList = ruleList {
                self.contentRuleList = ruleList
                print("Content Rule List erfolgreich geladen")
            }
            
            // Markiere Laden als abgeschlossen
            self.isRuleListLoading = false
            
            // Rufe Completion-Handler auf, falls vorhanden
            self.ruleListLoadCompletion?()
            self.ruleListLoadCompletion = nil
        }
    }
    
    /// Erstellt und konfiguriert eine neue WKWebView-Instanz
    func createWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Füge Content Rule List hinzu, falls bereits geladen
        if let ruleList = contentRuleList {
            configuration.userContentController.add(ruleList)
        }
        
        // Erlaube Inline-Medien-Wiedergabe
        configuration.allowsInlineMediaPlayback = true
        
        // Erstelle WebView mit Konfiguration
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        
        self.webView = webView
        
        return webView
    }
    
    /// Injiziert CSS für Dark Mode Support
    func injectDarkModeCSS() {
        let darkModeCSS = """
        (function() {
            var style = document.createElement('style');
            style.innerHTML = `
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #1c1c1e !important;
                        color: #ffffff !important;
                    }
                    a {
                        color: #0a84ff !important;
                    }
                    input, textarea, select {
                        background-color: #2c2c2e !important;
                        color: #ffffff !important;
                        border-color: #48484a !important;
                    }
                    table, th, td {
                        border-color: #48484a !important;
                        background-color: #2c2c2e !important;
                    }
                    div, p, span, li {
                        color: #ffffff !important;
                    }
                }
            `;
            document.head.appendChild(style);
        })();
        """
        
        webView?.evaluateJavaScript(darkModeCSS, completionHandler: nil)
    }
    
    // MARK: - Navigation Methods
    
    /// Lädt die Home-URL
    func loadHome() {
        webView?.load(URLRequest(url: homeURL))
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
    
    /// Aktualisiert den Navigation-Status
    func updateNavigationState() {
        canGoBack = webView?.canGoBack ?? false
        canGoForward = webView?.canGoForward ?? false
        currentURL = webView?.url
    }
}

// MARK: - WebView UIViewRepresentable Wrapper

/// SwiftUI-Wrapper für WKWebView
struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = viewModel.createWebView()
        webView.navigationDelegate = context.coordinator
        
        // Lade Home-URL initial
        viewModel.loadHome()
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Keine Updates notwendig
    }
    
    // MARK: - Coordinator für WKNavigationDelegate
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // Wird aufgerufen, wenn Navigation startet
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.viewModel.isLoading = true
            parent.viewModel.updateNavigationState()
        }
        
        // Wird aufgerufen, wenn Seite fertig geladen ist
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.viewModel.isLoading = false
            parent.viewModel.updateNavigationState()
            
            // Injiziere Dark Mode CSS nach dem Laden
            parent.viewModel.injectDarkModeCSS()
        }
        
        // Wird aufgerufen bei Fehlern
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.viewModel.isLoading = false
            parent.viewModel.updateNavigationState()
            print("Navigation fehlgeschlagen: \(error.localizedDescription)")
        }
        
        // Wird aufgerufen bei provisorischen Navigationsfehlern
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.viewModel.isLoading = false
            parent.viewModel.updateNavigationState()
            print("Provisorische Navigation fehlgeschlagen: \(error.localizedDescription)")
        }
    }
}

// MARK: - Navigation Bar View

/// Untere Navigationsleiste mit Buttons
struct NavigationBar: View {
    @ObservedObject var viewModel: WebViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // Zurück-Button
            Button(action: {
                viewModel.goBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .disabled(!viewModel.canGoBack)
            .foregroundColor(viewModel.canGoBack ? .blue : .gray)
            
            Divider()
            
            // Vor-Button
            Button(action: {
                viewModel.goForward()
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .disabled(!viewModel.canGoForward)
            .foregroundColor(viewModel.canGoForward ? .blue : .gray)
            
            Divider()
            
            // Reload-Button
            Button(action: {
                viewModel.reload()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .foregroundColor(.blue)
            
            Divider()
            
            // Home-Button
            Button(action: {
                viewModel.loadHome()
            }) {
                Image(systemName: "house")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .foregroundColor(.blue)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

// MARK: - Main Content View

/// Hauptansicht der App mit WebView und Navigation
struct ContentView: View {
    @StateObject private var viewModel = WebViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // WebView mit Ladeindikator
            ZStack {
                WebView(viewModel: viewModel)
                
                // Ladeindikator in der Mitte
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        Text("Lädt...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                }
            }
            
            // Untere Navigationsleiste
            NavigationBar(viewModel: viewModel)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

// MARK: - Preview Provider

/// Preview für SwiftUI Canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("LimoT - Loghatnameh Browser")
    }
}

// MARK: - App Entry Point

/// Haupt-App-Struktur für Swift Playgrounds
@main
struct LimoTApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
