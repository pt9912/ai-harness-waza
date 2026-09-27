# waza-Evals für das AI-Harness-Regelwerk

🇬🇧 [English](README.md) · 🇩🇪 **Deutsch**

Verhaltenstests für einen dünnen Skill (`skills/ai-harness-regelwerk/SKILL.md`), der auf das
[AI-Harness-Regelwerk](https://github.com/pt9912/ai-harness-course) (`lab-regelwerk.zip`, v6.10.0) verweist.
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
| `make run-ollama-isolated` / `run-ollama-baseline` | `waza run` je Task/Trial in eigenem Container | Ohne Judge-Spuren früherer Läufe; die Baseline nutzt ein Image ohne Regelwerk (reines Vorwissen) |
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

## Referenzantworten vor dem Agenten verbergen

Die Task-Dateien enthalten die Referenzantworten der Judges. Vier Leckwege, die in Läufen ohne Skill aufgetreten sind:

1. **Task-Dateien im Image.** Agenten haben sie per `find`/`grep` gefunden und gelesen (`m14-08`, `rr-05`, `sp-13`,
   `tr-04`). Abhilfe: `run-ollama`, `run-ollama-isolated`, `run-ollama-baseline` und `run-copilot` starten über
   `tools/run_hidden.sh`; es startet waza, löscht nach wenigen Sekunden `evals/*/tasks` und `evals/*/eval*.yaml`
   (waza hat die Tasks dann geladen; die Fixtures bleiben). Abschalten: `ENTRYPOINT_OPT=` (leer).
2. **Session-Logs des Copilot-CLI** (`/root/.copilot/session-state`, `/tmp/copilot-tool-output-*`): Dort steht der
   Judge-Prompt früherer Tasks/Trials im selben Container. Bei mehreren Trials fanden spätere Läufe die Referenz des
   ersten (4 von 7 „bestandenen" Läufen ohne Regelwerk). Löschen der Dateien während des Laufs ist riskant (ein Judge
   brach mit „failed to resume session" ab). Abhilfe: `make run-ollama-isolated` (und `run-ollama-baseline`) starten
   **jeden Task und Trial in einem eigenen Container** (`tools/run_isolated.sh`, Ergebnisse per
   `tools/merge_results.py` zusammengeführt; `TRIALS`, `JOBS`).
3. **Internet.** Die Modelle haben `web_fetch`, `bash` und `git clone` und haben das Regelwerk aus
   `github.com/pt9912/ai-harness-course` geholt (Deepseek: 31 von 255 Baseline-Läufen, 94 % bestanden; ohne diese Läufe
   29 % statt 37 %; eine Stichprobe ohne Netz fiel von 70 % auf 33 %). Abhilfe: `run-ollama-baseline` setzt
   `NET_ISOLATE=1`. `tools/run_hidden.sh` startet waza dann in einem leeren Netz-Namespace (`unshare --net`, nur der
   Container, nicht der Host); Ollama bleibt über ein `socat`-Relay per Unix-Socket erreichbar, `SYS_ADMIN`/`NET_ADMIN`
   werden danach aus dem Bounding-Set entfernt (kein `nsenter` zurück). Der Container braucht dafür
   `--cap-add SYS_ADMIN --cap-add NET_ADMIN` (setzt `run_isolated.sh`). Für andere Läufe: `make run-ollama-isolated NET_ISOLATE=1`.
4. **Fixtures anderer Tasks.** Sie enthalten Regelwerk-Auszüge (z. B. AGENTS.md-Regeln, Carveout-Vorlagen); ein Agent ohne
   Regelwerk fand sie im Image (`/workspace/evals/base/fixtures`) und zitierte „Hard Rule 3.1". Abhilfe: mit
   `NET_ISOLATE=1` setzt `run_isolated.sh` auch `HIDE_FIXTURES=1`; `run_hidden.sh` löscht die Fixtures nach dem Start (die
   Dateien des laufenden Tasks liegen dann schon im Arbeitsverzeichnis des Agenten).

Für Vorwissen-Messungen daher immer `make run-ollama-baseline` (Image ohne Regelwerk, isoliert, ohne Internet). Ältere
Läufe ohne Skill (Baseline mit 85 Tasks, 11-Task-Lauf, Matrix `*-baseline-mx.json`) sind nur eingeschränkt gültig. Läufe mit Skill sind nicht betroffen (dort
kein Judge-Inhalt in den Tool-Ergebnissen gefunden), laufen aber weiter in einem gemeinsamen Container.

## Ollama als Provider

`run-ollama` startet den Container mit `--network host` und setzt `COPILOT_PROVIDER=openai`,
`COPILOT_BASE_URL=http://localhost:11434/v1`, `COPILOT_WIRE_API=completions` und einen Platzhalter-Key.
Ollama muss auf dem Host laufen (`ollama list` zeigt die Modelle).

```bash
make run-ollama OLLAMA_MODEL='kimi-k2.7-code:cloud'                        # alle Tasks
make run-ollama OLLAMA_MODEL='kimi-k2.7-code:cloud' TASK='source-precedence*'   # ein Task
make run-ollama OLLAMA_MODEL='glm-5.3-flash:cloud' TASK="m09-08* m02-11*"       # mehrere Muster
```

Die `prompt`-Grader (LLM-Judge) nutzen `OLLAMA_JUDGE` (Standard `kimi-k2.7-code:cloud`), unabhängig vom
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
- 49 Tasks haben pro Task `graders:` mit einem `prompt`-Grader (LLM-Judge, `continue_session: true`, Referenzantwort,
  bei den überarbeiteten Tasks zusätzlich je eine richtige und falsche Beispielantwort). **Der Judge entscheidet.** Der
  `text`-Grader (höchstens die Kernaussage-Regex plus `regex_not_match`) ist nur eine Plausibilitätsprüfung; alle
  Regexes bestehen auf sämtlichen vom Judge bestandenen echten Antworten aus den Läufen mit v6.9.0 und v6.10.0.
  Beide Grader müssen bestehen.
- Die übrigen 36 Tasks prüfen mit `expected.output_contains` (case-insensitiv) bzw. haben keinen Judge.
- Die Regexes wurden mit `waza grade` gegen Beispielantworten geprüft (richtig besteht, falsch fällt durch) und
  nach einem Lauf mit GLM (`glm-5.3-flash:cloud`, Judge Kimi, ein Trial: 73/85 bestanden) an den echten Antworten
  nachjustiert (8 Tasks). Mit v6.10.0 (damals Judge Deepseek): 78/85 bestanden, alle 42 Judges bestanden; die vier vorher
  bemängelten Stellen des Regelwerks (v6.9.0) sind korrigiert und die zugehörigen Tasks `bg-01`, `hd-13`, `rr-13` bestehen jetzt. Mit mehr Modellen und Trials sind weitere Anpassungen zu erwarten.
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

## Vorwissen-Tasks

Elf Tasks wurden von einem Modell ohne Regelwerk bestanden (Baseline `--no-skills`, GLM) und danach auf eine
Regelwerk-spezifische Entscheidung geschärft. Kontrolle (GLM, Judge `minimax-m3:cloud`, ein Lauf): mit Skill
bestehen alle elf; ohne Skill fallen acht durch. Offen: `ds-07` besteht weiter mit reinem Vorwissen; bei `sp-05`
verhindert nur die Regex ein Bestehen ohne Regelwerk; bei `carveout-anlegen` und `tr-04` bestand das Modell ohne
Skill über eine Suche im Regelwerk. `--no-skills` entfernt nur den Skill, nicht die Dateien im Image.
