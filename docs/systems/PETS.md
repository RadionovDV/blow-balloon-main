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
- `RemoveFromStand(player, slot) -> bool`
- `SellPet(player, petUid) -> bool`
- `UpgradeBase(player) -> bool`

## Client Side
### PetController
- spawns pet visuals
- refreshes stand models
- shows billboards
- calls server actions for placement / collection

## Data
- `Pets` = inventory
- `StandPets` = placed pets

## Notes
- Income is server-authoritative
- Client only displays running visuals and sends interactions