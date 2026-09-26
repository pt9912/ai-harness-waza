# Diskrepanz-Notizen, Sub-Area `internal/parser/` (Repo "pegelwacht")

Stand: Welle W4, Slice-Planung fuer slice-052.

Bereits offen (aktive Carveouts in `docs/plan/carveouts/`):

- CO-004: Coverage-Gate ohne `internal/parser/lexer.go` (Lexer-Tests fehlen noch).
- CO-007: Suppression-Gate erlaubt `//nolint` in `internal/parser/ast.go`.
- CO-009: Architekturregel "keine Zyklen" ausgenommen fuer `internal/parser/` <-> `internal/eval/`.

Neu gefunden heute:

- Der gesamte `internal/parser/`-Baum wurde vor der Spezifikation geschrieben;
  fuer `visitor.go`, `errors.go` und `pos.go` gibt es weder LH-Anker noch ADR.

Vorschlag von dev-b: "Wir legen einfach CO-010, CO-011 und CO-012 an, je ein
Carveout pro Datei, mit Trigger 'sobald wir Zeit haben'."
