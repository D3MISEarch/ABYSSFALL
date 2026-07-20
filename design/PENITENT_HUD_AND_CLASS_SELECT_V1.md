# The Penitent — Class Selection and Combat HUD v1

## Goals

The class-selection screen must sell the fantasy of each hero before the player reads numbers. The Penitent HUD must communicate ritual setup, Fervor thresholds, sigil capacity, Rite Mark state, and health-sacrifice risk without covering combat.

---

# Class-selection screen

## Layout

- Full-screen dark stone chamber divided by a central abyssal altar.
- Void Warlock stands on the left in purple-black light with green corruption leaking through armor.
- The Penitent stands on the right in blood-red sigil light with neon-green contamination at the edges.
- Selecting a class brings that hero forward while the other recedes into shadow.
- Bottom center contains a large `ENTER THE ABYSS` confirmation control.
- Top area shows class name, title, difficulty, combat range, and resource identity.

## Void Warlock card

- Title: **Master of the Hungry Rift**
- Fantasy: immediate void control, gravity, portals, soul collection.
- Resource: Corruption.
- Tags: Ranged, Control, Summoning, Burst.
- Difficulty: Moderate.
- Preview loop: Void Bolt -> Grasping Rift -> soul collection -> Corruption meter grows.

## The Penitent card

- Title: **Saint of the Last Rite**
- Fantasy: carve marks, draw sigils, bind enemies, pay in blood.
- Resource: Fervor.
- Tags: Hybrid, Setup, Area Control, Risk/Reward.
- Difficulty: High.
- Preview loop: Ritual Blade marks -> Seal of Binding -> Martyr's Chain -> Sacrament activation.

## Selection details

When a class is highlighted, show:

- Four ability icons.
- A short resource animation.
- Three branch icons for the skill tree.
- Starting weapon and relic silhouette.
- `Strengths`, `Risks`, and `Playstyle` summaries.

## Locked-class behavior

Future classes remain visible as chained silhouettes. Selecting one shows a short lore line and unlock requirement rather than hiding it completely.

---

# Penitent combat HUD

## Screen hierarchy

### Top left

- Health bar.
- Small character level and XP strip.
- Current weapon/relic proc indicators.

### Near the lower-right ability cluster

- Circular Fervor seal.
- Four main ability buttons around the seal.
- Dodge button placed slightly outside the cluster.
- Consumable button above the cluster.

### Top center

- Objective text.
- Boss health bar when active.
- Ritual chain-reaction count briefly appears beneath the boss bar.

### World-space markers

- Rite Marks appear above enemies.
- Ground sigils use clear red boundaries and dark centers.
- Chains and connection lines show which enemies and sigils are part of the same ritual network.

---

# Fervor seal UI

The Fervor display is a circular forbidden seal made of separate black-iron pieces. It mechanically assembles as Fervor rises.

## 0–24: Dormant

- Only the inner red channels are visible.
- Chains hang loose.
- Ability-cost arcs are dim.

## 25–49: Kindled

- Inner ring rotates slowly.
- Red channels pulse when marks complete.
- First quarter of the outer geometry locks into place.

## 50–74: Zealous

- Second ring unfolds.
- Neon-green contamination leaks from broken sections.
- Chain segments begin pulling tight.

## 75–99: Fanatical

- Hooked outer geometry trembles.
- The seal appears crowded and unstable.
- Sacrifice abilities gain a faint heartbeat pulse.

## 100: Revelation

- All pieces snap into one complete symbol.
- Four chain locks close.
- The center flashes bone white, then returns to blood red with green contamination.
- The next major ritual gains Revelation bonuses.

## Spending behavior

- The matching cost segment tears away from the ring.
- Chains slacken and recoil.
- Health substitution adds a temporary red wedge to the health bar and a bone icon inside the Fervor seal.

---

# Rite Mark readability

Each enemy may show up to three visible mark states:

1. **Partial I:** one thin red slash.
2. **Partial II:** two connected strokes forming an incomplete symbol.
3. **Complete Rite:** closed blood-red glyph with a bone-white center point.

Rules:

- Marks scale with distance so they remain readable without becoming huge.
- Completed marks pulse once, then settle.
- Brand of Ruin adds a rotating outer ring around the normal mark.
- Boss marks attach to the boss health bar as segments rather than floating above the model.
- Mark expiry is shown by the glyph cracking and losing brightness.

---

# Sigil capacity and network display

- Small pips beside the Fervor seal show active sigil slots.
- Each pip uses the shape of its deployed sigil.
- When maximum sigils are active, placement abilities show which existing sigil will be replaced.
- Connected sigils share a thin pulsing line in world space.
- Cathedral of Flesh replaces normal connection lines with one large ritual network overlay.

---

# Ability-cost communication

- Each ability button has an outer cost arc tied to the Fervor ring.
- Affordable abilities glow red.
- Unaffordable abilities show missing sections in dark iron.
- Health-payable abilities show a secondary bone-white/red arc.
- Holding Sacrament previews exact Fervor and health cost before release.
- On mobile, health-paid casting requires a 0.3-second hold and haptic pulse.

---

# Status feedback

## Brand of Ruin

- Branded target shows a rotating crown-like red ring.
- Echo targets briefly connect with thin scripture lines when damage transfers.

## Seal of Binding

- Outer boundary is a solid red geometric circle.
- Slow field is indicated by inward-moving runes.
- Fully bound enemies gain black-iron chain icons beneath their Rite Mark.

## Martyr's Chain

- Valid small-enemy pull target: inward-facing hook icon.
- Valid large-enemy grapple target: forward-facing anchor icon.

## Sacrament

- Completed sigils flash in sequence before activation.
- Empty or incomplete sigils never use the full activation flash.

---

# Controller and mobile layouts

## Controller

- Right trigger: Ritual Blade.
- Left trigger: Seal of Binding aim/cast.
- Right bumper: Brand of Ruin.
- Left bumper: Martyr's Chain.
- Face button: Ashen Procession.
- Hold face/utility button: Sacrament.

## Mobile

- Left thumb: movement stick.
- Large lower-right button: Ritual Blade.
- Three smaller buttons around Fervor seal: Brand, Seal, Chain.
- Dodge sits outside the cluster for emergency access.
- Sacrament is a hold gesture on the center Fervor seal.
- Swipe from Seal button to aim placement.

---

# Accessibility requirements

- Marks must be distinguishable by shape, not color alone.
- Optional enemy-mark scale slider.
- Optional reduced-screen-shake mode.
- High-contrast sigil boundary setting.
- Health-payment preview must always include text or numeric confirmation.
- Controller focus order must never trap the player in the class-selection screen.

---

# Prototype acceptance criteria

- Class selection can switch between Void Warlock and Penitent placeholders.
- Each class card displays resource, tags, difficulty, and preview abilities.
- Fervor seal reacts to all five threshold states.
- Partial, complete, branded, and expiring Rite Marks are visually distinct.
- Active sigil count and replacement behavior are visible.
- Health substitution is previewed before Sacrament can fire.
- HUD remains readable at 1080p, Steam Deck scale, and common phone aspect ratios.
- HUD state is driven by signals rather than directly polling class-specific nodes every frame.
