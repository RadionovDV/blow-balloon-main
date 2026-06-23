# Stray Pets

## Responsibility
- spawn failed pets as world stray pets
- allow Robux purchase by other players via DevProduct
- allow free reclaim by the original owner
- respect `Save Pets` visibility rules

## Server Side
### StrayPetService
- creates stray pet models in the world at randomized spawn points
- assigns owner, rarity, and purchase state
- starts server-driven hover movement via `PetMovementService.WanderStray`
- allows purchase via Robux DevProduct flow (`MarketplaceService:PromptProductPurchase`)
- allows owner reclaim for free
- validates ownership and routes prompt triggers (Buy or Claim)
- cleans up expired stray pets (120s timeout)
- `GrantStrayPurchase` — called by `MonetizationService` on successful `ProcessReceipt`

## Client Side
### StrayPetController
- scans `Workspace` once on `Start()` and listens to `DescendantAdded`
- for each `ProximityPrompt` with an `OwnerUserId` attribute on its parent, updates:
  - owner → `ActionText = "Claim"`, `Enabled = true`
  - non‑owner, `SavePetsActive` true → `Enabled = false`
  - non‑owner, no `SavePetsActive` → `ActionText = "Buy"`, `ObjectText` with Robux price, `Enabled = true`

## Rules
- stray pets spawn at randomized world points using `Random.new()`
- stray pets move through the map using server-driven hover motion (`WanderStray`, no auto‑despawn)
- `Save Pets` makes the model semi‑transparent and disables the prompt for non‑owners
- `Save Pets` is applied retroactively to all existing stray pets of the player
- owner reclaim is always free
- purchase price is defined in `MonetizationConfig.STRAY_PRICES` as `{ productId, priceRobux }`
- one single `ProximityPrompt` per stray pet; server validates action on trigger

## Data
- stray pets are session-only world entities
- purchase state is authoritative on the server
- model carries `OwnerUserId`, `StrayPrice`, `SavePetsActive` Instance Attributes for client-side presentation

## Model Attributes
- `OwnerUserId` (number) — the `UserId` of the player who created the stray pet
- `StrayPrice` (number) — Robux price shown in the prompt
- `SavePetsActive` (boolean) — whether Save Pets protection is active

## Notes
- the player who created the stray pet can always reclaim it
- other players can buy only when `Save Pets` is not active
- after purchase/reclaim, the pet model is created on the base via `PetService.CreateStandModel`
- pending purchases are stored in-memory and cleaned up on `PlayerRemoving`
- `GrantStrayPurchase` is routed through `MonetizationService.ProcessReceipt`