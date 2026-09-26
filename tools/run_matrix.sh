#!/usr/bin/env bash
# Messmatrix: Modelle x Bedingungen (mit Skill / Baseline ohne Regelwerk), TRIALS Trials je Task, isoliert je Container.
# Bereits vorhandene Ergebnisdateien werden uebersprungen (fortsetzbar). Aufruf: TAG=mx tools/run_matrix.sh
set -u
MODELS=${MODELS:-"glm-5.3-flash:cloud deepseek-v4.1-flash:cloud"}; TRIALS=${TRIALS:-3}; JOBS=${JOBS:-3}; TAG=${TAG:-mx}
fname() { echo "results/ollama-$(echo "$1" | sed 's#[/:]#_#g')$2.json"; }
for m in $MODELS; do
  f=$(fname "$m" "-$TAG-skill")
  if [ -f "$f" ]; then echo "[matrix] uebersprungen (vorhanden): $f"; else
    echo "[matrix] $(date +%H:%M) $m mit Skill"; make --no-print-directory run-ollama-isolated OLLAMA_MODEL="$m" TRIALS="$TRIALS" JOBS="$JOBS" SUFFIX="-$TAG-skill"; fi
  f=$(fname "$m" "-baseline-$TAG")
  if [ -f "$f" ]; then echo "[matrix] uebersprungen (vorhanden): $f"; else
    echo "[matrix] $(date +%H:%M) $m Baseline (ohne Regelwerk)"; make --no-print-directory run-ollama-baseline OLLAMA_MODEL="$m" TRIALS="$TRIALS" JOBS="$JOBS" BASELINE_SUFFIX="-$TAG"; fi
done
echo "[matrix] $(date +%H:%M) fertig"
