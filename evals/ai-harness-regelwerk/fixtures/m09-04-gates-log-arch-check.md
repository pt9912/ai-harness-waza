# Terminal-Log

```text
$ make gates
[ok]   lint
[ok]   unit-tests
[ok]   noqa-gate
[FAIL] arch-check
       internal/handler/order.go imports internal/db
       verletzt ADR-0004 (Handler nur ueber Repository-Interface)
make: *** [gates] Error 1
```

# Auszug aus docs/plan/planning/in-progress/slice-064-order-export.md

## §1 Ziel und Abgrenzung

Bestellexport als CSV. Nicht im Umfang: Aenderungen am Rechnungsmodul.

## §2 Bezuege

- REQ-041 (Export)
- ADR-0004 (Schichtung)

## §3 Dateien

| Datei | Aenderung |
|---|---|
| internal/handler/order.go | Export-Endpunkt |
| internal/db/orders.go | Abfrage fuer Export |
