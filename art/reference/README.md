# Reference image archive

These are the project's source-of-truth visual references. Preserve originals unchanged; do not replace them with AI-generated approximations.

## Primary concept board
- Original library filename: `قطار الأشياء المفقودة بين الغيوم.png`
- Intended repository path: `art/reference/lost-things-express-primary-reference.png`
- Role: master visual direction for the locomotive, carriage, explorer and animal companions, floating islands, castles, lighting, palette, and mobile presentation.

## Alternate / wide concept capture
- Original library filename: `1000173104.png`
- Intended repository path: `art/reference/lost-things-express-concept-wide.png`
- Role: wider crop of the same concept board; retain as a secondary composition reference.

## Acceptance rule
A generated model or successful CI build is not proof of visual fidelity. Review screenshots/renders side by side with the references and record material differences before approving assets for the game.

## Archival status
The original images have been located in the ChatGPT Library, but their binary files have not yet been committed into this repository. Do not mark the archive complete until both image files exist at the paths above and have been verified.


## Permanent interaction and scene reference standard (added 2026-10-10)

Treat the five illustrative image examples shown in the project conversation as a permanent visual target for implementation and review. They are guidance for the desired realism and composition, not screenshots of the current game and not substitutes for the two original concept-board files above.

### A. Letter held in both hands — highest priority
- The actual in-world letter must be held visibly between the player's hands, not replaced by a floating UI panel.
- Its paper surface must display the readable letter text. Keep the text attached to the paper as it moves with the hands and camera.
- Reading/inspection may add controls, but must not hide the physical letter while it is being read.
- Use believable paper thickness, folds, edge wear, perspective, hand contact and warm carriage lighting.

### B. Brass key pickup and hold
- Keep the key as a persistent 3D object while held; do not make it vanish when the pickup animation ends.
- Animate reach, finger/thumb closure, contact and lift as one continuous action. Align the key with the grip and camera perspective.
- Hide the hands during ordinary exploration; show them only for relevant interactions, consistent with the existing design.

### C. Wooden chest opening
- The key/lock interaction must visibly connect to the lock. Animate the lid rotating around its hinge with a natural easing curve.
- Keep the chest, lock, hands and lid spatially consistent; reveal the contents only after the lid opens.
- The photo must be a physical, inspectable object, with a clear pickup/inspection transition.

### D. Passage into the clock carriage
- The doorway must be visibly open and wide enough for the existing player collider and camera.
- Check walls, thresholds, collision shapes and player limits together; no invisible blocker, snagging, teleport-like jump or forced control change.
- The clock must be in the reachable next carriage and have a clear interaction point.

### E. Pre-entry train scene
- Review the entire establishing shot before stage one: locomotive silhouette and proportions, rounded boiler, wheels and rods, brass details, passenger carriage, connected curved rails, floating cloud islands, depth, lighting and composition.
- Aim for a coherent, cinematic vintage train scene with grounded materials and consistent scale, matching the original concept board when it is available.
- Do not accept a box-built placeholder merely because it compiles. Compare an actual render/screenshot against the reference and log remaining differences.

## Permanent acceptance checklist
- [ ] Original concept-board images are committed and verified at the paths listed above.
- [ ] The physical letter and its text are visible between the hands during reading.
- [ ] Key pickup and held-key pose look continuous and believable.
- [ ] Chest lid, lock, hands and photo behave as one coherent interaction.
- [ ] Player traverses the doorway into the clock carriage without collision blockage.
- [ ] Pre-entry train scene has been inspected in an actual render and compared side by side with the original concept.
- [ ] Android build and project tests pass.
- [ ] Real-device screenshots/video confirm the visual and interaction checks; CI success alone is insufficient.

Do not check an item above until it has been verified. Preserve the original concept images unchanged. The illustrative image examples are a permanent direction for all future scene and asset revisions, not permission to claim visual validation without an actual render.

## User-supplied source references — 2026-10-10

The five image files attached by the user in the project conversation are authoritative visual references. Do not generate a replacement image for SUNSET STATION. Preserve these references unchanged and use them when shaping scene geometry, materials, camera composition, and visual QA:

| Supplied attachment filename | Reference role | Stable repository filename |
|---|---|---|
| `file_00000000a27081f4a16c023a7b226ef1.png` | Train, chest, sunset-station photograph and object composition | `lost-things-express-scene-reference-a.png` |
| `file_000000007b4c821098d8a94c5f9574b2.png` | Locomotive framing, carriage, chest and photo presentation | `lost-things-express-scene-reference-b.png` |
| `file_000000007df8821092ff04732735a543.png` | Opening train shot, objects, letter and chest interaction | `lost-things-express-scene-reference-c.png` |
| `Screenshot_20261009_175342~2.jpg` | Actual in-game carriage layout / comparison target | `lost-things-express-gameplay-reference.jpg` |
| `1000173104.png` | Primary concept board and overall art direction | `lost-things-express-concept-wide.png` |

**Important source policy:** the reference images guide implementation; they are not runtime textures unless a specific asset is explicitly approved for that use. The existing SUNSET STATION card must use the station/photo visible in the supplied reference as its target. Do not create a new station image or substitute a generated approximation. Keep the physical card orientation, border and title readable on the same face.

**Repository binary status:** these stable paths are the intended source locations, but this documentation update alone does not add the binary image files. The archive remains incomplete until the exact supplied originals are copied unchanged into those paths and verified in GitHub. Never check the archive-complete box before that happens.

## Reference-driven source implementation

- Keep scene/source comments and acceptance tests tied to the stable filenames above.
- For the opening shot, compare the whole locomotive and carriage composition against references A–C; individual details such as steam puffs or brass rings do not constitute acceptance.
- For the photo, use the reference photo as a target for crop, perspective, warmth, station silhouette, and readable lettering. Do not synthesize or generate a replacement station picture.
- Any discrepancy must be recorded in `docs/STAGE_ONE_ENGAGEMENT.md` and fixed before the visual gate is marked complete.
