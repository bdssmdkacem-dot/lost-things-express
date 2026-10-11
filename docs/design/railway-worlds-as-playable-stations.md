# Railway Worlds as Reusable Playable Stations

Status: **mandatory architecture and level-design rule** (2026-10-11).

## Core rule

Every distinct world shown along the railway in the opening train journey is a real game location, not disposable background scenery. The opening cinematic must preview the same canonical world/station assets that the player will later visit during gameplay. Do not create a cinematic-only version and then rebuild a visually different level for the stage.

## Required world pipeline

1. **Canonical world/station scene** — each world has one reusable Godot scene (or a clearly separated scene composition) containing its terrain silhouette, station/landmarks, railway segment, bridge/track connections, lighting mood, materials, collision, and points of interest.
2. **Opening journey** — the moving train passes and reveals instances of these same world assets. The camera may use cinematic framing and distance LODs, but the recognizable landmarks, palette, architecture, and track layout must match the playable station.
3. **Stage gameplay** — selecting a stage loads or streams the same canonical station scene, with its full-resolution gameplay geometry, collision, interactions, puzzle objects, and navigation.
4. **Shared updates** — visual fixes to a world/station must be made to its canonical source so the opening and its playable stage stay consistent. Avoid duplicated scene geometry or independent hand-maintained copies.
5. **Performance tiers** — cinematic instances may use cheaper LODs or distant proxy meshes derived from the canonical asset, but they must preserve the same silhouette, landmark placement, material identity, and railway continuity. Proxies are presentation variants, not separate world designs.

## World/stage identity

Maintain an explicit data mapping from each world/station ID to:
- its canonical scene/resource path;
- the cinematic segment/railway connection used by the intro train;
- its stage ID and playable spawn/arrival point;
- signature landmarks and environmental storytelling;
- its puzzle/interaction set and completion state.

A stage must never be assigned an unrelated replacement landscape just to make level loading easier. The train route and stage progression should use the same world IDs and station data.

## Acceptance checks

- Each world visible in the intro is assigned a stable world/station ID and a future playable stage.
- The intro and playable stage use the same canonical station assets or clearly derived LODs.
- Railway alignment at each station approach is continuous; bridges and tracks connect physically to the station.
- A world change made in the canonical asset appears in both the intro and stage build.
- Automated validation checks that every intro world reference resolves to a station definition and playable scene.
- Visual review compares the cinematic view and playable arrival view for each world before the world is approved.

## Implementation order

1. Finish and visually approve the train, coaches, couplers, track and bridge in the opening scene.
2. Define stable world/station IDs and a small registry/resource for intro-to-stage mapping.
3. Separate the five planned fantasy-world/station environments into reusable canonical scenes.
4. Make the cinematic route instantiate/reference those assets rather than standalone scenic geometry.
5. Connect stage selection to the same station scenes and add each stage's gameplay layer.
6. Add streaming/LOD only after shared identity and track continuity are correct.

This rule does not authorize moving on to hand/character polish while the train and railway opening still fail visual acceptance.
