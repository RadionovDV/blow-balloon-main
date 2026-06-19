# Roulette System

## Responsibility
- Generate roulette result
- Play roulette animation
- Show result UI
- Handle Take / Exit flow

## Server Side
### RouletteService
- rolls outcome
- supports bomb / key / pet results
- respects max rarity per balloon

## Client Side
### RouletteController
- builds animation sequence
- plays slot animation
- shows result
- calls `BalloonController.ReturnFromRoulette()`

## Result Types
- `pet`
- `key`
- `bomb`

## Notes
- Roulette is a visual client flow, but result source is server