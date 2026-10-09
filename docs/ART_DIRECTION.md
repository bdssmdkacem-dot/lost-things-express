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
