# V1.04.26 schrittweise erweitern – SQLite, Schritt 1

Dieser Stand basiert auf dem von Michael hochgeladenen, von Kollegen weiterentwickelten Archiv `Trade Assistent V1.04.26(2).zip`. Er ersetzt den bisher geplanten direkten V4-Neustart als aktuellen Entwicklungspfad. Die V4 bleibt separat als Architekturentwurf bestehen. Einstieg: **TradeAssistantV126_SQLite.mq5**, Entwicklungskennung V1.04.27 / MQL-Version 1.427. Die Oberfläche und ihre Chartbewegung stammen aus V1.04.26.

## Installation

1. `TradeAssistantV126_SQLite.mq5`, den vollständigen Ordner `v126` und `WebhookConfig.mqh` gemeinsam nach `MQL5/Experts/DowHowSignalService_V126/` kopieren. `WebhookConfig.mqh` ist der unveränderte Parser aus V2.x.
2. Michaels vorhandene `DowHowSignalService_webhooks.cfg` nach **MQL5/Files** dieses Terminals kopieren. Der Parser erwartet wie V2.x SYSTEM und TEST. Ausschließlich **TEST** wird ausgewählt, für alle Symbole sowie M2/M5/H1 und für Text und Screenshot. SYSTEM-/Symbol-Webhooks werden nicht als Versandziel benutzt. Der TEST-Eintrag muss tatsächlich den gewünschten Entwicklungs-Discord bezeichnen.
3. Im MetaEditor die neue Hauptdatei mit F7 kompilieren. Es wird keine alte EX5 mitgeliefert. MT5-Komponenten wurden hier nicht kompiliert; bei Fehlern die vollständige Fehlerliste zurückgeben.
4. Auf separatem Demo-Chart starten, `SendOnlyButton=true` lassen. Für WebRequest den Host des TEST-Webhooks in den MT5-Optionen freigeben. Es gibt keinen automatischen Start-Testpost. Fehlende/ungültige Konfiguration sperrt SEND, SL/Cancel können den lokalen Bestand weiterhin schließen und protokollieren.
5. Nummernfelder sind jetzt **schreibgeschützt** und zeigen die nächste Trade-Nummer und Position 1. `InpInitialLastTrade` legt nur bei einem neuen Kontext den letzten vergebenen Wert fest: beispielsweise 26 → erster Trade 27. Bestehende DB-Kontexte ignorieren den Initialwert. Keine automatische Übernahme alter Terminal-GlobalVariables, da deren Scope weder Server noch Timeframe eindeutig enthält.

SQLite-Datei: `DowHowSignalService_V126_dev.sqlite` unter dem gemeinsamen Terminal-Verzeichnis **Common/Files**. Eigener Dateiname, keine Verwendung der V2-/V4-Datenbank. WAL, Fremdschlüssel und vollständiges synchrones Schreiben sind eingeschaltet. Ein Kontext umfasst Server, Account, Magic, Symbol und Timeframe. LONG und SHORT teilen innerhalb dieses Kontexts einen Zähler. Andere Timeframes/Accounts besitzen getrennte Zähler. Die DB samt WAL-Datei nicht im laufenden Betrieb löschen/ersetzen; Sicherung bei beendetem EA durchführen.

## Bereits umgesetzt

- Vergabe der gemeinsamen Trade-Nummer und Speicherung des Signals samt Ereignis in derselben SQLite-Transaktion. Ein DB-Fehler verbraucht keine Nummer und erzeugt keinen Discord-Aufruf. Historische Positionen bleiben bestehen; abgeschlossene Nummern werden nicht wiederverwendet.
- Dauerhafte Zustände PENDING, OPEN, CLOSED_SL, CLOSED_CANCEL, einschließlich Entry, SL, Lots und Sabio-Werten. Entry-Hit, SL-Änderung und Abschluss werden vor Versand gespeichert. Aktive Positionen, Linien und Entry-Hit-Status werden beim EA-Start wiederhergestellt.
- Eine aktive Position je Richtung: ein weiterer SEND derselben Richtung wird gesperrt, damit die zwei Legacy-Slots nicht mehr still überschrieben werden. Position ist in diesem ersten Schritt immer **1**. Mehrere Positionen pro Trade und fortlaufende Positionsnummern sind der nächste separate Ausbau.
- Aktiven SL verschieben oder über Objekteigenschaften ändern: „Nein“ stellt den alten Preis wieder her; „Ja“ schreibt Zustand/Ereignis und sendet ein Update an TEST. Unveränderte Preise erzeugen kein Update. Für PENDING muss SL auf der richtigen Seite des Entry bleiben.
- Cancel über die bestehenden Buttons: lokaler Abschluss, Ereignis und TEST-Meldung. Kein Löschen fremder Broker-Orders. Trade & Send ist in diesem Schritt ausdrücklich nicht aktiviert; die Initialisierung verweigert `SendOnlyButton=false`.
- 30-Sekunden-Lease je Kontext mit Erneuerung alle fünf Sekunden: zweite Instanz desselben Kontexts wird abgewiesen. Verlust/Fristüberschreitung sperrt Änderungen und Versand; EA neu starten, damit zuerst der DB-Zustand geladen wird. Verschiedene Kontexte können parallel laufen.
- Bestehende Nummern-GlobalVariables und feste Webhook-Tokens werden nicht benutzt. Keine `@everyone`-Erwähnung; Text-Payload setzt zusätzlich `allowed_mentions.parse=[]`. Alle Meldungen kennzeichnen DEV TEST, Trade und Position.
- HTTP-Versuch und Ergebnis werden als Ereignisse mit Trade-/Positionsbezug protokolliert. Ein persistierter Versuch ohne Ergebnis ist ungeklärt und muss im Testkanal geprüft werden. Kein automatisches erneutes Senden nach Neustart.
- Kleine Bereinigung: fehlende Logo-Ressource entfernt, Methoden-Include geschützt, veraltete Doppel-SL-Handler entfernt, Orderlöschfunktionen im Entwicklungs-Include entfernt; Volumen nach Broker-Step abrunden und Min/Max prüfen. Risiko-Default bleibt wie in Kollegenversion **100**.

## Grenzen dieses Schritts

Keine Outbox und keine Garantie einer exakt einmaligen Zustellung: Ein lokal gespeichertes Signal kann bei HTTP-Fehlern unzugestellt oder beim Timeout bereits zugestellt sein. Erneutes SEND erzeugt deshalb keinen Ersatztrade derselben Richtung. Versandprobleme müssen zunächst anhand Events/Testkanal geprüft werden. Text und Screenshot bleiben getrennte Requests. Die Produktions-Webhooks wurden nicht hier überprüft; die Isolation beruht auf dem TEST-Eintrag in Michaels bereitgestellter V2-Konfiguration.

Keine Wiederherstellung des noch ungesendeten Entry-/SL-/Sabio-Entwurfs oder der Drag-Geometrie. Kein nachträgliches Ermitteln von Entry-/SL-Ereignissen während der Abschaltung. Nach Neustart gilt der gespeicherte Positionszustand; aktuelle Ticks setzen die Überwachung fort. Kein Mehrpositionspanel und keine Broker-Orders. Dieser Entwicklungsstand ist noch nicht für Produktion abgenommen.

## Prüfung

Automatisch: `python v126/tests/check_sqlite.py` – acht Prüfungen für Transaktionsrollback, gemeinsame Nummerierung, Historie, Kontexttrennung, Neustartdaten, konkurrierende Besitzer und sichere Distribution/TEST-Routing. Diese SQLite-/Quellstrukturprüfungen sind kein MQL-Laufzeittest.

MT5-Store-Smoke: `v126/tests/SQLiteSmoke.mq5` kompilieren und auf einem separaten Demo-Chart als Skript ausführen. Erwartung: ausschließlich PASS und `SQLite smoke failures: 0`. Das Skript benutzt eine eigene temporäre SQLite-Datei und keinerlei Discord-/Broker-Aufrufe. Es wurde hier nicht ausgeführt.

Demo-Abnahme:

1. Mit neuem Kontext/Initialwert 26 beginnen. LONG sendet Trade 27.1, SHORT Trade 28.1. Nur TEST enthält Meldungen. Zweiter LONG-SEND wird gesperrt, Nummer bleibt 29.
2. EA mit beiden aktiven Positionen neu starten. Nummer bleibt 29; Daten, Linien und OPEN/PENDING müssen stimmen. Keine erneute Initialsignal-Meldung.
3. SL verschieben: „Nein“ stellt alten Preis wieder her. „Ja“ speichert neuen Preis; genau ein Update im TEST-Kanal. Dasselbe über Objekteigenschaften prüfen.
4. Entry-Hit und anschließenden SL-Hit je Richtung prüfen; DB-Ereignisse und Historie kontrollieren. Nach Abschluss ist nächster Trade 29.1 verfügbar, Gegenrichtung bleibt bestehen.
5. Cancel mit OPEN und PENDING testen, „Nein“ ohne Zustandsänderung. Nach Neustart kommen geschlossene Linien nicht zurück.
6. Config vor Start umbenennen: SEND blockiert; kein Ersatz-/Produktionskanal. Config wiederherstellen und EA neu starten. HTTP-Zugriff sperren: Signal wird lokal gespeichert, Versuch/Fehler protokolliert; Neustart sendet nicht automatisch erneut.
7. Zweiten Chart desselben Kontexts starten: Init muss scheitern; erster Chart funktioniert weiter. Anderen Timeframe starten: eigener Kontext funktioniert. Nach abruptem Terminalende ggf. Lease-Ablauf (30 Sekunden) abwarten.
8. UI auf M2/M5/H1, Chartgrößen/DPI, Sabio, Entry-/SL-Drag und Klickunterdrückung prüfen. Ein Drag darf kein neues Signal auslösen.

## Nächste Schritte

1. Diesen Stand kompilieren und oben genannten Demo-Test abnehmen.
2. Versand in eine persistente Outbox überführen, unklare Zustellung sichtbar machen.
3. Mehrere Positionsdatensätze je Richtung und Trade, monotone Positionsnummern und Pos-1-SL-Regel implementieren.
4. Entwurf/UI-Wiederherstellung und Panel ergänzen; Module entlang der vereinbarten vier Bereiche schrittweise entkoppeln.
