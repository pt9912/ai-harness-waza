# Reconciliation-Register

| Kennung | Fund | Sub-Area | Klasse | Auflösung | Stand |
|---|---|---|---|---|---|
| RC-001 | Rate-Begrenzung im Gateway, von keiner Anforderung gedeckt | api | Code ohne Anforderung | CO-004 -> slice-rate-limit-gateway | offen |
| RC-002 | README verspricht CSV-Export, nicht implementiert | export | Anforderung ohne Code | slice-csv-export | offen |
| RC-003 | Retry-Logik im Indexer, von keiner Anforderung gedeckt | idx | Code ohne Anforderung | CO-006 -> slice-indexer-retry | offen |
| RC-004 | Lastenheft verspricht Passwort-Reset, nicht implementiert | auth | Anforderung ohne Code | slice-password-reset | offen |
| RC-005 | Legacy-Import ohne Test, Zusage in der Doku | import | Anforderung ohne Code | slice-import-tests | offen |

## Aufgelöste Einträge

| Kennung | Fund | Sub-Area | aufgelöst durch | Datum |
|---|---|---|---|---|
| RC-006 | Session-Store ohne dokumentierte Entscheidung | auth | ADR-0012 | 2026-03-18 |
