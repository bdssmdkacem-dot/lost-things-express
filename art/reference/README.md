# Reference image archive

These are the project's source-of-truth visual references. Preserve originals unchanged; do not replace them with AI-generated approximations.

## Approved primary visual reference (opening train / worlds)

- **Approved source-of-truth image:** `art/reference/file_00000000a27081f4a16c023a7b226ef1.png`
- **GitHub file:** https://github.com/bdssmdkacem-dot/lost-things-express/blob/main/art/reference/file_00000000a27081f4a16c023a7b226ef1.png
- **Raw image:** https://raw.githubusercontent.com/bdssmdkacem-dot/lost-things-express/main/art/reference/file_00000000a27081f4a16c023a7b226ef1.png
- **Role:** primary visual target for the opening locomotive/train, connected carriages, explorer and companions, floating islands, architecture, lighting, palette, and mobile composition.
- Preserve the binary unchanged. Do not rename, overwrite, or replace it with an AI-generated approximation.

The user explicitly selected this existing repository image as the primary reference on 2026-10-10. It takes precedence over previously proposed filenames. Do not block work on renaming or locating earlier filenames.

## First-stage carriage reference — LOCKED 2026-10-13

- **Definitive carriage photograph:** `art/reference/carriage-reference-approved-2026-10-13.jpg`
- **Role:** sole quality target for the playable opening compartment (facing emerald-tufted seats, marble table with green lamp / books / magnifying glass, deep-green pleated curtains with gold tassels, dark walnut walls, warm practical lighting, forest view through the large window).
- Supplied by the user on 2026-10-13 as the replacement for any earlier carriage photograph.
- Preserve the binary unchanged once committed. Do not generate a substitute and claim it is the original.

## Other reference captures

The other supplied PNG and JPG files in this folder remain supplementary references. Do not assume they are the same image or change their names without explicit approval.

## Acceptance rule
A generated model or successful CI build is not proof of visual fidelity. Review screenshots/renders side by side with the references and record material differences before approving assets for the game.

## Archival status
The approved primary (train/worlds) reference and the new carriage reference are locked. Visual approval of the game remains pending until actual in-game renders are compared side by side and the first stage is tested on a real Android device.


## Permanent interaction and scene reference standard (added 2026-10-10)

Treat the five illustrative image examples shown in the project conversation as a permanent visual target for implementation and review. They are guidance for the desired realism and composition, not screenshots of the current game and not substitutes for the original concept-board files.

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

## User-supplied source references — updated 2026-10-13

### Verified files currently in this folder

| Actual repository path | Role / handling |
|---|---|
| `art/reference/file_00000000a27081f4a16c023a7b226ef1.png` | Primary train/worlds reference |
| `art/reference/file_000000007b4c821098d8a94c5f9574b2.png` | Supplementary scene reference |
| `art/reference/file_000000007df8821092ff04732735a543.png` | Supplementary scene reference |
| `art/reference/Screenshot_20261009_175304~2.jpg` | Uploaded screenshot reference |
| `art/reference/Screenshot_20261010_203416.jpg` | Uploaded screenshot/reference |
| `art/reference/Screenshot_20261010_203427.jpg` | Uploaded screenshot/reference |
| `art/reference/Screenshot_20261010_203438.jpg` | Uploaded screenshot/reference |
| `art/reference/carriage-reference-approved-2026-10-13.jpg` | **LOCKED** first-stage carriage reference (user-supplied 2026-10-13) |

### Source-reference rules

- Keep exact filenames and use these real paths in source comments, tests, and visual-review notes.
- Do not generate a replacement station image. Match the existing physical in-game photo card against the station photograph visible in the supplied references.
- The images are visual references, not runtime textures unless a specific image is explicitly approved for runtime use.

## Reference-driven source implementation

- Source comments must point to the exact paths listed in the verified-files table.
- Compare the complete opening train shot, carriage, chest, letter, and station-photo composition against the supplied references. Individual detail additions do not constitute visual acceptance.
- Record differences and fixes in `docs/STAGE_ONE_ENGAGEMENT.md`.
- Keep visual approval pending until the references have been inspected side by side with an actual in-game render and the first stage has been tested on a real Android device.
