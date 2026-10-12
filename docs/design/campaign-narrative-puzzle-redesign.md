# Campaign narrative and puzzle redesign

Status: **design baseline approved for implementation; not yet game-complete**.

The present campaign has five themed arenas, but the play loop is mostly “tap three labelled objects in a known order.” That is a test scaffold, not a satisfying adventure. This document replaces it as the acceptance target.

## The core mystery — The Passenger Who Was Erased

The player wakes on the Lost Things Express with a brass key, a torn letter written in their own handwriting, and a photograph of Sunset Station. The letter warns: **“If the clock reaches the last chime, you will forget why you boarded.”** The train has no conductor. Each world outside the carriage is frozen at the instant somebody abandoned an important promise; a missing passenger's silhouette appears briefly in reflections, but never directly.

The player initially assumes the train is trying to steal their memories. Clues gradually reverse that belief: the train is preserving the memories until the player is ready to face them. The antagonist is the **Collector**, a voice heard through station speakers and clock mechanisms. It offers to remove painful moments in exchange for a “quiet” life. Its claims must be contradicted by environmental evidence, not explained only in dialogue.

The emotional reveal: the player once promised to meet someone at Sunset Station, but chose to leave rather than face a difficult goodbye. The memory has been fragmented—not because the player is evil, but because shame made the event easier to misremember. The final choice is not a simple good/bad ending: restore the full memory and accept responsibility, or release the memory's hold while keeping what it taught. Both endings must show a specific, different future.

## Narrative rules

- Every world answers one question and raises a more personal one. No generic “the world remembers” reward repeated five times.
- Environmental clues precede exposition: an empty second seat, a clock stopped one minute before departure, a platform announcement with a cut-off name, a reflection that includes a second person.
- The Collector speaks sparingly and tries to persuade the player to stop investigating. It should feel present before it is explained.
- Use short scenes with action, sound, and changed world state. Story cards support the scene; they must not carry the whole story.
- Each solved puzzle reveals a concrete memory fragment, a physical clue, and a change in the world.
- The photograph, letter, key, train, clock, and station must remain causally connected. Do not introduce unrelated fantasy lore.

## Five-world arc

### 1. The Clockwork Kingdom — “The minute that will not pass”
**Question:** Why does the train's clock stop at 11:59?
**Mechanic:** Restore a broken escapement. The player examines three gear assemblies, reads a mechanical diagram, then rotates/interacts with components to align teeth and release the minute hand. It is not a labelled three-button sequence. Mistakes produce a visible jam and a clue about the missing tooth.
**Evidence/reveal:** A brass passenger token engraved with half a name. The Collector's voice says the last chime can make regret disappear.
**World change:** The clock advances one minute; the first section of railway physically connects to the gate.

### 2. The Cloud Islands — “The seat saved for nobody”
**Question:** Who was the second passenger?
**Mechanic:** Reconnect a broken route across three floating platforms. Read wind vanes/cloud shadows and choose bridge spans whose height and direction form one continuous path. The player must walk the route; an incorrect span breaks/fades and gives readable feedback.
**Evidence/reveal:** A torn ticket for two passengers, but only one name remains legible.
**World change:** Clouds part and a distant coach becomes visible; a second shadow briefly appears beside the player.

### 3. The Remembering Forest — “A voice in the wrong order”
**Question:** Why does the name on the ticket sound familiar?
**Mechanic:** Listen to three distinct echo sources, then reproduce a sound motif at the memory tree. Audio cues and visual ripples must support deaf/low-volume play; wrong notes reset only the current phrase, not the whole level.
**Evidence/reveal:** The lullaby is recognized, but the face attached to it remains obscured. A tree-ring memory shows the player leaving a platform.
**World change:** The forest's lights stop flickering; a path appears where the player had seen a dead end.

### 4. Sunset Station — “The announcement that never finished”
**Question:** Was the missed meeting an accident?
**Mechanic:** Reconstruct a platform announcement from timetable fragments, ticket halves, and the physical photograph. Match time, platform, and destination from environmental evidence. The game must let the player inspect the photograph and compare it with the actual station architecture.
**Evidence/reveal:** The train was delayed. The player had time to return, but chose not to. The story avoids blaming the player for an accident; the conflict is a human choice and an avoided goodbye.
**World change:** The station announcement finishes the missing name. The final train arrives without a driver.

### 5. The Last Terminal — “The last chime”
**Question:** What does remembering cost—and who benefits from forgetting?
**Mechanic:** Combine the key, ticket, sound motif, and timetable into a single memory mechanism. Earlier clues must be used, not repeated as another arbitrary three-item sequence. The player then chooses what to do with the photograph at the final clock.
**Reveal:** The Collector is the train's protective function turned cruel by the player's avoidance: it has mistaken numbness for safety.
**Choice/endings:**
- **Restore:** play a short, specific memory scene at the platform; the player acknowledges the promise and boards the train with the full truth. The last clock moves forward.
- **Release:** place the photograph on the empty seat and leave without denying what happened; the player keeps the lesson but stops replaying the moment. The train departs at dawn.
Both endings need different animation, lighting, sound, final text, and final camera composition.

## Puzzle quality gates

Every puzzle must pass all of these before acceptance:
1. The objective is understandable without a walkthrough.
2. At least two clues are available in the environment; one may be optional.
3. The player performs a world-specific action (align, route, listen/replay, reconstruct, combine), not only taps a prescribed sequence.
4. Feedback distinguishes progress, error, and success through animation/audio/UI.
5. An error is recoverable without a frustrating full-level reset.
6. Solving changes the world and reveals story evidence.
7. Touch controls remain practical on a phone in landscape.
8. Automated tests cover correct solution, a wrong attempt, retry, gate unlock, transition, saved progress where applicable, and both final choices.

## Implementation order

1. Replace generic repeated story beats with the mystery arc and world-specific revelations.
2. Implement a genuinely distinct mechanic in each world, beginning with the Clockwork Kingdom as a vertical slice.
3. Add feedback and world-state changes, then adapt automated tests to player actions rather than directly setting completion flags.
4. Implement the remaining four mechanics one at a time.
5. Play the entire campaign on a physical Android phone. A passing build is not story/puzzle acceptance.

**Current status:** the repository still contains the older three-object sequence implementation. Do not mark the campaign as complete until the mechanics above replace it and pass playtesting.
