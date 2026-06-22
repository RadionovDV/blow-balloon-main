# Monetization System

## Responsibility
- Monopolises all monetization entitlements: GamePass ownership, Claims, Timed boosts
- GamePass ownership cache (last-known, persisted in MonetizationEntitlements.GamePasses)
- DevProduct handling (via ProcessReceipt, except ServerLuck)
- StarterPack claim flow (join-time, one-time)
- PromptGamePassPurchaseFinished signal for ownership re-check after purchase
- ProcessReceipt routing via productHandlers table (ProductId → handler)

## Rules
- GamePass ownership: MarketplaceService — source of truth, MonetizationEntitlements.GamePasses — fallback cache
- UserOwnsGamePassAsync успех: записать true/false в cache
- UserOwnsGamePassAsync ошибка: не трогать cache (использовать last-known)
- MonetizationEntitlements.Claims — idempotency флаги, один раз установлены — больше не меняются
- ServerLuck (DevProduct) — runtime-only, не сохраняется, не переживает rejoin
- StarterPack обрабатывается на PlayerAdded, не в RebirthService
- RebirthMoney — multi-use GamePass-эффект, проверяется при каждом Rebirth
- monetization state is replicated through MonetizationEntitlements in PlayerData
- ProcessReceipt возвращает только PurchaseGranted или NotProcessedYet
- Idempotency: runtime set grantedReceipts по receiptInfo.PurchaseId
- PromptGamePassPurchaseFinished — только signal для перепроверки, не source of truth
- GamePass и DevProduct — раздельные механизмы в одном MonetizationService

## Data Structure
- MonetizationEntitlements хранится в ProfileStore как часть PlayerData
- Runtime passCache дублирует MonetizationEntitlements.GamePasses для быстрых проверок
- ServerLuck живёт только в LuckService (serverBoostAmount / serverBoostExpires)
- grantedReceipts — runtime-таблица { [PurchaseId] = true }, не persistent
- Stickers = {} — persisted inventory, пишется через ProcessReceipt

## Configuration
- MonetizationConfig — GAMEPASS_IDS, ENSURE_ROLL_OFFERS, SERVER_LUCK_OFFERS, SAVE_PETS_OFFERS, MONEY_OFFERS, STARTER_PACK_BUNDLE, REBIRTH_MONEY_AMOUNT
- StickerConfig — Stickers[] с name, rarity, icon, productId (source of truth для sticker→productId связи)
- GameConfig — только core game constants (SERVER_BOOST_AMOUNT/DURATION остаются)

## Product Routing (ProcessReceipt)
- **EnsureRoll** → each offer.productId → MonetizationEntitlements.Timed (id="EnsureRoll", startsAt/expiresAt)
- **ServerLuck** → each offer.productId → LuckService.AddServerBoost(amount, offer.duration) (runtime-only)
- **SavePets** → each offer.productId → MonetizationEntitlements.Timed (id="SavePets", startsAt/expiresAt)
- **Money** → each offer.productId → EconomyService.AddCoins(offer.amount)
- **Stickers** → each StickerConfig.Stickers[].productId → data.Stickers (persisted inventory)

## StarterPack Bundle
- 200000 coins
- 25 Blue balloons + 3 Yellow balloons
- Pet "Forgot" (Uncommon, Base collection)
- SavePets timed boost (15 min)
- Handled on PlayerAdded (pre-Replica direct mutation) and on PromptGamePassPurchaseFinished (via existing services + Replica:Set)