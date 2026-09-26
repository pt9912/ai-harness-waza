# Roadmap

## Offene Wellen

- [welle-parser-haertung](../welle-parser-haertung.md)

## Nächste Wellen

| Welle | Trigger | Wichtigste Slices | Geschätzter Aufwand |
|---|---|---|---|
| welle-betrieb | welle-parser-haertung done | slice-latenz-replay-100k, slice-alerting | M |

## Meilensteine

| Meilenstein | Welle(n) | Trigger | Status |
|---|---|---|---|
| M2: Parser gehärtet | welle-parser-haertung | Welle geschlossen | offen |
| M3: Audit-Freigabe Export | ? | `slice-export-csv` liegt in `done/`, Freigabe durch Auditor | offen |

## Abgeschlossene Wellen

| Welle | Abschluss | Closure-Notiz |
|---|---|---|
| welle-grundgeruest | 2026-03-14 | [`welle-grundgeruest-results.md`](../done/welle-grundgeruest-results.md) |

## Historische Trigger-Verschiebungen

| Datum | Was wurde geändert? | Warum? |
|---|---|---|
| 2026-04-02 | Trigger welle-betrieb von Datum auf welle-parser-haertung done umgestellt | Datum ist kein beobachtbarer Trigger |

---

Notiz (Projektleitung): `slice-export-csv` hat keine Welle, er baut den CSV-Export und ist mit
seiner eigenen DoD fertig. Er liefert aber den letzten Beleg für M3. Wir wollen, dass in der
Roadmap sichtbar ist, dass er gerade läuft.
