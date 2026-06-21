# Pet Receive Flow

## Goal
Fix the pet receive flow so pets are server-owned, visible to all players, and support a `Take / Leave` choice after roulette.

## Role
You are a careful Roblox Luau implementation agent. Make the smallest correct change for pet receive flow and nothing else.

## Read First
- `docs/ARCHITECTURE.md`
- `docs/STATE.md`
- `docs/contracts/API_RULES.md`
- `docs/contracts/DATA_SCHEMA.md`
- `docs/contracts/REMOTES.md`
- `docs/contracts/UI_STRUCTURE.md`
- `docs/systems/BALLOON.md`
- `docs/systems/ROULETTE.md`
- `docs/systems/PETS.md`
- `docs/systems/UI.md`
- `docs/systems/INDEX.md`

## Problem Summary
Current issues to fix:
1. Pet models appear only on the client in `SpawnPets`.
2. Pets on `StandSlot` are invisible to other players.
3. After `Balloon_Stop`, the server gives the pet immediately instead of waiting for a roulette choice.

## Scope
- Part 1 and Part 2 are already complete.
- Work on Part 3 only.

## Core Rule
Pet models must be server-owned and visible to all players.

## Part 1 - Server-owned spawning
- [x] Move pet spawning for `SpawnPets` to the server.
- All players must see the spawned pet model.
- If needed, add a small server module for pet flow instead of keeping this in client code.
- Do not keep spawned pets as client-only visual state.

## Part 2 - Shared stand visibility
- [x] Refactor pet storage so `StandPets` is the only canonical pet field.
- Remove `Pets` usage completely from the flow.
- Do not add migration logic.
- Pets placed on `StandSlot` must be visible to every player.
- Stand updates must be driven from the server.
- Prefer one shared server source of truth for stand models instead of per-client duplication.
- Do not touch roulette choice flow here.
- Do not touch homeless flow here.

## Part 3 - Roulette `Take / Leave`
- After `Balloon_Stop`, do not immediately award the pet.
- Use a new `RemoteFunction` named `Roulette_ResolvePetChoice` for the choice result.
- `RouletteGui` already have two buttons:
  - `Take`
  - `Leave`
- Use a small buffer for pending roulette pet data, preferably in a separate server module like `PendingPetService`.
- Use a separate server movement module like `PetMovementService` for world pet movement.
- `StandPets` is still the only canonical pet storage.
- Do not reintroduce `Pets` anywhere.
- If `Take` is pressed and there are no free stand slots:
  - spawn the pet on `SpawnPets`
  - switch it to the same homeless flow as `Leave`
  - send `Notification` with the message: `Игрок физически не может забрать питомца, из-за нехватки мест на стендах`
- `Take` flow:
  - player selects `Take`
  - pet appears on `SpawnPets`
  - pet moves toward the player's base
  - pet looks in the direction it moves
  - when it reaches the base, it is teleported to the correct `StandSlot`
  - all players see the movement
- `Leave` flow:
  - player selects `Leave`
  - pet appears on `SpawnPets`
  - pet wanders randomly inside `Workspace.Location.POI.PetsMovement`
  - movement must be server-driven with a simple `RunService.Heartbeat` loop
  - each step must choose the next target point
  - pet must look in the direction it moves
  - after 1 minute, pet moves toward `Workspace.Location.POI.PetsQuit`
  - pet disappears permanently
  - all players see the whole flow

## Rules
- Server is authoritative for pet spawning, movement, stand placement, and removal.
- Client only handles UI and input.
- Do not leave important pet visibility logic on the client.
- Do not touch Part 1 or Part 2 except where Part 3 wiring strictly depends on them.
- Do not break unrelated balloon or index systems.
- Do not add extra systems unless a real blocker forces it.
- If a small architectural adjustment is the cleanest fix, do it, but keep it minimal.

## Expected Output
- Fix pet spawning so it is visible to all players.
- Fix stand pets so they are visible to all players.
- Implement the `Take / Leave` roulette flow.
- Keep the implementation server-driven and maintainable.

## Response Format
1. Files changed.
2. Part 1 summary.
3. Part 2 summary.
4. Part 3 summary.
5. Blockers or follow-up work, if any.

## Stop Conditions
- Stop if the task requires a full UI redesign.
- Stop if it requires unrelated changes to index, rebirth, or balloon economy.
- Stop if a new remote or schema change is needed and cannot be avoided.
