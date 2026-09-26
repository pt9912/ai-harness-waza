# Lastenheft

**Status:** Freigegeben · **Version:** 1.3

## Anforderungen

### LH-FA-020 Export

Das System exportiert Berichte als CSV mit höchstens 100 Zeilen pro Datei.

- Happy: Given ein Bericht mit 80 Zeilen, When Export, Then eine CSV-Datei.
- Boundary: Given 100 Zeilen, When Export, Then eine CSV-Datei.
- Negative: Given 101 Zeilen, When Export, Then Fehlermeldung, keine Datei.
- Out of Scope: Export als PDF.

## Historie

| Datum | Änderung | Version | Verweis |
| --- | --- | --- | --- |
| 2025-01-14 | LH-FA-020 angelegt | 1.0 | CR-2025-003 |
| 2025-04-02 | LH-FA-020: Zeilenlimit von 50 auf 100 | 1.3 | CR-2025-011 |
