# Task: Balloon Shop

## Goal
Implement the balloon shop in three isolated phases so the agent does not expand scope.

## Source Docs
- `docs/ARCHITECTURE.md`
- `docs/STATE.md`
- `docs/contracts/API_RULES.md`
- `docs/contracts/DATA_SCHEMA.md`
- `docs/contracts/REMOTES.md`
- `docs/systems/UI.md`
- `docs/systems/ECONOMY.md`
- `docs/systems/ROULETTE.md`
- `docs/systems/LUCK.md`
- `docs/systems/BALLOON.md`

## Hard Rules
- Stay within the current phase only.
- Do not implement future phases early.
- Do not change architecture, contracts, or data schema unless the task explicitly requires it.
- If a required change touches a contract, stop and report it instead of guessing.
- Use existing `BalloonConfig` as the source of truth for balloon metadata.
- Keep all server-critical logic on the server.

## Phase 1 - Shop UI
### Scope
- Open the shop from `HudGui.RightSide.ShopButton`.
- Show and hide the shop window.
- Display the list of balloons from config.
- Show balloon names and prices.
- Allow selecting a balloon in UI, but do not purchase yet.

### Do Not Touch
- Inventory mutation.
- Currency mutation.
- Roulette rarity logic.
- Balloon reward logic.
- Pet spawning or pet inventory.

### Expected Result
- A working shop interface that can be opened and closed from the HUD.
- The UI is wired to the existing balloon data.

## Phase 2 - Purchase and Inventory
### Scope
- Buying one balloon adds one balloon to player inventory.
- Validate purchase on the server.
- Deduct coins through `EconomyService`.
- Update player balloon data through replica-backed state.
- Use `BalloonConfig` for price and metadata.

### Do Not Touch
- Roulette rarity rules.
- UI layout beyond buy interaction.
- Reward formulas.

### Expected Result
- Server-authoritative purchase flow for balloon inventory.

## Phase 3 - Balloon to Roulette Rarity Link
### Scope
- Balloon `maxRarity` determines the highest pet rarity available in roulette.
- Rarities above the balloon limit are still possible, but their chance is reduced by 10x.
- Keep the rarity decision server-side.
- Integrate into existing roulette flow without rewriting the whole system.

### Do Not Touch
- Shop UI.
- Purchase flow.
- Balloon inventory logic.

### Expected Result
- Roulette respects balloon quality while keeping a non-zero chance for higher rarities.

## Current Task
- Phase 1 only.

## Completion Criteria
- The agent reports only changes relevant to Phase 1.
- The response lists files changed and a short summary.
- The response must mention any required follow-up for Phase 2, if discovered.
