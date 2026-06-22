# Index System

## Responsibility
- track all pets the player has ever obtained
- store unique pet names permanently
- show collection progress in UI

## Server Side
### IndexService
- adds pet names to the player's index when `PetService.AddPet` succeeds
- keeps index unique
- persists index in ProfileStore

## Client Side
### IndexController
- renders the full pet catalog
- marks collected pets as open
- marks uncollected pets as locked
- updates progress UI from replica data

## Data
- `Index` = list of unique pet names the player has obtained at least once

## Notes
- source of truth is server data replicated through Replica
- UI shows the whole catalog from `PetConfig.Base`
