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
- [x] Monetization Stage 1 foundation:
  * MonetizationEntitlements data model (GamePasses, Claims, Timed)
  * PlayerService: last-known GamePass cache with MarketplaceService sync
  * PlayerService: StarterPack join-time one-time claim flow
  * PlayerService: Timed boost expiry filter on load
  * RebirthService: RebirthMoney multi-use bonus (replaces StarterPack)
  * RebirthConfig: starterPackCash → rebirthBonusCash
  * DATA_SCHEMA.md: MonetizationEntitlements documented
  * MONETIZATION.md: rules and architecture updated
- [x] Monetization Stage 2 ownership and receipts:
  * MonetizationService created: ProcessReceipt + productHandlers
  * PromptGamePassPurchaseFinished: re-check ownership (only ok+owns updates cache)
  * productHandlers: 4 offer tables (ENSURE_ROLL, SERVER_LUCK, SAVE_PETS, MONEY) + Stickers
  * Idempotency: runtime grantedReceipts by PurchaseId
  * ServerLuck: runtime-only, not in profile
  * Stickers: persisted inventory field in ProfileTemplate
  * Server.legacy.luau: MonetizationService Init/Start added
  * MonetizationConfig: GAMEPASS_IDS + 4 offer tables + STARTER_PACK_BUNDLE + REBIRTH_MONEY_AMOUNT
  * StickerConfig: created with Stickers[] array (productId inside each sticker)
  * GameConfig: cleaned — monetization/sticker fields removed
  * PlayerService: StarterPack bundle (coins, balloons, pet, Index dedup, SavePets timed)
  * DATA_SCHEMA.md: Stickers field documented
  * MONETIZATION.md: Stage 2 rules, configs, routing, StarterPack bundle documented

## In Progress
- [ ] Balloon rarity link for roulette (deferred)

## Completed (Stage 3)
- [x] FormatNumber: Shared/Util/FormatNumber with Format() and FormatTime()
- [x] RobuxShopController: open/close ShopGui, Buy/Purchased/Equip/Unequip states from Replica
- [x] Temporary boost UI: HudGui.States renders active Timed boosts with live countdown
- [x] BalloonService: EnsureRoll forces roulette when active
- [x] BalloonService: Roulette leave creates stray pet via StrayPetService
- [x] RouletteService: WithoutBombs gamepass disables bomb outcome
- [x] StrayPetService: stray pet lifecycle with Save Pets transparency/prompt suppression
- [x] StrayPetService: free owner reclaim, priced buy for others, cleanup timers
- [x] StickerService: server-side Equip/Unequip validation via RemoteFunctions
- [x] Sticker flow: single active sticker, Decal.ColorMapContent apply on balloon
- [x] Save Pets stray-pet behavior: Transparency 0.5, buy prompt disabled for non-owners
- [x] MonetizationConfig: STRAY_PRICES and BOOST_ICONS tables
- [x] PlayerService ProfileTemplate: ActiveSticker field (persistent)
- [x] Client boot: +RobuxShopController
- [x] Server boot: +StrayPetService, +StickerService

## Frozen Contracts
- [x] PlayerData schema v1
- [x] Remote registry v1
- [x] Core service Init/Start pattern
- [x] Server max players: 4
- [x] Base count in MVP: 4

## Next Tasks
- [ ] Balloon rarity link for roulette (deferred)

## Notes
- Все изменения архитектуры фиксируются здесь после завершения задачи
