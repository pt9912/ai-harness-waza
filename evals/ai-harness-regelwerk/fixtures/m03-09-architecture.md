# Architektur-Sicht

**Letzte Änderung:** 2025-06-03

## Komponenten

| Kennung | Komponente | Pfad | Aufgabe |
| --- | --- | --- | --- |
| ARC-001 | API-Gateway | `src/gateway/` | Nimmt Anfragen an, prüft Tokens |
| ARC-002 | Cache | `src/cache/` | Hält Sitzungsdaten im Speicher |
| ARC-003 | Berichts-Service | `src/report/` | Erzeugt Berichte, nutzt ARC-002 |

## Sequenz: Bericht abrufen

Gateway (ARC-001) ruft Berichts-Service (ARC-003); dieser liest
Sitzungsdaten aus dem Cache (ARC-002).
