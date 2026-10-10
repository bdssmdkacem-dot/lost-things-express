# Blender Production Pipeline

## First asset: antique first-class carriage

The carriage generator is the source of truth for the generated model. Change `art/blender/create_train_carriage.py`, regenerate the outputs, and review them; do not hand-edit the generated GLB or blend file because the next run overwrites them.

### Locked visual requirements

- Polished dark walnut/mahogany panels with beveled joinery and antique-brass inlay.
- Emerald green upholstered benches and seat piping, deep-green curtains and an emerald aisle runner with restrained gold motifs.
- Tall framed windows, cool twilight beyond the windows, and warm amber lighting.
- Small ivory-marble side tables with brass reading lamps.
- Overhead walnut luggage racks with leather suitcases and brass bands.
- An open, walnut-framed doorway at the far end that reveals a second carriage section and focal clock; the first-stage movement boundary remains in the initial compartment until that section becomes a playable level.
- Three readable interactive story props in Godot: brass key, torn letter and brass-trimmed memory chest.

### Generate the starter model

Use Blender 4.x with its glTF 2.0 exporter. From the repository root:

```bash
blender --background --python art/blender/create_train_carriage.py
```

The script writes:

- `assets/blender/train_carriage.blend` — editable Blender source.
- `assets/models/train_carriage.glb` — runtime model imported by Godot.

The `Generate carriage art assets` GitHub Actions workflow runs the generator whenever the Blender source changes. It checks that both files exist, imports the generated GLB in Godot, launches the actual main scene headlessly, commits changed outputs, and uploads them as `lost-things-express-carriage-assets` for review. These checks establish reproducibility and import/runtime startup only; **they do not establish visual approval**.

### Godot integration and review

1. Keep the GLB as the visual carriage and the Godot collision shapes as separate gameplay proxies.
2. Verify the model's dimensions, opening direction, floor level and camera-facing clock.
3. Confirm the central aisle is unobstructed and that seat collision proxies prevent walking through benches.
4. Inspect the curtain, table, lamp and rack placement from the game's actual first-person camera, not only from Blender's viewport.
5. Compare the mobile screenshot with the approved reference: walnut, emerald fabric, brass detailing, warm practical light and cool twilight must all be apparent at phone size.
6. Play through key → letter → chest and inspect the chest-opening animation.
7. Install and run the verified Android APK on the target phone before approving the stage.

### Performance targets

- Use GLB/glTF for runtime delivery and keep the `.blend` as editable source.
- Share materials where practical and avoid unnecessary unique meshes/materials.
- Avoid realtime shadows on every small prop; preserve mobile readability with a small number of practical lights and a restrained ambient fill.
- Treat the current generator as an iterative art pass, not final production approval. Add detailed UVs, authored texture maps, optimized meshes and lighting only after the composition and gameplay pass review.
- All in-game text remains English-only for the current production phase.
