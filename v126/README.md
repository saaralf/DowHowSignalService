# V1.04.28 – editierbare Nummern und mehrere Positionen

Dieser Stand entwickelt Michaels Kollegenversion V1.04.26 schrittweise weiter. Einstieg bleibt **TradeAssistantV126_SQLite.mq5**. Entwicklungskennung V1.04.28 / MQL-Version 1.428. Die Oberfläche stammt weiterhin aus V1.04.26; SQLite verwaltet jetzt alle Positionen unabhängig. Der separate V4-Entwurf bleibt als Architekturreferenz bestehen.

## Nummerierung und manuelle Übernahme

**Trade- und Positionsnummer sind READ/WRITE.** Der EA zeigt einen Vorschlag an und verwendet beim SEND tatsächlich die eingegebenen Zahlen.

| Zustand / Aktion | Nächster Vorschlag |
|---|---|
| LONG 2.1 gesendet | LONG 2.2 |
| LONG 2.2 gesendet | LONG 2.3 |
| Wechsel auf SHORT, bislang kein aktiver SHORT-Trade | SHORT 3.1 |
| SHORT 3.1 gesendet, zurück auf LONG | LONG 2.3 |
| Alle LONG-Positionen von Trade 2 geschlossen, SHORT 3 weiter aktiv | Neuer LONG-Trade 4.1 |
| Manueller Einstieg mit LONG 127.3 | LONG 127.4; für einen neuen SHORT-Trade 128.1 |

Der Trade bleibt je Richtung aktiv, solange mindestens eine seiner Positionen PENDING oder OPEN ist. Der neue Trade beginnt erst nach Abschluss aller Positionen dieser Richtung. LONG und SHORT teilen einen Zähler für neue Trades; Folgepositionen verbrauchen keine neue Trade-Nummer.

Für den Produktionseinstieg die **bestehende Trade-/Positionsnummer in die Felder eintragen**, dann SEND. Es besteht keine Verpflichtung, bei 1 zu beginnen. Alternativ setzt `InpInitialLastTrade` nur bei einem neuen Datenbank-Kontext den letzten vergebenen Wert. Die manuell bestätigte Nummer hebt den gemeinsamen Zähler mindestens auf diese Trade-Nummer an. Manuelle Korrekturen werden zusammen mit Signal und Zustand gespeichert; ein `NUMBERS_CORRECTED`-Ereignis enthält Vorschlag und übernommene Kombination.

Regeln gegen Datenverlust:

- Positive ganze Zahlen bis 2147483647; keine Dezimalwerte, Vorzeichen oder freier Text.
- Bestehende Kombinationen werden niemals überschrieben. Eine neue Positionsnummer muss größer sein als sämtliche bisher vergebenen Nummern dieses Trades, einschließlich geschlossener Positionen. Ein Sprung, beispielsweise 127.3 → 127.8, ist erlaubt.
- Ein aktiver Trade derselben Richtung muss unter seiner bisherigen Trade-Nummer fortgeführt werden. Die Eingabefelder benennen gespeicherte Positionen nicht nachträglich um. Soll ein neuer Trade beginnen, muss der alte zuvor abgeschlossen sein.
- Bereits benutzte Trade-Nummern, auch abgeschlossene oder solche der Gegenrichtung, sind für einen neuen Trade gesperrt. Eine unbenutzte manuelle Nummer unterhalb des höchsten Zählerstands senkt diesen nicht ab.
- Maximal **vier gleichzeitig aktive Positionen je Richtung**. IDs bleiben fortlaufend über 4 hinaus möglich: P3 schließen → nächste Position P5, nicht nochmals P3.
- Bei einer Ablehnung bleibt die Eingabe erhalten; kein Discord-Aufruf und keine Änderung an Nummern oder Positionszustand.

Eine manuell übernommene Kombination importiert nur das jetzt gesendete Signal mit seinen Entry-/SL-/Sabio-Werten. Früher vorhandene, aber nicht in dieser DB gespeicherte Positionen werden damit nicht rekonstruiert. Noch nicht gesendete manuelle Eingaben werden nicht über einen EA-Neustart hinweg gespeichert. Eine bewusst ausgelöste Richtungsänderung lädt den Vorschlag dieser Richtung; automatische Tick-Abschlüsse überschreiben manuelle bzw. gerade bearbeitete Nummernfelder nicht.

## Installation und Upgrade vom ersten SQLite-Stand

1. Alten Entwicklungs-EA entfernen bzw. alle Instanzen stoppen, die dieselbe V126-SQLite-Datei benutzen. Bei abruptem Terminalende kann die Lease noch bis zu 30 Sekunden gelten.
2. `TradeAssistantV126_SQLite.mq5`, den vollständigen Ordner `v126` und `WebhookConfig.mqh` gemeinsam nach `MQL5/Experts/DowHowSignalService_V126/` kopieren. `WebhookConfig.mqh` ist der unveränderte Parser aus V2.x.
3. Michaels vorhandene `DowHowSignalService_webhooks.cfg` liegt weiterhin in **MQL5/Files** dieses Terminals. Nur der **TEST**-Eintrag wird für Text und Screenshot ausgewählt. SYSTEM und TEST müssen für den V2-Parser vorhanden sein; Symbol- und SYSTEM-Routen werden nicht als Versandziel verwendet. Der TEST-Eintrag muss tatsächlich den Entwicklungs-Discord bezeichnen.
4. Im MetaEditor die neue Hauptdatei mit F7 kompilieren. Eine alte EX5 ist nicht enthalten. Die neue MQL-Version wurde hier nicht kompiliert; bei Fehlern die vollständige Fehlerliste zurückgeben.
5. Auf einem Demo-Chart starten; `SendOnlyButton=true`. Den bisherigen SQLite-Dateinamen und die gleichen Kontext-Einstellungen beibehalten. Für WebRequest den Host des TEST-Webhooks in den MT5-Optionen freigeben.

**Die vorhandene SQLite-Datei nicht löschen.** Schema 1 wird innerhalb einer Transaktion auf Schema 2 umgestellt. Der bisherige aktive Trade 2.1 bleibt erhalten und kann als 2.2 fortgesetzt werden. Bestehende geschlossene Positionen, Ereignisse und der höchste Trade-Zähler bleiben bestehen. Bei einem Fehler wird die Migration zurückgerollt. Eine Migration bei noch aktiven alten Instanzen wird verweigert. Vor dem Upgrade bei beendetem EA eine Kopie der Datenbank sichern.

Datei: `DowHowSignalService_V126_dev.sqlite` unter **Common/Files**. Keine Verwendung der V2-/V4-Datenbank. Kontext weiterhin Server, Account, Magic, Symbol und Timeframe. Andere Kontexte besitzen getrennte Zähler. WAL, Fremdschlüssel und vollständiges synchrones Schreiben bleiben aktiv. Eine 30-Sekunden-Lease mit Erneuerung alle fünf Sekunden verhindert konkurrierende Besitzer; Verlust sperrt Änderungen und Versand, ein Neustart lädt zuerst die gespeicherten Daten.

## Positionsverwaltung und Anzeige

- Alle aktiven Positionen besitzen eigene Entry-/SL-Linien mit Trade-, Positionsnummer, Richtung und OPEN/PENDING-Beschriftung. Nach Neustart werden sämtliche Positionen und ihre Sabio-Werte wieder geladen; keine Wiederholung alter Initialsignale.
- Aktiven SL verschieben oder über Objekteigenschaften ändern: „Nein“ stellt den alten Preis wieder her; „Ja“ schreibt Zustand/Ereignis vor dem TEST-Update. Jede Linie betrifft nur ihre eigene Position. PENDING-SL muss auf der richtigen Seite des Entry bleiben.
- Entry-Hit öffnet die betreffende Position. Ein SL einer Folgeposition schließt diese Position. Gemäß bisheriger Pos-1-Regel beendet **SL von Position 1 den gesamten Trade**; übrige aktive Positionen erhalten `CLOSED_POS1_SL`, die Gegenrichtung bleibt bestehen.
- Die bestehenden Cancel-BUY/SELL-Buttons schließen nach ausdrücklicher Bestätigung **alle aktiven Positionen des betreffenden Richtungstrades**, einschließlich OPEN/PENDING. Pro Position wird ein Ereignis und eine eindeutig bezeichnete TEST-Meldung erzeugt. Ein eigener Einzelpositions-Cancel-Button ist noch nicht implementiert.
- Die Zustandsänderungen, Abschlüsse aller betroffenen Positionen und Ereignisse werden jeweils atomar gespeichert. Historische Identitäten und geschlossene Positionsdaten sind gegen Überschreiben geschützt.

## Discord und verbleibende Grenzen

Die von Michael getestete TEST-Routing-Logik bleibt bestehen: keine festen Tokens, kein Start-Testpost, keine `@everyone`-Erwähnung, keine Brokeroperationen. M2/M5/H1 verwenden denselben TEST-Eintrag. Fehlende/ungültige Konfiguration blockiert SEND; lokale Abschlüsse und Ereignisse bleiben möglich. Der Risiko-Default bleibt wie in V1.04.26 bei **100**.

Weiterhin keine Outbox und keine Garantie einer exakt einmaligen Zustellung: Signal/Zustand werden vor HTTP gespeichert, Versuch und Ergebnis zusätzlich protokolliert. Bei Timeout kann eine Meldung bereits zugestellt sein. Ein erneuter SEND ist **keine Versandwiederholung**, sondern würde die nächste Position erstellen. Fehler zuerst anhand Events und Testkanal prüfen. Text und Screenshot bleiben getrennte Requests; nach Neustart wird nicht automatisch erneut gesendet.

Kein Wiederherstellen des ungesendeten Preis-/Sabio-Entwurfs oder der Drag-Geometrie, keine historische Rekonstruktion verpasster Kursereignisse. Aktuelle Ticks setzen die gespeicherte Positionsüberwachung fort. Noch kein separates vollständiges Mehrpositionspanel; bei gleichen Preisen können die Linien/Labels überlappen. Keine Produktionsabnahme dieses Ausbaus.

## Prüfung und Demo-Abnahme

Automatisch: `python v126/tests/check_sqlite.py` – **17 Prüfungen** für Trade-Fortsetzung, Richtungswechsel, manuelle Produktionseinstiege, Transaktionsrollback, Historie, vier aktive Positionen mit IDs >4, Pos-1-Abschluss, Kontexttrennung, Neustart, echte Schema-Migration samt Fehler-Rollback und Quellstruktur/TEST-Isolation. Diese SQLite-/Quellstrukturprüfungen kompilieren oder führen MQL5 nicht aus.

MT5-Store-Smoke: Für den Start über den Navigator den Ordner `v126` zusätzlich unter `MQL5/Scripts/DH126_Smoke/` ablegen, `v126/tests/SQLiteSmoke.mq5` kompilieren und auf separatem Demo-Chart als Skript ausführen. Erwartung: nur PASS und `SQLite smoke failures: 0`. Das Skript nutzt eine eigene temporäre Datei ohne Discord-/Broker-Aufrufe. Es prüft den echten MQL-Store mit manueller Nummer 127, Folgepositionen, Richtungswechsel und Wiederherstellung. Hier nicht ausgeführt.

Demo-Fälle:

1. Upgrade deiner bestehenden Datei: Trade 2.1 bleibt sichtbar. LONG zeigt 2.2; SEND legt 2.2 mit eigenen Linien an, danach Vorschlag 2.3.
2. Auf SHORT wechseln: 3.1 senden; danach zurück auf LONG → Vorschlag 2.3. Alle drei Positionen müssen nach Neustart wieder erscheinen.
3. In einem separaten Testkontext manuell 127.3 eintragen und senden → nächster LONG-Vorschlag 127.4, neuer SHORT 128.1. Beide Felder müssen tatsächlich editierbar bleiben.
4. Gleiche Kombination zweimal bzw. fremde Trade-Nummer bei aktivem Richtungstrade eingeben: klare Ablehnung, Felder bleiben erhalten, kein neues Signal im TEST-Kanal.
5. Vier aktive Positionen senden, fünfte ablehnen. Eine Folgeposition per SL schließen, nächste ID größer als bisheriges Maximum. Historie bleibt vorhanden.
6. Position-1-SL: alle Positionen ihres Trades schließen; Gegenrichtung bleibt aktiv. Erst jetzt darf diese Richtung einen neuen Trade erhalten. Cancel bestätigt das Schließen aller Positionen nur seiner Richtung.
7. SL einzelner Positionslinie ändern: „Nein“ ohne Änderung, „Ja“ mit genau einem lokalen Ereignis und TEST-Update. Unverändertes Loslassen erzeugt keinen Auftrag.
8. Während manueller Nummerneingabe einen Tick-Abschluss provozieren: Eingabe bleibt erhalten. Nach einem abgelehnten SEND darf kein Timer sie überschreiben.
9. Konfiguration/HTTP-Zugriff sperren, zweites Besitzer-Chart und andere Timeframes testen. Kein Produktionskanal und keine automatische Versandwiederholung.

## Danach

Nach Compile-/Demo-Abnahme die persistente Versand-Outbox, separate Panel-/Einzelpositionsbedienung und vollständige Draft-Wiederherstellung ergänzen; die vier vereinbarten Bereiche schrittweise entkoppeln.
