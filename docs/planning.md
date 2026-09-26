# Planung und Stand

Stand: 2026-09-26 (Commit `4b101e3` und danach). Dieses Dokument soll einer neuen Session den direkten Einstieg geben.
Bedienung und Grundlagen stehen in `README.md`; hier steht, was gemessen wurde, was offen ist und wo die Fallstricke liegen.

## Ziel

Testen, wie gut Code-Agenten das AI-Harness-Regelwerk (`pt9912/ai-harness-course`, Release-ZIP, aktuell **v6.10.0**) anwenden:

1. Skill-Wrapper `skills/ai-harness-regelwerk/` (dünn, Token-Budget 500, aktuell 475) + 85 Tasks in `evals/ai-harness-regelwerk/`.
2. Mehrwert des Regelwerks gegenüber Vorwissen messen (mit Skill vs. Baseline ohne Regelwerk).
3. Modelle vergleichen (bisher GLM 5.3 flash und Deepseek v4.1 flash, beide Ollama-Cloud).

Rahmenbedingungen (Entscheidungen des Nutzers):
- Alles über `Makefile` + `Dockerfile`, Host braucht nur `make` + `docker`. **Kein Bind-Mount**, Ergebnisse per `docker cp`.
  (Ausnahme: `tools/matrix_eval.py` läuft mit dem Host-Python, nur Auswertung.)
- Provider ist Ollama (lokal, Cloud-Modelle erlaubt). Der Vergleich Opus/Haiku über die Anthropic-API mit **promptfoo** kommt
  später in ein **eigenes neues Repo**.
- Regelwerk-Änderungen gehören ins Kurs-Repo (`../KI/ai-harness-course`, dort passt ein anderer Code-Agent das Regelwerk
  an, „Welle 140“). Dieses Repo nur lesen, nichts ändern.
- Das Repo wird umbenannt und umgezogen: Pfade in Doku/Skripten sind relativ; `README.md` und Makefile nennen den Namen
  `waza` nur als Image-Namen (`waza:local`, `waza:baseline`). `results/` ist gitignored und muss beim Umzug **mitkopiert
  werden**, wenn die Ergebnisse gebraucht werden. Einen Git-Remote gibt es noch nicht.

## Stand der Arbeit

- waza v0.38.7 (Quellbau im Dockerfile), Regelwerk-ZIP mit SHA256 verifiziert, Multi-Stage: `project` (Skill + Evals) und
  `project-baseline` (kein Regelwerk, Evals unter `/workspace/evals/base`, socat/iproute2 für die Netzsperre).
- 85 Tasks (12 ursprüngliche + 73 regelbasierte aus allen 25 Regelwerk-Dateien), 49 mit LLM-Judge (`prompt`-Grader,
  Referenz + RICHTIG/FALSCH-Beispiel + Kriterium, höchstens eine Plausibilitäts-Regex). Judge: `kimi-k2.7-code:cloud`.
- Judge-Referenzen wurden gegen v6.10.0 geprüft (Commit `8685188`). Judge-Übereinstimmung wurde mit 4 Judges geprüft (Cohen-Kappa).
- Isolation je Task/Trial in eigenem Container (`tools/run_isolated.sh`), Task-/Eval-Dateien werden nach dem Start gelöscht
  (`tools/run_hidden.sh`), Wiederholung bei Judge-Infrastrukturfehlern (`tools/judge_silent.py`, bis 3 Versuche).
- Messmatrix (`tools/run_matrix.sh`, TAG=mx, 3 Trials, Judge Kimi), ausgewertet mit `python3 tools/matrix_eval.py`:

| Modell | mit Skill | ohne Regelwerk (roh) |
|---|---|---|
| GLM 5.3 flash | 246/255 = 96,5 % [93,4–98,1] | 33/255 = 12,9 % [9,4–17,6] |
| Deepseek v4.1 flash | 245/255 = 96,1 % [92,9–97,9] | 94/255 = 36,9 % [31,2–42,9] |

  Keine Task liegt mit Skill in beiden Modellen unter 2 von 3 (kein Kandidat für Regelwerk-/Task-Mangel). 9 (GLM) bzw. 8
  (Deepseek) von 85 Tasks streuen mit Skill.
- **Die Baseline-Zellen der Matrix sind nur eingeschränkt gültig** (siehe Leckwege). Deepseek: 31 von 255 Läufen holten das Kurs-Repo
  aus dem Netz (94 % bestanden), ohne diese Läufe 29 % statt 37 %. Zusätzlich lagen die Fixtures aller Tasks im Image.

## Leckwege der Vorwissens-Messung (alle in README dokumentiert)

1. Task-Dateien mit Judge-Referenzen im Image → `run_hidden.sh` löscht sie nach dem Start.
2. Copilot-Session-Logs mit früheren Judge-Prompts → isolierter Container je Task/Trial.
3. **Internet** (`web_fetch`, `curl`, `git clone` holten das Regelwerk von GitHub) → `NET_ISOLATE=1` (leerer Netz-Namespace, Ollama per
   socat-Relay, SYS_ADMIN/NET_ADMIN danach entzogen). Standard nur bei `make run-ollama-baseline`.
4. **Fixtures anderer Tasks** enthalten Regelwerk-Auszüge → `HIDE_FIXTURES=1` (gilt zusammen mit `NET_ISOLATE=1`).

Der Leck-Check in `matrix_eval.py` sucht nur nach Judge-Markern, **nicht** nach Netzzugriff. Prüfung auf Netzzugriff (Beispiel, siehe
Session-Verlauf): in `tool_events` der Ergebnisdatei nach `pt9912|ai-harness-course|lab-regelwerk` in `args` suchen.

## Geschärfte Tasks (Commit `4b101e3`)

Zusatzfragen mit Regelwerk-spezifischem Wissen und strengere Judge-Kriterien, damit sie ohne Regelwerk nicht bestehen:

| Task | Zusatz | Prüfung per Lauf |
|---|---|---|
| bs-11 | Wann ist das Register leer? (Graduation je Sub-Area) | ja: ohne Regelwerk 1/3, mit Skill 3/3 |
| m09-10 | Carveout statt Schwellen-Senkung | ja: ohne 1/2, mit Skill 3/3 (teilweise ratbar) |
| m13-01 | Prompt ohne Hinweis auf Semantik; beide Regeln Pflicht | ja: ohne 0/2, mit Skill 3/3 |
| m0-02 | AGENTS.md allein ist halbgesetzt, Fitness Function nötig (modul-09) | Baseline 3/3 → bleibt leicht (Allgemeinwissen) |
| m02-11 | Nachfolge-Eintrag statt Edit (append-only) | **nicht verifiziert** |
| m02-15 | Umgebaut: 2 von 14 Zeilen ohne Auflösung → nicht abgeschlossen; anerkannte Auflösungsarten | **nicht verifiziert** |
| m04-06 | Slice-Verweis nur als markierter Verifikations-Zeiger | Baseline ✓✓✗, mit Skill nicht verifiziert |
| m06-02 | Regelwerks-Test für Start-Trigger (Slice-Liste der Welle) | **nicht verifiziert** |

## Offene Aufgaben (Reihenfolge = Empfehlung)

1. **Voraussetzung: Ollama-Nutzungslimit.** Am 2026-09-26 war das monatliche Limit erreicht (`you have reached your monthly usage
   limit`, betrifft alle Cloud-Modelle einschließlich Judge). Test: `curl -s localhost:11434/api/chat -d '{"model":"kimi-k2.7-code:cloud","stream":false,"messages":[{"role":"user","content":"ok"}]}'`.
   Erst wenn das antwortet, weitermessen.
2. **Geschärfte Tasks per Lauf prüfen** (m02-11, m02-15, m04-06, m06-02, dazu m0-02 mit Skill):
   `make run-ollama-baseline OLLAMA_MODEL=deepseek-v4.1-flash:cloud TRIALS=2 BASELINE_SUFFIX=-sharp5 TASK="m02-11-001 m02-15-001 m04-06-001 m06-02-001"`
   und dasselbe mit `make run-ollama-isolated ... SUFFIX=-sharp5-skill`. Erwartung: mit Skill ≥ 2/3, ohne Regelwerk niedrig.
   Ergebnisse mit Fehlerzählung prüfen: „Failed to get response from the AI model“ = Limit/Ausfall, keine Modellaussage.
3. **Saubere Vorwissens-Baseline neu messen** (beide Modelle, 3 Trials, dauert ca. 2,5 h): `TAG=mx2 JOBS=4 TRIALS=3 tools/run_matrix.sh`
   (ohne Skill-Zellen zu wiederholen, `MODELS`/Dateien anpassen oder die vorhandenen `*-mx-skill.json` nach `*-mx2-skill.json`
   kopieren; die Skill-Zellen sind gültig, aber die Tasks sind seitdem teilweise geändert, für strenge Vergleichbarkeit neu laufen lassen).
   Danach `RESULTS_DIR=results python3 tools/matrix_eval.py` und die Netz-Prüfung auf den Baseline-Läufen.
4. **Weitere leichte Tasks schärfen** oder als „Allgemeinwissen“ markieren. Aus der Matrix bestehen ohne Regelwerk u. a. in beiden Modellen:
   m0-02, m09-10, referenz-richtung-001, roadmap-welle-001, spec-architektur-001, die beiden should-not-trigger-Tasks; bei
   Deepseek zusätzlich viele weitere (agents-md-duplikat, bootstrap, m03-07, m05-02, m05-09, m16-04, rr-04, sp-11 …, teils nur durch
   Netzzugriff). Erst mit der sauberen Baseline (Punkt 3) entscheiden, welche wirklich Vorwissen sind. Nur mit Zustimmung des Nutzers
   ändern.
5. **Judge-Strenge prüfen.** Kimi ließ bei bs-11 eine falsche Nebenaussage durch, bis das Kriterium verschärft wurde. Stichproben
   (ca. 10 Referenzbehauptungen menschlich gegenprüfen wurde dem Nutzer angeboten, steht offen).
6. **Regelwerk-Mängel** (bereits verifiziert, gehören ins Kurs-Repo, Welle 140): der Widerspruch bei der Referenz-Richtung, das Gate-Template,
   modul-01/03/09/05 (Details im Git-Log ab `1e33daa` und in den Task-Beschreibungen). v6.10.0-Diffs in modul-04/11/12/13/00 und den
   Templates sind noch nicht gegen die Tasks geprüft.
7. **CI:** `.github/workflows/eval.yml` stammt aus `waza init` und nutzt `azd`; auf `make schema-check` / Mock-Lauf umstellen.
8. **Repo-Umzug:** Remote einrichten, `results/` mitnehmen oder neu erzeugen, README-Titel/Namen anpassen, ggf. Image-Namen in
   Makefile (`IMAGE`, `IMAGE_BASELINE`) umbenennen.
9. **Später, eigenes Repo:** promptfoo-Vergleich (Opus/Haiku über Anthropic-API). Die 85 Tasks samt Judge-Referenzen lassen sich als
   Testfälle übernehmen; die Isolation (kein Netz, keine fremden Fixtures) muss dort neu bedacht werden.

## Wichtige Befehle

```
make image image-baseline        # Images bauen
make schema-check                # Tasks/Evals gegen waza-Schemas, Fixtures, IDs, Regex prüfen
make check tokens spec-verify    # Skill-Readiness, Token-Budget, Abdeckung
make run                         # Mock-Lauf (offline, ohne Bewertung)
make run-ollama-isolated OLLAMA_MODEL=glm-5.3-flash:cloud TRIALS=3 JOBS=4 SUFFIX=-x TASK="<ids>"   # mit Skill
make run-ollama-baseline OLLAMA_MODEL=... TRIALS=3 JOBS=4 BASELINE_SUFFIX=-x                      # ohne Regelwerk, ohne Netz
TAG=mx JOBS=4 TRIALS=3 tools/run_matrix.sh                                                           # Matrix, fortsetzbar
python3 tools/matrix_eval.py                                                                         # Auswertung (Wilson-CI, Mehrwert, Streuung)
```

Ergebnisse landen in `results/` (gitignored, teils 100 MB je Datei). `results/iso.*` sind Einzelergebnisse und Logs der isolierten Läufe
und können gelöscht werden, wenn die zusammengeführte Datei vorhanden ist.

## Fallstricke

- Ein Task ohne Judge-Urteil zählt als bestanden=False mit Feedback „All prompts passed“; `judge_silent.py` fängt das ab.
  Fehler „failed to send prompt: session error“ = Judge-Modell nicht erreichbar.
- Judge-Grader (`prompt`) brauchen `continue_session: true`; `waza grade` kann sie nicht ausführen (Kopie ohne Judge für Neubewertung nötig).
- `waza run --no-skills` deaktiviert nur den Skill, nicht das Regelwerk im Image; deshalb das eigene Baseline-Image.
- Go-RE2: keine Lookarounds/Backreferences; `output_contains` ist case-insensitiv.
- Gemischte Trials (mind. 1 bestanden, 1 nicht) sind normal; Aussagen immer mit Wilson-Intervall und Einzelläufen, nicht mit Task-Bestehen.
- Judge-Referenzen stehen in den Task-Dateien im Klartext. Diese Dateien nie in ein Image legen, in dem der getestete Agent sie lesen darf.
