# Stage One — Playability, Suspense & Acceptance Plan

This document extends the product vision in `README.md` and must remain consistent with `docs/ART_DIRECTION.md`. The approved carriage reference and the committed Blender/GLB carriage are the source of truth; do not replace them with generic props or treat generated placeholders as approved art.

## Player promise

The first 10–15 minutes should feel like entering a beautiful, lonely train with a mystery that is reacting to the player. Exploration must lead to discoveries, discoveries must change the world, and the final chest reveal must create a strong reason to continue.

## Current playable mystery

1. **Arrival:** cinematic train introduction, then control is handed to the player. Show one clear first objective and a short touch-control hint without covering the central aisle.
2. **The warm brass key:** locate and collect the key. Give clear pickup feedback and a short unsettling response from the carriage.
3. **The torn letter:** pick up/read the physical paper; preserve the physical letter between the hands while its message is readable. The clue should add a new question, not merely repeat the objective.
4. **The memory chest:** the key and letter together explain why the chest matters. The lock, hands, lid hinge and revealed photograph must behave as one coherent physical interaction.
5. **The reveal:** the chest lid rotates at its hinge, then a physical 3D photograph rises into view with a restrained copper glow. The photograph is a separate interactable: inspecting it reveals the stamped `SUNSET STATION` clue. The photo, its interaction target, and the open lid are reconstructed after save/resume. The next-stage promise must be clear, but stage two must not be represented as playable until it exists.

## Engagement rules

- Keep the player curious, not confused: one active objective, optional environmental clues, and explicit feedback when an action is blocked.
- Every key interaction should produce at least two feedback channels (animation, light, sound, UI, or story). Avoid relying on text alone.
- Use brief authored beats rather than long interruptions. Keep all controls responsive and never change the established movement/look scheme to stage an effect.
- Build suspense through sound design, lamp response, small controlled environmental motion, visual clues and pacing; avoid random jumpscares, constant camera shake, or visual effects that obscure interactables.
- Reward observation: the letter, clock, suitcase and photograph should carry distinct visual silhouettes and readable details at phone size.
- Persist puzzle state, and ensure reload reconstructs the visible state (key removed, letter state preserved, chest lid open and reward available).

## First-stage acceptance gates

### Art and camera
- [ ] Compare an actual in-game mobile-aspect screenshot against the approved carriage reference.
- [ ] Verify dark walnut, emerald upholstery, brass trim, green carpet, curtains, overhead luggage, warm pools of light, cool exterior and the layered second-compartment doorway.
- [ ] Verify no story overlay, particles or interaction glow hides clues or UI.
- [ ] Inspect locomotive establishing shot against the original concept board.

### Gameplay
- [ ] A first-time player can identify the objective and complete key → letter → chest without outside instructions.
- [ ] Touch movement/look and INTERACT work reliably on the target Android phone.
- [ ] Interactable range and prompt always match the actual target; no stale tap target.
- [x] Automated test covers key pickup, paper reading, hinged chest lid, delayed 3D photograph reveal, photograph inspection and save/resume reconstruction.
- [ ] Visually inspect the photograph composition, hinge timing and glow on the target phone; automated assertions are not visual approval.
- [ ] The clock/doorway is reachable after the chest sequence; no invisible collision blocks the player.
- [ ] Save, close, relaunch and verify the exact puzzle state is restored.
- [ ] Story beats improve tension without camera/input conflicts or excessive mobile performance cost.

### Build and device
- [ ] Godot headless import and scene validation pass.
- [ ] Android APK export, signature, alignment, package and native-library checks pass.
- [ ] Emulator launch is reported as passed only if it actually ran; skipped KVM testing is not a pass.
- [ ] Install and play the complete first-stage sequence on a real Android device and inspect screenshots/video before visual approval.


## Latest visual refinement pass — 2026-10-10

Implemented in source and committed to GitHub; these changes are **not yet visually approved**:

- Added an emerald jacquard aisle runner with a subtle procedural weave, paired antique-gold borders, and repeating diamond/stitch motifs in the Blender carriage generator.
- Corrected the reward photograph backing to an upright card so the copper sunset artwork, brass frame, and station name share the same readable face. Added regression assertions for card orientation and title placement.
- Added a low-cost exterior vista visible through the carriage windows: six floating-island silhouettes with tapered rock undersides and a few restrained distant station beacons. This is visual-only and does not change player controls or collision.
- Added locomotive boiler bands, whistle fittings, connecting rods/joints, and a restrained translucent steam plume to the establishing shot.
- Added automated assertions for the exterior vista and locomotive details. The asset-generation workflow is expected to regenerate the committed Blender source, GLB, and preview after the generator change.

### Remaining approval blockers

- Inspect the regenerated assets/blender/train_carriage_preview.png at mobile aspect ratio and compare it to the original user-supplied carriage reference.
- Inspect the actual Godot render for window vista visibility, carpet scale/readability, steam transparency, photograph reveal, and station-name legibility.
- Install the newest successful APK on a physical Android phone and test chest opening, photo inspection, touch movement/look, doorway clearance, and arrival in the next carriage.
- Do not claim complete asset quality or visual approval until these checks have actual screenshots/video or device observations attached.

Do not mark the first stage complete until the relevant gates have been observed. A successful code commit or CI build alone is not visual/gameplay approval.

## Source-reference lock — 2026-10-10

The user explicitly requested continuing without creating a new SUNSET STATION image. The reference binaries have now been uploaded to `art/reference/` under their original, non-standard filenames. The exact verified paths are listed in `art/reference/README.md` and the source comment in `scripts/main.gd` points to those paths.

Do not rename, modify, or replace the supplied images merely to match the earlier suggested filenames. The original concept-board names `قطار الأشياء المفقودة بين الغيوم.png` and `1000173104.png`, and the earlier expected screenshot name `Screenshot_20261009_175342~2.jpg`, were not found in the current directory listing; do not claim they are present or guess which uploaded file is equivalent. Visually inspect the uploaded references to assign precise roles.

Do not generate a replacement station image. Use the supplied station photograph as the target for the existing physical in-game photo card. Reference upload is now present, but visual approval is still pending until the actual scene render is compared side by side with the images and the first stage is tested on a real Android device.


## Interaction reliability and visual review — 2026-10-10

### Automated interaction improvements

- Fixed a real inventory/view-model bug: the brass key was deleted when the generic hand-action tween finished. It now remains attached to the first-person view model while hands are hidden during normal exploration, and it is rebuilt when saved key progress is restored.
- Gameplay touch and keyboard input now stop behind story cards. Showing a modal releases any captured move/look touch so a swipe on dialogue cannot rotate the hidden camera or leave movement latched.
- Added a pause overlay with Resume, movement/look guidance, and a look-sensitivity slider. The chosen sensitivity is saved to `user://first_stage_settings.cfg` and restored on relaunch.
- Added automated assertions for key persistence, key reconstruction on resume, modal touch blocking, pause movement freeze, sensitivity updates, and settings persistence.

### Visual comparison result — not approved

The committed Blender preview `assets/blender/train_carriage_preview.png` was inspected at 1280×720 against the user-supplied carriage screenshot and concept boards. It has a centered aisle, emerald seating and runner, repeated windows, and a far clock, but it still falls short of the premium reference:

- Upholstery and joinery read as large, hard-edged stylized blocks rather than soft, richly surfaced leather and crafted walnut.
- Overhead luggage is only partially readable in the framing and needs to feel deliberately placed, not clipped at the top corners.
- Warm lamps are visually too bright and uniform; the scene needs softer pools of light and better shadow detail.
- The exterior windows do not yet communicate a clear, layered floating-island vista at a glance.
- The current preview is a Blender asset render, not proof that the imported GLB and Godot mobile scene look the same.

A new generator pass brings the island silhouettes closer to the window plane, gives them tapered rocky undersides, and enlarges the distant tower shapes. Its regenerated preview must be inspected before accepting that fix. The scene remains **not visually approved** until a new render is compared side by side and the first-stage interactions are tested on a physical Android device.
