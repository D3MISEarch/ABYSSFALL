# Combat Design

## Confirmed

- Combat should be weighty, dangerous, and readable (stated project value; see [`GAMEPLAY_BIBLE.md`](GAMEPLAY_BIBLE.md)).
- Combat is fixed-camera 3D action combat in the current prototype (`PROJECT_OVERVIEW.md`).
- Ability execution always follows one pipeline: **validate → spend cost → start cooldown → execute effects**, owned by `AbilityExecutor`. A rejected attempt spends no resource and starts no cooldown ([ADR-013](../ADR/ADR-013-ABILITY-RESOURCE-ARCHITECTURE.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md), and see [`../Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md)).
- Final stats rebuild deterministically as `(Base + Flat) × (1 + Additive%) × Multiplicative% factors`; damage calculations consume a frozen stat snapshot ([ADR-012](../ADR/ADR-012-STAT-MODIFIER-PIPELINE.md)).
- Each playable class has a distinct class resource with its own rules, not a reskin of another class's resource: Void Warlock uses **Corruption**; The Penitent uses **Fervor**. The full Fervor gain/spend/threshold/decay specification is in `design/FERVOR_SYSTEM_V1.md` (repository root) — that document is authoritative for Fervor and is not restated here.
- The Penitent's core mechanic is Rite Marks: blade attacks carve partial marks, abilities place ground sigils, completing a pattern activates its effect, and health can be spent to force an incomplete rite to activate. Full ability specs (Ritual Blade, Seal of Binding, Brand of Ruin, Martyr's Chain, Sacrament, Ashen Procession, Cathedral of Flesh) are in `docs/PENITENT_CLASS.md` (repository root, lowercase `docs/`).
- Void Warlock's confirmed kit: Void Bolt, Shadow Step, Grasping Rift, gravity/portal/soul-collection/summoning tools (`PROJECT_OVERVIEW.md`).

## Proposed

- The Sigil Cultist direction (see [`CLASS_DESIGN.md`](CLASS_DESIGN.md)) implies a combat loop that mixes ritual/sigil casting with selective melee interaction — this is a class-identity constraint from project direction, not yet a specified ability kit.
- Legendary items are intended to alter ability behavior rather than only scale numbers (`design/PENITENT_ITEM_POOL_V1.md` drop philosophy) — see [`ITEMIZATION.md`](ITEMIZATION.md) for the itemization side of this.

## Open Questions

- Exact numeric tuning for combat feel (hit-stop, enemy density, TTK targets) is explicitly marked as not-yet-final in `PROJECT_OVERVIEW.md` Phase 3 ("tune movement, hit feel, enemy density...").
- Whether any future class will break the fixed-camera 3D convention is undecided.

## Deprecated

None currently.
