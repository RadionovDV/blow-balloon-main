# Pets System

## Responsibility
- Pet inventory
- Pet placement on stands
- Passive income
- Pet visuals

## Server Side
### PetService
Methods:
- `AddPet(player, petResult) -> entry`
- `PlaceOnStand(player, petUid, slot) -> bool`
- `SellFromStand(player, slot) -> bool`
- `SellPet(player, petUid) -> bool`
- `UpgradeBase(player) -> bool`

## Client Side
### PetController
- spawns pet visuals
- refreshes stand models
- shows billboards
- calls server actions for placement / collection

## Data
- `StandPets` = all pets the player owns

## Flow
- New pets are auto-placed into the first free `StandPets` slot by `AddPet`
- `PlaceOnStand` only reorders existing owned pets between stand slots
- `SellFromStand` sells a pet from a stand slot

## Notes
- Income is server-authoritative
- Client only displays running visuals and sends interactions
- World pets for roulette spawn are server-owned and visible to all players
- World pet movement is server-driven, collisionless, anchored, and keeps height via raycast hover
