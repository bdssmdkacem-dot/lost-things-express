# Professional Asset Production and Acceptance

This checklist is mandatory for the railway opening. Export or scene-load success alone is not visual approval.

## Priority order
1. Locomotive and connected coaches.
2. Track, sleepers, ballast, fasteners, curves and couplers.
3. Bridges, arches, piers, parapets and rail-to-bridge transitions.
4. Five canonical worlds and stations, landmarks and rail connections.
5. Lighting, atmospheric depth and mobile performance.
6. Hand/character assets only after the railway opening meets the visual reference.

## Locomotive
- Believable steam locomotive proportions: boiler, smokebox, chimney, cab and running gear read as one engineered object.
- Wheels align to rails; rotation and connecting rods are synchronized without clipping or floating.
- Lamps, piping, valves, rivets, bands, buffers, steps and handrails are readable at phone scale.
- Brass/copper and painted metal use named PBR materials with restrained roughness variation.
- Steam stays subtle and does not obscure silhouette, track or landmarks.

## Coaches and couplings
- Coaches have believable scale and a coherent shared design, with restrained variation in trim and window rhythm.
- Couplers remain connected on curves; no gaps, intersecting bodies or impossible rigid pivots.
- Windows, doors, steps, roof seams, undercarriage, axles and wheels use consistent scale.
- Interior details stay legible from the intended camera without cluttering silhouettes.

## Track and bridges
- Rails stay parallel and maintain gauge through curves and across bridges.
- Sleepers remain visible; ballast does not cover sleepers or bury rail bases.
- Fasteners align to rail seats; rail segments meet without gaps, overlaps or floating ends.
- Bridges show load-bearing structure: deck, piers, individual arch stones, keystone, parapets and abutments.
- Track, bridge deck and approach terrain connect continuously; no floating train or rails passing through parapets.
- Stone has controlled variation and defined joints rather than a flat ring or uniform slab.

## Worlds and stations
- Every intro world maps to a stable world/station ID and the same canonical asset used in gameplay.
- Each world has a distinct silhouette, palette, architecture and landmark; avoid generic repeated islands.
- Railway approach, bridge, platform and arrival point connect physically and read from cinematic and gameplay cameras.
- Lighting preserves contrast; pale paths retain texture and highlights are not blown out.
- Review each world in both intro and playable arrival views.

## Materials, lighting and mobile quality
- No missing textures or unexpected black/magenta surfaces; metallic and roughness values are meaningful.
- Avoid overexposed paths, crushed shadows and excessive bloom.
- Main subjects remain readable in 16:9 and common mobile landscape framing.
- Use shared meshes/materials and sensible collision proxies; detail must justify its mobile cost.

## Validation per iteration
1. Regenerate assets using the repository's documented Blender pipeline.
2. Verify source project, exported GLB, named materials and expected outputs.
3. Import GLB into Godot and confirm no missing resources.
4. Capture the actual opening camera and relevant close views.
5. Inspect wheel/rail alignment, couplers, bridge transitions, material response, exposure and silhouette.
6. Run project checks, visual-review workflow and Android APK workflow.
7. Record commit, workflow links, artifacts and remaining defects.

## Definition of done
An asset is not done merely because it exists, exports, imports or passes CI. It must meet the reference-driven visual criteria, connect correctly to neighboring assets, remain readable on a phone, and pass automated validation plus visual inspection. Physical Android motion and performance remain a separate device-test gate.