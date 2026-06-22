# Monetization System

## Responsibility
- Monopolises all monetization entitlements: GamePass ownership, Claims, Timed boosts
- GamePass ownership cache (last-known, persisted in MonetizationEntitlements.GamePasses)
- DevProduct handling (via ProcessReceipt, except ServerLuck)
- StarterPack claim flow (join-time, one-time)

## Rules
- GamePass ownership: MarketplaceService — source of truth, MonetizationEntitlements.GamePasses — fallback cache
- UserOwnsGamePassAsync успех: записать true/false в cache
- UserOwnsGamePassAsync ошибка: не трогать cache (использовать last-known)
- MonetizationEntitlements.Claims — idempotency флаги, один раз установлены — больше не меняются
- ServerLuck (DevProduct) — runtime-only, не сохраняется, не переживает rejoin
- StarterPack обрабатывается на PlayerAdded, не в RebirthService
- RebirthMoney — multi-use GamePass-эффект, проверяется при каждом Rebirth
- monetization state is replicated through MonetizationEntitlements in PlayerData

## Data Structure
- MonetizationEntitlements хранится в ProfileStore как часть PlayerData
- Runtime passCache дублирует MonetizationEntitlements.GamePasses для быстрых проверок
- ServerLuck живёт только в LuckService (serverBoostAmount / serverBoostExpires)