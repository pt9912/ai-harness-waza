IMAGE      ?= waza:local
IMAGE_BASELINE ?= waza:baseline
# Image, in dem waza laeuft (Baseline ueberschreibt es per Sub-Make).
RUN_IMAGE  ?= $(IMAGE)
# Wrapper, der die Task-/Eval-Dateien (Referenzantworten der Judges) nach dem Start von waza loescht, damit der
# getestete Agent sie nicht per Dateisuche lesen kann. Standard fuer alle Laeufe mit echtem Modell;
# abschaltbar mit ENTRYPOINT_OPT= (leer).
HIDE_OPT        = --entrypoint /opt/waza/tools/run_hidden.sh
ENTRYPOINT_OPT ?= $(HIDE_OPT)
# Zusatz-Flags/Suffix nur fuer run-ollama-baseline (z. B. BASELINE_EXTRA='--trials 3').
BASELINE_EXTRA  ?=
BASELINE_SUFFIX ?=
TRIALS ?= 1
JOBS   ?= 3
ALL_IDS = $(shell grep -h '^id:' evals/$(SKILL)/tasks/*.yaml | sed 's/^id: *//')
MODEL_FILE = $(subst /,_,$(subst :,_,$(OLLAMA_MODEL)))
SKILL      ?= ai-harness-regelwerk
SKILL_DIR   = skills/$(SKILL)
EVAL_YAML   = evals/$(SKILL)/eval.yaml
EVAL_MOCK   = evals/$(SKILL)/eval.mock.yaml
FIXTURES    = evals/$(SKILL)/fixtures

# Kein Bind-Mount: Skills und Evals werden beim Build per COPY ins Image gelegt
# (Stage `project`), Ergebnisse per `docker cp` aus dem Container geholt.
# Host braucht nur make + docker.
WAZA        = docker run --rm $(IMAGE)

# Ollama als eigener Provider (OpenAI-kompatibel). --network host, damit der
# Container localhost:11434 des Hosts erreicht. Der Key ist ein Platzhalter.
OLLAMA_URL      ?= http://localhost:11434/v1
OLLAMA_PROVIDER ?= openai
# Fester Judge fuer die prompt-Grader (unabhaengig vom getesteten Modell).
OLLAMA_JUDGE    ?= minimax-m3:cloud
OLLAMA_ENV       = -e COPILOT_PROVIDER=$(OLLAMA_PROVIDER) -e COPILOT_BASE_URL=$(OLLAMA_URL) \
                   -e COPILOT_WIRE_API=completions -e COPILOT_API_KEY=ollama

# $(1) = zusaetzliche docker-create-Optionen, $(2) = waza-Argumente.
# Startet den Container, kopiert /workspace/results nach ./results, raeumt auf
# und gibt den Exit-Code von waza zurueck.
define RUN_WITH_RESULTS
ctr=$$(docker create $(1) $(RUN_IMAGE) $(2)) && docker start -a $$ctr; rc=$$?; \
mkdir -p results; docker cp $$ctr:/workspace/results/. results/ >/dev/null 2>&1; \
docker rm $$ctr >/dev/null; exit $$rc
endef

.DEFAULT_GOAL := help
.PHONY: help image image-baseline run-ollama-isolated run-ollama-baseline schema-check check tokens spec-verify run run-copilot run-ollama compare shell waza-help clean

help: ## Diese Hilfe
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-16s %s\n", $$1, $$2}'

image: ## Image bauen (waza aus Quellcode, Regelwerk-ZIP verifiziert, Skills/Evals per COPY)
	docker build --target project -t $(IMAGE) .

image-baseline: ## Baseline-Image bauen (ohne Skill und ohne Regelwerk)
	docker build --target project-baseline -t $(IMAGE_BASELINE) .

schema-check: image ## Tasks/Evals/Config gegen waza-JSON-Schemas pruefen (+ Fixtures, IDs, Regex)
	docker run --rm --entrypoint python3 $(IMAGE) /opt/waza/tools/schema_check.py

check: image ## Skill-Readiness pruefen (Compliance, Token-Budget)
	$(WAZA) check $(SKILL_DIR)

tokens: image ## Tokens der Skill-Dateien zaehlen
	$(WAZA) tokens count $(SKILL_DIR)

spec-verify: image ## Eval-Abdeckung gegen SKILL.md pruefen
	$(WAZA) spec verify $(SKILL_DIR) $(EVAL_YAML)

run: image ## Geruest-Test mit Mock-Executor (offline, ohne Bewertung)
	@$(call RUN_WITH_RESULTS,,run $(EVAL_MOCK) --context-dir $(FIXTURES) -v --skip-graders --output results/mock.json)

run-copilot: image ## Evals mit echtem Modell (braucht GITHUB_TOKEN)
	@test -n "$$GITHUB_TOKEN" || { echo "GITHUB_TOKEN nicht gesetzt"; exit 1; }
	@$(call RUN_WITH_RESULTS,-e GITHUB_TOKEN $(ENTRYPOINT_OPT),run $(EVAL_YAML) --context-dir $(FIXTURES) -v --output results/copilot.json)

run-ollama: image ## Evals mit Ollama: make run-ollama OLLAMA_MODEL=<name> [TASK="<glob> ..."] [EXTRA="<waza-Flags>"] [SUFFIX=<Dateisuffix>]
	@test -n "$(OLLAMA_MODEL)" || { echo "Aufruf: make run-ollama OLLAMA_MODEL=<name> [TASK=\"<glob> ...\"]  (Modelle: ollama list)"; exit 1; }
	@$(call RUN_WITH_RESULTS,--network host $(OLLAMA_ENV) $(ENTRYPOINT_OPT),run $(EVAL_YAML) --context-dir $(FIXTURES) -v --model '$(OLLAMA_MODEL)' --judge-model '$(OLLAMA_JUDGE)' $(foreach t,$(TASK),--task '$(t)') $(EXTRA) --output results/ollama-$(subst /,_,$(subst :,_,$(OLLAMA_MODEL)))$(SUFFIX).json)

run-ollama-isolated: image ## Wie run-ollama, aber jeder Task/Trial in eigenem Container (keine Judge-Spuren frueherer Laeufe): [TASK="<ids>"] [TRIALS=n] [JOBS=n]
	@test -n "$(OLLAMA_MODEL)" || { echo "Aufruf: make run-ollama-isolated OLLAMA_MODEL=<name> [TASK=\"<ids>\"] [TRIALS=3] [JOBS=3]"; exit 1; }
	@mkdir -p results
	IMAGE='$(RUN_IMAGE)' MODEL='$(OLLAMA_MODEL)' JUDGE='$(OLLAMA_JUDGE)' EVAL_YAML='$(EVAL_YAML)' FIXTURES='$(FIXTURES)' \
	TASKS='$(if $(TASK),$(TASK),$(ALL_IDS))' TRIALS='$(TRIALS)' JOBS='$(JOBS)' EXTRA='$(EXTRA)' \
	OUT='results/ollama-$(MODEL_FILE)$(SUFFIX).json' OLLAMA_URL='$(OLLAMA_URL)' OLLAMA_PROVIDER='$(OLLAMA_PROVIDER)' tools/run_isolated.sh

run-ollama-baseline: image-baseline ## Reines Vorwissen: Baseline-Image (kein Regelwerk), --no-skills, isoliert je Task/Trial
	@$(MAKE) --no-print-directory run-ollama-isolated RUN_IMAGE=$(IMAGE_BASELINE) EVAL_YAML=evals/base/eval.yaml FIXTURES=evals/base/fixtures EXTRA='--no-skills $(BASELINE_EXTRA)' SUFFIX='-baseline$(BASELINE_SUFFIX)'

compare: image ## Ergebnisse vergleichen: make compare A=results/a.json B=results/b.json
	@test -f "$(A)" -a -f "$(B)" || { echo "Aufruf: make compare A=<datei> B=<datei>"; exit 1; }
	@ctr=$$(docker create $(IMAGE) compare /tmp/a.json /tmp/b.json) && \
	docker cp $(A) $$ctr:/tmp/a.json && docker cp $(B) $$ctr:/tmp/b.json && \
	docker start -a $$ctr; rc=$$?; docker rm $$ctr >/dev/null; exit $$rc

waza-help: image ## waza --help
	$(WAZA) --help

shell: image ## Shell im Container
	docker run --rm -it --entrypoint bash $(IMAGE)

clean: ## Ergebnisse und Image entfernen
	rm -rf results
	-docker rmi $(IMAGE)
