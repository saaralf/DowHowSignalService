# TradeAssistant V3 – Greenfield architecture

## Ziel

V3 bildet die Kernfunktionen des bisherigen TradeAssistenten neu ab, ohne dessen historisch gewachsene Kopplungen zu übernehmen.

Der bestehende `TradeAssistent.mq5` bleibt unverändert. V3 läuft parallel über `TradeAssistantV3.mq5` und verwendet eine eigene SQLite-Datenbank.

## Architektur

```
TradeAssistantV3.mq5
        |
        +--> CTA3UI
        |      |
        |      +--> erzeugt nur Benutzer-Intents / Drafts
        |
        +--> CTA3Application
        |      |
        |      +--> Nummernvergabe
        |      +--> Lot-Berechnung
        |      +--> Send/Cancel/Open/SL Use-Cases
        |      +--> Discord-Orchestrierung
        |
        +--> CTA3Repository
        |      |
        |      +--> ta3_meta
        |      +--> ta3_positions
        |
        +--> CDiscordClient
               |
               +--> CWebhookRouter
               +--> externe Webhook-Config
```

## Grundregeln

1. UI schreibt niemals direkt in SQLite.
2. Repository enthält keine Fachentscheidungen.
3. Application ist alleiniger Owner von Trade-/Positionszuständen.
4. Discord wird nur aus Application-Use-Cases aufgerufen.
5. TradeNo und PosNo werden vor dem irreversiblen Discord-Send finalisiert.
6. Maximal vier Positionen je Trade/Richtung.
7. PENDING, OPEN und CLOSED_* sind explizite Zustände.
8. V3 benutzt keine Legacy-Meta-Keys des alten EA.
9. Webhook-Secrets bleiben außerhalb des Repositories.
10. V3 benutzt eine eigene Datenbank: `DowHowSignalServiceV3.sqlite`.

## Dateien

- `TradeAssistantV3.mq5` – Composition Root / MT5 Entry Points
- `TA3_Types.mqh` – reine Domain-Datentypen
- `TA3_Repository.mqh` – SQLite Persistenz
- `TA3_Application.mqh` – Fachlogik / Use-Cases
- `TA3_UI.mqh` – Chart UI und Event-Übersetzung

Bewährte Infrastruktur wird weiterverwendet:

- `CDiscordClient.mqh` – WebRequest/Discord Transport
- `CWebhookRouter.mqh` – Symbol-/Alias-Routing
- `WebhookConfig.mqh` – externe Secret-Konfiguration
- `logger.mqh` – Logging

## Implementierte Funktionsabdeckung

### Draft / UI
- Entry-Linie
- SL-Linie
- automatische LONG/SHORT-Erkennung
- TRNB
- POSNB
- Sabio Entry
- Sabio SL
- manuelle Sabio-Flags
- Draft-Persistenz
- Send-Button
- aktive Positionsübersicht

### Trading-Signal-Lifecycle
- 1%-Equity-Lotberechnung, konfigurierbar
- Broker Min/Max/Step
- finale Trade-/Positionsnummer vor Send
- max. 4 Positionen
- PENDING vor Discord persistieren
- Rollback bei fehlgeschlagenem Send
- PENDING -> OPEN bei Entry-Hit
- OPEN -> CLOSED_SL bei SL-Hit
- Einzel-Cancel
- Trade-Cancel in Application vorhanden

### Discord
- externe Config
- Symbol-Aliase
- Chart-Screenshot beim neuen Signal
- Lifecycle-Nachrichten ohne Screenshot

### Persistenz
- separate V3 SQLite DB
- created_at / updated_at
- Draft-Meta
- Positionen
- Restore aktiver Positionen

### Chart
- aktive Entry-/SL-Positionslinien
- PENDING gestrichelt
- OPEN durchgezogen
- Label werden als Pixel-Labels rechts verankert und nicht an eine Kerze gebunden

## Bewusste Unterschiede zum alten EA

V3 übernimmt nicht automatisch jeden historischen Helper oder jede interne Variable. Ziel ist Funktionsgleichheit aus Anwendersicht, nicht Quellcode-Kompatibilität.

Insbesondere werden nicht übernommen:

- Legacy-Keys wie `trnb_ui`, `L_sl`, `L_entry`, `S_sl`, `S_entry`
- globale State-Writes aus UI/Helpern
- mehrere konkurrierende Send-APIs
- `CUIManager`
- `sonstige_methoden.mqh` als Architekturbaustein
- TradePosLine-Registry als globaler Owner

## Noch zu validieren

Diese Version wurde im Repository implementiert, aber noch nicht mit MetaEditor kompiliert.

Vor Merge in einen produktiven V3-Zweig müssen mindestens geprüft werden:

1. MetaEditor: 0 Compile Errors.
2. Config Load / Alias Routing.
3. SQLite Open/Create/Upsert.
4. TRNB/POSNB Persistenz.
5. Sabio Persistenz.
6. Signal-Send mit Screenshot.
7. Discord-Fehler -> DB Rollback.
8. Entry Hit -> OPEN.
9. SL Hit -> CLOSED_SL.
10. Cancel Buttons.
11. Restart / Restore.
12. Lot-Berechnung auf FX, Gold und Index.

## Migrationsstrategie

V3 sollte zunächst parallel zum alten EA auf einem Testkonto betrieben werden.

Empfohlen:

1. gleicher Chart / gleiche Signale,
2. alter EA sendet produktiv,
3. V3 zunächst nur in einen separaten Discord-Testkanal,
4. Ergebnisse vergleichen,
5. nach Funktionsparität V3 als neuer Haupt-EA festlegen,
6. alte Architektur danach entfernen.
