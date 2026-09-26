# AGENTS.md (Entwurf, Repo "pegelwacht")

## 1. Kanonische Quellen
Source Precedence: Lastenheft, Spezifikation, Architektur, ADRs, Roadmap, README, AGENTS.md.

## 2. Harte Regeln
- Docker-only: kein lokaler Toolchain-Install, alles ueber `make`.
- Kein Inline-`# noqa`.

## 3. Quality Gates (neu, damit der Agent alles sofort sieht)

| Target | Prueft | Bindung |
| --- | --- | --- |
| `make lint` | Ruff, Formatierung | jeder Commit |
| `make test` | Unit-Tests | jeder Commit |
| `make coverage-gate` | Coverage >= 80 % | jeder PR |
| `make doc-gate` | Links und Anker in Markdown | jeder PR |
| `make verify-slice` | Slice-Akzeptanz | Slice-Closure |

Hinweis von Kollegin Lena: In `harness/README.md` gibt es schon eine Sensors-Tabelle
mit denselben Targets. Ich wuerde die Liste aber in AGENTS.md pflegen und die
README-Tabelle spaeter loeschen, weil AGENTS.md ja jeder Agent liest.
