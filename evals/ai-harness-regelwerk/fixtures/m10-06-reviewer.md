# Reviewer-Skill (.harness/skills/reviewer.md)

Rolle: Code-Review des fertigen Diffs.

## Klassifikation

- HIGH: SQL-Injection, Secrets im Code, Path Traversal, Nullpointer-Zugriffe,
  unbehandelte Exceptions in Request-Handlern
- MEDIUM: fehlende Tests fuer neuen Code, zu grosse Funktionen (> 80 Zeilen),
  unklare Fehlermeldungen
- LOW: Namensinkonsistenz, Formatierung, veraltete Kommentare
- INFO: Hinweise ohne Aktion

## Output-Schema

Pro Finding: Datei, Zeile, Kategorie, Beschreibung.
Am Ende eine Summary-Zeile mit der Anzahl je Kategorie.
