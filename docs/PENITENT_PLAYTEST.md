# The Penitent Playtest Checklist

## Launch and selection

- [ ] Launching without arguments opens class selection.
- [ ] The Penitent card can be selected with mouse and controller.
- [ ] The Sunken Crypts loads with the circular Fervor HUD.
- [ ] The HUD begins at 0 / 3 active sigils.

## Ritual Blade and Rite Marks

- [ ] The first two Ritual Blade hits show distinct partial-mark states.
- [ ] The third hit completes the Rite.
- [ ] Completing a new Rite grants Fervor.
- [ ] Marks are readable above Reavers, Archers, Brutes, and the Hollow King.

## Brand of Ruin

- [ ] Pressing F or right-stick click spends 12 Fervor and Brands the best living target in front of the Penitent.
- [ ] Targets behind the Penitent and targets beyond roughly eight meters are ignored.
- [ ] Recasting Brand removes it from the previous primary target.
- [ ] The Brand ring remains visually distinct from Partial and Complete Rite geometry.
- [ ] Hitting the Branded target with Ritual Blade echoes damage into nearby enemies that already have a Rite Mark.
- [ ] Unmarked nearby enemies do not receive echo damage.
- [ ] Echoes never jump back into the primary target or recursively trigger additional echoes.
- [ ] No more than five secondary targets are struck by one Brand echo.
- [ ] Successful echoes grant a small, capped amount of Fervor.
- [ ] Brand expires after roughly ten seconds.
- [ ] Brand cooldown and insufficient-Fervor messages are readable without interrupting combat.

## Seal of Binding

- [ ] Pressing Q, right mouse, or left bumper spends 18 Fervor and places a seal ahead of the Penitent.
- [ ] The circle boundary remains readable from normal camera distance.
- [ ] Unmarked and partially marked Reavers and Archers are visibly slowed inside the seal.
- [ ] Reavers and Archers with a Complete Rite are arrested and display ritual chains.
- [ ] Brutes remain mobile but visibly struggle against short binding pulses.
- [ ] The Hollow King is hindered but never permanently rooted.
- [ ] Enemies recover their original movement after leaving the circle.
- [ ] Overlapping seals do not permanently alter enemy movement.
- [ ] The seal expires after roughly seven seconds.

## Martyr's Chain

- [ ] Pressing C or left-stick click spends 14 Fervor and targets the best enemy in front of the Penitent.
- [ ] Rite-marked targets receive a small targeting preference.
- [ ] Reavers and Archers are dragged to melee distance from the Penitent.
- [ ] Dragged enemies can be pulled into an active Seal of Binding.
- [ ] Brutes and the Hollow King act as anchors and pull the Penitent toward them instead.
- [ ] The Penitent receives a brief protected travel window while being pulled to an anchor.
- [ ] The chain remains visibly connected throughout either pull direction.
- [ ] A Complete Rite adds impact damage and refunds a small amount of Fervor.
- [ ] Targets beyond roughly ten meters or behind the Penitent are rejected.
- [ ] Chain cooldown and insufficient-Fervor messages are readable during combat.
- [ ] Pulling does not permanently disable enemy or player movement.

## Ashen Procession

- [ ] Pressing Space or controller A performs the normal protected dodge and writes a blood scripture along the traveled path.
- [ ] The trail begins dim and becomes clearly armed after the Penitent moves away from it.
- [ ] Remaining on the dodge endpoint does not instantly complete the trail.
- [ ] Walking or dodging back across the armed scripture completes it.
- [ ] Fast crossings are detected even when the Penitent moves entirely through the line between frames.
- [ ] Enemies standing on the completed line take ritual damage.
- [ ] Unmarked enemies struck by the line receive a Partial Rite.
- [ ] Partially marked enemies take increased damage and gain another mark step.
- [ ] Complete Rite enemies take the strongest judgment damage and flash venom green.
- [ ] Crossing an empty trail grants no Fervor.
- [ ] Hitting enemies grants a capped Fervor reward, with a small bonus for Complete Rites.
- [ ] An unfinished trail expires after roughly five seconds.
- [ ] Creating a new trail replaces the previous unfinished trail without leaving visual debris.

## Sacrament

- [ ] Pressing V or D-pad Down casts Sacrament only when a marked enemy or relevant active seal exists.
- [ ] The base price is 40 Fervor.
- [ ] Missing Fervor converts into blood at two missing Fervor per one percent maximum health.
- [ ] Sacrament refuses to cast when the blood payment would reduce the Penitent below one health.
- [ ] The health bar and Fervor seal update immediately after payment.
- [ ] Partial Rite enemies within roughly 6.5 meters are forced to Complete Rite before judgment.
- [ ] Complete Rites detonate for the strongest base damage and are consumed afterward.
- [ ] Branded targets receive one additional damage bonus without recursive Brand echoes.
- [ ] Enemies inside an active Seal of Binding receive the seal-collapse bonus.
- [ ] Unmarked enemies caught only inside a collapsing seal survive with a new Partial Rite when applicable.
- [ ] Every relevant active Seal of Binding visibly collapses and disappears from the 0 / 3 HUD pips.
- [ ] Paying blood increases Sacrament damage, capped at the twenty-percent-health contribution.
- [ ] The Hollow King receives reduced boss-safe damage and is never hard-locked.
- [ ] The cathedral rings, vertical judgment beams, Brand-red feedback, and Complete-Rite green feedback remain readable from normal camera distance.
- [ ] Sacrament enters an eight-second cooldown after a successful cast.
- [ ] Failed or empty casts do not spend Fervor or health.

## Capacity and replacement

- [ ] The Fervor HUD pips update from 0 / 3 through 3 / 3.
- [ ] Placing a fourth seal removes the oldest seal.
- [ ] Replacing or expiring a seal restores affected enemies correctly.
- [ ] Sacrament collapse removes each affected seal from the roster once.
- [ ] Death clears all active seals, the active Brand, any chain pull, and the Ashen Procession trail.

## Regression

- [ ] Void Warlock still uses the living Corruption meter.
- [ ] Void Bolt, Grasping Rift, and Shadow Step still work.
- [ ] Inventory, skill tree, XP choices, loot, generators, gates, and the Hollow King remain functional.
- [ ] No script or runtime errors appear in the Godot debugger during a full run.

## Feel notes

Record:

- Brand targeting confidence
- Brand and Rite Mark readability
- Echo radius and damage feedback
- Seal placement distance
- Circle readability
- Slow strength
- Seal-chain readability
- Martyr's Chain targeting confidence
- Pull speed and stopping distance
- Whether anchor travel feels reckless or empowering
- Ashen Procession trail width and readability
- Whether leaving and recrossing the line feels natural during a horde fight
- Whether five seconds is enough time to route back through the trail
- Ashen damage and Fervor payoff
- Sacrament cast-radius readability
- Sacrament blood-payment pressure
- Whether consuming Complete Rites feels satisfying rather than punitive
- Cathedral and seal-collapse readability during a crowded fight
- Sacrament cooldown and damage payoff
- Fervor cost pressure
- Whether seven seconds feels too short or too long
- Whether the three-sigil limit creates meaningful choices
