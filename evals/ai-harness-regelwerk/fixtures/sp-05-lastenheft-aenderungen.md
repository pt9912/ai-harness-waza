# Lastenheft: Dokumentensuche (Auszug aus spec/lastenheft.md)

Status: Accepted
Version: 1.1.0
Autor: Team Suche, Datum: 2026-02-10

## 1. Zweck und Geltungsbereich

Das System durchsucht die Dokumente der Stadtwerke Nord im Volltext.
Auftraggeber und Entwickler sind in diesem Repo dieselbe Person; es gibt
kein Ticketsystem.

## 2. Anforderungen

### LH-FA-IDX-003 Reindex-Frist

Ein Reindex nach Aenderung eines Dokuments ist innerhalb von 14 Tagen abgeschlossen.

### LH-FA-IDX-004 CSV-Export

Trefferlisten koennen als CSV-Datei exportiert werden.

## 3. Historie

| Version | Datum      | Aenderung                        | Verweis                |
| ------- | ---------- | -------------------------------- | ---------------------- |
| 1.0.0   | 2025-11-03 | Erstfassung (Status: Accepted)   | Vertrag V-2025-114     |
| 1.1.0   | 2026-01-15 | LH-FA-IDX-004 (CSV-Export) neu   | Anhang A zu V-2025-114 |

---

Notizen von Kollege Meier zu drei offenen Lastenheft-Aenderungen:

1. Neue Anforderung LH-QA-SUP-010 (Suche liefert Treffer in 2 Sekunden)
   ergaenzen. Das ist ja nur eine neue Zeile, bestehender Text bleibt unangetastet.
2. Im Zweck-Abschnitt steht "Stadtwerke Nord". Laut unterschriebenem Vertrag V-2025-114
   heisst der Auftraggeber "Stadtwerke Nordost". Wurde beim Abschreiben falsch uebernommen.
3. Bei LH-FA-IDX-003 steht 14 Tage. Im Vertrag steht 10 Tage; das ist ebenfalls ein
   Abschreibfehler und daher nur ein Tippfehler.
