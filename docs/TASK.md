# Rebirth Task

## Goal
Implement `Rebirth` as a repeatable server-side progression reset.

## Role
You are a careful Roblox Luau implementation agent. Make the smallest correct change for `Rebirth` and nothing else.

## Core Rule
`Rebirth` can be used multiple times.
Each rebirth tier may have different requirements, so validation must depend on the current `RebirthCount`.

## Read First
- `docs/ARCHITECTURE.md`
- `docs/STATE.md`
- `docs/contracts/API_RULES.md`
- `docs/contracts/DATA_SCHEMA.md`
- `docs/contracts/REMOTES.md`
- `docs/systems/ECONOMY.md`
- `docs/systems/PETS.md`
- `docs/systems/LUCK.md`
- `docs/systems/MONETIZATION.md`

## Rebirth Rules
- Current rebirth tier is determined by `RebirthCount`.
- Rebirth requirements must be resolved per tier.
- For the current task, the base requirements are:
  - cost: `10000` coins
  - required pets: `Frog` and `Cube`
  - luck multiplier: `1.2`
- The implementation must support future tiers with different costs, pets, and multipliers.

## Rebirth Effects
On successful rebirth:
- increase `RebirthCount`
- apply the rebirth luck multiplier to permanent luck (`BaseLuck`)
- clear owned pets
- reset coins
- clear balloon inventory
- grant starting money if the player owns the relevant GamePass

## Rules
- All rebirth validation and mutation must happen on the server.
- Do not let the client decide whether rebirth is allowed.
- Do not change unrelated systems unless required by a real blocker.
- Do not add new remotes unless there is no valid way to complete the task with existing contracts.
- Do not change data schema unless the rebirth flow cannot be implemented otherwise.
- If a schema or contract change is needed, stop and explain why.

## Expected Output
- Implement the rebirth flow.
- Use `RebirthCount` to choose the active rebirth rule set.
- Report how requirements are validated.
- Report how player data is reset.
- Report how the luck multiplier is applied.

## Response Format
1. Files changed.
2. Rebirth rule resolution summary.
3. Reset / reward summary.
4. Blockers or follow-up work, if any.

## Stop Conditions
- Stop if rebirth would require roulette changes.
- Stop if rebirth would require unrelated UI redesign.
- Stop if rebirth requires a new remote or breaking schema change.
