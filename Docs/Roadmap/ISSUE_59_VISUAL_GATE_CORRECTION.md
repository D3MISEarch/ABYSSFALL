# Issue 59 — Visual Gate Correction

Owner Windows playtest of exact head `56b9ec3b6917247c6e3e563835cfa6e244f78e8e` returned a visual FAIL: the courtyard still appeared materially identical to the prototype.

Root cause: legacy `RoomFoundationDisc_*` meshes were rendered slightly above the new procedural courtyard tiles, visually covering the Art Pass 0 floor. Legacy room OmniLight3D nodes also preserved the saturated prototype color treatment.

Correction:

- hide every legacy `RoomFoundationDisc_*` mesh during Art Pass 0 installation;
- retune matching legacy room lights to low-energy cold light;
- increase drowned-stone tile and crypt-architecture readability;
- add a regression proving the legacy disc is hidden and room glow no longer dominates.

This correction changes presentation only. It does not alter collision, room layout, combat rules, progression, inventory, persistence, or front-end behavior.
