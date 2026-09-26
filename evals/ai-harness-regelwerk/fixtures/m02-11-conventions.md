# Konventionen

Baseline: `.harness/baseline/v6.9.0/` (SHA256SUMS geprüft)

## Adaptions-Index

| ID | Titel | Geltungsbereich | Status | Auflösung |
| --- | --- | --- | --- | --- |
| MR-000 | Adoptions-Erklärung Baseline v6.9.0 (Adaptionen: MR-002, MR-003) | gesamtes Repo | aktiv | permanent |
| MR-002 | Link-Prüfung nur auf Warnstufe | `docs/`, Gate `doc-links` | aktiv | permanent |
| MR-003 | ADR-Index als Tabelle statt Liste | `docs/plan/adr/README.md` | aktiv | Baseline regelt die Index-Form |

## MR-002 — Link-Prüfung nur auf Warnstufe

Die Baseline verlangt, dass tote Links im Doku-Gate `doc-links` den Lauf
rot färben. Wir setzen den Befund auf Warnstufe, weil `docs/` viel
ungepflegten Bestand enthält. Diese Lockerung gilt dauerhaft.
