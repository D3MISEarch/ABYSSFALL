# The Penitent — Skill Tree v1

## Class identity

The Penitent is a close-to-mid-range ritual combatant. He does not cast freeform projectiles like the Void Warlock. He **carves rules into enemies and the floor**, then completes those rules through movement, blade strikes, chains, and sacrifice.

Core loop:

1. Apply Rite Marks with Ritual Blade and Brand of Ruin.
2. Place a ground sigil or connect marked enemies.
3. Reposition enemies with Martyr's Chain or Ashen Procession.
4. Complete the pattern.
5. Spend Fervor or health to trigger a violent ritual activation.

## Starting kit

- **Ritual Blade:** three-hit hooked-sickle sequence. The first two hits carve partial Rite Marks; the finisher completes one mark.
- **Brand of Ruin:** places a persistent brand on one enemy. Ritual damage dealt to that enemy echoes to nearby marked enemies.
- **Seal of Binding:** draws a floor sigil that slows enemies and chains fully marked targets.
- **Martyr's Chain:** pulls small enemies toward the Penitent or pulls the Penitent toward large targets and bosses.
- **Ashen Procession:** short dash that draws a temporary sigil line. Crossing the line again completes it and causes an eruption.
- **Sacrament:** spends Fervor to activate nearby completed sigils. If Fervor is insufficient, the Penitent may pay the missing cost with health.

---

# Branch I — Brands

Focus: enemy marks, spreading curses, echoed damage, and chain reactions.

### Tier 1 — Blood Scripture
Rite Marks last 3 seconds longer. Ritual Blade finishers apply an additional partial mark to a nearby enemy.

### Tier 2A — Spreading Sin
When a branded enemy dies, Brand of Ruin jumps to the nearest unbranded enemy within 7 meters.

### Tier 2B — Open Confession
Fully marked enemies take 12% increased damage from ritual activations.

### Tier 3A — Ruinous Echo
Brand of Ruin echoes 25% more damage. Echoed damage can complete partial Rite Marks once per enemy.

### Tier 3B — Sentence of Ash
Completing a mark ignites the target for 4 seconds. Killing an ignited target leaves a small burning sigil.

### Capstone — The Final Confession
Activating any completed sigil causes every fully marked enemy in range to confess simultaneously. Each target erupts once, then sends one reduced-strength echo to every other marked target. Bosses receive a single amplified ritual strike instead of repeated echoes.

---

# Branch II — Circles

Focus: battlefield geometry, traps, zones, bindings, and controlling where combat happens.

### Tier 1 — Consecrated Ground
The Penitent gains 10% movement speed and 12% ritual damage while standing inside one of his active sigils.

### Tier 2A — Binding Geometry
Seal of Binding grows 20% larger and its slow becomes stronger near the center.

### Tier 2B — Crossing Lines
Ashen Procession can maintain two sigil lines. Crossing lines creates an intersection node that detonates when either line is completed.

### Tier 3A — Iron Gospel
Fully marked enemies inside Seal of Binding are chained to the center. Large enemies and bosses are heavily slowed instead.

### Tier 3B — Great Seal
The Penitent may hold Seal of Binding to draw a larger version with a longer cast time and higher Fervor cost. The Great Seal stores one completed Rite and repeats it at reduced power when it expires.

### Capstone — Cathedral of Flesh
Sacrament temporarily connects every active sigil into one ritual network. Enemies standing within any connected sigil share a portion of ritual damage, and every completed mark adds duration. When the network ends, all connected sigils collapse inward.

---

# Branch III — Sacrifice

Focus: health spending, lifesteal, dangerous power spikes, and temporary mutation.

### Tier 1 — Willing Wound
Health spent by Sacrament grants bonus Fervor and 8% increased ritual damage for 5 seconds.

### Tier 2A — Pain Tithe
The first health-paid ability every 12 seconds costs 35% less health.

### Tier 2B — Martyr's Reserve
Taking damage while below 40% health grants a small amount of Fervor. This can trigger only once per second.

### Tier 3A — Devouring Vow
Ritual activations heal the Penitent for a percentage of damage dealt to fully marked enemies, with reduced healing against bosses.

### Tier 3B — Unclean Ascension
At 75 or more Fervor, Ritual Blade gains extended spectral reach and Martyr's Chain leaves a neon-green rot trail that damages enemies crossing it.

### Capstone — Saint of the Last Rite
Sacrament can consume all current Fervor and up to 20% maximum health to enter a short transformed state. During the transformation, completed marks automatically activate at reduced power, melee reach increases, and ritual damage restores health. The Penitent cannot die from the activation cost.

---

# Unlock rules

- One skill point is awarded per character level during a run.
- Tier 2 requires the branch's Tier 1 node.
- Tier 3 requires at least two previously purchased nodes in that branch.
- A capstone requires four nodes in its branch.
- Players may freely hybridize all three branches.
- Respecs are allowed between runs at the hub, not during combat.

# First prototype subset

The first Penitent vertical slice should implement only:

1. Blood Scripture
2. Spreading Sin
3. Consecrated Ground
4. Binding Geometry
5. Willing Wound
6. Devouring Vow

Capstones should remain data definitions until the basic mark/sigil loop is fun and stable.
