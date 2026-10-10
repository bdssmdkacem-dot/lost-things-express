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

Do not mark the first stage complete until the relevant gates have been observed. A successful code commit or CI build alone is not visual/gameplay approval.
