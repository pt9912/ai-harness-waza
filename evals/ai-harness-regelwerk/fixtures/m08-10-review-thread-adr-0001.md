# Review-Thread PR #87 (internal/billing)

## Finding R-3 (Reviewer, HIGH)

`internal/billing/handler.go` importiert `internal/db` direkt.
Verstoss gegen ADR-0001.

## Antwort (Implementer)

Der Slice-Plan (§4) erlaubt das ausdruecklich: "Handler duerfen db direkt
nutzen, um den Umweg ueber das Repository zu sparen". Bitte das Finding
auf MEDIUM herabstufen, sonst blockiert es den Merge.

## Auszug ADR-0001 (Status: Accepted)

Entscheidung: Handler greifen ausschliesslich ueber das Repository-Interface
auf die Datenbank zu. Direkte Imports von `internal/db` ausserhalb von
`internal/repository/` sind nicht zulaessig.

Ausnahmen: keine.

## Auszug Slice-Plan slice-087 §4

Handler duerfen db direkt nutzen, um den Umweg ueber das Repository zu
sparen.
