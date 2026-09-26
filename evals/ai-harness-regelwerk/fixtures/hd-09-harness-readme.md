# Harness

## Purpose

Einstiegspunkt für Agenten und neue Teammitglieder dieses Repos.

## Sensors

| Target | Vertrag | Bindung |
| --- | --- | --- |
| `test` | Führt alle Unit-Tests aus; Exit 0 = grün. | ADR-0004 |
| `lint` | Statische Analyse über `src/`. | ADR-0004 |
| `make verify-slice SLICE=<id>` | Prüft die DoD des angegebenen Slice. | LH-QA-SUP-002 |
| [`coverage`](sensors/coverage.md) | Coverage-Schwelle, siehe Datei. | Schwelle 40 %, M2 -> 70 % |

## Traceability rules

Jeder Commit nennt mindestens eine LH-, ADR- oder Slice-Kennung.
