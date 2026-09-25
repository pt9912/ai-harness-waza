IMAGE      ?= waza:local
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
OLLAMA_ENV       = -e COPILOT_PROVIDER=$(OLLAMA_PROVIDER) -e COPILOT_BASE_URL=$(OLLAMA_URL) \
                   -e COPILOT_WIRE_API=completions -e COPILOT_API_KEY=ollama

# $(1) = zusaetzliche docker-create-Optionen, $(2) = waza-Argumente.
# Startet den Container, kopiert /workspace/results nach ./results, raeumt auf
# und gibt den Exit-Code von waza zurueck.
define RUN_WITH_RESULTS
ctr=$$(docker create $(1) $(IMAGE) $(2)) && docker start -a $$ctr; rc=$$?; \
mkdir -p results; docker cp $$ctr:/workspace/results/. results/ >/dev/null 2>&1; \
docker rm $$ctr >/dev/null; exit $$rc
endef

.DEFAULT_GOAL := help
.PHONY: help image check tokens spec-verify run run-copilot run-ollama compare shell waza-help clean

help: ## Diese Hilfe
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-16s %s\n", $$1, $$2}'

image: ## Image bauen (waza aus Quellcode, Regelwerk-ZIP verifiziert, Skills/Evals per COPY)
	docker build --target project -t $(IMAGE) .

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
	@$(call RUN_WITH_RESULTS,-e GITHUB_TOKEN,run $(EVAL_YAML) --context-dir $(FIXTURES) -v --output results/copilot.json)

run-ollama: image ## Evals mit Ollama: make run-ollama OLLAMA_MODEL=<name> [TASK=<glob>]
	@test -n "$(OLLAMA_MODEL)" || { echo "Aufruf: make run-ollama OLLAMA_MODEL=<name> [TASK=<glob>]  (Modelle: ollama list)"; exit 1; }
	@$(call RUN_WITH_RESULTS,--network host $(OLLAMA_ENV),run $(EVAL_YAML) --context-dir $(FIXTURES) -v --model '$(OLLAMA_MODEL)' $(if $(TASK),--task '$(TASK)') --output results/ollama-$(subst /,_,$(subst :,_,$(OLLAMA_MODEL))).json)

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
