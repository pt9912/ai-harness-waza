feat(index): Tie-Break bei gleichem Score deterministisch machen

Treffer mit identischem Score werden nach Dokument-ID aufsteigend
sortiert. Damit liefert dieselbe Anfrage immer dieselbe Reihenfolge.

Der Vergleich sitzt in ranking/compare.py; die Tests dazu liegen in
tests/test_ranking_determinism.py.

Refs: SPEC-014, ARC-006, LH-FA-12, ADR-0009
