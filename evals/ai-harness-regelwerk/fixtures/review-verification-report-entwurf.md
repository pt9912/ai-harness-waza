# Review-Report: slice-064-order-export - 2026-03-05

**Review-Art:** Code
**Gegenstand:** [slice-064-order-export](../plan/planning/in-progress/slice-064-order-export.md)
**Skill:** .harness/skills/reviewer.md @ 3f2c9d1 - **Modell:** claude-sonnet - **Datum:** 2026-03-05

## Findings

| ID | Kategorie | Befund | Quelle | Pfad | Verifizierbar | Klasse |
|---|---|---|---|---|---|---|
| F-1 | HIGH | Handler importiert internal/db direkt. | ADR-0004 | internal/handler/order.go:42 | ja - [arch-check](../../harness/sensors/arch-check.sh) wird rot | Layer-Grenze im Handler verletzt |
| F-2 | MEDIUM | Export-Abfrage ohne Tie-Break bei gleichem Zeitstempel. | [modul-10 Reviewer-Skill](../../.harness/baseline/v6.10.0/regelwerk/modul-10-review-harness.md#ziel-form-reviewer-skill) | internal/db/orders.go:88 | nein | Tie-Break nicht dokumentiert |

## Negativbefunde

| Bereich | Ergebnis |
|---|---|
| internal/invoice/ | geprueft, ohne Befund |

## Summary

HIGH: 1 - MEDIUM: 1 - LOW: 0 - INFO: 0
