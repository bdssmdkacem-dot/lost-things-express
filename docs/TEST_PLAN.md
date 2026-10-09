# First Playable — Acceptance Tests

## Import and startup
- [ ] Project imports in the agreed stable Godot 4.x version without parse errors.
- [ ] Main scene starts and can be restarted.
- [ ] No missing resource warnings.

## Movement and boundaries
- [ ] Keyboard movement works for desktop development.
- [ ] Touch movement and look work on Android.
- [ ] Player cannot walk through carriage walls or leave the carriage.
- [ ] No stuck input after focus loss or app resume.

## Puzzle state
- [ ] Brass key can be collected exactly once.
- [ ] Letter clue can be inspected and read again.
- [ ] Chest remains locked if either requirement is missing.
- [ ] Chest opens only after the key and letter clue are acquired.
- [ ] The story reward is displayed and remains consistent after interaction.
- [ ] UI clearly explains why a locked interaction cannot proceed.

## Usability and accessibility
- [ ] A first-time player understands the controls without verbal coaching.
- [ ] Important props remain identifiable on a small phone screen.
- [ ] Text is readable and respects safe areas.
- [ ] Touch targets are comfortably sized.
- [ ] Essential story information is not communicated by color alone.

## Performance and reliability
- [ ] Test at least one lower-mid-range Android phone and one newer phone.
- [ ] Record frame pacing, load time, memory, and thermal behavior.
- [ ] No crash during a 15-minute repeated-play session.
- [ ] Test pause/resume, app backgrounding, and interrupted interaction.
- [ ] Do not add content complexity until the agreed minimum device meets the performance budget.

## Release gate
Do not expand the game until the puzzle can be completed repeatedly, new players understand the core loop, and the slice is stable on target hardware. Record actual results; never mark a test passed without running it.
