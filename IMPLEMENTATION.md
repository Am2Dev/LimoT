# LimoT - Implementierungs-Details

## Übersicht

LimoT ist eine iOS SwiftUI App, die speziell für Swift Playgrounds entwickelt wurde. Sie lädt das Deutsch-Persisch Wörterbuch loghatnameh.de in einem optimierten WKWebView mit Werbeblocker, Dark Mode Support und intuitiver Navigation.

## Architektur-Entscheidungen

### MVVM Pattern

**Warum MVVM?**
- Klare Trennung von UI-Logik und Business-Logik
- Testbarkeit durch isolierte ViewModels
- SwiftUI-konforme Architektur mit ObservableObject
- Einfache State-Verwaltung mit @Published Properties

**Komponenten:**

1. **WebViewModel**: 
   - Zentraler State-Manager
   - Verwaltet WebView-Instanz
   - Handhabt Navigation und Lade-Status
   - Injiziert Dark Mode CSS

2. **Views**:
   - `WebView`: UIViewRepresentable Wrapper für WKWebView
   - `NavigationBar`: Bottom Navigation UI
   - `ContentView`: Haupt-Container mit Layout

### Single-File Approach

**Vorteile:**
- Swift Playgrounds kompatibel (keine Multi-File-Projekte nötig)
- Einfach zu teilen und zu deployen
- Übersichtlich für kleinere Apps (< 500 Zeilen)
- Keine Package Dependencies

**Nachteile:**
- Weniger skalierbar für große Projekte
- Keine modulare Wiederverwendung

**Entscheidung:** Für diesen Use-Case optimal, da es eine in-sich geschlossene App ist.

## Feature-Implementierungen

### 1. Werbeblocker (WKContentRuleList)

**Technologie:** WKContentRuleListStore API

**Implementierung:**
```swift
WKContentRuleListStore.default().compileContentRuleList(
    forIdentifier: "AdBlockRules",
    encodedContentRuleList: blockRules
) { ruleList, error in
    // Asynchroner Callback
}
```

**Blockierte Domains:**
- `*googlesyndication.com` (AdSense Scripts)
- `*doubleclick.net` (Display Ads)
- `*googleadservices.com` (Ad Services)
- `*google-analytics.com` (Tracking)

**Race Condition Prevention:**
- Flag `isRuleListLoading` verhindert mehrfaches Laden
- Weak self capture vermeidet Retain Cycles
- ContentRuleList wird zur Configuration hinzugefügt, falls bereits geladen

### 2. Dark Mode (CSS-Injection)

**Ansatz:** JavaScript-basierte CSS-Injection

**Vorteile gegenüber nativer WKWebView Dark Mode:**
- Volle Kontrolle über Styling
- Kompatibel mit allen Webseiten
- Anpassbar für spezifische Domains
- iOS System Dark Mode aware

**Implementierung:**
```swift
webView?.evaluateJavaScript(darkModeCSS, completionHandler: nil)
```

**CSS Media Query:**
```css
@media (prefers-color-scheme: dark) {
    /* Custom Dark Mode Styles */
}
```

**Injection-Zeitpunkt:**
- Nach jedem `didFinish` Navigation Event
- Stellt sicher, dass DOM vollständig geladen ist
- Funktioniert auch bei dynamisch geladenen Inhalten

### 3. Navigation

**Design Pattern:** Bottom Navigation (iOS Standard für Browser-Apps)

**Komponenten:**
```swift
HStack {
    BackButton    // ←
    ForwardButton // →
    ReloadButton  // ↻
    HomeButton    // 🏠
}
```

**State Management:**
- `canGoBack` / `canGoForward` aus WKWebView
- Automatische Button-Aktivierung/Deaktivierung
- Visual Feedback (Farbe: blue/gray)

**Accessibility:**
- SF Symbols für universelle Verständlichkeit
- Große Touch-Targets (44pt+ Höhe)
- Disabled State visuell unterscheidbar

### 4. Ladeindikator

**UI/UX Design:**
- Zentrierte Anzeige (nicht störend)
- Halbtransparenter Hintergrund
- Schatten für Tiefe
- "Lädt..." Text für Klarheit

**Conditional Rendering:**
```swift
if viewModel.isLoading {
    ProgressView()
    // ...
}
```

**State Binding:**
- `@Published var isLoading` in ViewModel
- Automatisches Update bei Navigation Events
- Synchron mit WKNavigationDelegate callbacks

## Technische Besonderheiten

### Thread-Safety

**Problem:** WKContentRuleListStore ist asynchron

**Lösung:**
```swift
private var isRuleListLoading = false  // Thread-safe flag

guard !isRuleListLoading else { return }  // Early return
isRuleListLoading = true

// Async operation
{ [weak self] in
    self?.isRuleListLoading = false  // Reset auf Main Thread
}
```

### Memory Management

**Retain Cycles vermeiden:**
```swift
{ [weak self] ruleList, error in
    guard let self = self else { return }
    // Safe usage
}
```

**WebView Lifecycle:**
- WebView als weak reference in ViewModel (optional)
- Coordinator Pattern für Delegate
- Automatisches Cleanup durch ARC

### SwiftUI Best Practices

**@StateObject vs @ObservedObject:**
```swift
// In ContentView (Owner)
@StateObject private var viewModel = WebViewModel()

// In Child Views (Observer)
@ObservedObject var viewModel: WebViewModel
```

**Safe Area Handling:**
```swift
.ignoresSafeArea(.all, edges: .bottom)  // Navigation Bar am Bildschirmrand
```

## Performance-Optimierungen

### Lazy Loading
- ContentRuleList wird asynchron im Background kompiliert
- WebView Initialisierung erst bei Bedarf
- CSS-Injection nur nach erfolgreichem Seitenaufruf

### Resource Management
- Einmalige ContentRuleList-Kompilierung
- Wiederverwendung der gleichen WebView-Instanz
- Effiziente State-Updates durch @Published

## Sicherheit

### Web Content Security
- WKContentRuleList blockiert Tracking-Scripts
- Same-Origin Policy durch WKWebView
- No eval() in injected JavaScript
- Sichere URL-Validierung

### Data Privacy
- Keine Datensammlung oder -speicherung
- Kein Analytics oder Tracking
- Lokale Ad-Blocking Rules
- Keine externen Dependencies

## Testing

### Preview Provider
```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("LimoT - Loghatnameh Browser")
    }
}
```

**Vorteile:**
- Live Preview in Xcode Canvas
- Schnelle UI-Iterationen
- Verschiedene Device-Größen testbar

### Manuelle Tests
1. Initial Load → Lädt loghatnameh.de
2. Navigation → Alle Buttons funktionieren
3. Dark Mode → CSS wird angewendet
4. Ad Blocking → Keine Google Ads sichtbar
5. Loading State → Indikator erscheint/verschwindet

## Erweiterbarkeit

### Neue Features hinzufügen

**Beispiel: Lesezeichen-Funktion**
```swift
// In WebViewModel
@Published var bookmarks: [URL] = []

func addBookmark() {
    if let url = currentURL {
        bookmarks.append(url)
    }
}
```

**Beispiel: Tab-Verwaltung**
- Neue WebView-Instanzen im ViewModel
- Tab-Bar Komponente
- State für aktiven Tab

**Beispiel: Offline-Modus**
- WKWebsiteDataStore für Caching
- URLCache Konfiguration
- Offline-Indikator

## Kompatibilität

### iOS Versionen
- **Minimum:** iOS 16.0 (async/await Support)
- **Target:** iOS 17.0+ (optimale Performance)
- **APIs:**
  - SwiftUI 4.0+
  - WebKit Framework
  - Combine Framework

### Devices
- iPhone (alle Größen)
- iPad (Full Support)
- Mac Catalyst (nicht getestet)

## Lessons Learned

### Was gut funktioniert
✅ Single-File Approach für Swift Playgrounds
✅ MVVM mit ObservableObject
✅ CSS-Injection für Dark Mode
✅ WKContentRuleList für Ad-Blocking

### Herausforderungen
⚠️ Race Conditions bei async ContentRuleList
⚠️ CSS-Injection bei dynamischen Webseiten
⚠️ Testing ohne echtes iOS Device schwierig

### Verbesserungspotential
🔧 Persistente ContentRuleList (Cache)
🔧 User-definierbare Block-Rules
🔧 Erweiterte Tab-Funktionalität
🔧 Lesemodus für Artikel

## Fazit

LimoT demonstriert moderne iOS-Entwicklung mit:
- SwiftUI für deklarative UI
- MVVM für saubere Architektur
- WebKit für Web-Content
- Combine für reaktive Updates

Die App ist produktionsreif für Swift Playgrounds und kann als Basis für erweiterte Browser-Apps dienen.

---

**Entwickelt:** 2025-12-27
**Swift Version:** 5.7+
**iOS Version:** 16.0+
**Lizenz:** Apache 2.0
