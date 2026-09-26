#!/bin/sh
# Startet waza und loescht kurz danach die Task- und Eval-Dateien (enthalten die Referenzantworten der Judges),
# damit der getestete Agent sie nicht per Dateisuche liest. Die Fixtures bleiben.
# Voraussetzung: waza hat die Tasks beim Start vollstaendig eingelesen (getestet: der Lauf endet ohne sie).
# Gegen Judge-Spuren fruehrerer Sessions (Copilot-Logs) hilft nur Isolation: siehe run_isolated.sh.
# NET_ISOLATE=1 (braucht --cap-add SYS_ADMIN --cap-add NET_ADMIN und --network host): waza und der Agent laufen in einem eigenen, leeren
# Netz-Namespace ohne Internet. Ollama (127.0.0.1:11434 des Hosts) bleibt ueber ein socat-Relay per Unix-Socket erreichbar
# (Unix-Sockets sind nicht netns-gebunden). Danach werden SYS_ADMIN/NET_ADMIN aus dem Bounding-Set entfernt, damit der
# Agent nicht per nsenter in den Host-Namespace zurueck kann. Betrifft nur diesen Container, nicht den Host.
# HIDE_FIXTURES=1: loescht auch die Fixtures (--context-dir). Die Fixtures enthalten Regelwerk-Auszuege ALLER Tasks; ein
# Agent ohne Regelwerk fand sonst dort die Regeln (Baseline). waza kopiert die Dateien des laufenden Tasks vor dem
# Prompt in dessen Arbeitsverzeichnis, deshalb genuegt es bei Einzel-Task-Laeufen, sie nach dem Start zu loeschen.
# Aufruf wie waza: run_hidden.sh run <eval.yaml> ...
if [ "${NET_ISOLATE:-0}" = 1 ]; then
  rm -f /run/ollama.sock
  socat UNIX-LISTEN:/run/ollama.sock,fork,mode=600 TCP:127.0.0.1:11434 &
  for _ in 1 2 3 4 5 6 7 8 9 10; do [ -S /run/ollama.sock ] && break; sleep 0.2; done
  export NET_ISOLATE=0
  exec unshare --net sh -c '
    ip link set lo up
    socat TCP-LISTEN:11434,bind=127.0.0.1,fork,reuseaddr UNIX-CONNECT:/run/ollama.sock &
    sleep 0.5
    exec setpriv --bounding-set=-sys_admin,-net_admin,-sys_ptrace --inh-caps=-sys_admin,-net_admin,-sys_ptrace "$0" "$@"
  ' "$0" "$@"
fi
waza "$@" &
pid=$!
sleep "${HIDE_AFTER:-4}"
rm -rf /workspace/evals/*/tasks /workspace/evals/*/eval*.yaml
[ "${HIDE_FIXTURES:-0}" = 1 ] && rm -rf /workspace/evals/*/fixtures
echo "[run_hidden] Task- und Eval-Dateien entfernt; verbleibend: $(ls /workspace/evals/* 2>/dev/null | tr '\n' ' ')"
wait $pid
