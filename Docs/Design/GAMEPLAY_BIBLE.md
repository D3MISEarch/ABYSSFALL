# Gameplay Bible

The top-level index for AbyssFall's design documentation. This document states the pillars, locks the project's production-scope doctrine, and points to the detailed documents that own each area. It does not duplicate their full specifications. See [`Docs/Standards/DOCUMENTATION.md`](../Standards/DOCUMENTATION.md) for why.

Every section below uses the same convention: **Confirmed** (verifiable from repository documentation), **Proposed** (directional intent, not yet built or locked), **Open Questions** (genuinely undecided), **Deprecated** (superseded, kept for history). Do not treat a Proposed item as implemented.

## Confirmed

- AbyssFall is a dark ARPG / dark-fantasy action dungeon crawler.
- Combat should be weighty, dangerous, readable, visceral, and satisfying.
- The project values high build expression.
- Core pillars per `PROJECT_OVERVIEW.md`: arcade horde combat, distinct playable classes, build progression, exploration and realms, a dark original identity, and an expandable co-op foundation with single-player first.
- The current playable prototype is Void Warlock v0.4 Hotfix 3 ("The Sunken Crypts").
- Persistent character continuity is a locked product rule: players are never required to restart a character to access new content ([ADR-010](../ADR/ADR-010-PERSISTENT-CHARACTER-CONTINUITY.md)).
- Active production is the first polished Voidbringer operation. Additional classes, realms, bosses, broad endgame systems, co-op, and platform expansion do not block this operation.
- The long-term AbyssFall vision remains valid as a destination. It is not a promise that every envisioned class, region, boss, system, or presentation target must ship simultaneously or in the first commercial release.

## Binding production and scope doctrine

### Status and authority

**OWNER APPROVED — BINDING PROJECT PRODUCTION DOCTRINE**

- **Decision date:** 2026-07-31
- **Human owner:** D3MISEarch
- **Scope:** all design roadmaps, class plans, content plans, agent production packets, milestone definitions, release-scope discussions, and expansion sequencing.
- **Authority boundary:** this doctrine controls production scope and sequencing. It does not override the Engineering Constitution, approved ADRs, runtime architecture, persistence ownership, or testing standards.
- **Change control:** only an explicit owner-approved revision may replace it. A speculative roadmap, prototype convenience, funding assumption, collaborator assumption, or agent-generated plan cannot silently expand active scope.

### Vision and active scope are different layers

AbyssFall may retain an enormous long-term destination: a deep roster, multiple contested regions, memorable bosses, sophisticated buildcraft, meaningful loot, repeatable endgame, cinematic presentation, and eventual multiplayer expansion.

That destination must not be misread as one simultaneous launch checklist.

Production advances through bounded operations. The active operation receives concentrated quality until it is fun, coherent, tested, packaged, and owner-approved. Future operations remain design direction until the current operation passes its acceptance gate and the owner explicitly opens the next one.

### Operation model

The manufacturing model is:

> **Prove one complete part, its fixture, its tooling, its inspection process, and its repeatability before scheduling the next operation.**

For AbyssFall, an operation is not merely a code milestone. It is a player-visible, end-to-end proof containing the design, gameplay, presentation, persistence, testing, performance, documentation, packaging, and owner playtest required for that slice to feel real.

The governing rules are:

1. **One major operation at a time.** Do not spread production across multiple unfinished classes, realms, bosses, or endgame systems.
2. **Quality concentration before breadth.** A smaller slice that looks and plays expensive is more valuable than a broad collection of unfinished systems.
3. **Future scope does not block present completion.** No current milestone may require an unbuilt future class, hypothetical team, publisher, funding event, or later realm.
4. **Build specifically enough to make the current operation excellent.** Do not weaken Voidbringer to satisfy imagined future classes.
5. **Build cleanly enough to preserve proven reuse.** Stable contracts, data ownership, persistence, tests, and documentation must support later extension.
6. **Generalize after a real second use case appears.** Avoid speculative universal frameworks designed around classes or content that do not yet exist in production.
7. **Team growth is optional acceleration, not a dependency.** OP1 must be completable by the owner and approved AI/tooling workflow. A future collaborator, contractor, publisher, or community may increase capacity only after tangible proof exists.
8. **Launch scope follows proven capacity.** The first commercial scope is selected after OP1 demonstrates quality, production speed, player response, available resources, and maintainable reuse. The long-term roster is not automatically the launch roster.

### OP1 — first polished AbyssFall proof

The active operation is centered on one exceptional Voidbringer slice:

- one polished playable class with a brutal, specific combat identity and several visibly distinct build directions;
- one deep but understandable persistent class tree and meaningful skill evolution;
- one visually coherent environment, currently the Sunken Crypts foundation;
- one memorable main boss, currently the Hollow King foundation;
- meaningful build-changing loot rather than stat-only filler;
- one focused repeatable Wound or equivalent endgame loop;
- strong lighting, materials, atmosphere, VFX, audio, impact, camera, and cinematic presentation;
- stable controller play, persistence, packaging, performance, and regression coverage;
- documented production pipelines that can be reused or deliberately generalized during a later operation.

OP1 is not disposable preproduction before the "real game." It is the first finished proof of the real game. Its purpose is to make players, collaborators, contractors, or funding partners experience the vision directly rather than infer it from plans.

### Reusable capability, not speculative infrastructure

OP1 should leave behind proven production capability, including where actually required:

- data-owned skills, mutations, resources, tags, items, and affixes;
- reusable hit, reaction, death, impact, VFX, audio, and feedback pipelines;
- boss state, telegraph, reward, and encounter-authoring patterns;
- modular environment materials, lighting, atmosphere, and set-dressing workflows;
- durable save/load, build-loadout, controller, UI, test, packaging, and handoff processes.

"We will reuse it later" is not sufficient justification for a large abstraction. A shared system must solve the active operation cleanly, avoid known hard-coding traps, and be generalized only when a second real consumer proves the common contract.

### OP1 acceptance gate

OP1 passes only when owner playtests show that:

- Voidbringer feels exciting and mechanically specific rather than static or generic;
- the environment, boss, progression, loot, and repeatable loop form one coherent experience;
- several builds differ in rotation, positioning, resource use, defense, movement, gear priorities, and presentation;
- combat causality is readable and impacts feel intentional;
- the slice is stable enough to replay, save, relaunch, package, and show externally;
- the documented workflow can produce the next piece without rebuilding the entire foundation;
- the result is strong enough that another person can see the intended game without needing the director to explain what it will eventually become.

Only after that gate may the owner define OP2. OP2 may add another class, environment, boss, deeper content for the proven slice, or another strategically chosen unit. Its exact shape is not precommitted.

### Scope rejection tests

A roadmap or production packet must be rejected or revised when it:

- treats the eight-class destination as a mandatory first-launch roster;
- opens another class, realm, or broad system before OP1's current quality gate is met;
- uses future reuse to justify speculative overengineering;
- prioritizes horizontal content count over combat, boss, atmosphere, loot, or repeatability quality;
- assumes a future human team, funding event, or publisher is required to finish the active operation;
- interprets "AAA" as matching AAA breadth instead of concentrating high-end presentation inside a bounded slice;
- makes a future operation a dependency of present completion;
- cuts AbyssFall's core identity merely to satisfy an arbitrary content-count or calendar promise.

## Proposed

- Additional classes, regions, bosses, build systems, and endgame layers may be added through later owner-approved operations after OP1 passes.
- The long-term roadmap and roster direction describe a franchise-scale destination, not committed launch scope or dates.
- Local co-op, online multiplayer, platform expansion, and any engine migration remain gated behind a fun, stable, visually coherent single-player proof.

## Open Questions

- Exact content and commercial form of OP2 after OP1 acceptance.
- The launch class count, realm count, boss count, and endgame breadth that proven capacity can support without lowering the quality bar.
- Exact scope and timing of local versus online co-op.
- Android release scope and performance targets, if mobile remains strategically valuable after the polished vertical-slice evaluation.

## Owning documents

| Area | Document |
|---|---|
| Combat feel and the ability execution model | [`COMBAT.md`](COMBAT.md) |
| Items, affixes, and procedural generation | [`ITEMIZATION.md`](ITEMIZATION.md) |
| Playable classes and build-depth doctrine | [`CLASS_DESIGN.md`](CLASS_DESIGN.md) |
| Active operation, exact gates, and work queue | [`../Roadmap/CURRENT_SLICE.md`](../Roadmap/CURRENT_SLICE.md) |
| World and narrative lore | [`../Lore/WORLD_LORE.md`](../Lore/WORLD_LORE.md) |
| Detailed, already-shipped design specs | `design/` at the repository root — still authoritative inside their approved scope |

## Deprecated

- Treating the full long-term vision as one simultaneous first-release requirement.
- Calling the eight-class destination an approved full launch roster.
- Starting broad class, realm, co-op, or platform production before the first polished Voidbringer proof passes.
- Building a speculative universal framework for future content instead of proving the current use case and generalizing from a real second consumer.
- Treating OP1 as disposable scaffolding rather than the first complete proof of AbyssFall.