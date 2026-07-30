# ADR-021 — Voidbringer Combat State, Ability Charge, and Force Ownership

## Status

OWNER APPROVED — PENDING MERGE

- **Proposal date:** 2026-07-28
- **Owner approval date:** 2026-07-28
- **Human owner:** D3MISEarch
- **Implementation authority:** NONE UNTIL THIS OWNER-APPROVED ADR IS MERGED AND THE RESULTING MAIN SHA IS RECORDED
- **Primary tracker:** Issue #97
- **First dependent implementation:** Issue #89

## 1. Context

The current playable Voidbringer compatibility path uses the durable class ID `void_warlock`. `CharacterFactory` creates `VoidWarlockCharacter`, which wraps the legacy playable node and shares the `RuntimeSession` already created and bound by the playable progression bridge.

The live runtime already establishes these generic authorities:

- one `RuntimeSession` per play session;
- one session-owned `RuntimeEventBus`;
- one session-owned `AbilityExecutor`;
- one `RuntimeCharacter` per bound build;
- transactional `RuntimeSession.bind_character()`;
- cooldown state keyed by build and ability inside `AbilityExecutor`;
- persistent data written only through the existing persistence boundary.

The approved Voidbringer foundation adds several concerns that do not belong in the generic session root or the legacy player script:

- transient Mass Anchors and their carriers, stages, caps, replacement and expiry;
- Fold Line geometry;
- transient Instability and Breach state;
- generic charged-ability and recharge support;
- spatial force request/result conversion;
- a one-pass structured damage result reporting confirmed critical state;
- class-specific command, target and gameplay orchestration.

ADR-011 and ADR-017 are both marked `Proposed`. This ADR does not claim that either was previously ratified. It adopts the applicable ownership intent, reconciles it with live code, and records the decision required for the Voidbringer foundation.

## 2. Decision summary

1. `RuntimeSession`, `RuntimeEventBus`, `AbilityExecutor`, `RuntimeCharacter`, persistence and target locomotion remain the existing generic authorities.
2. `VoidWarlockCharacter` may compose one character-combat-scoped `VoidbringerController` after the existing session/runtime bind succeeds.
3. The controller owns only class-specific transient state and orchestration. It creates no second session, event bus, resource pool, cooldown ledger, charge ledger, movement owner or persistence owner.
4. `AbilityExecutor` and `AbilityRuntime` gain generic charge/recharge support and remain the sole generic cooldown/charge transaction authority.
5. `ForceResolver` is a pure deterministic request-to-result converter. Target locomotion owners apply results.
6. Instability changes synchronously exactly once after a successful executor commit and never from an event-bus observer.
7. All new world/combat state remains transient. The durable class ID remains `void_warlock`; no save-schema migration occurs in this milestone.

## 3. Character-combat-scoped controller

`VoidWarlockCharacter` may own one optional `VoidbringerController` associated with its active playable lifetime.

The controller is configured only with explicit references to:

- the playable owner;
- the already-bound `RuntimeSession`;
- that session's active `RuntimeCharacter`;
- the effective compatibility loadout projected by the existing playable/runtime bridge.

The controller:

- does not discover services through the scene tree;
- does not construct a `RuntimeSession` or `RuntimeCharacter`;
- performs no disk I/O;
- never branches generic `RuntimeSession` behavior on class ID;
- owns no generic item, reward, health, damage, resource, cooldown, charge, movement or save state;
- may coordinate bounded class-specific skill/projectile/field instances after a successful ability transaction.

This state is character-combat-scoped rather than a generic session service because Anchors, Fold Lines, Instability and Breach are Voidbringer rules attached to one active playable body. Keeping them out of `RuntimeSession` prevents class conditionals from entering the generic composition root and isolates future simultaneous characters or sessions.

## 4. Class-specific transient owners

`VoidbringerController` composes the following single-purpose owners.

### 4.1 `AnchorManager`

Owns:

- stable transient Anchor IDs;
- carrier reference and carrier type;
- carrier-local/world placement data;
- Anchor Mass in the canonical `0–100` range;
- Dormant/Dense/Critical stage derivation;
- cap, deterministic replacement, expiry and invalid-carrier cleanup;
- resolving/removed state preventing duplicate Collapse;
- Anchor lifecycle facts emitted after successful mutation.

It does not deal damage, apply force, spend resources, run ability cooldowns or persist world state.

### 4.2 `FoldLineManager`

Owns:

- deterministic line identities between valid active Anchors;
- endpoint and segment snapshots;
- crossing/intersection queries;
- line creation/removal facts driven by Anchor lifecycle.

It owns no collision shape, damage, force, target movement or presentation state.

### 4.3 `InstabilityController`

Owns:

- transient Instability value and timing;
- decay-delay and decay rules;
- Breach generation, entry, duration/drain and end resolution;
- later Closure-extension, Clean Closure and Spatial Recoil state;
- read-only class multipliers exposed to dependent skills;
- once-only generation-scoped success/failure resolution.

It does not replace `RuntimeCharacter.class_resource`; Corruption remains the durable compatibility class resource during this migration.

### 4.4 `VoidbringerAbilityCatalog`

Provides immutable definitions using approved stable IDs. It is not a runtime state owner.

### 4.5 `ForceResolver`

Performs pure request/profile-to-result conversion as specified in Section 10.

## 5. Runtime binding and replacement

### 5.1 Initial bind

Class binding begins only after the existing playable progression bridge successfully creates/binds its `RuntimeSession` and confirms the active `RuntimeCharacter`.

The class-specific bind must:

1. validate the session, active character, playable owner, class ID and effective loadout references;
2. construct/configure a candidate controller without enabling commands;
3. connect candidate-owned signals using a new generation token;
4. confirm that the candidate references the same active session and character;
5. only then install the candidate on `VoidWarlockCharacter` and enable class commands.

Failure leaves the existing playable runtime intact and the new class commands disabled. It creates no partially active controller.

### 5.2 Rebind/replacement

A rebind is transactional across the existing session and class controller:

1. `RuntimeSession.bind_character()` completes successfully first;
2. a candidate controller binds to the newly active runtime character;
3. only after candidate success are old class commands disabled and the old controller torn down;
4. executor state for the old build may be cleared only after the successful replacement or during real session teardown;
5. a failed runtime rebind or failed candidate bind preserves the previously active runtime/controller and may not clear its executor state.

### 5.3 Generation token

Every successful class bind receives a monotonically increasing controller generation token. Delayed projectile, field, tween, timer or event callbacks must carry/check the generation they were created under. A stale generation cannot mutate the active controller or release resources owned by a newer generation.

## 6. Death and teardown

### 6.1 Combat death

On playable death:

1. disable new class commands;
2. cancel/unbind active class input requests;
3. invalidate the current combat generation;
4. clear Anchors, Fold Lines, Instability/Breach and bounded class skill instances;
5. remove source-keyed temporary modifiers belonging to this combat lifetime.

The session/runtime references may remain if the existing respawn route retains them, but all character-combat state is empty before play resumes.

### 6.2 Rebind, menu return and scene/session teardown

Use this order:

1. disable commands;
2. unbind input/request paths;
3. disconnect controller-owned signals;
4. invalidate the generation token;
5. clear all class-specific transient state and bounded instances;
6. remove controller-owned modifier sources through their authoritative generic owners;
7. clear old-build executor state only at the successful replacement/session-teardown boundary;
8. release session, runtime-character and playable references.

Cleanup is idempotent. Repeated teardown callbacks are no-ops after the first terminal transition.

## 7. Ability definition and runtime charge extension

The existing generic ability system is extended rather than special-casing Mass Brand.

### 7.1 Immutable definition fields

`AbilityDefinition` may add:

- `maximum_charges: int = 0`;
- `recharge_seconds: float = 0.0`;
- `instability_delta: float = 0.0` as class metadata consumed by the controller, not the executor;
- `slot_type`;
- immutable tags/metadata required for validation and presentation.

The authoritative `slot_type` values are `ACTIVE_SKILL`, `DEDICATED_ACTION`, `BASIC_ATTACK`, `UNIVERSAL_EVADE`, and `ULTIMATE`. The six configurable active positions are loadout indices under `ACTIVE_SKILL`, not six separate definition categories.

### 7.2 Backward-compatible modes

- `maximum_charges == 0`: cooldown-only ability. Existing behavior remains unchanged; no charge state is created or checked.
- `maximum_charges > 0`: charge-enabled ability. Initial current charges equal `maximum_charges`.
- `maximum_charges < 0`: invalid definition.
- charge-enabled definitions require finite `recharge_seconds > 0.0`; zero, negative or non-finite recharge is invalid rather than silently creating infinite/immediate behavior.

### 7.3 Charge consumption and recharge

For a charge-enabled ability:

- successful executor commit consumes exactly one charge;
- zero charges rejects before resource spending, cooldown liability, Instability or gameplay effects;
- recharge intervals advance sequentially rather than in parallel: only one missing-charge interval accumulates progress at a time, regardless of missing-charge count;
- each completed interval restores exactly one charge;
- a single tick may nevertheless complete multiple consecutive intervals when its scaled delta is large enough; excess delta carries into each next interval until the delta is exhausted or charges are full;
- this large-delta loop is deterministic;
- when full, recharge progress is reset to zero and no hidden progress accumulates;
- charge consumption, cooldown liability and the structured commit result occur atomically.

A definition may combine charges with a post-cast cooldown only when explicitly specified. The executor remains the owner of both checks and returns both facts in one result.

### 7.4 Source-keyed recharge-rate modifiers

`AbilityRuntime` owns a map keyed by stable source ID. Each modifier contains a finite positive rate multiplier and optional bounded remaining duration. The only permitted duplicate-source modes are:

- `REPLACE`: replace the existing source's multiplier and remaining duration with the incoming values.
- `REFRESH_DURATION`: when the source exists, preserve its current multiplier and replace its remaining duration with the incoming duration; when the source does not exist, create it using the incoming multiplier and duration.

When a caller omits the mode, it defaults to `REPLACE`. Adding the same source never creates a duplicate entry.

- the effective recharge rate is calculated deterministically from modifiers in sorted source-ID order;
- removal names the exact source;
- duration ticking and expiry occur in the executor/runtime ability clock;
- modifiers do not grant charges directly;
- full-charge state does not bank modified progress;
- death/rebind/teardown removes sources associated with the ending combat generation;
- class controllers request add/remove operations but never own a parallel modifier timer.

## 8. Command/loadout and executor boundary

The class controller owns command mapping and class-specific preflight:

- map input to six active slots, dedicated Closure, basic attack, universal evade and ultimate;
- project an effective compatibility loadout for old empty saves without rewriting durable data;
- verify that the command maps to an equipped slot/action;
- validate target, Anchor, line or destination snapshots required before committing an ability;
- reject locally when class-specific preflight fails, with no executor transaction or success presentation.

`AbilityExecutor` owns generic transaction validation:

- known immutable definition;
- active bound build/runtime character;
- unlocked ability through the runtime character;
- class-resource availability and spending;
- cooldown availability/state;
- charge availability/state;
- recharge state/modifiers;
- one structured commit or rejection result;
- one gameplay event emission.

The executor does not read `BuildData`, hotbar UI state, Anchor state, Fold Lines, Instability or controller internals.

After a successful executor commit, the controller resolves the class-specific gameplay exactly once. A committed projectile may miss; that does not roll back cost, cooldown, charge or Instability.

## 9. Instability transaction rule

`AbilityDefinition.instability_delta` is immutable class metadata. `AbilityExecutor` reports the committed ability ID/transaction facts but does not mutate Instability.

Immediately after a successful executor result, the bound `VoidbringerController` synchronously requests one Instability mutation from `InstabilityController` using the transaction/generation identity.

- rejected attempts add no Instability;
- one transaction ID may mutate Instability once;
- event-bus listeners are observational and may not add it again;
- class gameplay resolution occurs after the committed transaction and Instability mutation;
- a stale generation rejects the mutation and subsequent class resolution.

## 10. Spatial force boundary

`ForceResolver` is a stateless deterministic converter.

### 10.1 Request/profile inputs

Immutable inputs may include:

- source/result identity and controller generation;
- force mode, origin/center and direction;
- abstract force magnitude;
- duration/impulse profile;
- source tags;
- target-owned response profile;
- approved contextual facts such as stored-force units or collision result.

### 10.2 Result

The immutable result may report:

- accepted/resisted magnitude;
- target translation/velocity request;
- rotation request;
- stance, armor-stress, internal-Mass or Anchor-Mass conversion facts;
- duration/decay facts;
- rejection/conversion reason;
- telemetry identity.

### 10.3 Prohibited behavior

`ForceResolver` does not:

- move or rotate a node;
- call `move_and_slide()`;
- deal damage;
- mutate health, AI, Anchors, Instability or rewards;
- tick effects;
- discover targets;
- own collision shapes or a global registry.

Target locomotion owners apply accepted movement/rotation results. Target health/stance owners apply separately approved consequence results. Bosses/immovable targets convert resisted force through supported channels rather than returning a generic immunity presentation.

Concrete target response profiles, supported conversion channels, channel priority/order, conversion magnitudes, and gameplay consequences are selected by later owner-approved gameplay issues and implementation contracts. This ADR decides only pure request/result ownership, target-owned application, deterministic conversion vocabulary, and that resisted force may not become a generic immunity result. It does not approve boss balance or Issue #95's final conversion values.

## 11. Structured outgoing-damage compatibility

The current playable combat projection may add a structured result path reporting at minimum:

- pre-critical resolved amount;
- final resolved damage;
- confirmed critical state.

The structured method performs class-tree/stat contribution and deterministic critical consumption exactly once.

The legacy integer method delegates once to the structured method and returns only final damage. New gameplay calls the structured method directly and never calls both methods for one hit. Target mitigation, health, death and rewards remain target/existing-owner responsibilities.

This is a compatibility bridge for skill coefficients and confirmed critical placement. It is not a final universal itemization formula.

## 12. Persistence and compatibility

- durable class ID remains `void_warlock`;
- `RuntimeCharacter.class_resource` remains Corruption;
- Instability is separate transient class state;
- approved stable ability IDs use the `vb.*` namespace;
- existing `BuildData.skills.unlocked_abilities` and `BuildData.hotbar` remain durable source fields;
- old empty saves may receive an idempotent effective compatibility projection without rewriting a non-empty hotbar or silently unlocking later skills;
- no save-schema/version migration occurs.

The following are not persisted:

- world Anchors or carriers;
- Fold Lines;
- Instability or Breach;
- barriers or Spatial Recoil;
- force requests/results;
- cooldowns, charges or recharge progress;
- temporary recharge modifiers;
- bounded skill/projectile/field instances;
- controller generation tokens.

## 13. Events and presentation

`RuntimeEventBus` remains the sole gameplay event bus. Producers emit confirmed facts after authoritative mutations.

Presentation:

- consumes confirmed results;
- may pool/render through a scene-owned presentation boundary;
- adds no gameplay collision descendants;
- owns no damage, force, Anchor, Fold Line, Instability, cooldown, charge, reward or persistence state;
- cannot infer successful gameplay from animation timing;
- cannot mutate gameplay through cleanup.

No Voidbringer autoload or second event bus is allowed.

## 14. Session and future multi-character isolation

Every controller references one explicit playable/session/runtime-character tuple and one generation. Static/global class state is prohibited.

Two sessions or future simultaneous characters therefore have distinct:

- controllers;
- managers;
- executor build keys;
- event buses;
- transient effects and generation tokens.

This ADR does not define network authority, replication, rollback or co-op ownership. Those require a future decision.

## 15. Rejected alternatives

1. Put Anchors, Fold Lines and Instability into legacy `player.gd`.
2. Add `void_warlock` branches to `RuntimeSession`.
3. Widen `CharacterContract` with Voidbringer-only APIs.
4. Create a global Voidbringer singleton or second event bus.
5. Let each skill own private cooldown, charge, recharge, Anchor or force state.
6. Route general spatial force permanently through Rift-specific methods.
7. Persist combat-world state immediately.
8. Infer impact force or critical state from presentation/health deltas.
9. Clear old executor state before a replacement bind has succeeded.

## 16. Consequences

### Positive

- one authoritative owner for every generic and class-specific responsibility;
- safe staged migration from the current compatibility prototype;
- reusable charge and force vocabulary without a broad global framework;
- deterministic failure and teardown behavior;
- no save migration or class-ID break;
- testable separation between gameplay facts and presentation.

### Costs and risks

- requires careful transactional binding across the existing playable bridge;
- adds generic ability-runtime complexity that must preserve cooldown-only callers;
- class skill slices must maintain preflight/commit/result ordering;
- target enemy scripts require minimal explicit force-response adapters;
- delayed effects need generation checks and bounded cleanup;
- the compatibility bridge must be retired deliberately under future migrations.

## 17. Required implementation evidence

Before Issue #89 or later integration may merge, focused tests must prove:

1. one existing session/event bus/executor is reused;
2. failed initial bind and failed rebind preserve the prior valid runtime;
3. commands enable only after successful class bind;
4. ordered, idempotent death/rebind/menu/scene teardown;
5. stale-generation callbacks cannot mutate active state;
6. cooldown-only abilities preserve current behavior;
7. charge initialization, zero-charge rejection, sequential recharge and large-delta behavior;
8. invalid zero/negative charge recharge definitions reject deterministically;
9. source-keyed recharge modifier replacement, expiry and cleanup;
10. failed ability transactions are side-effect free;
11. Instability mutates once after successful commit only;
12. Anchor/Fold Line/Instability state is isolated by controller/session;
13. pure ForceResolver and target-owned application;
14. one-pass critical consumption with legacy integer compatibility;
15. no persistence/schema impact;
16. presentation remains observational and collision-free.

## 18. Implementation gate

### Completed

1. independent read-only architecture review;
2. every required wording correction on frozen exact head `8e9d1492967312f2ef59f48169b0eb7130b7401d`;
3. independent verdict `PASS — CORRECTIONS COMPLETE`;
4. explicit human owner approval.

### Remaining

1. merge ADR-021 and the synchronized Future Design section into `main`;
2. record the resulting exact `main` SHA in Issues #97 and #89.

This owner-approved ADR grants no implementation authority before merge. Issue #89 may begin only after merge and SHA recording. No architecture rule changed during this status synchronization.
