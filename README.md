# LimoT - Loghatnameh iOS Browser

Eine iOS SwiftUI App für Swift Playgrounds, die das Deutsch-Persisch Wörterbuch loghatnameh.de in einem optimierten WebView lädt.

## Features

### 🚫 Werbeblocker
- Blockiert Google Ads über WKContentRuleList
- Filtert Scripts und Bilder von Werbedomains:
  - googlesyndication.com
  - doubleclick.net
  - googleadservices.com
  - google-analytics.com

### 🌙 Dark Mode Support
- Automatische CSS-Injection für Dark Mode
- Passt sich dem System-Theme an
- Optimiert Hintergrund, Text und Formularelemente

### 🧭 Navigation
Bottom Navigation Bar mit vier Funktionen:
- **Zurück**: Vorherige Seite
- **Vor**: Nächste Seite
- **Reload**: Seite neu laden
- **Home**: Zur Startseite (loghatnameh.de)

### ⏳ Ladeindikator
- Visuelles Feedback während des Ladens
- Zentrierte Anzeige mit "Lädt..." Text

## Technische Details

### Architektur
- **MVVM Pattern**: Trennung von UI und Logik
- **ObservableObject**: Reaktive State-Updates
- **WKWebView**: Native Browser-Integration
- **iOS 16+**: Nutzt moderne SwiftUI Features

### Race Condition Prevention
- Flag-basierte Synchronisation beim Laden der ContentRuleList
- Verhindert mehrfaches gleichzeitiges Laden
- Sicherer asynchroner Zugriff

### Code-Struktur
Alles in einer Datei (`LimoT.swift`):
- `WebViewModel`: ViewModel für WebView-Verwaltung
- `WebView`: UIViewRepresentable Wrapper
- `NavigationBar`: Bottom Navigation Komponente
- `ContentView`: Hauptansicht
- `LimoTApp`: App Entry Point

## Installation

### Swift Playgrounds (iPad/Mac)
1. Öffne Swift Playgrounds
2. Erstelle ein neues App-Projekt
3. Ersetze den Inhalt mit `LimoT.swift`
4. Führe die App aus

### Xcode
1. Erstelle ein neues iOS App Projekt
2. Füge `LimoT.swift` hinzu
3. Baue und führe aus (iOS 16+ Simulator/Gerät)

## Verwendung

Die App startet automatisch mit der loghatnameh.de Homepage. Nutze die untere Navigationsleiste für:
- Vor/Zurück Navigation
- Seite neu laden
- Zur Startseite zurückkehren

## Anforderungen

- iOS 16.0+
- Swift 5.7+
- Xcode 14+ oder Swift Playgrounds 4+

## Lizenz

Apache License 2.0 - siehe LICENSE Datei

## Entwickelt für

Deutsch-Persisch Wörterbuch: [loghatnameh.de](https://www.loghatnameh.de)