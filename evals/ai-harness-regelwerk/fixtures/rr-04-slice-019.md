# slice-019: CSV-Export fuer Trefferlisten

- Status: In Arbeit
- Roadmap: naechste Welle, siehe [roadmap.md](in-progress/roadmap.md)
- LH-Scope: LH-FA-05
- ADR: [ADR-0011](../adr/0011-csv-streaming.md) (Status: Accepted)
- Carveout: keiner

## Ziel

Trefferlisten werden als CSV gestreamt, ohne den Index komplett im Speicher zu halten.

## DoD

- `make test-export` gruen
- Export von 10.000 Treffern in unter 5 Sekunden
