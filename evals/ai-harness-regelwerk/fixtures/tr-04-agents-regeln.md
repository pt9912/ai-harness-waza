# AGENTS.md (Auszug) und Notizen zur Herkunft der Regeln

## 3. Hard Rules

### 3.1 Gates werden nicht ohne ADR gelockert.
### 3.2 Cache vor dem ersten Testlauf aufwaermen.
### 3.3 Audit-Log-Eintraege tragen immer einen Zeitstempel.
### 3.4 Keine Gleitkomma-Vergleiche mit `==`.

## Notizen zur Herkunft (Vorschlag: bei jeder Regel ein "seit ..."-Feld ergaenzen)

- 3.1: folgt aus ADR-0007 und LH-QA-SUP-002.
- 3.2: als Steering-Loop-Beobachtung dreimal aufgetreten, Schwelle erreicht. Entstanden in
  der Welle `welle-cache-warmup` (Slices `slice-cache-warmup-ttl` und
  `slice-cache-warmup-job`); die Regel wurde im Welle-Closure verkoerpert.
- 3.3: ebenfalls dreimal beobachtet, aber ohne Welle verkoerpert, allein durch den Slice
  `slice-audit-log-hardening`.
- 3.4: stammt aus dem ersten Projektjahr; niemand weiss mehr, woher sie kam.
- Zeitzonen-Fehler in Exporten: bisher zweimal aufgetreten, steht im Beobachtungs-Register,
  noch keine Regel.
