# The Penitent — Class Blueprint

## Identity

A close-to-mid-range sigil combatant. The Void Warlock casts immediate spatial magic; The Penitent physically writes rules into the battlefield and triggers them through ritual action. Melee is used to carve and complete magic, not as the class's entire identity.

## Visual language

- Ritual black
- Blood-crimson sigils
- Neon venom-green corruption accents
- Bone/ivory mask
- Exposed carved symbols
- Ragged priest robes, scripture strips, chains, and black iron
- Hooked ceremonial sickle

## Core resource — Fervor

Fervor rises from completing sigils, fighting inside circles, striking branded enemies, sacrificing health, and causing ritual chain reactions. At high Fervor, carved symbols glow and basic attacks place marks more efficiently.

## Core mechanic — Rite Patterns

- Blade attacks carve partial Rite Marks into enemies.
- Abilities place larger ground sigils.
- Completing a pattern activates its effect.
- Marked targets can be connected into ritual networks.
- The Penitent can spend health to force incomplete rites to activate.

## Prototype abilities

### Ritual Blade
Three-hit hooked-sickle sequence. Early hits carve marks; the final slash completes one fragment.

### Seal of Binding
Places a ground circle that slows enemies. Fully marked enemies become chained; completed rites cause spectral chains to erupt.

### Brand of Ruin
Brands one target. Ritual damage echoes to nearby marked enemies, and the brand jumps on death.

### Martyr's Chain
Pulls small enemies toward the Penitent or pulls the Penitent toward large enemies and bosses. Passing through a sigil empowers it.

### Sacrament
Spends health to instantly complete nearby sigils. More health sacrificed produces a stronger activation.

### Ashen Procession
A fast ritual dash leaving a line sigil. Crossing the line again completes and detonates it.

### Cathedral of Flesh
Ultimate. Connects existing marks into an arena-wide ritual network, chains enemies together, echoes damage, mutates the Penitent, and collapses the giant sigil inward.

## Skill branches

- **Brands** — spreading marks, damage echoes, chain detonations.
- **Circles** — traps, territory control, barriers, ritual zones.
- **Sacrifice** — health spending, mutation, lifesteal, and dangerous power spikes.

## First implementation slice

1. Reusable playable-character selection.
2. Fervor resource component and HUD interface.
3. Enemy Rite Mark component.
4. Seal of Binding ground sigil.
5. Ritual Blade three-hit sequence (10/12/18 damage) that carves partial marks and completes Rites on the finisher.
6. One activation reaction when a marked enemy is inside the circle.

Do not build the complete skill tree until this core interaction is fun.
