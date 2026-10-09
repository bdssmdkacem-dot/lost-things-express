# Blender Production Pipeline

## First asset: passenger carriage interior

The first authored Blender asset is the antique passenger carriage interior. It follows the locked palette and dimensions of the Godot prototype (approximately 5.8 m wide, 12 m long, 3.5 m high) so we can replace the temporary procedural shell without redesigning player scale or interaction spacing.

### Generate the starter model

Use Blender 4.x with the glTF 2.0 exporter enabled. From the repository root:

```bash
blender --background --python art/blender/create_train_carriage.py
```

The script creates:
- mahogany carriage shell and inset wall panels;
- individual oak floor planks and brass trim/rivets;
- dark teal windows with brass frames;
- crimson velvet benches with wooden surrounds and brass feet;
- pendant lantern geometry with amber emissive glass.

It writes:
- `assets/blender/train_carriage.blend` — editable Blender source;
- `assets/models/train_carriage.glb` — Godot import asset.

The generator is intentionally procedural and repeatable: adjust the script, rerun it, and review the result rather than hand-editing an output that will be overwritten. Do not claim the asset has been visually approved until the .blend is opened and checked in Blender.

### Godot integration checklist

1. Copy/commit the generated `.blend` and `.glb` outputs after reviewing them.
2. Import the GLB into Godot and inspect its real-world dimensions and orientation.
3. Add collision proxies in Godot (or explicitly authored collision meshes); glTF render meshes are not automatically reliable gameplay collision.
4. Keep interactable props separate from the carriage shell so key, letter and chest logic remains independent.
5. Compare the result against `docs/ART_DIRECTION.md` and profile on Android before adding expensive materials or lighting.
6. Replace the procedural carriage shell only after verifying scale, window visibility, walkable floor, collision, and touch movement.

### Performance targets

- Use GLB/glTF for runtime delivery; keep the .blend as editable source.
- Prefer shared materials and modular meshes; avoid unnecessary unique materials.
- Keep decorative bevels modest and avoid real-time shadows on every small object.
- Treat the current generator as a first modeling pass, not final art approval. Add exterior train geometry, richer material variation, optimized UVs/lightmaps and final lighting in later passes.
- All in-game text remains English-only for the current production phase.
