# Stray Pets

## Responsibility
- spawn failed pets as world stray pets
- allow Robux purchase by other players
- allow free reclaim by the original owner
- respect `Save Pets` visibility rules

## Server Side
### StrayPetService
- creates stray pet models in the world
- assigns owner, rarity, and purchase state
- allows purchase via Robux flow
- allows owner reclaim for free
- cleans up expired stray pets

## Rules
- stray pets spawn at randomized world points
- stray pets move through the map using server-driven hover motion
- `Save Pets` makes the model semi-transparent
- `Save Pets` hides the Robux buy prompt from other players
- owner reclaim is always free
- purchase price is defined in `MonetizationConfig`

## Data
- stray pets are session-only world entities
- purchase state is authoritative on the server

## Notes
- the player who created the stray pet can always reclaim it
- other players can buy only when `Save Pets` is not active
