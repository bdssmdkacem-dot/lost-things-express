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

- One richly dressed antique sleeper carriage, with a clear central aisle and a visible second compartment through a framed doorway.
- Polished dark walnut/mahogany joinery, emerald upholstery and carpet, brass/copper details, curtains, warm lamps, tables and overhead luggage.
- Three meaningful puzzle objects: brass key, torn letter, memory chest.
- A complete puzzle requiring the player to discover the key, read the letter, and open the chest.
- A story reward that points to Sunset Station.
- Touch-first movement and camera controls, with desktop controls for development.
- Collision around seating and carriage boundaries, readable mobile UI, and an APK that passes signature/package checks.
- Save/load, pause/resume, settings, and full device QA remain release gates, not features to assume complete.

## Tech stack

- **Godot 4.3**: gameplay, input, scene flow, UI, audio, save data, Android export.
- **Blender 4.x**: authored carriage and props, materials, lighting, exportable GLB assets.
- **GLB/glTF**: runtime asset interchange.
- **GitHub Actions**: Godot validation, carriage regeneration, Android export and APK verification.

## Build and install on Android

1. Open the [Android APK workflow](https://github.com/bdssmdkacem-dot/lost-things-express/actions/workflows/android-apk.yml).
2. Open the latest successful **Android APK** run and download the artifact named `The-Lost-Things-Express-Android-APK`.
3. The downloaded artifact is a **ZIP archive**. Extract it first; install the inner `TheLostThingsExpress.apk` file, not the ZIP.
4. Extract and install the inner `TheLostThingsExpress.apk`, not the ZIP.
5. The workflow verifies the APK signature, 4-byte alignment, package identifier, manifest and native libraries, then installs and launches the app in an Android 14 x86_64 emulator before publishing the APK.
6. If you installed a previous test APK signed with a different temporary key, uninstall that old test app once before installing this new build. The CI workflow now caches a stable debug keystore for subsequent builds so upgrades use the same test certificate while that cache is retained.

The CI artifact is a **debug/testing build**, not a release-signed Google Play build. The emulator test checks installation and process startup in CI; it does not replace testing controls, graphics, performance and the puzzle on the target physical phone.

## Current state

The repository contains the Godot first-person puzzle foundation, a Blender carriage generator, and committed `.blend` / `.glb` outputs. The generator has been updated to add an open framed doorway with a second-compartment depth cue, emerald seat piping, marble side tables, brass reading lamps and overhead leather luggage. The latest generator revision also renders `assets/blender/train_carriage_preview.png` from a camera aligned to the game's opening view. The asset regeneration workflow checks this image, imports the GLB in Godot, launches the scene headlessly, and archives the preview. The model still requires visual inspection against the approved reference; automated generation is not visual approval.

The Android export preset previously had `package/signed=false`, even though the workflow called an APK export successful. Signing is enabled; version **0.1.3 (version code 4)** is the current test target. The workflow now verifies the signature, checks that both arm64 and x86_64 native libraries are present, checks the package version, and performs an emulator install-and-launch smoke test. Only a build that passes these steps should be offered for installation.

**Visual approval is still pending.** The carriage must be rendered/imported and reviewed at a phone aspect ratio against [docs/ART_DIRECTION.md](docs/ART_DIRECTION.md), followed by a real Android install and a complete key → letter → chest play-through. Do not treat the CI result as visual or device approval.

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
- [ ] Add and test persistent save data, pause/resume and settings
- [ ] Replace remaining placeholder props with approved production art and animation
- [ ] Add sound, subtitles, accessibility and cinematic transitions
- [ ] Build a second playable station only after the first slice passes review
- [ ] Complete Android device QA, store assets, privacy review and release preparation
