# The Penitent — Fervor System v1

## Purpose

Fervor rewards the Penitent for **finishing rituals under pressure**. It must not feel like the Void Warlock's Corruption meter with a different color.

- Corruption is collected and fed.
- Fervor is performed and earned.
- Corruption feels hungry and parasitic.
- Fervor feels fanatical, geometric, and increasingly unstable.

## Base resource rules

- Minimum: 0 Fervor
- Maximum: 100 Fervor
- No passive regeneration
- Fervor does not decay during combat
- After 8 seconds outside combat, Fervor decays at 4 points per second until it reaches 25
- Health may substitute for missing Fervor only through Sacrament and explicitly marked Sacrifice upgrades

## Recommended starting gains

These numbers are initial tuning values, not final balance.

- Ritual Blade finisher completes a mark: **+6**
- Brand of Ruin jumps to a new target: **+4**
- Enemy becomes fully marked: **+5**
- Sigil activation hits at least one enemy: **+8**
- Sigil activation hits four or more enemies: **+12 total**
- Marked enemy killed by ritual damage: **+4**
- Chain reaction kills an additional enemy: **+2 each**, capped at +10 per activation
- Martyr's Chain moves an enemy through a sigil: **+5**
- Ashen Procession line is completed: **+7**
- Sacrifice 5% maximum health: **+10**

## Recommended starting costs

- Brand of Ruin: **15 Fervor**
- Seal of Binding: **25 Fervor**
- Martyr's Chain: **20 Fervor**
- Ashen Procession: no Fervor cost; charge-based cooldown
- Sacrament: **40 Fervor**
- Great Seal upgrade: **45 Fervor**
- Cathedral of Flesh capstone: **80 Fervor**
- Saint of the Last Rite capstone: consumes all current Fervor and a controlled health payment

## Threshold behavior

### 0–24: Dormant
- Thin red lines are visible in the UI seal.
- Ritual effects are precise and restrained.
- The character's carved skin sigils are mostly dark.

### 25–49: Kindled
- The inner seal begins rotating.
- Red channels pulse with each completed mark.
- Minor ember-red particles appear on the blade and chains.

### 50–74: Zealous
- Secondary rings unfold around the meter.
- Neon-green contamination appears at broken sections of the seal.
- Completed marks produce a sharper audio sting.

### 75–99: Fanatical
- The UI seal becomes crowded with hooked geometry and trembling chain segments.
- The Penitent's carved body sigils remain visibly lit.
- Sacrifice-branch bonuses may activate.
- The resource display should look dangerous, but must remain readable.

### 100: Revelation
- The outer ring snaps shut into a complete forbidden symbol.
- A brief heartbeat and chain-lock sound communicates readiness.
- The next major ritual activation gains **Revelation**:
  - +20% ritual radius
  - +15% ritual damage
  - consumes 25 extra Fervor after the cast
- Revelation is not an automatic transformation and does not lock the player out of normal abilities.

## Health substitution

When Sacrament is cast without enough Fervor:

- Each missing 2 Fervor costs 1% maximum health.
- The health cost is calculated before healing from the activation.
- The cast cannot reduce the Penitent below 1 health.
- The UI must preview both Fervor and health costs before confirmation.
- Holding the cast button for 0.3 seconds confirms a health-paid Sacrament to prevent accidental self-damage on mobile.

## Anti-abuse rules

- Repeatedly activating an empty sigil grants no Fervor.
- The same enemy cannot award full mark-completion Fervor more than once every 1.5 seconds.
- Summoned disposable enemies grant reduced Fervor.
- Bosses grant Fervor from completed mechanics, not repeated rapid hits.
- Lifesteal is capped per activation to prevent one large horde from instantly restoring full health.

## UI concept

The Fervor meter should resemble a **ritual seal mechanically assembling itself**, not a normal bar.

Visual language:

- Black iron circular frame
- Blood-red channels painted or carved into the ring
- Bone-white tick marks for 25/50/75/100 thresholds
- Small hanging chain segments that pull tight as Fervor rises
- Neon-green rot only appears after 50%, implying the Abyss is contaminating the rite
- At 100%, the separate geometric pieces lock into one complete forbidden sigil
- After spending, the seal violently separates and the chains slacken

Mobile readability:

- Place the circular meter near the ability cluster rather than across the entire top of the screen
- Show a numeric value inside the center only while aiming or holding a Fervor-cost ability
- Flash the relevant missing segment when the player cannot afford an ability
- Health-substitution preview uses a red section on the health bar and a pulsing bone icon

## Audio language

- Gain: scratching quill, blade-on-stone, whispered syllable
- Threshold: chain ratchet and distant choir breath
- Spend: seal crack, iron snap, low ritual boom
- Health substitution: wet blade cut followed by a heartbeat
- Revelation ready: four chain locks, then sudden silence

## Prototype acceptance criteria

1. Fervor is a reusable resource component, not hard-coded into the character scene.
2. The system supports gain, spend, threshold events, and optional health substitution.
3. UI updates are signal-driven.
4. Automated tests cover clamping, threshold crossing, insufficient-cost behavior, and health substitution safety.
5. The Void Warlock remains fully functional and does not depend on Fervor code.
