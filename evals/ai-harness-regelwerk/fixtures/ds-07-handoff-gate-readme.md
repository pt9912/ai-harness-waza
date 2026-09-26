# .claude/hooks/README.md (Auszug)

## Handoff-Gate (Stop-Hook)

`.claude/hooks/stop-gate.sh` laeuft, bevor der Agent "fertig" melden darf.

Mechanik:

- `make gates` schreibt bei Erfolg einen Nachweis nach `.claude/state/gates.sha`:
  SHA-256 ueber die Inhalte aller getrackten und nicht ignorierten Dateien
  des Arbeitsbaums.
- Der Hook berechnet denselben Hash neu und vergleicht. Stimmt er, darf der
  Agent abschliessen; stimmt er nicht, wird blockiert. Beim zweiten Anlauf
  derselben Runde gibt sich der Hook frei.
- `.claude/state/` steht in `.gitignore`.

**Garantie:** Ein Agent kann in diesem Repo nie "fertig" melden, ohne dass
alle Gates auf genau diesem Stand gruen gelaufen sind.

# Auszug aus dem Hook-Log der letzten Woche

```text
2026-03-02 09:14 stop-gate: hash a41f.. == gates.sha  -> frei
2026-03-02 15:40 stop-gate: hash 9c02.. != gates.sha  -> BLOCK (gates neu laufen lassen)
2026-03-03 11:02 stop-gate: hash 77be.. == gates.sha  -> frei
2026-03-04 08:31 stop-gate: .claude/state/gates.sha fehlt, Arbeitsbaum clean (frischer Klon)
                            -> kein Nachweis pruefbar, frei
2026-03-04 08:33 Agent-Meldung: "Aenderung ist bereits committet, Gates sind gelaufen."
```
