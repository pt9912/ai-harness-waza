# waza-Evals für das AI-Harness-Regelwerk

Verhaltenstests für einen dünnen Skill (`skills/ai-harness-regelwerk/SKILL.md`), der auf das
[AI-Harness-Regelwerk](https://github.com/pt9912/ai-harness-course) (`lab-regelwerk.zip`, v6.9.0) verweist.
Getestet wird mit [waza](https://github.com/microsoft/waza) (v0.38.7).

Auf dem Host werden nur `make` und `docker` gebraucht. waza läuft im Container, es gibt keinen Bind-Mount.

## Make-Targets

Alle Targets führen genau einen waza-Befehl im Container aus (nach `make image`).

| Target | waza-Befehl | Zweck |
|---|---|---|
| `make image` | – (docker build) | Image bauen: waza aus dem Quellcode, Regelwerk-ZIP mit SHA256-Prüfung, Skills/Evals per `COPY` |
| `make schema-check` | – (Python-Validator im Container) | Tasks, Evals und Config gegen die JSON-Schemas der waza-Version prüfen; dazu Fixtures vorhanden, eindeutige Task-IDs, Regex-Syntax und RE2-Tauglichkeit (Heuristik) |
| `make check` | `waza check` | Skill-Readiness: Compliance, Token-Budget, Links |
| `make tokens` | `waza tokens count` | Token-Zählung der Skill-Dateien |
| `make spec-verify` | `waza spec verify` | Deckt die Eval-Suite die Trigger aus der `SKILL.md` ab? |
| `make run` | `waza run` (Mock, `--skip-graders`) | Gerüsttest offline; bewertet nichts |
| `make run-copilot` | `waza run` (copilot-sdk) | Echter Lauf mit Modell; braucht `GITHUB_TOKEN` |
| `make run-ollama OLLAMA_MODEL=… [TASK="…"] [OLLAMA_JUDGE=…]` | `waza run` (Ollama als Provider) | Echter Lauf mit einem Ollama-Modell, auch `:cloud`-Modelle; kein Key nötig |
| `make compare A=… B=…` | `waza compare` | Zwei Ergebnisdateien vergleichen |
| `make waza-help` | `waza --help` | Hilfe |
| `make shell` | – (bash im Container) | Shell im Container |
| `make clean` | – | `results/` und Image entfernen |

`make help` listet die Targets.

## Typischer Ablauf

```bash
make check
make spec-verify
make run                                  # Gerüst prüfen (Mock, ohne Bewertung)
GITHUB_TOKEN=... make run-copilot         # echter Lauf, Ergebnis: results/copilot.json
make compare A=results/copilot.json B=results/anderer-lauf.json
```

Ergebnisse landen per `docker cp` in `./results/`.

## Ollama als Provider

`run-ollama` startet den Container mit `--network host` und setzt `COPILOT_PROVIDER=openai`,
`COPILOT_BASE_URL=http://localhost:11434/v1`, `COPILOT_WIRE_API=completions` und einen Platzhalter-Key.
Ollama muss auf dem Host laufen (`ollama list` zeigt die Modelle).

```bash
make run-ollama OLLAMA_MODEL='kimi-k2.7-code:cloud'                        # alle Tasks
make run-ollama OLLAMA_MODEL='kimi-k2.7-code:cloud' TASK='source-precedence*'   # ein Task
make run-ollama OLLAMA_MODEL='glm-5.3-flash:cloud' TASK="m09-08* m02-11*"       # mehrere Muster
```

Die `prompt`-Grader (LLM-Judge) nutzen `OLLAMA_JUDGE` (Standard `deepseek-v4.1-flash:cloud`), unabhängig vom
getesteten Modell (`--judge-model`).

- Bei `:cloud`-Modellen gehen Prompts und gelesene Regelwerk-Auszüge an ollama.com.
- Kleine lokale Modelle scheitern am Kontext: `Qwen3-4B` meldete 10.830 Prompt-Tokens gegen 4096 Kontext.
  Ein größerer Kontext (`OLLAMA_CONTEXT_LENGTH`) ist nicht getestet und bei 8 GB GPU-Speicher knapp.
- Ergebnisse: `results/ollama-<modell>.json`.

## Aufbau

```
Dockerfile                        waza-Build, Regelwerk-ZIP (URL + SHA256), Stage `project`
Makefile
tools/schema_check.py             Validator für `make schema-check`
.waza.yaml                        waza-Projektdefaults
skills/ai-harness-regelwerk/
  SKILL.md                        Wrapper (einziger eigener Skill-Inhalt)
evals/ai-harness-regelwerk/
  eval.yaml                       echtes Modell (copilot-sdk)
  eval.mock.yaml                  Offline-Gerüsttest
  tasks/*.yaml                    85 Tasks (12 Einstiegs-Tasks + 73 aus den Regeln der 25 Regelwerk-Dateien)
  fixtures/                       Testdateien
```

### Prüfung der Tasks

- Jeder der 73 regelbasierten Tasks nennt im `description`-Feld Regel-ID und Quelldatei.
- Die 39 im Review beanstandeten Tasks haben pro Task `graders:` mit einem `text`-Grader (Regex: Wortstamm,
  Umlaut-/ASCII-Varianten, Kernaussage) und einem `prompt`-Grader (LLM-Judge, `continue_session: true`,
  Referenzantwort plus je eine richtige und falsche Beispielantwort). Beide müssen bestehen.
- Die übrigen Tasks prüfen mit `expected.output_contains` (case-insensitiv).
- Die Regexes wurden mit `waza grade` gegen Beispielantworten geprüft (richtig besteht, falsch fällt durch) und
  nach einem Lauf mit GLM (`glm-5.3-flash:cloud`, Judge Kimi, ein Trial: 73/85 bestanden) an den echten Antworten
  nachjustiert (8 Tasks). Mit mehr Modellen und Trials sind weitere Anpassungen zu erwarten.
- `make schema-check` prüft die Regex-Syntax nur mit Pythons `re` und einer Liste bekannter RE2-Unterschiede; ob Go sie akzeptiert, zeigt erst ein Waza-Lauf (`waza grade`).
- `waza grade` funktioniert nicht mit `prompt`-Gradern ("requires an execution engine"); für eine Nachprüfung
  von Regexes muss man die Judges aus einer Kopie der Tasks entfernen.

`regelwerk/` und `templates/` liegen nicht im Repo. Sie werden beim Build aus dem ZIP entpackt
und stehen im Image unter `/workspace/skills/ai-harness-regelwerk/`.

## Regelwerk-Version wechseln

`REGELWERK_URL` und `REGELWERK_SHA256` im `Dockerfile` ändern, dann `make image`.

## Grenzen

- Skill und Tasks ändern: Dateien im Repo bearbeiten, dann erneut `make …` (das Image wird dabei neu gebaut).
- `waza init`, `waza new` und `waza dev` haben kein Make-Target, da sie Dateien im Repo schreiben würden.
- Die Erwartungen in `tasks/*.yaml` (Regex und Begriffe) sind Annahmen und nach echten Läufen zu kalibrieren; Regexes sind die häufigste Quelle falscher Fehlschläge.
- Der Mock-Executor gibt nur den Prompt zurück; nur `make run-copilot` misst echtes Verhalten.
