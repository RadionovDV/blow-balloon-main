# Monetization Stage 3: Gameplay and UI

## Goal
Подключить уже определенную монетизацию к UI и игровым системам.

## Read First
- `docs/ARCHITECTURE.md`
- `docs/contracts/UI_STRUCTURE.md`
- `docs/contracts/REMOTES.md`
- `docs/contracts/DATA_SCHEMA.md`
- `docs/systems/BALLOON.md`
- `docs/systems/ROULETTE.md`
- `docs/systems/PETS.md`
- `docs/systems/ECONOMY.md`
- `docs/systems/BASES.md`
- `docs/systems/AUDIO.md`
- `docs/MONETIZATION_STAGE_1_FOUNDATION.md`
- `docs/MONETIZATION_STAGE_2_OWNERSHIP_AND_RECEIPTS.md`

## Scope
- Реализовать `RobuxShopController`.
- Открывать и закрывать `ShopGui`.
- Отражать состояние `Purchased / Buy / Equip / Unequip`.
- Показывать временные бусты в `HudGui.States` через `ReplicatedStorage.Assets.UI.TemporaryBoost`.
- Подключить entitlement-ы к:
  - `BalloonService`
  - `RouletteService`
  - `RebirthService`
  - `PetService`
  - `EconomyService`
- Реализовать `FormatNumber` в `Shared/Util/FormatNumber` для цен и больших чисел.
- Реализовать stray pet flow:
  - `StrayPetService`
  - Robux purchase price by rarity
  - owner free reclaim
  - `Save Pets` visual and purchase rules
- Реализовать sticker equip flow:
  - только один стикер может быть активен одновременно
  - переключение `Equip / Unequip`
  - применение к `Workspace.BalloonPart.Decal.ColorMapContent`

## Required Output
1. Предложить структуру `RobuxShopController`.
2. Предложить структуру UI-state для временных бустов.
3. Предложить точки интеграции в gameplay systems.
4. Описать stray pet purchase rules.
5. Описать sticker ownership and equip rules.

## Rules
- Не менять основу данных из Stage 1.
- Не менять receipt routing из Stage 2.
- Не предлагать новые продукты.
- Не смешивать UI logic и server authoritative logic в одном слое.
- Stray pet prices live in `MonetizationConfig`.

## Expected Thinking Order
1. UI wiring.
2. Gameplay hooks.
3. Special interaction flows.
4. Edge cases.

## Response Format
```text
1. UI controller plan
2. Temporary boost UI plan
3. Gameplay integration plan
4. Stray pet flow
5. Sticker flow
6. Number formatting plan
```
