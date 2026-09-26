# docs/plan/planning/observations/BEO-PAR/fehler-ohne-kontext/

## observation.md

Bezeichnung: Fehlermeldungen des Parsers nennen weder Datei noch Zeile.
Sub-Area: PAR

## state.md

Stand: offen

## evidence/slice-041.md

Vorgang: slice-041 (geschlossen, in `done/`)
Fund 1: `parse_header()` wirft ParseError ohne Zeilenangabe.
Fund 2: `parse_body()` wirft ParseError ohne Dateiname.

## evidence/slice-047.md

Vorgang: slice-047 (geschlossen, in `done/`)
Fund: `parse_footer()` wirft ParseError ohne Kontext.

## Weitere Notizen

Dasselbe Muster trat erneut in slice-052 auf. slice-052 liegt noch in
`in-progress/`, die Closure-Notiz fehlt.
