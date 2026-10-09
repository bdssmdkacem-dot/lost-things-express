# قطار الأشياء المفقودة | The Lost Things Express

A mobile-first, cinematic 3D adventure built with Godot 4 and Blender.

> **Permanent art direction:** Read [docs/ART_DIRECTION.md](docs/ART_DIRECTION.md) before changing visuals. The user's supplied concept image is the project's primary visual north star across sessions and development environments.

## Product vision
A premium fantasy train adventure where players explore strange stations, discover lost keepsakes, solve environmental puzzles, and decide how each object's story should end.

## Quality principles
- Commercial quality is the target from day one: consistent art direction, expressive characters, polished interaction feedback, legible mobile UI, robust save/resume, and accessibility.
- Prototype geometry validates mechanics only; it is not the final visual quality bar.
- Keep systems modular and test each gameplay change before expanding content.
- Preserve all project decisions and changes in GitHub. Read the current repository before resuming work in another environment.
- Do not claim a build or device test passed unless it actually ran and the result was inspected.

## First vertical slice: “The Station That Forgot Its Name”
- One richly dressed train carriage.
- Three meaningful objects: brass key, torn letter, memory chest.
- A complete puzzle requiring the player to discover the key, read the letter, and open the chest.
- A story reward that points to the next station.
- Touch-first movement and camera controls, with desktop controls for development.
- Save/load, pause/resume, settings, and device QA before external testing.

## Tech stack
- **Godot 4**: gameplay, input, scene flow, UI, audio, save data, Android export.
- **Blender**: final train, character, props, animations, and environment assets.
- **GLB/glTF**: tested asset interchange.
- **GitHub**: source of truth, issue tracking, code review, and automated checks.

## Start
1. Install a stable Godot 4.x version.
2. Import `project.godot`.
3. Run the project and validate the initial puzzle on desktop.
4. Export and test on the target Android devices before considering the prototype mobile-ready.

## Current state
Repository foundation and art-direction contract are established. A repeatable Blender generator for the first passenger-carriage interior now lives at `art/blender/create_train_carriage.py`; see [docs/BLENDER_PIPELINE.md](docs/BLENDER_PIPELINE.md). The generated `.blend` and `.glb` outputs still need to be produced in Blender, visually reviewed, and imported into Godot. Procedural prototype assets remain temporary until that replacement is verified.

## Roadmap
- [x] Lock visual direction in version-controlled documentation
- [x] Define first vertical slice and quality gates
- [ ] Build and run the carriage prototype
- [ ] Verify puzzle states and interaction feedback
- [ ] Add pause/resume and persistent save data
- [x] Add repeatable Blender-to-GLB generator and pipeline instructions
- [ ] Generate, visually review, and integrate the first carriage asset
- [ ] Replace placeholders with production art and animation
- [ ] Add sound, subtitles, accessibility, and cinematic transitions
- [ ] Add a second station only after the first slice passes playtests
- [ ] Android device QA, store assets, privacy review, and release preparation
