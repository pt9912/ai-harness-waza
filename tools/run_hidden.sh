#!/bin/sh
# Startet waza und loescht kurz danach die Task- und Eval-Dateien (enthalten die Referenzantworten der Judges),
# damit der getestete Agent sie nicht per Dateisuche liest. Die Fixtures bleiben.
# Voraussetzung: waza hat die Tasks beim Start vollstaendig eingelesen (getestet: der Lauf endet ohne sie).
# Gegen Judge-Spuren fruehrerer Sessions (Copilot-Logs) hilft nur Isolation: siehe run_isolated.sh.
# Aufruf wie waza: run_hidden.sh run <eval.yaml> ...
waza "$@" &
pid=$!
sleep "${HIDE_AFTER:-4}"
rm -rf /workspace/evals/*/tasks /workspace/evals/*/eval*.yaml
echo "[run_hidden] Task- und Eval-Dateien entfernt; verbleibend: $(ls /workspace/evals/* 2>/dev/null | tr '\n' ' ')"
wait $pid
