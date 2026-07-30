# AbyssFall Camera and Combat Presentation Foundation

> Status: **OWNER APPROVED DESIGN FOUNDATION — PENDING PR #40 MERGE**  
> Decision ID: `DEC-PR40-021`  
> Human-owner approval: **“Sick! Lets lock that in.”** on 2026-07-23  
> Applies to: camera identity, combat framing, impact presentation, motion comfort, and future camera playtests  
> Implementation authority: **NONE BY DEFAULT**

This document records the approved player-view and camera philosophy for AbyssFall. It defines the experience to prove, not exact production values. Final distance, angle, field of view, damping, shake amplitude, pullback thresholds, and obstruction behavior must be established through graphical playtesting.

---

# 1. Player-view identity

AbyssFall uses a **close cinematic isometric camera**.

It remains a three-quarter overhead action-RPG view, but it sits lower and closer than the conventional practical view used by many modern isometric ARPGs.

The intended result is:

> **Destiny-like physical presence translated into an isometric action RPG: close enough to appreciate the character, violence, animation, materials, and environmental scale; wide and stable enough to command the battlefield.**

The reference defines presence and embodiment only. AbyssFall does not copy another game’s first-person perspective, camera behavior, encounter design, weapons, movement model, or presentation language.

AbyssFall is not:

- a distant overhead dollhouse;
- a straight-down tactical camera;
- a first-person game;
- a conventional over-the-shoulder action game;
- a constantly moving cinematic camera;
- a camera-management game.

---

# 2. Normal framing

The player character should remain slightly below screen center, leaving more readable space in the direction of movement, aiming, and danger.

The default view must be close enough to read:

- armor silhouette, materials, and visible damage;
- class-specific body changes and equipment;
- the Voidbringer’s fused harness and detached components;
- Graftborn anatomical adaptation;
- ritual gestures, stance changes, and weapon commitment;
- enemy wounds, fractures, posture loss, and execution windows;
- nearby environmental storytelling details.

The view must remain wide enough to read:

- flanking enemies;
- ranged threats and projectiles;
- ground hazards;
- boss telegraphs;
- territory and route mechanics;
- weak-point windows;
- the player’s intended escape path.

Character detail may never be purchased by hiding essential combat information.

---

# 3. Camera distance states

The camera may change distance only when the change protects readability or strengthens a rare major moment.

## 3.1 Exploration

Use the closest normal framing.

Purpose:

- strengthen embodiment;
- show character and equipment detail;
- make architecture loom over the player;
- support environmental horror and small narrative details;
- let silence, ambience, and scale carry tension.

## 3.2 Normal combat

Use a modest smooth pullback when combat density requires more awareness.

The player character must remain visually important. Normal combat should not immediately zoom into a distant miniature view.

## 3.3 Dense packs and elite pressure

Ease backward only enough to show relevant flankers, projectiles, hazards, and elite attack space.

The camera should anticipate sustained danger through clear rules rather than rapidly breathing in and out with every enemy entering range.

## 3.4 Boss encounters

Pullback is determined by:

- boss size;
- arena geometry;
- attack radius;
- hazard coverage;
- phase mechanics;
- required weak-point visibility.

A boss must never begin meaningful attacks outside a fair readable view merely to preserve intimacy.

## 3.5 Executions and major payoffs

Most executions remain in the normal gameplay view.

Rare emphasis may include:

- a small brief push-in;
- short impact framing;
- restrained hit-stop;
- one controlled camera impulse;
- immediate return to player control and normal readability.

No routine execution should trigger a long camera spin, forced angle change, repeated cutaway, or animation that becomes irritating through normal ARPG repetition.

---

# 4. Camera behavior law

The camera must feel **present but trustworthy**.

Approved rules:

- fixed or strongly controlled orientation during ordinary play;
- no required constant manual rotation;
- gentle look-ahead based on movement or aim only when predictable;
- smooth follow behavior without floaty lag;
- foreground structures fade, dissolve, cut away, or become transparent when they obstruct play;
- changes in distance use restrained damping rather than snapping;
- player inputs never fight automatic camera movement;
- cinematic framing never takes priority over enemy telegraphs;
- large environmental reveals may use authored camera movement only when control and comfort remain protected.

Future limited rotation may be prototyped only if it materially improves play. It is not part of the locked default requirement.

---

# 5. Motion-comfort law

AbyssFall aims for physical presence without camera chaos.

Default behavior must avoid:

- camera roll;
- head-bob imitation;
- constant sway;
- rapid automatic rotation;
- continuous zoom pulsing;
- prolonged shake;
- shake on every ordinary attack;
- aggressive motion blur;
- repeated forced cinematic movement;
- distortion that hides enemy information.

Large impacts may use one short controlled impulse. The effect must stop quickly and must never disrupt aiming, dodging, targeting, or telegraph recognition.

The guiding rule is:

> **The camera watches the violence. It does not join the mosh pit.**

---

# 6. Player comfort and accessibility controls

The camera and presentation options must include, where technically applicable:

- camera shake intensity, including **Off**;
- dynamic zoom, including **Off** or a stable fixed alternative;
- execution-camera emphasis;
- motion blur;
- screen distortion intensity;
- hit flash intensity;
- reduced VFX mode;
- a wider stable gameplay view;
- foreground-obstruction transparency behavior;
- subtitle and HUD scaling independent of camera distance.

The default camera must already be comfortable. Settings refine the experience; they do not rescue an uncomfortable default.

---

# 7. Combat-presentation relationship

The closer camera exists to make AbyssFall’s combat readable and physical.

It must reveal:

- attack anticipation and follow-through;
- weapon and body contact;
- armor fracture and weak-point exposure;
- directional blood and debris;
- posture and stagger state;
- class transformation and resource state;
- short execution windows;
- environmental reaction to force.

It must not encourage:

- opaque particle clouds;
- full-screen flashes as the primary impact language;
- constant screen shake;
- damage numbers replacing animation feedback;
- camera movement replacing enemy reaction;
- gore that blocks tactical information.

The character, enemy, environment, sound, and music should carry impact together. The camera provides framing and restrained emphasis.

---

# 8. Environmental composition requirements

Levels should be composed for the approved lower, closer angle.

The view must support:

- towering vertical architecture;
- distant moving threats;
- hanging structures and bodies;
- broken machinery below or beyond the playable surface;
- inverted or impossible spaces;
- foreground geometry designed to fade cleanly;
- landmarks readable from the primary camera direction;
- combat arenas that remain legible during dynamic pullback.

Environment art may not assume a distant camera will hide weak scale, empty backgrounds, or unclear traversal boundaries.

---

# 9. First camera prototype matrix

The first graphical camera prototype must test the same character and control scheme in:

1. a narrow crypt corridor;
2. a medium cathedral room;
3. an open exterior or large chamber;
4. a dense melee pack;
5. a mixed melee-and-ranged pack;
6. an elite fight with ground hazards;
7. a large boss arena;
8. an execution or major class payoff;
9. heavy foreground obstruction;
10. a low-effects and camera-shake-off configuration.

It must test both controller and keyboard/mouse behavior where supported.

---

# 10. Prototype acceptance criteria

The camera direction passes only when graphical playtesting confirms:

- the character and class details are meaningfully more visible than in a distant conventional ARPG view;
- normal combat remains readable without frequent emergency pullback;
- attacks do not originate unfairly from outside the useful visible threat area;
- boss telegraphs and arena hazards remain readable;
- ranged play does not feel cramped;
- territory, line, anchor, ritual, and ground mechanics remain understandable;
- foreground obstruction resolves cleanly;
- automatic movement feels predictable and does not fight aiming or locomotion;
- executions feel impactful without becoming repetitive camera interruptions;
- a sustained play session does not produce meaningful discomfort, nausea, eye strain, or camera fatigue for the owner playtester;
- shake-off and dynamic-zoom-off modes remain fully playable;
- the camera feels distinctively close and embodied without changing AbyssFall into a third-person action game.

Exact numbers remain prototype outputs. They are not canonized by this document.

---

# 11. Production boundary

This approval authorizes:

- camera requirements;
- graphical prototype planning;
- playtest scenarios;
- accessibility requirements;
- environment-composition guidance;
- future implementation acceptance criteria.

It does not authorize:

- changes to gameplay code;
- changes to scenes or camera nodes;
- changes to input behavior;
- changes to test or workflow files;
- a new implementation branch;
- a merge of PR #40.

Any implementation must occur through the project’s existing issue, branch, verification, graphical playtest, and owner-approval process.
