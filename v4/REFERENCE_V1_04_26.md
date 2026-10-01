# Kollegenversion V1.04.26: Referenzabgleich für V4

Stand: 01.10.2026. Produktionsreferenz bleibt die von Michael benannte V1.04.15. Die Kollegenversion ist eine zusätzliche Entwicklungsreferenz; eine Ablösung der Produktion wurde nicht bestätigt.

## Prüfgrundlage

Archiv `Trade Assistent V1.04.26(1).zip`, SHA-256: `c58ef5b1f284305442a641f0e2af614da3feb8a2b0f7fac10b222222bc9997c1`.
Geprüft: Hauptquelle, tatsächlich eingebundene `methoden_4.22.mqh`, `discord_4.23.mqh` und `LabelundMessageButton.mqh`. Die EX5 wurde nicht ausgeführt. Die Hauptquelle nennt intern **01.04.23** statt 1.04.26. Das referenzierte BMP `Images/MG-DH111_3.bmp` fehlt im Archiv. Quellcode und Binärdatei sind deshalb nicht als identischer Build nachgewiesen. Keine MT5-Kompilierung oder Laufzeitabnahme.

## Vergleich mit Produktion und V4

| Thema | Änderung gegenüber V1.04.15 / IST der Kollegenversion | Konsequenz für V4 |
|---|---|---|
| Positionsnummer | Eigenes Eingabefeld; Signal enthält Trade- und Positionsnummer | In V4 vorhanden, automatisch vergeben; IDs unveränderlich und über 4 hinaus fortlaufend |
| Speicherung | Terminal-GlobalVariables für zuletzt eingegebene Trade-/Positionsnummer je Account, Magic, Symbol und Richtung | V4 speichert vollständigen Zustand und Ereignisse in SQLite; keine direkte Übernahme dieses Schlüsselmodells |
| Kontext | Zählerschlüssel enthält weder Server noch Timeframe | V4 bleibt bei Server/Account/Profil/Symbol/Timeframe und gemeinsamem Trade-Zähler für LONG/SHORT |
| Mehrere Positionen | Mehrfaches Senden erlaubt, aber `tradeInfo[2]` wird je Richtung überschrieben | Kein Nachweis für parallele Positionsverwaltung; V4 benötigt unabhängige Datensätze und max. vier aktive Positionen je Richtung |
| Aktiver SL | Aktive SL-Linien verschiebbar; Popup „SL senden?“ nach Änderung, eigener Discord-Formatter | V4 besitzt SL-Änderung mit Ereignis und Outbox; Bestätigung und Abbruchverhalten ausdrücklich abnehmen |
| Richtung | BUY/SELL aus Entry und SL statt TP abgeleitet | Passt zu V4; gleicher Entry/SL darf kein sendbares Signal ergeben |
| TP | TP fehlt im regulären Signal-/Überwachungspfad; Broker-Aufträge werden mit TP 0 erzeugt; Altcode bleibt | SL-zentrierter V4-Basispfad passt; optionaler TP bleibt separate Erweiterung |
| Sabio | Initialsignal übernimmt manuelle Entry-/SL-Felder; Drag überschreibt Texte mit Linienpreisen | V4 hat getrennte Sichtbarkeit/Ausgabe und Overrides bis zur nächsten Bewegung |
| Timeframes | SEND erlaubt M2, M5 und neu H1; alle verwenden `LinkChannelM2` | M2/M5/H1 als Referenzfälle testen; Kanalauswahl muss eindeutig konfiguriert sein |
| Bedienung | Drag-Schwelle 3 px, Klicksperre 250 ms nach Drag; Send-Hit-Test; Repositionierung bei Chartänderung | Als zusätzliche Abnahmekriterien aufnehmen; Gleichwertigkeit der V4-Bedienung noch nicht unter MT5 nachgewiesen |
| Risiko | Default `riskMoney=100` statt 250; Schutz gegen ungültige Tick-/Step-Werte | Defaultänderung nicht stillschweigend übernehmen; V4 derzeit 250, fachliche Festlegung offen |
| Nachrichten | Initialsignal mit Positionsnummer; SL/Cancel/Update nennen weiterhin nur Trade | V4 muss jede Einzelpositionsmeldung eindeutig mit Trade und Position kennzeichnen |
| Wiederanlauf | Nummern werden geladen, `InitTradeInfo` initialisiert aktive Daten neu | Keine vollständige Wiederherstellung; V4 muss Positionen, Draft, Zustände und Versandaufträge wiederherstellen |

## Auffälligkeiten, die nicht übernommen werden sollen

- `DiscordSend` schreibt Zustand bereits vor dem HTTP-Ergebnis. Im LONG-Pfad wird `was_send=true` auch nach einem Fehler gesetzt. Text und Screenshot sind getrennte Aufrufe. Keine persistente Outbox.
- SL wird bereits beim Drag in `tradeInfo` geändert. „Nein“ im Popup verhindert nur die Nachricht, stellt den alten SL nicht wieder her. Ein stiller lokaler SL-Wechsel muss in V4 durch eine eindeutige Regel ersetzt werden.
- `slDragStartPrice` wird erst im `CHARTEVENT_OBJECT_DRAG`-Handler gelesen. Ob damit der ursprüngliche Preis zuverlässig erfasst wird und das Popup erscheint, ist durch statische Analyse nicht nachgewiesen.
- Der Update-Formatter schreibt den normalen SL auch in das Sabio-Feld und formuliert immer „down“, auch für die Gegenrichtung. Positionsnummer fehlt.
- Pending-Order-Löschung filtert Symbol und Ordertyp, aber nicht Magic oder konkretes Ticket. Das vorhandene `InpMagic` beseitigt dieses Problem nicht.
- Volumenberechnung normalisiert auf zwei Nachkommastellen; Minimum/Maximum und variable Step-Präzision sind nicht vollständig behandelt. Ergebnisse von BuyStop/SellStop werden nicht geprüft.
- Versionskennung und H1-Fehlermeldung sind veraltet; nicht unterstützte Timeframes fallen auf einen Testkanal zurück. Ein fest eingebauter Test-WebHook ist vorhanden; dessen Wert wird nicht in die Dokumentation oder V4 übernommen.

## Ergänzungen für das Pflichtenheft

Die folgenden Formulierungen sind Vorschläge für die V4-Abnahme, keine nachträgliche Freigabe aller Kollegeneigenschaften.

| ID | Prüfbare Anforderung | Abnahmekriterium |
|---|---|---|
| UI-09 | Drag und SEND werden eindeutig unterschieden. | Entry/SL ziehen und loslassen erzeugt kein SIGNAL_CREATED und keinen neuen Versandauftrag; anschließend ist ein bewusster SEND-Klick möglich. 3 px/250 ms dienen als Referenzwerte. |
| UI-10 | Eine aktive SL-Änderung besitzt ein klares Bestätigungs- und Abbruchverhalten. | Vorschlag: „Nein“ stellt den alten Preis wieder her; „Ja“ speichert Änderung und genau einen Outbox-Auftrag atomar. Unverändertes Loslassen erzeugt keinen Auftrag. Bestehende V4-Änderungslogik unter MT5 prüfen. |
| MSG-06 | Jede Positionsmeldung identifiziert Symbol, Timeframe, Richtung, Trade und Position. | Initialsignal, SL-Änderung, SL-Abschluss und Einzel-Cancel lassen sich demselben Positionsdatensatz zuordnen. Trade-Sammelmeldungen nennen betroffene Positionen. |
| MSG-07 | M2, M5 und H1 haben explizit konfigurierte Versandwege. | Für jeden Referenz-Timeframe korrektes Ziel prüfen; fehlende Konfiguration zeigt Fehler und verwendet keinen versteckten Testkanal. |
| DB-06 | Nummern-Wiederherstellung ist von Positions-Wiederherstellung unterscheidbar. | Neustart mit LONG/SHORT und mehreren OPEN/PENDING stellt jeden Datensatz samt SL, Sabio und Versandstatus wieder her. Der Test darf nicht nur Nummernfelder prüfen. |
| OPS-04 | Auslieferung enthält eindeutige Version und vollständige Ressourcen. | Versionskennung, Archivname und Buildnachweis stimmen überein; saubere Installation benötigt keine undokumentierten BMP-Dateien. |

## Entscheidungen und Vorgehen

1. V1.04.15 bleibt Produktions-IST. V1.04.26 wird separat als Kollegen-IST geführt; main/V3 bleiben weitere technische Referenzen.
2. Die vereinbarte V4-Architektur mit Eingabe, Discord, Panel und SQLite sowie zentraler Fachlogik bleibt bestehen. Kollegeneigenschaften werden diesen Modulen zugeordnet, nicht als zusammenhängender Legacy-Code importiert.
3. Offene Entscheidungen: Geldrisiko-Default 100 oder 250; exakte SL-Bestätigung; H1-Kanal; Erwähnungen wie `@everyone`; optionale TP-Funktion. Die Kollegenversion entscheidet diese Fragen nicht automatisch.
4. Vor einer Produktionsmigration sind Compile-/Demo-Abnahme, Drag-/Chartgrößentests, parallele Positionen und Neustart mit unterbrochenem Versand erforderlich. Alte GlobalVariables erlauben keine sichere automatische Rekonstruktion historischer aktiver Positionen.
