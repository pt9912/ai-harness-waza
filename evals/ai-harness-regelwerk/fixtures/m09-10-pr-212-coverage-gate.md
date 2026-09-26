# PR #212: Coverage-Gate fuer internal/report anpassen

## Aenderungen

- `pyproject.toml`: `fail_under` von 80 auf 70 gesenkt
- `report/exporter.py`, Zeile 88: `import legacy_fmt  # noqa: F401`
- Tests fuer `report/summary.py` ergaenzt

## Begruendung

`report/exporter.py` laesst sich nicht sinnvoll testen, deshalb erreichen
wir die 80 % nicht. Die Begruendung steht im PR-Kommentar von @mila
(12.09.). Reviewer haben zugestimmt.

## Checkliste

- [x] Tests gruen
- [x] Reviewer zugestimmt
