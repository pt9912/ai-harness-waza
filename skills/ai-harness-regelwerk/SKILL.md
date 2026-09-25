---
name: ai-harness-regelwerk
description: |
  USE FOR: Arbeit nach dem AI-Harness-Regelwerk — Spec (Lastenheft, Spezifikation,
  Architektur), ADRs, Slices und Wellen, Roadmap, Carveouts, AGENTS.md, Review- und
  Verification-Harness, Quality Gates, Harness-Bootstrap.
  DO NOT USE FOR: allgemeine Programmier-, Code- oder Alltagsfragen ohne Bezug zum Harness.
---

# AI-Harness-Regelwerk

Dünner Einstieg in das Betriebsregelwerk für Code-Agenten. Die Regeln stehen
ausschließlich in `regelwerk/`; diese Datei dupliziert sie nicht.

## Ablageort

Alle Pfade in dieser Datei (`regelwerk/…`, `templates/…`) sind relativ zum Ordner dieser
`SKILL.md`, **nicht** zum Arbeitsverzeichnis — das ist oft ein leeres Temp-Verzeichnis.
Dieser Skill liegt unter `/workspace/skills/ai-harness-regelwerk/`; der Index ist also
`/workspace/skills/ai-harness-regelwerk/regelwerk/README.md`. Nicht per `ls`/`find` suchen.

## Vorgehen

1. `regelwerk/README.md` öffnen — das ist der Index.
2. Nur den Abschnitt laden, den die aktuelle Entscheidung braucht. Nie das ganze Regelwerk.
3. Skelette für neue Artefakte stehen unter `templates/`.
4. Bei Konflikt zwischen Briefing und kanonischer Quelle gilt die kanonische Quelle
   (`regelwerk/grundlagen-source-precedence.md`).

## Beispiele

- „Wie lege ich einen Carveout an?" → `regelwerk/modul-07-carveouts.md`, Vorlage unter `templates/docs/plan/carveouts/`.
- „Was gilt bei Widerspruch zwischen AGENTS.md und Spec?" → `regelwerk/grundlagen-source-precedence.md`.

## Fehlerfall

Passt kein Abschnitt zur Frage oder widersprechen sich zwei Abschnitte: nicht raten,
den Widerspruch benennen und die Quelle mit Vorrang laut Source Precedence anwenden.

## Referenzen

- `regelwerk/README.md` — Index aller Abschnitte
- `templates/README.md` — Index der Vorlagen
