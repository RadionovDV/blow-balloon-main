# Project State

## Completed
- [x] Spawn player near assigned base
- [x] Replica subscription fixed using `ReadyPlayers` / `NewReadyPlayer`
- [x] Balloon shop UI wired to existing `ShopGui`
- [x] Balloon purchase flow added via `Shop_BuyBalloon`
- [x] Balloon inventory is consumed on `Balloon_Start`
- [x] Rebirth UI controller wired to `HudGui.RebirthFrame`
- [x] Index system added for permanent pet collection tracking
- [x] Pet world spawn moved to server for roulette flow
- [x] Pet flow uses `StandPets` as canonical storage and `Pet_PlaceStand` only reorders existing pets
- [x] Pet movement uses server-driven no-collision hover movement

## In Progress
- [ ] Monetization staged planning

## Frozen Contracts
- [x] PlayerData schema v1
- [x] Remote registry v1
- [x] Core service Init/Start pattern
- [x] Server max players: 4
- [x] Base count in MVP: 4
- [x] Stray pet flow uses Robux pricing and owner reclaim

## Next Tasks
- [ ] Balloon rarity link for roulette (deferred)
- [ ] Monetization stage docs for DeepSeek

## Notes
- Все изменения архитектуры фиксируются здесь после завершения задачи
