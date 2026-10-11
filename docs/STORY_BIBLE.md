# The Lost Things Express — Story Bible (Primary Canon)

**Status:** Primary narrative and gameplay reference  
**Language of in-game text:** English  
**Purpose:** This document is the source of truth for story direction, opening sequence, core gameplay loop, five-world structure, themes, and proposed ending. New features must support this reference unless the story bible is deliberately revised.

## 1. Core premise

The Lost Things Express is a first-person, mobile-first cinematic mystery adventure. A strange steam train crosses five connected fantasy worlds, carrying objects whose owners have lost more than their possessions: they have lost memories, promises, belonging, time, or the meaning attached to something important.

**Core theme:** Sometimes we do not lose things; we lose the meaning that made them matter.

Opening line:
> “Every lost thing remembers where it belongs.”

The opening cinematic takes place **before Stage 1**. It establishes the moving locomotive, connected passenger carriages, railway bridges, and five distinct worlds. It is part of the story, not a menu decoration.

## 2. Stage 1 — The chest and the missing memory

The player awakens in a richly detailed vintage train carriage with a brass key, a torn letter, and a locked memory chest.

### Required sequence
1. Explore the carriage in first person; learn movement, looking, and object interaction.
2. Find and collect the brass key.
3. Inspect and read the torn letter in a close-up physical interaction.
4. The letter reads:

   > WHEN THE CLOCK STRIKES THREE TIMES,  
   > RETURN WHAT THE TRAVELER FORGOT.  
   > DO NOT LET THE CLOCK FINISH.

5. Use the key and the information from the letter to unlock the chest. The lid and first-person hands animate as part of the interaction.
6. Reveal a clearly visible, complete photograph of **SUNSET STATION** inside the chest. The image must not be cropped into a fragment, hidden, or replaced by an approximate placeholder.
7. A door behind the chest leads into a second carriage: the clock compartment. The doorway must be traversable, not merely decorative.
8. The clock becomes the next objective. Interacting with it after the chest sequence triggers three chimes and a change in the world outside, foreshadowing the journey.

**Stage 1 reveal:** The player recovers a photograph but not the memory behind it. Sunset Station does not appear on any known map.

## 3. Clock compartment

The second carriage must feel like a meaningful place the player can enter. It should have a clear open doorway, believable carriage construction, warm practical lights, walnut and brass detailing, a carpet runner, and a focal clock niche. The clock must be readable as the objective. The player should be able to walk from the first carriage through the doorway without collision-blocking geometry.

The warning about the clock is a narrative mystery. Do not explain its full meaning in the opening.

## 4. The five worlds

The railway connects five worlds that each have a distinct visual identity and a narrative theme. Their landmarks should be memorable and should remain consistent when revisited; they are not disposable background scenery.

1. **The Clockwork Kingdom — lost time and missed chances.** Stone keeps, brass gears, and clocks stopped at different moments. Gameplay: gear alignment, clock comparisons, and puzzles based on chimes.
2. **The Cloud Islands — lost belonging.** Floating islands, waterfalls into clouds, separated homes, and railway bridges. Gameplay: restore bridges and routes; connect clues belonging to people separated from one another.
3. **The Remembering Forest — lost memories and identity.** Ancient trees, an abandoned village, and echoes of people who passed through. Gameplay: listen to sound clues and associate objects and memories with the right places and people.
4. **Sunset Station — lost promises and relationships.** The station from the photograph exists but is abandoned. Gameplay: compare the photo with the real location, arrange belongings and letters, and decide what to do with a message that never reached its recipient.
5. **The Last Terminal — truth and acceptance.** Railway lines converge at a vast terminal filled with clocks, old carriages, and doors. Gameplay: a multi-step final puzzle that requires clues gathered across the previous worlds.

These are the canonical world identities and themes. Detailed level geometry, puzzles, characters, and events must be implemented and tested; their inclusion here does not imply that they already exist in the game.

## 5. Core gameplay loop

Explore → inspect and interact → compare evidence → infer a connection → solve a puzzle → reveal a story beat or open a route.

Mobile controls should support:
- Virtual movement joystick.
- Touch-drag camera/look controls.
- Contextual interaction button near usable objects.
- Close-up inspection for letters, photographs, keys, and mechanisms.
- An evidence journal that records collected photographs, messages, and symbols.
- First-person hands for tactile interactions, with credible proportions, fingers, joints, nails, and animation.

Combat is not a core mechanic. Suspense comes from sound, environmental changes, time pressure, unfamiliar spaces, and connected clues.

## 6. Mystery behind the train

The train gathers objects whose owners have lost their connection to them. Each carriage preserves an unfinished memory. The protagonist initially believes they are simply helping return lost belongings, but evidence across the five worlds suggests that they have been to these places before.

The Sunset Station photograph is the first clue that the larger mystery is personal: the protagonist may be connected to the memory they are trying to recover. Reveal this gradually through objects, photographs, letters, and sound, rather than a long exposition dump.

## 7. Proposed finale and endings

At the Last Terminal, the player discovers that the great clock does more than measure time: it determines when unrecovered memories are erased. The player combines clues from all five worlds to restore the clock's course and faces a final choice about the memory they have recovered.

- **Restoration ending:** The player returns the memory to its owner. The train leaves the terminal at dawn; accepting the past makes it possible to move forward.
- **Letting-go ending:** The player chooses not to return the memory. The train's pursuit ends in a quieter, more ambiguous conclusion.

Neither ending should be treated as a simple good/bad outcome. Each should have understandable consequences. These endings are the approved narrative direction, not a claim that branching endings are already implemented.

## 8. Meaning and emotional promise

The story should express three connected ideas:
- An apparently ordinary object can carry a life-changing story.
- Forgetting or avoiding pain does not necessarily resolve it.
- Recovering a memory is not the same as returning to the past; it can mean understanding what happened and moving forward.

The intended final thought:
> You do not have to return everything to the way it was. You have to understand what is worth carrying with you, and what you must allow to go.

## 9. Production and acceptance rules

- Keep in-game text in English.
- Preserve the five world identities and their continuity.
- Keep the opening cinematic before Stage 1.
- The chest, photograph, letter, doorway, and clock sequence must be playable and visually verified in-engine.
- The photograph and letter must be legible and faithful to the approved reference; never accept a successful build as proof of visual quality.
- First-person hands must be judged in actual gameplay screenshots, not only by mesh counts or code inspection.
- Avoid placeholder overlays that conceal unfinished geometry or interactions.
- Each world needs actual playable puzzles and story consequences; a beautiful backdrop alone is not a completed stage.
- A feature is not complete until build/tests pass **and** its in-engine behavior and visual result have been reviewed.
- This story bible is the primary reference for future implementation, testing, and continuity. If a design decision conflicts with it, follow this document or explicitly revise it with the project owner.
