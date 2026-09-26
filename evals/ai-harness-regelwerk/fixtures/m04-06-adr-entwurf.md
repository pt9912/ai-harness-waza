# ADR-0009: Export-Format CSV mit Streaming-Writer

- Status: Proposed
- Datum: 2025-05-12
- Bezug: LH-FA-020
- Supersedes: —
- Re-Evaluierungs-Trigger: Export-Volumen > 1 Mio. Zeilen pro Tag

## Kontext
Anforderung LH-FA-020: "Das System exportiert Berichte als CSV mit
höchstens 100 Zeilen pro Datei. Happy: 80 Zeilen ergeben eine Datei.
Boundary: 100 Zeilen ergeben eine Datei. Negative: 101 Zeilen ergeben
eine Fehlermeldung." Umgesetzt wird das in slice-031-csv-export.

## Verglichene Alternativen
1. In-Memory-Aufbau: einfach, aber hoher Speicherbedarf.
2. Streaming-Writer: geringer Speicher, etwas komplexer.
3. Externer Export-Dienst: entkoppelt, aber zusätzlicher Betriebsaufwand.

## Entscheidung
Streaming-Writer (Alternative 2).

## Konsequenzen
Fitness Function: `make arch-check` (import-linter) verbietet Importe von
`src/report/` nach `src/export/writer_legacy/`.
