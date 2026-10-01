# TradeAssistant V4 — erste SendOnly-Implementierung

V4 ist ein eigener EA mit eigener SQLite-Datei. V1/V2 wurden nicht geändert. Dieser Stand ist ein Entwicklungsstand: **MetaEditor-Kompilierung, MQL-Smoke-Test und UI-Abnahme sind noch auszuführen.** Er ist noch kein Produktionsersatz.

## Architektur und Verträge

| Bereich | Modul | Schnittstelle |
|---|---|---|
| Eingaben | TA4_InputUI.mqh | Draft / Command; keine DB- oder HTTP-Abhängigkeit |
| Discord | TA4_Discord.mqh | Deliver(outbox) → SENT / FAILED / UNKNOWN / RATE_LIMITED |
| Panel | TA4_Panel.mqh | Render(positions), Command für Aktionen |
| SQLite | TA4_Repository.mqh, schema.sql | Transaktionen, Zustand, Ereignisse, Lease, Outbox |
| gemeinsamer Trade-Kern | TA4_Core.mqh | SaveDraft / Send / Adjust / ClosePosition / CancelTrade / Evaluate |
| EA-Koordination | ../TradeAssistantV4.mq5 | Initialisierung, Eingabebefehle, Timer und Markt-Ticks |
| gemeinsame Typen | TA4_Types.mqh | Context, Draft, Position, Command, Outbox, Settings |

Nur das Repository nutzt Database-APIs. Input und Panel kennen weder Repository noch Core/Discord. Der Core benutzt das Repository für atomare Änderungen, aber keine Chart-/HTTP-/Brokerfunktionen. Der EA koordiniert die Versandwarteschlange; der Discord-Adapter verändert keine Trades.

Bestehende `WebhookConfig.mqh` und `CWebhookRouter.mqh` werden nur für lokales Laden/Zuordnen wiederverwendet. Der alte Discord-Client und TradeManager sind nicht Teil des V4-Flows.

## Implementierte Regeln

- Kontext = Server + Konto + Profil + Broker-Symbol + Timeframe. Ein DB-Lease verhindert gleichzeitig schreibende V4-Charts desselben Kontexts. Lease wird jede Sekunde verlängert; nach einem Crash kann Übernahme bis 30 s warten.
- Gemeinsame Trade-Nummern für LONG/SHORT. Höchstens ein aktiver Trade je Richtung. Nummernfelder sind schreibgeschützte Vorschau, keine manuellen Overrides.
- Positionsnummern zählen unbegrenzt weiter: 1,2,3,4,5…; maximal vier PENDING/OPEN je Richtungstrade. Geschlossene IDs und Historie bleiben erhalten.
- Pos-1-SL beendet alle aktiven Folgepositionen mit eigenem Abschlussgrund CLOSED_POS1_SL. Dieser erste Implementierungsentscheid folgt Michaels Trade-Ende-Vorgabe; die konkrete Nachrichtenform ist noch abzunehmen.
- Trade-Cancel schließt PENDING und OPEN; Gegenrichtung bleibt bestehen. Eine Sammelmeldung nennt alle betroffenen Positionen. Einzel-SL/Cancel wird bestätigt.
- PENDING-Entry veränderbar, OPEN-Entry gesperrt, SL änderbar. Änderung speichert Ereignis und Discord-Auftrag. Unveränderte Preise sind no-op. Änderungen erfolgen erst nach Loslassen.
- LONG-Entry Ask >= Entry / SHORT-Entry Bid <= Entry; LONG-SL Bid <= SL / SHORT-SL Ask >= SL. Entry und SL können auf demselben Tick geprüft werden. Entry-Hit wird gespeichert, aber ohne Discord-Post.
- Gleichstand SL/Entry wird als LONG dargestellt; SEND ist gesperrt. Geldrisiko (Default 250 Kontowährung) oder Equity-% konfigurierbar. Volumen nach unten auf Broker-Step, Minimum/Maximum prüfen. Kein aggregiertes Trade-/Kontorisikolimit.
- Entry-Button bewegt Entry/SL mit Preisabstand; SL bewegt nur SL. Native Basislinien bewegen die Gruppe mit. Sabio-Overrides halten bis zur nächsten Bewegung. Sabio-Sichtbarkeit und Nachrichtenausgabe getrennt.
- EA startet mit gespeichertem Draft, dann aktiven Positionslinien und Panel. Keine erneute Erzeugung alter Signale. Fachliche Ereignisse werden gespeichert; Maus-Pixel/Markt-Ticks ohne Statuswechsel nicht.

## Bewusste vorläufige Entscheidungen

- **Nur SendOnly.** Es gibt keine Brokerorder-Erstellung/-Änderung/-Löschung. Späterer Broker-Service bleibt P2.
- Discord ist standardmäßig **deaktiviert**. SEND speichert und stellt in die Warteschlange; das Panel bezeichnet dies ausdrücklich als queued. Zum Testen einen eigenen Profilnamen und eine eigene DB benutzen. Beim späteren Aktivieren werden bestehende QUEUED-Aufträge in Reihenfolge versendet — vorher DB/Queue kontrollieren.
- `@everyone` standardmäßig aus. Kein automatischer Testpost beim Start.
- TP standardmäßig aus. Optionaler numerischer TP-Input ist vorhanden; ein separater TP-Button-/Linienverbund und Sabio-TP fehlen noch. Bei aktivem TP wird dessen Preis pro Position gespeichert; Hit-Regeln LONG Bid / SHORT Ask, also bewusst nicht die alte V1-TP-Regel. TP wird nicht vor einem Offline-Entry historisch rekonstruiert. Neue Richtung erfordert passenden TP-Wert; Eingabe wird validiert.
- Entry bereits erreicht: im virtuellen SendOnly wird zunächst PENDING gespeichert und auf nächstem Tick zu OPEN. Keine V1-Blockierregel. Fachlich noch entscheiden.
- Close-Ereignis bleibt bei Discord-Ausfall gespeichert. Damit ist der virtuelle Kurszustand unabhängig vom Netzwerk; die Nachricht verbleibt in der Outbox.
- Live-Chartfarbe: Entry Aqua, SL Red; PENDING gestrichelt, OPEN durchgezogen. Panel rechtsgerichtete Labels enthalten Richtung, Trade, Position und Preis.

## Outbox und Wiederanlauf

State + Event + Outbox entstehen gemeinsam innerhalb BEGIN IMMEDIATE / COMMIT. Keine Netzwerkoperation hält eine DB-Transaktion offen. Im Gegensatz zu V2 ist ein fehlgeschlagener Versand kein Anlass, die Position und ihre Historie zu löschen.

QUEUED → SENDING wird vor dem HTTP-Aufruf committed. HTTP-2xx → SENT. Definitive HTTP-4xx → FAILED. Timeout/Transportfehler/5xx → UNKNOWN. Nach Neustart wird verbliebenes SENDING → UNKNOWN. Das erste nicht SENT-Element blockiert spätere Nachrichten, bis es bearbeitet ist.

HTTP-429 wird höchstens dreimal versucht, mit 30/60 s Pause; `Retry-After` wird noch nicht ausgewertet. Das ist ein begrenzter Entwicklungsstand, keine produktive Rate-Limit-Implementierung. UNKNOWN wird niemals automatisch erneut gesendet. Im Panel:

- **Retry:** explizite Bestätigung mit Duplikatwarnung; gleicher Event-Bezug bleibt erhalten.
- **Delivered:** Anwender muss Nachricht in Discord verifiziert haben; manuelle Bestätigung wird protokolliert.

Genau-einmal-Zustellung an Discord wird nicht behauptet. Der feste Event-Bezug ermöglicht den Abgleich. Bei DB-Ausfall nach POST wird pausiert; Neustart behandelt das SENDING als UNKNOWN.

Screenshot wird beim SEND lokal aufgenommen und sein eindeutiger Dateiname im Auftrag gespeichert. Text und Bild werden beim Versand gemeinsam gepostet. Fehlendes/noch nicht lesbares Bild führt zu Text-only mit sichtbarer Warnung. SENT löscht die lokale Bilddatei. Screenshots liegen terminal-lokal, DB im Common-Bereich; bei Wechsel in ein anderes Terminal kann deshalb Text-only entstehen. Verwaiste Dateien nach Crash vor DB-Commit und automatische Aufbewahrungsregeln sind noch nicht umgesetzt.

## Installation/Test

1. Den Repository-Ordner unverändert zusammen nach `MQL5/Experts/DowHowSignalService/` kopieren. V4 enthält relative Includes in `v4/` und zu den zwei gemeinsamen Routingmodulen.
2. `TradeAssistantV4.mq5` im MetaEditor öffnen und kompilieren. Fehler-/Warnungsprotokoll dokumentieren. Es wurde hier keine EX5 erzeugt.
3. Auf einem **separaten Demo-Chart** starten, Profil z. B. `v4-test`, DB z. B. `DowHowSignalServiceV4_Test.sqlite`, Discord zunächst false. Mindestfenster für erste UI-Prüfung: ungefähr 1000×600; schmale/hohe DPI-Fenster noch nicht abgenommen.
4. Draft und Sabio verändern; EA neu starten. Preise/Overrides müssen wiederhergestellt werden. LONG T1, SHORT T2, nächste LONG-Position prüfen.
5. Vier Positionen senden, P3 schließen, nächste P5 erwarten; P1-SL muss den Trade beenden. Gemischte OPEN/PENDING per Trade-Cancel testen.
6. PENDING-Entry und SL ändern; OPEN-Entry muss gesperrt sein. Beim Editieren darf Timer keinen Eingabetext überschreiben. Labels rechts, Offscreen-Preise und Drag ohne neue Ticks prüfen.
7. **MT5-Core-Test:** `v4/tests/TA4_CoreSmoke.mq5` kompilieren und als Script auf einem Demo-Chart ausführen. Es erzeugt eine neue disposable Common-DB mit `TA4_Smoke_…`, keinerlei Discord- oder Brokeraufrufe. PASS/FAIL-Ausgaben prüfen; nur `failures: 0` ist erfolgreich. Script/DB nicht mit der EA-Produktionsdatei verwechseln.
8. Für Discord Konfiguration im terminal-lokalen `MQL5/Files` ablegen, URLs in MT5 WebRequest erlauben, eigenen Testkanal zuordnen. Vor Aktivierung vorhandene Queue prüfen. Alle Konfigurationszeilen SYSTEM/TEST/Symbol werden vom bestehenden Loader verlangt; SYSTEM wird für V4-Signale nicht als Fallback verwendet.
9. Discord aktivieren und eine Nachricht testen; Netzwerkfehler → UNKNOWN, kein automatischer Retry. Die zwei Auflösungsbuttons separat prüfen.

Beispielkonfiguration ausschließlich mit Platzhaltern:

```text
SYSTEM|<SYSTEM-WEBHOOK>
TEST|<TEST-WEBHOOK>
EURUSD|<TESTKANAL-WEBHOOK>|EURUSD*
```

Keine echten Webhook-Tokens in Git oder Testbelege schreiben. Der V4-Transport protokolliert nur HTTP-/MT5-Code, nicht URL, Antwortkörper oder Payload.

## Validierung in dieser Arbeitsumgebung

`python v4/tests/check_v4.py` prüft das tatsächliche SQLite-Schema: aktive Kapazität und unveränderliche IDs, eindeutige aktive Richtungstrades, Kontexttrennung, Transaktionsrollback, UNKNOWN-Recovery/Reihenfolge, Abschlussfilter, Lease-Übernahme, Fremdschlüssel sowie Modulgrenzen. Die generierte MQL-Schemazeichenfolge muss exakt schema.sql entsprechen.

**Diese Python-Prüfungen ersetzen weder MQL-Kompilierung noch den Core-Smoke-Test.** Ein SQl-Test der Pos-1-Abschlussfilter beweist nicht allein den kompletten MQL-Aktionspfad; dafür gibt es das MT5-Script.

Die SQLite-Transaktions-/Column-API und ArrayCopy-Einschränkungen wurden gegen die offizielle MQL5-Referenz geprüft:
- https://www.mql5.com/en/docs/database
- https://www.mql5.com/en/docs/database/databaseexecute
- https://www.mql5.com/en/docs/database/databasecolumnlong
- https://www.mql5.com/en/docs/array/arraycopy

## Noch offen vor Produktionsfreigabe

- MetaEditor-Kompilierung und komplette UI-/Discord-Abnahme.
- Offline-Historie für verpasste Entry/SL/TP-Ereignisse; der aktuelle Kurs allein reicht nicht.
- Vollständiges TP-/Sabio-TP-Design und bestätigte Nachrichtenverträge.
- Chartgrößen/DPI, Textbreiten, Offscreen-Linien, Überschneidungen bei sehr kleinem SL-Abstand.
- DB-Sicherungen, Schema-Versionen >1, Retention von Events/Screenshots.
- Backoff nach Discord Retry-After; aktive Queue-Übersicht und Suche vergangener Positionen.
- Performance unter hoher Tickrate und mehreren Kontexten; SQLite-Abfragen laufen aktuell pro Marktprüfung.
- Übernahme aktiver V1-Signale (V1 liefert keine persistente Historie), globale Risikogrenzen, spätere Brokerintegration.
