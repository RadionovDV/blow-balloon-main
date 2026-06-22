# Monetization Stage 1: Foundation

## Goal
Собрать фундамент монетизации: единая модель entitlements, схема данных, правила хранения и восстановления состояния.

## Read First
- `docs/ARCHITECTURE.md`
- `docs/contracts/DATA_SCHEMA.md`
- `docs/systems/MONETIZATION.md`
- `docs/STATE.md`

## Scope
- Ввести единый серверный контейнер для прав игрока: `MonetizationEntitlements`.
- Разделить права на:
  - `permanent` = постоянные права и владение
  - `timed` = временные бусты с `startsAt` / `expiresAt`
  - `consumable` = одноразовые награды, если им нужен флаг получения
- Зафиксировать, что `StarterPack` в Dashboard создается как `GamePass`, но в игре он работает как одноразовая награда с отдельным `claimed/granted` флагом.
- Определить, что хранится в `ProfileStore`, а что только в runtime cache.
- Обновить схему профиля так, чтобы она покрывала все будущие продукты без дублирования полей.

## Required Output
1. Кратко описать предложенную структуру `MonetizationEntitlements`.
2. Показать, какие части должны быть сохранены в базе.
3. Показать, какие части должны жить только в памяти сервера.
4. Перечислить риски, если смешать `GamePass`, `DevProduct` и timed boosts в одном плоском поле.

## Rules
- Не писать gameplay-интеграции.
- Не писать UI.
- Не подключать `MarketplaceService` обработчики.
- Не менять unrelated systems.
- Если обнаружены пробелы в текущем `DATA_SCHEMA.md`, перечислить их как TODO, а не исправлять молча.

## Expected Thinking Order
1. Сначала определить модель данных.
2. Потом определить persistence rules.
3. Потом определить server runtime cache.
4. Только после этого описать, как будет выглядеть follow-up work в следующих этапах.

## Response Format
```text
1. Assumptions
2. Proposed data model
3. Persistent fields
4. Runtime-only fields
5. Open questions / risks
```
