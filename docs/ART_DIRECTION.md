# Art Direction — The Lost Things Express

**Status: LOCKED BASELINE.** The user's supplied concept image is the permanent primary visual reference for this project. Continue from this direction across sessions, branches, contributors, and development environments. Do not casually replace it with a different art style.

## Visual north star
A premium, cinematic, handcrafted 3D fantasy adventure featuring:
- A majestic antique steam locomotive with dark mahogany, aged brass, copper fittings, rivets, and glowing amber lanterns.
- A curious, expressive young train explorer, accompanied by memorable animal companions.
- Dreamlike floating islands, grand clock towers, distant castles, bridges, waterfalls, clouds, and strange stations.
- Warm golden light from the train contrasted with cool midnight blues and atmospheric skies.
- Story-rich lost objects presented as tactile treasures: keys, watches, photographs, letters, toys, music boxes, and keepsakes.
- Rich cinematic compositions with a clear focal subject, layered depth, readable silhouettes, and carefully controlled detail.

## Palette
- Midnight navy: #071A28
- Deep teal: #164451
- Antique brass: #B8752D
- Lantern amber: #FFB24D
- Mahogany: #4B2419
- Parchment: #E8D8B7
- Cloud ivory: #F3E9D6

## Materials and lighting
Use physically based materials with restrained roughness variation, convincing brass and wood, warm practical lights, cool atmospheric fill, soft volumetric depth where mobile performance allows, and selective bloom. Never let bloom, fog, particles, or UI cover important puzzle clues.

## Shape language
- Train: bold recognizable silhouette, rounded metalwork, brass trim, rich wood, glowing windows.
- Characters: expressive faces and distinct silhouettes, premium stylization rather than generic low-poly placeholders.
- Lost objects: handcrafted, tactile, and legible at phone-screen size.
- Worlds: fantastical vertical scale, floating architecture, bridges and waterfalls; avoid generic flat environments.
- UI: dark navy panels, brass borders, warm parchment typography, elegant iconography, clear Arabic localization and touch targets.

## Production rules
1. This document is the stable art-direction contract; update it only deliberately and document why.
2. The supplied reference image is the primary visual north star, not a license to copy unrelated copyrighted characters or logos.
3. The prototype may use temporary geometry to validate mechanics, but temporary geometry is not the final quality bar.
4. Build final models in Blender and import through GLB/glTF with named materials and tested collision proxies.
5. Review every major scene against the reference palette, lighting, material quality, composition, and storytelling.
6. Always validate readability and frame pacing on real Android hardware before expanding asset complexity.
7. Preserve the art direction in future sessions and development locations; read this file before visual changes.

## Reference image archival
The full reference inventory and intended repository paths are tracked in [`art/reference/README.md`](../art/reference/README.md). Preserve both source images unchanged:
- `art/reference/lost-things-express-primary-reference.png` — primary concept board.
- `art/reference/lost-things-express-concept-wide.png` — alternate wide capture of the concept board.

Do not substitute a newly generated image and claim it is the user's original reference. The archive is incomplete until both original binary files are committed and verified. Build success alone never approves visual fidelity.


## First-stage carriage reference — approved by the user (2026-10-10)

The user's newly supplied carriage photograph is the definitive reference for the **playable opening compartment**. Keep the same centered, eye-level view down a clear central aisle into a second warmly lit compartment. The cabin should read as a real, premium vintage sleeper carriage rather than a box-shaped prototype.

### Non-negotiable visual cues
- Polished dark walnut/mahogany joinery with layered, beveled panel frames and fine brass inlay.
- Deep emerald-green leather bench seats facing each other across the aisle; sculpted wood armrests and subtle upholstery seams.
- Tall side windows with substantial dark wood/brass surrounds; pleated deep-green curtains and brass tie-backs.
- A cream/ivory ceiling with repeated arched-looking walnut ribs, recessed panels, and warm brass ceiling lamps.
- Emerald patterned aisle carpet with antique-gold borders and small repeating woven motifs.
- Warm golden pools of light and visible material detail in shadows; cool blue twilight scenery outside windows.
- Marble-topped small tables beside the seats, brass reading lamps, overhead luggage racks with leather suitcases, and a central discoverable brass-trimmed suitcase.
- A far-end doorway framing a second carriage section with depth, chairs, and a small focal clock; avoid a flat dead-end wall.
- Cinematic symmetry and a readable walkable aisle. Decorative objects must not block movement or hide quest items.

### First playable stage — independent component checklist
1. **Carriage shell** — openings, wall/ceiling/floor, modular collision, doorway into the next compartment.
2. **Joinery kit** — walnut panels, carved borders, brass rails, rivets, window casings and arch ribs.
3. **Windows & curtains** — dark-blue exterior view, window reflections kept subtle, green pleats and tie-backs.
4. **Seating kit** — emerald leather upholstery, piping/tuft details, walnut armrests and brass feet.
5. **Tables & lamps** — dark polished marble tops, brass supports and small warm practical lights.
6. **Ceiling & lighting** — ivory inset panels, walnut arches, warm ceiling fixtures plus low-cost ambient fill.
7. **Carpet & trim** — patterned emerald runner with restrained gold details, not a noisy high-contrast texture.
8. **Luggage & story props** — overhead racks, leather bags, a brass-edged suitcase and readable interactive lost objects.
9. **Far doorway & next compartment** — layered framing and a strong depth cue.
10. **Playable interactions** — reliable touch movement/look, visible interaction prompt, key/letter/chest sequence and objective feedback.

Build these as separately named, reusable Blender collections and Godot scene/components where practical. Test the full opening sequence in the actual Godot scene at mobile aspect ratio and performance settings. The uploaded photograph is the quality target; a successful import/export or CI run alone is not visual approval.


## Root-level visual quality commitment — permanent (confirmed 2026-10-10)

The current prototype is **not approved as visually complete**. The next production work must improve the foundations, not merely add polish on top of placeholder geometry.

### Required production order
1. **Finish the opening locomotive/world shot first.** Replace the primitive train silhouette with an authored, detailed locomotive; build physically continuous curved rails and visible viaduct links; make the distant worlds read as terrain with depth, vegetation, architecture, atmosphere and consistent scale. Iterate from actual mobile-aspect screenshots until the opening scene is explicitly approved.
2. Rebuild the playable carriage to the approved reference: carved walnut/mahogany joinery, emerald upholstered seating, patterned aisle carpet, tall windows and pleated curtains, ivory ceiling with ribs, warm brass lamps, luggage racks and layered doorway depth.
3. Verify that the world beyond the carriage windows belongs to the same rail-connected setting, with no disconnected placeholder ovals or scenery that contradicts the establishing shot.
4. Make the story interactions physically coherent: key pickup, letter inspection, chest lock, hinged lid and photograph reveal must form one understandable sequence and persist after save/resume.
5. **Only after the opening train/world scene is visually approved, move on to the first-person hands.** Replace the primitive hands with authored, believable anatomy and materials; validate grasp/contact points, finger proportions, paper visibility and animation in actual mobile captures.
6. Run automated project checks and Android build, then inspect actual in-game renders at mobile aspect ratio and verify the complete sequence on a real device before approving quality.

### Non-negotiable rules
- Prioritize asset quality and visual inspection before expanding content.
- Build success, code presence, procedural placeholders, and illustrative target images are not proof of final visual quality.
- Do not claim a visual/device test passed unless the corresponding render, screenshot/video, or device result was actually inspected.
- Do not alter the existing movement controls or camera handling solely to make visual work easier.
- Keep this commitment in the repository as the persistent handoff contract across sessions and work locations.
