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

## Product Routing (ProcessReceipt)
- ServerLuck → LuckService.AddServerBoost (runtime-only)
- EnsureRoll → MonetizationEntitlements.Timed (id + startsAt/expiresAt)
- SavePets → MonetizationEntitlements.Timed (id + startsAt/expiresAt)
- Money → EconomyService.AddCoins
- Stickers → data.Stickers (persisted inventory)