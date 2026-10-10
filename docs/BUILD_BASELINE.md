# Verified Android Build Baseline

**Purpose:** keep a known-good installable APK baseline while the first playable stage is completed. This file records verified facts, not assumptions.

## Last verified package

- Repository: `bdssmdkacem-dot/lost-things-express`
- Successful Android workflow: https://github.com/bdssmdkacem-dot/lost-things-express/actions/runs/38073685913
- APK artifact: `The-Lost-Things-Express-Android-APK` (artifact ID `11677722044`)
- Source commit used for that APK: `20639d9f1bfe0ee8ab5e9b8c31fa125e6f61925a`
- Package: `com.lostthingsexpress.game`
- Version: `0.1.3` (version code `4`)
- CI verified export, APK signature, 4-byte alignment, package/version, manifest and native library.
- Emulator install/launch was **skipped** because KVM was unavailable. Physical-phone installation and visual QA have not yet been confirmed.

## Current gameplay validation

- Latest successful project-check run: https://github.com/bdssmdkacem-dot/lost-things-express/actions/runs/38073707897
- Tested source commit: `2cc3fbdb7f2e769438844ad4365ad7330f84e845`
- Passed: project/resource import, script parsing, headless main-scene launch, and first playable key → letter → chest puzzle sequence including save/resume assertions.

## Non-negotiable release gate for every visual milestone

1. Keep each visual milestone in its own Git commit.
2. Run project checks after each gameplay/script change.
3. Export and verify an APK from the same final source commit before calling that milestone APK-verified.
4. Preserve package ID and signing setup so subsequent APKs remain installable as updates; if the signing certificate cache is lost, document the reinstall requirement instead of promising an in-place update.
5. Never equate a successful export with successful Android runtime, touch controls, visual quality or full-device QA.
6. Do not do the first phone QA until the entire first stage is complete, as requested; keep this baseline available for rollback/comparison.

## First-stage completion gate

The first stage is not complete until all are checked:
- [ ] Carriage and story UI follow the locked reference and palette.
- [ ] Key, letter, chest, and photograph have distinct readable art and reliable interaction feedback.
- [ ] Story panels and HUD share one consistent visual system and do not clip at mobile landscape aspect ratios.
- [ ] Opening, puzzle solution, chest animation, completion card and save/resume pass automated checks.
- [ ] Final APK built from the final first-stage commit passes signature/package validation.
- [ ] Then perform one complete physical-phone play-through and record any issues before starting stage two.
