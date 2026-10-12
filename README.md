# قطار الأشياء المفقودة | The Lost Things Express

A mobile-first, cinematic 3D adventure built with Godot 4 and Blender.

> **Permanent art direction:** Read [docs/ART_DIRECTION.md](docs/ART_DIRECTION.md) before changing visuals. The user's supplied concept image and approved carriage reference are the project's visual north star across sessions.

## Product vision

A premium fantasy train adventure where players explore strange stations, discover lost keepsakes, solve environmental puzzles, and decide how each object's story should end.

## Quality principles

- Commercial quality is the target from day one: consistent art direction, expressive characters, polished interaction feedback, legible mobile UI, robust save/resume, and accessibility.
- Prototype geometry validates mechanics only; it is not the final visual quality bar.
- Test the produced APK's signature and package contents, not just whether Godot exported a file.
- Test the real Android installation and game behavior before declaring the mobile build approved.
- Preserve all project decisions and changes in GitHub. Read the current repository before resuming work in another environment.
- Do not claim a build or device test passed unless it actually ran and the result was inspected.

## First vertical slice: “The Station That Forgot Its Name”

- One richly dressed antique sleeper carriage in landscape mobile orientation, with a clear central aisle and a visible second compartment through a framed doorway.
- Polished dark walnut/mahogany joinery, emerald upholstery and carpet, brass/copper details, curtains, warm lamps, tables and overhead luggage.
- Three meaningful puzzle objects: brass key, torn letter, memory chest.
- A complete puzzle requiring the player to discover the key, read the letter, and open the chest.
- A story reward that points to Sunset Station.
- Touch-first movement and camera controls, with desktop controls for development.
- Collision around seating and carriage boundaries, readable mobile UI, and an APK that passes signature/package checks.
- Puzzle progress is now saved automatically to the app's user data and restored on relaunch; the automated first-slice test checks the save/resume path. Pause/resume controls and a persistent look-sensitivity setting are now implemented and covered by automated tests. The physical letter stays visible between the player's hands while reading, with a close action and a printed clock warning; automated tests cover this interaction and persistent key state. Physical-device behavior and visual quality remain release gates.

## World continuity rule — cinematic worlds are playable stations

Every fantasy world the train passes in the opening journey must be reused later as the actual playable station for its stage. The intro and gameplay must share canonical world/station assets and stable world IDs; cinematic LODs are allowed, but separate look-alike copies are not. Railway, bridge and station connections must remain continuous, and each intro world must map to a playable stage. This is a permanent architecture rule: see [docs/design/railway-worlds-as-playable-stations.md](docs/design/railway-worlds-as-playable-stations.md). Do not build the intro worlds as disposable scenery.

## Tech stack

- **Godot 4.3**: gameplay, input, scene flow, UI, audio, save data, Android export.
- **Blender 4.x**: authored carriage and props, materials, lighting, exportable GLB assets.
- **GLB/glTF**: runtime asset interchange.
- **GitHub Actions**: Godot validation, carriage regeneration, Android export and APK verification.

## Build and install on Android

1. Open the [Android APK workflow](https://github.com/bdssmdkacem-dot/lost-things-express/actions/workflows/android-apk.yml).
2. Open the latest successful **Android APK** run and download the artifact named `The-Lost-Things-Express-Android-APK`.
3. The downloaded artifact is a **ZIP archive**. Extract it first; install the inner `TheLostThingsExpress.apk` file, not the ZIP.
4. The workflow gates publishing on APK signature verification, 4-byte alignment, the correct package/version, manifest and both native libraries. When KVM acceleration is available, it must also pass an emulator install/launch smoke test; otherwise that test is explicitly skipped and physical-device testing remains required.
5. If a previous test APK was signed with a different temporary key, uninstall that old test app once before installing this build. CI now caches a stable debug keystore for subsequent builds so upgrades can use the same test certificate while the cache is retained.

The CI artifact is a **debug/testing build**, not a release-signed Google Play build. CI checks for KVM before launching an emulator: if the runner lacks acceleration, the smoke test is recorded as skipped instead of waiting for a boot that cannot succeed. A skipped emulator step is not a passed emulator test. Installation, controls, graphics, performance and the puzzle still need verification on the target physical phone.

## Current state

The repository contains the Godot first-person puzzle foundation, a Blender carriage generator, and committed `.blend` / `.glb` outputs. The generator has been updated to add an open framed doorway with a second-compartment depth cue, emerald seat piping, marble side tables, brass reading lamps and overhead leather luggage. The latest generator revision also renders `assets/blender/train_carriage_preview.png` from a camera aligned to the game's opening view. The asset regeneration workflow checks this image, imports the GLB in Godot, launches the scene headlessly, and archives the preview. The model still requires visual inspection against the approved reference; automated generation is not visual approval.

The Android export preset previously had `package/signed=false`, even though the workflow called an APK export successful. Signing is enabled; version **0.1.3 (version code 4)** is the current test target. The workflow gates publishing on the signature, alignment, package/version and native-library checks. It runs an emulator install-and-launch smoke test only when KVM hardware acceleration is available; otherwise that step is explicitly skipped. A successful CI artifact is still not proof of graphics or interaction quality on the target phone.

**Visual and device approval are still pending.** The current work adds persistent first-stage puzzle progress and an automated resume assertion, but it does not replace visual inspection. Review the generated carriage preview and the actual Godot opening view at a phone aspect ratio against [docs/ART_DIRECTION.md](docs/ART_DIRECTION.md), then install the latest APK on a real Android phone and complete the key → letter → chest play-through. Do not treat the CI result as visual or device approval.

## Roadmap

- [x] Lock visual direction and the first vertical slice in version-controlled documentation
- [x] Define the initial key / letter / chest puzzle flow
- [x] Add repeatable Blender-to-GLB generation
- [x] Enable Android APK signing and add APK signature/package verification
- [x] Add an automated first-person Blender preview render to carriage generation
- [ ] Inspect the generated preview against the approved carriage reference
- [ ] Regenerate and visually inspect the revised carriage asset
- [ ] Review the in-game opening view side by side with the user's reference
- [ ] Test touch movement, camera look, interactions and collision on an Android phone
- [x] Add persistent puzzle progress, pause/resume and saved look sensitivity (automated tests pass)
- [ ] Verify pause/resume, settings, touch controls and the full puzzle on a physical Android phone
- [ ] Replace remaining placeholder props with approved production art and animation
- [ ] Add sound, subtitles, accessibility and cinematic transitions
- [ ] Build a second playable station only after the first slice passes review
- [ ] Complete Android device QA, store assets, privacy review and release preparation


## Narrative and puzzle redesign (2026-10-12)

The previous five-stage story and puzzles are not accepted as compelling yet. The new design contract is [Story and Puzzle Redesign](docs/design/story-and-puzzle-redesign.md): one central mystery carried by the train, a complete carriage-led first stage, distinct stage-specific puzzles, evidence that changes later chapters, visible train travel between stages, and endings with meaningful emotional costs.

- [x] Document the new narrative premise, five-stage arc, puzzle principles and acceptance gates
- [ ] Expand the first stage into a complete carriage-led chapter, from waking and meaningful exploration through its resolution and train departure
- [ ] Replace instant world-gate hopping with authored train departure, in-transit and arrival sequences between complete stages
- [ ] Replace the old story text and stage objectives in the game
- [ ] Implement distinctive stage puzzle mechanics and evidence/journal progression
- [ ] Make previous stage outcomes feed the final manifest puzzle
- [ ] Add in-world reactions and distinct ending sequences
- [ ] Fresh-save Android playtest each puzzle without developer hints

**Important:** design documentation is not implementation. The current gameplay code still contains the earlier abstract puzzle flow, so narrative/puzzle acceptance remains open until the new campaign is playable and tested.

## Five-world campaign validation (2026-10-11)

- [x] Add automated checks for all five puzzle arenas, puzzle progression, exit gates and both ending branches
- [x] Correct the ending test setup so it clears intro/transition flags before exercising the choice callbacks
- [x] Confirm a fresh signed Android APK build for the latest campaign and realm-detail changes (commit `d51827c`; signature, alignment, package and native-library checks passed)
- [x] Review the latest captured screenshots for the train intro, carriage, physical letter, chest photograph, all five worlds, the final choice and both epilogues (visual review run 38177642006)
- [ ] Complete hands-on Android QA for lighting/readability, touch controls, puzzle solving, gate transitions and ending choice

### Latest visual QA notes (2026-10-11)

- Added realm-specific edge terrain, foreground props, route edging and focal details; added separate sky/fog palettes in the preceding visual pass.
- Increased finger size slightly and added visible nail/joint cues to the camera-attached hand model.
- Automated Godot project checks and the five-world interaction sequence pass on commit `d51827c`; both ending branches are exercised by the automated test.
- Signed APK artifact is available from Android workflow run 38177642026. Emulator launch was skipped because the runner lacks KVM acceleration.
- **Visual acceptance remains open:** the new screenshots show better realm separation and a clearer path, but world construction still reads as stylized prototype geometry rather than the locked premium reference. The letter/hand pose is readable, yet hand anatomy and photo-card fidelity still need a closer visual pass against the original reference.
- **Physical Android verification remains open:** install and test the APK on a real phone. Check frame rate, shadows/fog readability, multi-touch camera/movement, all puzzle sequences and gate transitions, and each ending. Do not claim device QA based on CI.

Do not mark the five-world campaign complete until the remaining visual acceptance and physical-device QA checks pass.
