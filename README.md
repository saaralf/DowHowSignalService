# DowHowSignalService

DowHowSignalService ist ein MetaTrader-5 Expert Advisor fuer die Verwaltung und Veröffentlichung von Trading-Signalen nach Discord. Das Projekt kombiniert eine Chart-nahe Bedienoberflaeche, Status- und Positionsverwaltung, SQLite-Persistenz sowie ein Routing von Symbolen auf unterschiedliche Discord-Webhooks.

Der EA ist darauf ausgelegt, Signale kontrolliert zu erzeugen, Bearbeitungen im Chart nachzuhalten, Statuswechsel sauber zu verarbeiten und die Laufzeitdaten auch nach einem Neustart wiederherzustellen.

## Ziel des Projekts

Der EA unterstuetzt einen Signalservice-Workflow direkt im MT5-Chart:

- Trade-Ideen im Chart vorbereiten
- Entry- und SL-Linien visuell setzen oder verschieben
- Trades und Positionen nummeriert verwalten
- Nachrichten an den passenden Discord-Kanal senden
- Offene, geschlossene oder stornierte Positionen konsistent in der DB fuehren
- Linien, Panel-Zustand und Trade-Kontext nach Neustarts wiederherstellen

## Hauptfunktionen

- Interaktives Panel fuer Trade-Eingaben und Aktionen
- Chart-basierte Entry- und Stop-Loss-Linien
- Verwaltung von LONG- und SHORT-Trades mit Trade- und Positionsnummern
- Discord-Versand ueber Webhooks inklusive Symbol-Routing
- SQLite-Datenbank fuer Meta-Zustaende und Positionsdaten
- Persistenz von Drafts, Linienpreisen und Statuswerten
- Wiederherstellung offener Trade-Visualisierungen nach Neustart
- Logging in eine Datei zur Fehlersuche
- Idempotente Status-Transitions, damit wiederholte Trigger keine Doppelmeldungen und keine unnötigen DB-Flaps erzeugen
- `created_at` in `positions`, damit der urspruengliche Insert-Zeitpunkt nachvollziehbar bleibt

## Architektur ueberblick

Das Projekt ist modular aufgebaut. Die wichtigsten Bestandteile sind:

### `Trade Assistent V2.033.mq5`
Haupteinstieg des Expert Advisors. Hier werden zentrale Services initialisiert, Webhooks registriert, Logging aktiviert und die Hauptmodule verdrahtet.

### `CTradeManager.mqh`
Zentrale Business-Logik fuer Trades und Positionen.

Typische Aufgaben:
- Senden eines neuen Signal-Drafts
- Ermitteln von Trade- und Positionsnummern
- Statuswechsel von Positionen
- Cancel-Logik auf Trade- und Positionsebene
- Wiederherstellung von Trade-Linien
- Steuerung der DB-Schreibpfade

### `CDBService.mqh`
SQLite-Abstraktion fuer das Projekt.

Verantwortlich fuer:
- Oeffnen und Initialisieren der globalen SQLite-Datenbank
- Schema-Erzeugung
- Lesen und Schreiben von `meta`-Werten
- Lesen und Schreiben von `positions`
- Namespaced Keys pro Symbol und Timeframe
- Migrationen wie neue Spalten, z. B. `created_at`

Die Datenbank wird global im MT5 Common Files Bereich gespeichert:

- Datei: `DowHowState_Global.sqlite`

### `CDiscordClient.mqh`
Kapselt den Versand von Discord-Nachrichten via `WebRequest()`.

### `CWebhookRouter.mqh`
Ordnet Broker-Symbole den passenden kanonischen Symbolen und Webhooks zu. Unterstuetzt Alias-Muster, damit z. B. Symbolvarianten mit Broker-Suffixen trotzdem korrekt geroutet werden.

### `CTradesPanel.mqh`
Panel-Logik fuer Bedienung, Buttons, Eingabefelder und Benutzeraktionen.

### `CVirtualTradeGUI.mqh`
Verwaltet GUI-nahe Entwurfs- und Darstellungslogik fuer Linien, Eingaben und Chartobjekte.

### `CChartEventRouter.mqh`
Zentraler Router fuer `OnChartEvent`, damit Eingaben aus Panel, Chart und Drag-Interaktionen sauber an die richtigen Komponenten delegiert werden.

### `positions_cache.mqh`
Laufzeit-Cache fuer Positionsdaten. Die Quelle der Wahrheit fuer die Persistenz ist weiterhin die Datenbank, der Cache hilft aber bei performanter Laufzeitlogik.

### `logger.mqh`
Datei-Logging fuer Debugging und Diagnose.

## Projektstruktur

Typische Dateien im Repository:

- `Trade Assistent V2.033.mq5` - Haupt-EA
- `CTradeManager.mqh` - Trade-Logik
- `CDBService.mqh` - SQLite-Zugriff
- `CDiscordClient.mqh` - Discord-Kommunikation
- `CWebhookRouter.mqh` - Symbol-zu-Webhook-Routing
- `CTradesPanel.mqh` - Panel
- `CVirtualTradeGUI.mqh` - visuelle Trade-Steuerung
- `CChartEventRouter.mqh` - Event-Dispatch
- `trade_pos_line_registry.mqh` - Verwaltung gezeichneter Trade-/Positionslinien
- `logger.mqh` - Logging
- `ui_*.mqh`, `context.mqh`, `event.mqh` - UI-, Kontext- und Glue-Code

Zusätzlich liegen kompilierte EX5-Dateien verschiedener Versionen im Projektordner.

## Voraussetzungen

- MetaTrader 5
- MQL5 Database API fuer SQLite
- Erlaubte `WebRequest`-Zugriffe fuer Discord-Webhook-Domains
- Schreibzugriff auf den MT5 Common Files Bereich

## Installation

### 1. Dateien in MT5 ablegen
Kopiere den Projektordner bzw. die `.mq5`- und `.mqh`-Dateien in dein MQL5-Verzeichnis, typischerweise unter:

- `MQL5/Experts/`
- optional weitere Includes unter `MQL5/Include/`, falls du das Projekt so strukturierst

Am einfachsten bleibt die komplette Struktur zusammen in einem gemeinsamen Ordner, damit alle Includes aufgeloest werden.

### 2. EA kompilieren
Oeffne `Trade Assistent V2.033.mq5` im MetaEditor und kompiliere den EA.

### 3. WebRequest freigeben
In MetaTrader 5 muessen die Discord-Endpunkte fuer `WebRequest()` erlaubt sein.

Typisch:
- `https://discord.com`
- `https://discordapp.com`

Ohne diese Freigabe wird der Versand scheitern. Discord ist dann stumm wie ein beleidigter Hamster.

### 4. EA auf Chart legen
Ziehe den EA auf den gewuenschten Chart und pruefe die Eingabeparameter.

## Konfiguration

Der EA besitzt zahlreiche `input`-Parameter. Besonders relevant sind:

### Allgemein
- `InpBotName` - Anzeigename fuer Discord-Nachrichten
- `InpDebug` - Debug-Verhalten
- `InpRequireDiscord` - ob Discord-Verfuegbarkeit verpflichtend ist
- `InpRequireKnownSymbol` - nur bekannte Symbol-Mappings duerfen gesendet werden

### Webhooks und Symbol-Aliase
Pro Symbol kann ein eigener Webhook mit Alias-Mustern hinterlegt werden, z. B. fuer:

- EURUSD
- GBPUSD
- USDJPY
- USDCHF
- USDCAD
- AUDUSD
- NZDUSD
- XAUUSD
- WTI
- NASDAQ
- EURJPY
- EURNZD
- Testkanal

Alias-Muster helfen bei Broker-Namen wie:

- `EURUSDm`
- `US100.cash`
- `GOLDmicro`

### Design und UI
Es gibt zahlreiche Parameter fuer:

- Schriften
- Farben
- Linienfarben
- Panel-Abstaende
- Sichtbarkeit bestimmter Eingabefelder

## Typischer Workflow

1. EA auf einen Chart legen
2. Entry- und SL-Bereiche vorbereiten
3. LONG oder SHORT ueber Panel/GUI aufbauen
4. Draft pruefen
5. Signal an Discord senden
6. DB-Status und Linien werden gespeichert
7. Beim Erreichen von Entry, Cancel oder SL werden Statuswechsel verarbeitet
8. Nach Neustarts werden aktive Trades und Linien aus der DB rekonstruiert

## Persistenz und Datenbank

Die SQLite-Datenbank enthaelt mindestens zwei zentrale Tabellen:

### `meta`
Key-Value-Speicher fuer globale oder namespaced Zustandswerte, z. B.:

- aktive Trade-Nummern
- letzte Trade-Nummern
- UI-nahe Persistenzwerte
- Draft-Daten

### `positions`
Persistiert einzelne Positionen eines Trades.

Wichtige Felder:

- `symbol`
- `tf`
- `direction`
- `trade_no`
- `pos_no`
- `entry`
- `sl`
- `sabio_entry`
- `sabio_sl`
- `status`
- `was_sent`
- `is_pending`
- `created_at`
- `updated_at`

### Wichtige Hinweise zu `created_at`

`created_at` wird beim ersten Insert automatisch von der Datenbank gesetzt. Damit dieser Zeitstempel stabil bleibt, verwendet das Projekt fuer Positions-Upserts keine Logik mehr, die einen bestehenden Datensatz loescht und neu anlegt.

Das bedeutet:
- erster Insert setzt `created_at`
- spaetere Updates aendern nur mutable Felder
- `created_at` bleibt der urspruengliche Erstellungszeitpunkt

## Status-Logik

Ein wichtiger Fokus des Projekts ist konsistente Statusverarbeitung.

Aktuelle Leitlinie:
- wiederholte Trigger sollen keine doppelten Meldungen erzeugen
- bereits geschlossene Positionen sollen bei erneuten Events no-op sein
- Cancel-/SL-/Open-Transitions sollen die DB nicht unnoetig erneut beschreiben

Das reduziert:
- doppelte Discord-Meldungen
- inkonsistente Wiederholungsaktionen
- unnötiges Schreiben derselben Zustände

## Logging und Debugging

Beim Start wird Logging in eine Datei aktiviert:

- Logdatei: `DowHowSignalService.log`

Das Logging hilft besonders bei:
- WebRequest-Problemen
- DB-Fehlern
- Statuswechseln
- Event-Routing
- Wiederherstellungslogik nach Neustart

## Sicherheitshinweise

Wichtig: In Projektstaenden oder Testkopien sollten keine echten produktiven Discord-Webhooks im Repository verbleiben.

Empfehlung:
- Webhooks vor einem öffentlichen Commit entfernen oder durch Platzhalter ersetzen
- produktive URLs nicht in Screenshots, ZIPs oder Git-Repositories verteilen
- sensible Zugangsdaten nur lokal pflegen

Wenn ein echter Webhook einmal im Repository gelandet ist, gilt die goldene Regel des Internets: Er ist nicht mehr geheim. Dann bitte rotieren.

## Bekannte Schwerpunkte und laufende Refactorings

Im Code sind mehrere technische Ziele erkennbar, unter anderem:

- weitere Zentralisierung von Business-Logik im `CTradeManager`
- Reduktion direkter DB-Schreibzugriffe ausserhalb des TradeManagers
- weitere Absicherung des Multi-Symbol-/Multi-Timeframe-Verhaltens
- Validierung von Eingaben wie TRNB/POSNB vor dem Senden
- Entkopplung von Router-, UI- und Persistenzlogik

## Entwicklungshinweise

Wenn du am Projekt weiterentwickelst, sind diese Regeln sinnvoll:

- DB-Schreibpfade moeglichst nur an einer Stelle halten
- Symbol- und TF-bezogene Keys immer namespaced bilden
- Chart-Events nur dispatchen, Business-Logik nicht wild ueber viele UI-Klassen verteilen
- Statusaenderungen idempotent gestalten
- UI-Zustand und Persistenz sauber trennen

## Lizenz

Siehe Datei `LICENSE` im Projekt.

## Autoren

Im Projektkopf genannt:

- Michael Keller
- Steffen Kachold

## Hinweis

Diese README beschreibt das Projekt auf Basis der vorhandenen Struktur und des aktuellen Code-Stands rund um Version 2.033. Wenn du magst, kann ich dir als naechsten Schritt auch noch eine zweite Variante schreiben:

- technisch-nuechtern fuer GitHub
- oder marketing-/anwenderorientiert fuer interne Doku
