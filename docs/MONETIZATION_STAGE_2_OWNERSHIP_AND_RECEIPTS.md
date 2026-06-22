# Monetization Stage 2: Ownership and Receipts

## Goal
Собрать серверную основу покупки: проверка GamePass ownership, fallback, обработка DevProduct через единый `ProcessReceipt`.

## Read First
- `docs/ARCHITECTURE.md`
- `docs/contracts/DATA_SCHEMA.md`
- `docs/contracts/REMOTES.md`
- `docs/systems/MONETIZATION.md`
- `docs/STATE.md`
- `docs/MONETIZATION_STAGE_1_FOUNDATION.md`

## Scope
- Реализовать схему проверки `UserOwnsGamePassAsync` на входе игрока.
- Добавить fallback, если проверка не ответила или упала:
  - сначала runtime cache
  - затем сохраненные данные профиля
  - затем безопасный `false`
- Использовать `PromptGamePassPurchaseFinished` только как сигнал для обновления состояния после покупки, но не как единственный источник истины.
- Сделать единый модуль для `MarketplaceService.ProcessReceipt`.
- Этот модуль должен маршрутизировать все `Developer Products` через таблицу `ProductId -> handler`.
- Защитить обработку от повторной выдачи награды.

## Product Coverage
- `StarterPack` = GamePass ownership + одноразовый claim flow
- `Ensure Roll` = DevProduct timed offer
- `Server Luck` = DevProduct timed offer
- `Save Pets` = DevProduct timed offer
- `Money` = DevProduct instant reward
- `Stickers` = DevProduct unlock + inventory write

## Required Output
1. Предложить lifecycle для `GamePass` проверки на входе.
2. Предложить lifecycle для `ProcessReceipt`.
3. Описать, как обрабатывать success / retry / duplicate receipt.
4. Описать, где хранить persistent state для `StarterPack`.

## Rules
- Не писать клиентский UI.
- Не подключать gameplay effects, только выдачу прав и наград.
- Не описывать stray pet flow.
- Не описывать sticker equip UI, только receipt-side unlock.

## Expected Thinking Order
1. Проверка ownership.
2. Fallback and cache.
3. Receipt routing.
4. Idempotency.

## Response Format
```text
1. Ownership flow
2. Fallback flow
3. Receipt flow
4. Product routing table
5. Risks / edge cases
```
