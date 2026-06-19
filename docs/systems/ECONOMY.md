# Economy System

## Responsibility
- Add / remove coins
- Handle rewards
- Handle shop purchases
- Centralize currency mutation

## Server Side
### EconomyService
- `AddCoins(player, amount)`
- `SpendCoins(player, amount) -> bool`
- `CalcReward(...)`

## Rules
- All currency changes are server-side
- Client only displays values
- Shop must validate affordability on server