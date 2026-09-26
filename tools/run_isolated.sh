#!/usr/bin/env bash
# Fuehrt jeden Task und jeden Trial in einem EIGENEN Container aus und fasst die Ergebnisse zusammen.
# Grund: Der Copilot-CLI legt Session-Logs (/root/.copilot, /tmp/copilot-tool-output-*) an, in denen der Judge-Prompt
# mit der Referenzantwort steht. In einem gemeinsamen Container finden spaetere Tasks/Trials diese Spuren per grep.
# Parameter (Umgebung): IMAGE MODEL TASKS [JUDGE EVAL_YAML FIXTURES TRIALS JOBS EXTRA OUT OLLAMA_URL OLLAMA_PROVIDER]
set -u
: "${IMAGE:?IMAGE fehlt}" "${MODEL:?MODEL fehlt}" "${TASKS:?TASKS fehlt}"
JUDGE=${JUDGE:-minimax-m3:cloud}; EVAL_YAML=${EVAL_YAML:-evals/ai-harness-regelwerk/eval.yaml}
FIXTURES=${FIXTURES:-evals/ai-harness-regelwerk/fixtures}; TRIALS=${TRIALS:-1}; JOBS=${JOBS:-3}
EXTRA=${EXTRA:-}; OUT=${OUT:-results/isolated.json}
URL=${OLLAMA_URL:-http://localhost:11434/v1}; PROV=${OLLAMA_PROVIDER:-openai}
mkdir -p results; TMP=$(mktemp -d results/iso.XXXXXX)
one() {
  id=$1; i=$2
  ctr=$(docker create --network host -e COPILOT_PROVIDER="$PROV" -e COPILOT_BASE_URL="$URL" -e COPILOT_WIRE_API=completions \
        -e COPILOT_API_KEY=ollama --entrypoint /opt/waza/tools/run_hidden.sh "$IMAGE" run "$EVAL_YAML" \
        --context-dir "$FIXTURES" -v --model "$MODEL" --judge-model "$JUDGE" --task "$id" $EXTRA --output results/one.json) || return
  docker start -a "$ctr" > "$TMP/$id.$i.log" 2>&1
  docker cp "$ctr:/workspace/results/one.json" "$TMP/$id.$i.json" > /dev/null 2>&1
  docker rm "$ctr" > /dev/null
  echo "fertig: $id (Trial $i)"
}
export -f one; export IMAGE MODEL JUDGE EVAL_YAML FIXTURES EXTRA URL PROV TMP
for id in $TASKS; do for i in $(seq 1 "$TRIALS"); do echo "$id $i"; done; done | xargs -P "$JOBS" -L1 bash -c 'one "$0" "$1"'
python3 "$(dirname "$0")/merge_results.py" "$TMP" "$OUT" && echo "Ergebnis: $OUT (Einzelergebnisse und Logs: $TMP)"
