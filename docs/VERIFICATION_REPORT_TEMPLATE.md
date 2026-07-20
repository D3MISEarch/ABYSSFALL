# AbyssFall Independent Verification Report

## Verdict

Choose one:

- PASS
- PASS WITH FOLLOW-UP
- FAIL
- NEEDS GRAPHICAL PLAYTEST

## Build identity

- Change:
- Repository:
- Pull request:
- Branch:
- Full commit SHA:
- Handoff ZIP name:
- Godot version:
- Verification environment:

## Commands executed

```bash
# List the exact commands used.
```

## Automated tests rerun

- [ ] Editor/parser/import validation
- [ ] Fervor resource
- [ ] Fervor HUD
- [ ] Rite Marks
- [ ] Seal of Binding
- [ ] Brand of Ruin
- [ ] Martyr's Chain
- [ ] Ashen Procession
- [ ] Sacrament
- [ ] New or changed feature suite
- [ ] Class-selection startup
- [ ] Void Warlock runtime
- [ ] Penitent runtime

Record omissions and reasons rather than leaving uncertainty.

## Manual code-path trace

Describe what was inspected in each relevant category:

- Scene-tree lifecycle and ordering:
- Local/global transform math:
- Input and controller routing:
- Physics and collision behavior:
- Cooldowns, timers, and state transitions:
- Cleanup, death, replacement, and overlapping effects:
- Standing bug-pattern log checks:

## Findings

### Blocking findings

None, or list each issue with:

- File and function
- Failure mechanism
- Reproduction steps
- Expected behavior
- Actual behavior
- Suggested regression-test shape

### Non-blocking findings

None, or list tuning, readability, maintainability, or follow-up concerns.

## Confirmed behavior

State what the independent environment directly proved. Do not repeat implementation claims that were not rerun or traced.

## Known unverified areas

List graphical feel, visual clarity, controller ergonomics, camera behavior, combat balance, or other areas the verification environment could not establish.

## Integration recommendation

State whether the project owner should:

- merge
- merge with focused follow-up issues
- return the branch for fixes
- hold for graphical playtest
