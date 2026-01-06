# DowHowSignalService
Tool für den Metatrader MT5 um einen Signaldienst in Discord zu betreiben



## Beschreibung des Expert Advisors (EA)

Dieser Expert Advisor (EA) für MetaTrader 5 automatisiert den DowHow‑Signaldienst. Er überwacht Marktdaten und generiert Handelssignale, die per Discord‑Webhook in verschiedenen Kanälen veröffentlicht werden.

### Funktionen

- Automatisiertes Senden von Trading‑Signalen an Discord inklusive `@everyone`‑Markierung
- Benutzerfreundliches Panel zur Eingabe und Verwaltung von Trades
- Automatische Vergabe von Trade‑ und Positionsnummern sowie Speicherung in einer internen Datenbank
- Optionales Anhängen von Screenshots des Charts zur Discord‑Nachricht
- Prüfung der WebRequest‑Berechtigungen im Terminal und Test der Discord‑Verbindung
- Unterstützung von Updates, Stornierungen und Überwachung offener Positionen
- Erweiterbar um zusätzliche Symbole und Webhook‑Kanäle

Dieser EA bildet die DowHow‑Trendfolge‑Handelsstrategie effizient ab und informiert die Discord‑Community rechtzeitig über neue Signale.

