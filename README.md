# waza Evals for the AI-Harness Rulebook

🇬🇧 **English** · 🇩🇪 [Deutsch](README.de.md)

Behavioral evals for a thin skill (`skills/ai-harness-regelwerk/SKILL.md`) that references the
[AI-Harness rulebook](https://github.com/pt9912/ai-harness-course) (`lab-regelwerk.zip`, v6.10.0).
Tested with [waza](https://github.com/microsoft/waza) (v0.38.7).

Only `make` and `docker` are needed on the host. waza runs inside the container; there is no bind mount.

## Make targets

Every target runs exactly one waza command inside the container (after `make image`).

| Target | waza command | Purpose |
|---|---|---|
| `make image` | – (docker build) | Build the image: waza from source, rulebook ZIP with SHA256 check, skills/evals via `COPY` |
| `make schema-check` | – (Python validator in the container) | Validate tasks, evals and config against the waza version's JSON schemas; also checks fixtures exist, task IDs are unique, regex syntax and RE2 compatibility (heuristic) |
| `make check` | `waza check` | Skill readiness: compliance, token budget, links |
| `make tokens` | `waza tokens count` | Token count of the skill files |
| `make spec-verify` | `waza spec verify` | Does the eval suite cover the triggers from `SKILL.md`? |
| `make run` | `waza run` (mock, `--skip-graders`) | Offline scaffolding test; grades nothing |
| `make run-copilot` | `waza run` (copilot-sdk) | Real run with a model; needs `GITHUB_TOKEN` |
| `make run-ollama-isolated` / `run-ollama-baseline` | `waza run` per task/trial in its own container | No judge traces from earlier runs; the baseline uses an image without the rulebook (pure prior knowledge) |
| `make run-ollama OLLAMA_MODEL=… [TASK="…"] [OLLAMA_JUDGE=…]` | `waza run` (Ollama as provider) | Real run with an Ollama model, including `:cloud` models; no key needed |
| `make compare A=… B=…` | `waza compare` | Compare two result files |
| `make waza-help` | `waza --help` | Help |
| `make shell` | – (bash in the container) | Shell in the container |
| `make clean` | – | Remove `results/` and the image |

`make help` lists the targets.

## Typical workflow

```bash
make check
make spec-verify
make run                                  # check scaffolding (mock, no grading)
GITHUB_TOKEN=... make run-copilot         # real run, result: results/copilot.json
make compare A=results/copilot.json B=results/other-run.json
```

Results are copied to `./results/` via `docker cp`.

## Hiding reference answers from the agent

The task files contain the judges' reference answers. Four leak paths seen in runs without the skill:

1. **Task files in the image.** Agents found and read them via `find`/`grep` (`m14-08`, `rr-05`, `sp-13`,
   `tr-04`). Mitigation: `run-ollama`, `run-ollama-isolated`, `run-ollama-baseline` and `run-copilot` start via
   `tools/run_hidden.sh`; it starts waza and, after a few seconds, deletes `evals/*/tasks` and `evals/*/eval*.yaml`
   (waza has already loaded the tasks by then; the fixtures stay). Disable via `ENTRYPOINT_OPT=` (empty).
2. **Copilot CLI session logs** (`/root/.copilot/session-state`, `/tmp/copilot-tool-output-*`): these contain the
   judge prompt of earlier tasks/trials in the same container. With multiple trials, later runs found the first
   run's reference (4 of 7 "passing" runs without the rulebook). Deleting the files during the run is risky (one
   judge aborted with "failed to resume session"). Mitigation: `make run-ollama-isolated` (and
   `run-ollama-baseline`) start **every task and trial in its own container** (`tools/run_isolated.sh`, results
   merged via `tools/merge_results.py`; `TRIALS`, `JOBS`).
3. **Internet.** The models have `web_fetch`, `bash` and `git clone`, and fetched the rulebook from
   `github.com/pt9912/ai-harness-course` (Deepseek: 31 of 255 baseline runs, 94% passing; excluding those runs
   29% instead of 37%; one no-network sample dropped from 70% to 33%). Mitigation: `run-ollama-baseline` sets
   `NET_ISOLATE=1`. `tools/run_hidden.sh` then starts waza in an empty network namespace (`unshare --net`, only
   the container, not the host); Ollama stays reachable via a `socat` relay over a Unix socket, and
   `SYS_ADMIN`/`NET_ADMIN` are then dropped from the bounding set (no `nsenter` back). The container needs
   `--cap-add SYS_ADMIN --cap-add NET_ADMIN` for this (set by `run_isolated.sh`). For other runs:
   `make run-ollama-isolated NET_ISOLATE=1`.
4. **Other tasks' fixtures.** They contain rulebook excerpts (e.g. AGENTS.md rules, carveout templates); an agent
   without the rulebook found them in the image (`/workspace/evals/base/fixtures`) and cited "Hard Rule 3.1".
   Mitigation: with `NET_ISOLATE=1`, `run_isolated.sh` also sets `HIDE_FIXTURES=1`; `run_hidden.sh` deletes the
   fixtures after startup (the running task's own files are already in the agent's working directory by then).

Always use `make run-ollama-baseline` (image without the rulebook, isolated, no internet) for prior-knowledge
measurements. Older runs without the skill (baseline with 85 tasks, 11-task run, matrix `*-baseline-mx.json`) are
only of limited validity. Runs with the skill are unaffected (no judge content was found in the tool results
there), but keep running in a shared container.

## Ollama as provider

`run-ollama` starts the container with `--network host` and sets `COPILOT_PROVIDER=openai`,
`COPILOT_BASE_URL=http://localhost:11434/v1`, `COPILOT_WIRE_API=completions` and a placeholder key.
Ollama must be running on the host (`ollama list` shows the models).

```bash
make run-ollama OLLAMA_MODEL='kimi-k2.7-code:cloud'                        # all tasks
make run-ollama OLLAMA_MODEL='kimi-k2.7-code:cloud' TASK='source-precedence*'   # one task
make run-ollama OLLAMA_MODEL='glm-5.3-flash:cloud' TASK="m09-08* m02-11*"       # several patterns
```

The `prompt` graders (LLM judge) use `OLLAMA_JUDGE` (default `kimi-k2.7-code:cloud`), independent of the model
under test (`--judge-model`).

- With `:cloud` models, prompts and read rulebook excerpts go to ollama.com.
- Small local models run out of context: `Qwen3-4B` reported 10,830 prompt tokens against a 4096 context.
  A larger context (`OLLAMA_CONTEXT_LENGTH`) is untested and tight with 8 GB of GPU memory.
- Results: `results/ollama-<model>.json`.

## Layout

```
Dockerfile                        waza build, rulebook ZIP (URL + SHA256), stage `project`
Makefile
tools/schema_check.py             Validator for `make schema-check`
.waza.yaml                        waza project defaults
skills/ai-harness-regelwerk/
  SKILL.md                        Wrapper (the only skill content of its own)
evals/ai-harness-regelwerk/
  eval.yaml                       real model (copilot-sdk)
  eval.mock.yaml                  offline scaffolding test
  tasks/*.yaml                    85 tasks (12 baseline tasks + 73 derived from the rules of the 25 rulebook files)
  fixtures/                       test files
```

### Task validation

- Each of the 73 rule-based tasks names the rule ID and source file in its `description` field.
- 49 tasks have per-task `graders:` with a `prompt` grader (LLM judge, `continue_session: true`, reference answer,
  plus a correct and an incorrect example answer for the revised tasks). **The judge decides.** The `text` grader
  (at most the core-claim regex plus `regex_not_match`) is only a plausibility check; all regexes pass on every
  judge-passed real answer from the runs with v6.9.0 and v6.10.0. Both graders must pass.
- The remaining 36 tasks check with `expected.output_contains` (case-insensitive) or have no judge.
- The regexes were checked with `waza grade` against sample answers (correct passes, incorrect fails) and
  re-tuned against real answers after a run with GLM (`glm-5.3-flash:cloud`, judge Kimi, one trial: 73/85 passed;
  8 tasks adjusted). With v6.10.0 (judge Deepseek at the time): 78/85 passed, all 42 judges passed; the four
  previously flagged spots in the rulebook (v6.9.0) are fixed and the corresponding tasks `bg-01`, `hd-13`,
  `rr-13` now pass. Further adjustments are expected with more models and trials.
- `make schema-check` only validates regex syntax with Python's `re` plus a list of known RE2 differences;
  whether Go accepts them only shows up in a waza run (`waza grade`).
- `waza grade` does not work with `prompt` graders ("requires an execution engine"); to re-check regexes, remove
  the judges from a copy of the tasks.

`regelwerk/` and `templates/` are not in the repo. They are unpacked from the ZIP at build time and end up in the
image under `/workspace/skills/ai-harness-regelwerk/`.

## Switching the rulebook version

Change `REGELWERK_URL` and `REGELWERK_SHA256` in the `Dockerfile`, then `make image`.

## Limitations

- To change the skill or tasks: edit the files in the repo, then run `make …` again (this rebuilds the image).
- `waza init`, `waza new` and `waza dev` have no make target, since they would write files into the repo.
- The expectations in `tasks/*.yaml` (regex and terms) are assumptions and need calibration against real runs;
  regexes are the most common source of false failures.
- The mock executor only echoes the prompt back; only `make run-copilot` measures real behavior.

## Prior-knowledge tasks

Eleven tasks were passed by a model without the rulebook (baseline `--no-skills`, GLM) and were then sharpened
into a rulebook-specific decision. Control run (GLM, judge `minimax-m3:cloud`, one run): all eleven pass with the
skill; eight fail without it. Open issues: `ds-07` still passes on pure prior knowledge; for `sp-05`, only the
regex prevents passing without the rulebook; for `carveout-anlegen` and `tr-04`, the model passed without the
skill by searching the rulebook. `--no-skills` only removes the skill, not the files in the image.
