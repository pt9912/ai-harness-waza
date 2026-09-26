# Baseline-Audit

Adoptierter Stand (harness/conventions.md): `v6.8.0`
Neuestes Kurs-Release laut Release-Liste: `v6.10.0`

Der Delta-Review laeuft ueber die geaenderten Dateien. Ausgabe von
`git diff --stat v6.8.0 v6.10.0 -- .harness/baseline/` (nach Re-Vendoring):

```
 .harness/baseline/v6.10.0/regelwerk/grundlagen-harness-dateien.md | 41 ++++--
 .harness/baseline/v6.10.0/regelwerk/modul-02-harness-bootstrap.md | 23 +--
 .harness/baseline/v6.10.0/regelwerk/modul-03-spec.md              |  9 +-
 .harness/baseline/v6.10.0/regelwerk/modul-06-roadmap.md           | 17 ++-
 .harness/baseline/v6.10.0/regelwerk/modul-09-implementierung.md   | 12 +-
 .harness/baseline/v6.10.0/regelwerk/modul-13-quality-gates.md     | 30 ++--
 6 files changed
```

Inhalt von `.harness/baseline/v6.10.0/regelwerk/` (vollstaendig):

```
README.md
grundlagen-begriffe.md
grundlagen-bootstrap.md
grundlagen-durchsetzungsschicht.md
grundlagen-harness-dateien.md
grundlagen-klassifikation.md
grundlagen-referenz-richtung.md
grundlagen-source-precedence.md
grundlagen-traceability.md
modul-00-einfuehrung.md
modul-01-entwicklungszyklus.md
modul-02-harness-bootstrap.md
modul-03-spec.md
modul-04-adrs.md
modul-05-planning-harness.md
modul-06-roadmap.md
modul-07-carveouts.md
modul-08-agentenrollen.md
modul-09-implementierung.md
modul-10-review-harness.md
modul-11-verification.md
modul-12-replay-evaluierung.md
modul-13-quality-gates.md
modul-14-docker-harness.md
modul-15-observability.md
modul-16-produktiver-betrieb.md
```
