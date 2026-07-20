# AbyssFall UI Playtest Checklist

## Class selection

- [ ] Launching without command-line arguments opens class selection.
- [ ] Void Warlock is selected first and has visible keyboard/controller focus.
- [ ] Left/right keyboard navigation cycles through all four cards.
- [ ] Controller D-pad and left stick navigation cycle through all four cards.
- [ ] Mouse clicks select cards and a second click confirms an unlocked card.
- [ ] Void Warlock displays Corruption, Moderate difficulty, four abilities, and three skill branches.
- [ ] The Penitent displays Fervor, High difficulty, four abilities, and Brands/Circles/Sacrifice.
- [ ] Both Unknown Path cards remain visible as chained silhouettes.
- [ ] Selecting an Unknown Path shows lore and an unlock hint.
- [ ] Unknown Paths cannot be confirmed or launched.
- [ ] Confirming Void Warlock loads the Sunken Crypts as Void Warlock.
- [ ] Confirming The Penitent loads the Sunken Crypts as the Penitent placeholder.

## Readability and scaling

- [ ] Class cards remain readable at 1920x1080.
- [ ] Class cards remain usable at 1280x720.
- [ ] The horizontal card row can scroll on a narrow phone-shaped window.
- [ ] The selected card is distinguishable without relying only on color.
- [ ] Locked cards look disabled while remaining readable.
- [ ] Long descriptions wrap instead of clipping.
- [ ] The confirm button remains visible without overlapping details.
- [ ] Focus never becomes trapped outside the card row or confirm action.

## Gameplay handoff

- [ ] Loading either class does not leave the class-selection UI visible.
- [ ] Only one gameplay root is created.
- [ ] Restarting after defeat preserves a valid boot flow.
- [ ] Void Warlock HUD and controls remain unchanged.
- [ ] Penitent placeholder displays Fervor rather than Corruption text.

## Accessibility follow-ups

- [ ] Test at increased operating-system text scale.
- [ ] Add a future UI-scale slider.
- [ ] Add a future high-contrast focus-border option.
- [ ] Verify locked/unlocked state is communicated with text and symbols, not color alone.
- [ ] Verify final character art does not reduce text contrast.

## Current automated coverage

GitHub Actions currently verifies:

- Godot 4.4.1 parser/import validation
- Fervor unit tests
- Class-selection scene headless startup
- Explicit Void Warlock gameplay startup
- Explicit Penitent placeholder gameplay startup

Automated headless checks cannot verify visual hierarchy, focus feel, text clipping, mouse behavior, or phone readability. Those require a graphical playtest.
