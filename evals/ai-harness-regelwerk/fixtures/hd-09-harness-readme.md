# Harness

## Purpose

Einstiegspunkt für Agenten und neue Teammitglieder dieses Repos.

## Sensors

| Target | Vertrag | Bindung |
| --- | --- | --- |
| `test` | Führt alle Unit-Tests aus; Exit 0 = grün. | ADR-0004 |
| `lint` | Statische Analyse über `src/`. | ADR-0004 |
| [`mutation`](sensors/mutation.md) | Mutationstest über `src/parser/`; Grenze und Exit-Codes siehe Datei. | ADR-0007 |
| [`coverage`](sensors/coverage.md) | Coverage-Schwelle, siehe Datei. | Schwelle 40 %, M2 -> 70 % |

## Traceability rules

Jeder Commit nennt mindestens eine LH-, ADR- oder Slice-Kennung.
