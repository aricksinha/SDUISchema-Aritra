# SDUISchema

The contract layer. Pure `Codable`, zero Apple UI framework imports —
if this target ever needs `import SwiftUI`, something has leaked
across the seam.

## The three contracts hiding inside "the schema"

Don't version these as one thing — they change at different rates
and for different reasons:

| Contract | What it covers | Changes | Represented as |
|---|---|---|---|
| **Structure** | `Node`/`Screen` shape itself | Rarely | `structureVersion` — bump on genuine breaking shape changes only |
| **Vocabulary** | node `type`s, style token names | Constantly | Open `String`, never versioned — unknown values degrade, never fail |
| **Behavior** | `Action` cases | Occasionally | A closed, client-owned enum (lives in `SDUIActions`), reviewed like a security boundary |

Conflating these is the most common versioning mistake: it turns "a
designer added a color token" into a forced client update.

## Decode rules (Postel's Law, applied to Codable)

- **Required fields throw.** Only `Node.id` and `Node.type` (and
  `Screen.screenId`/`structureVersion`/`root`). Everything else is
  optional and degrades to `nil` on failure — see `Node.swift`'s
  `decodeDegrading`.
- **Unknown keys are always ignored.** Free with `Codable`'s
  `CodingKeys` — never switch to a strict/exhaustive decode mode.
- **The array/table element type is what makes decode resilient, not
  a decoder flag.** `ChildSlot` and `ComponentSlot` never rethrow —
  that's the actual mechanism behind "one bad node doesn't blank the
  screen." There is no `JSONDecoder` option that achieves this; it
  has to be the element type.
- **The root node is the one deliberate exception.** An unparseable
  root has no partial UI worth saving — let it throw, and handle the
  fallback (cached last-good screen, error state) one layer up, in
  the networking/state code, not here.
- **Never repurpose a field name once shipped**, even after it's
  unused. Old cached payloads and slow-to-update clients may still
  reference it.

## Experimental fields

Prefix a node `type` or a `props` key with `x-` while it's unstable
and not yet committed to the vocabulary (`"type": "x-newCarousel"`).
Signals "may change or disappear without a structural version bump"
to anyone reading a payload or reviewing a diff.

## Contract fixtures are the source of truth, not this README

`Tests/SDUISchemaTests/Fixtures/` is what backend CI should decode
against on every relevant PR — not a wiki page, not tribal knowledge.
If a backend change breaks a fixture here, that's the contract
catching a break before it ships, exactly as intended. Add a new
fixture for every new node type and every new edge case you want
guaranteed to never regress.

## Governance

Schema changes go through the same review a public API change would:
a diff + an updated/added fixture + sign-off from iOS, backend, and
(for vocabulary/token changes) design — not a Slack message. One
named owner, so there's a single decision-maker when a change is
ambiguous.
