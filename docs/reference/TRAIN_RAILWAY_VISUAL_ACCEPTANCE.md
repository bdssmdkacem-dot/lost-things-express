# Visual Reference Pass — Train, Railway and Five Existing Worlds

Status: reference brief created; generated concept board is a planning aid, not an acceptance render. Keep the approved visual north-star image in `art/reference/file_00000000a27081f4a16c023a7b226ef1.png` unchanged.

## Non-negotiable continuity
- Keep the five worlds already shown in the current opening cinematic; do not replace them with the eight-world planning list.
- Preserve stable world IDs so each environment can later become the corresponding playable station.
- The cinematic runs before Stage 1.
- Do not start hand/first-person polish until the exterior train-and-world scene meets the visual acceptance criteria below.

## Reference production order
1. `train/train_locomotive_exterior_v01.png`: realistic 3/4 silhouette, boiler proportions, front lamp, chimney, cab, buffers/cowcatcher, material separation and restrained steam.
2. `train/train_carriage_exterior_v01.png`: at least two clearly distinct connected passenger coaches, consistent scale, windows, doors, undercarriage and warm interior light.
3. `train/train_bogies_wheels_couplings_v01.png`: wheel diameter/spacing, axles, rods, bogies and mechanical couplings that physically connect adjacent cars.
4. `railway/railway_track_types_v01.png`: two continuous rails, sleepers, ballast and plausible alignment under every wheelset.
5. `railway/railway_bridges_v01.png`: coherent stone/metal bridge structure with visible load-bearing arches/piers; track must sit on the bridge deck without gaps.
6. Five world-specific `intro_view` images for the existing worlds: distinct terrain silhouettes, architecture, vegetation, atmosphere and lighting, while retaining their current identities.
7. `vfx` steam reference: small, translucent upward-drifting particles only; no large opaque sphere meshes or circular sky discs.

## Screenshot comparison checklist
- [ ] No visible circular sky discs from steam.
- [ ] Steam is visibly emitted from the chimney in the rendered screenshot.
- [ ] Locomotive boiler and cab read as one coherent machine; no floating decorative parts.
- [ ] Passenger coaches are visibly separate, attached, and aligned to the same track.
- [ ] Wheelsets contact the rails; rods/couplings align with wheel and car positions.
- [ ] Track remains continuous across bridge transitions; no floating rail segments or unexplained gaps.
- [ ] Bridge supports and deck have believable structural continuity.
- [ ] The five existing worlds remain recognizable and visually distinct.
- [ ] Actual Godot screenshot is compared side-by-side with the approved art reference; CI success alone is not visual acceptance.

## Current render observation (run 38170136120, commit 0444538)
The current image still reads as stylized low-poly geometry rather than the approved premium cinematic reference. The locomotive and coaches are visible and connected in composition, but materials and silhouettes remain simplified; the bridge/track structure looks skeletal in places; world architecture and terrain lack detail; and the screenshot does not visibly show a convincing steam plume. Therefore visual acceptance is **not met**. Continue train/railway/world work before hands.

## Verification status
- Project checks at commit `7b7f8bb`: passed.
- Project checks at commit `0444538`: failed in software-rendered first playable puzzle sequence test; investigate this failure before treating that commit as validated.
- Android APK and first-stage visual-review workflows at `0444538`: completed successfully, but a successful build is not proof of visual fidelity.
