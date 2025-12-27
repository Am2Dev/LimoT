# LimoT - Verwendungsanleitung

## Schnellstart

### Swift Playgrounds (iPad)
1. Öffne die **Swift Playgrounds** App auf deinem iPad
2. Tippe auf **"+"** → **"App"**
3. Benenne das Projekt "LimoT"
4. Öffne die erstellte App-Datei
5. Ersetze den gesamten Code mit dem Inhalt von `LimoT.swift`
6. Tippe auf **"Ausführen"** (Play-Button)

### Swift Playgrounds (Mac)
1. Öffne **Swift Playgrounds** auf deinem Mac
2. Wähle **"App"** als Projekttyp
3. Füge den Code aus `LimoT.swift` ein
4. Klicke auf **"Run"**

### Xcode
1. Öffne Xcode (14.0+)
2. Erstelle ein neues Projekt: **iOS App**
3. Wähle **SwiftUI** als Interface
4. Ersetze `ContentView.swift` und `[ProjectName]App.swift` durch `LimoT.swift`
5. Baue und führe das Projekt aus (⌘R)

## Features im Detail

### 🚫 Werbeblocker

Der integrierte Werbeblocker nutzt Apples WKContentRuleList API und blockiert:

- **Google AdSense** (googlesyndication.com)
- **DoubleClick** (doubleclick.net)
- **Google Ad Services** (googleadservices.com)
- **Google Analytics** (google-analytics.com)

Die Regeln werden asynchron beim App-Start geladen, um Race Conditions zu vermeiden.

### 🌙 Dark Mode

Die App injiziert automatisch CSS für Dark Mode, wenn das System im Dark Mode ist:

- Dunkler Hintergrund (#1c1c1e)
- Helle Textfarben (#ffffff)
- Angepasste Link-Farben (#0a84ff)
- Optimierte Formularelemente
- Angepasste Tabellen

Das CSS wird nach jedem Seitenaufruf neu injiziert.

### 🧭 Navigation

Die untere Navigationsleiste bietet:

| Button | Symbol | Funktion | Aktivierung |
|--------|--------|----------|-------------|
| Zurück | ← | Vorherige Seite | Wenn Historie vorhanden |
| Vor | → | Nächste Seite | Wenn Forward-Historie vorhanden |
| Reload | ↻ | Seite neu laden | Immer aktiv |
| Home | 🏠 | Zur Startseite | Immer aktiv |

Buttons werden automatisch deaktiviert, wenn die Funktion nicht verfügbar ist (z.B. Zurück auf der ersten Seite).

### ⏳ Ladeindikator

Ein zentrierter Ladeindikator erscheint während:
- Initial-Laden der Seite
- Navigation zu neuen Seiten
- Reload-Vorgängen

Der Indikator zeigt:
- Kreisförmige Progress-Animation
- "Lädt..." Text
- Halbtransparenter Hintergrund mit Schatten

## Technische Hinweise

### MVVM Architektur

```
WebViewModel (ObservableObject)
    ├── @Published Properties (isLoading, canGoBack, etc.)
    ├── WebView-Referenz
    ├── Navigation Methods
    └── Dark Mode CSS Injection

WebView (UIViewRepresentable)
    ├── WKWebView Wrapper
    └── Coordinator (WKNavigationDelegate)

ContentView
    ├── WebView
    ├── Ladeindikator (conditional)
    └── NavigationBar
```

### Race Condition Prevention

```swift
private var isRuleListLoading = false  // Flag-basierte Synchronisation
private var contentRuleList: WKContentRuleList?

private func setupContentRuleList() {
    guard !isRuleListLoading else { return }  // Verhindert mehrfaches Laden
    isRuleListLoading = true
    
    WKContentRuleListStore.default().compileContentRuleList(...) {
        // Completion Handler
        self.isRuleListLoading = false
    }
}
```

### State Management

Die App nutzt SwiftUI's `@StateObject`, `@ObservedObject` und `@Published` für reaktive Updates:

- `@StateObject` in ContentView für ViewModel-Lifecycle
- `@ObservedObject` in Child Views für Updates
- `@Published` Properties triggern automatisch UI-Updates

## Anpassungen

### Andere Webseite laden

Ändere die `homeURL` in `WebViewModel`:

```swift
let homeURL = URL(string: "https://deine-webseite.de")!
```

### Zusätzliche Werbedomains blockieren

Erweitere das `blockRules` JSON in `setupContentRuleList()`:

```swift
{
    "trigger": {
        "url-filter": "deine-werbedomain.com"
    },
    "action": {
        "type": "block"
    }
}
```

### Dark Mode CSS anpassen

Modifiziere das CSS in `injectDarkModeCSS()`:

```swift
body {
    background-color: #deine-farbe !important;
    color: #deine-textfarbe !important;
}
```

### Navigation Position ändern

In `ContentView`, verschiebe `NavigationBar`:

```swift
VStack(spacing: 0) {
    NavigationBar(viewModel: viewModel)  // Oben
    WebView(viewModel: viewModel)
}
```

## Fehlerbehebung

### "No such module 'SwiftUI'"
- Stelle sicher, dass du auf iOS 16+ testest
- Nutze einen iOS Simulator oder echtes Gerät
- Linux/Windows werden nicht unterstützt

### Webseite lädt nicht
- Überprüfe Internetverbindung
- Stelle sicher, dass loghatnameh.de erreichbar ist
- Checke Console-Logs in Xcode

### Dark Mode funktioniert nicht
- CSS-Injection erfolgt nach Seitenaufruf
- Manche Webseiten überschreiben externe Styles
- Versuche, das CSS anzupassen

### Werbeblocker blockiert zu viel/wenig
- Passe die `blockRules` an
- Nutze Safari Web Inspector für Debugging
- Überprüfe die Console auf blockierte Requests

## System-Anforderungen

- **Minimal**: iOS 16.0, iPadOS 16.0
- **Empfohlen**: iOS 17.0+
- **Xcode**: 14.0+
- **Swift Playgrounds**: 4.0+

## Support & Beitragen

Bei Fragen oder Problemen:
1. Checke die Console-Logs
2. Überprüfe die Requirements
3. Erstelle ein Issue auf GitHub

## Lizenz

Apache License 2.0 - Siehe LICENSE Datei für Details.
