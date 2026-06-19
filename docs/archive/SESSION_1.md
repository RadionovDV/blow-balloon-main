# SESSION 1 — Config, Shared Utils, Remotes

> **Цель сессии:** Создать весь фундамент проекта — конфиги, утилиты и реестр Remotes.  
> Код не запускается сам по себе, но от этих файлов зависят ВСЕ последующие сессии.  
> **Писать только ModuleScript-и в ReplicatedStorage.**

---

## Контекст проекта

Игра: Roblox Tycoon "Blow Biggest Balloon"  
Стек: Luau, ProfileStore, Replica (MadStudio), только Roblox Studio  
Полная архитектура: см. `docs/ARCHITECTURE.md`

---

## Задачи сессии (в порядке выполнения)

### 1. `ReplicatedStorage.Shared.Config.GameConfig`

Создать ModuleScript с константами игры. Взять структуру из ARCHITECTURE.md раздел "GameConfig — структура".

Содержимое:
- `ROULETTE_CHANCE = 10` (1/10)
- `KEY_CHANCE = 0.01`, `BOMB_CHANCE = 0.10`, `KEY_CHANCE_MAX_INFLATE = 0.05`
- `STAND_INCOME_INTERVAL = 60`
- `BASE_SLOTS_PER_FLOOR = 10`, `BASE_UPGRADE_KEY_COST = 1`
- `REBIRTH_COIN_REQUIREMENT = 100000`, `REBIRTH_LUCK_MULTIPLIER = 0.5`
- `SERVER_BOOST_AMOUNT = 5`, `SERVER_BOOST_DURATION = 1800`
- `GAMEPASS_IDS` — все `0` (заполнить после публикации)
- `DEVPRODUCT_IDS` — все `0`
- `TUTORIAL_STEPS` — enum шагов туториала
- `APPLAUSE_INTERVAL = 10`

---

### 2. `ReplicatedStorage.Shared.Config.BalloonConfig`

Создать ModuleScript с конфигом шаров. Взять структуру из ARCHITECTURE.md раздел "BalloonConfig — структура".

Шары для MVP:
- `Default`: maxRarity="Common", baseReward=10, maxReward=600, popCurve с 5 точками
- `Pink`: maxRarity="Rare", baseReward=20, maxReward=1200, popCurve (чуть сложнее)
- `Blue`: maxRarity="Uncommon", baseReward=15, maxReward=900, popCurve

**Важно:** `popCurve` — список `{ time, chance }`. `time` в секундах (0–60), `chance` от 0 до 1.  
При `time=0` шанс уже ненулевой (~0.15). При `time=60` шанс = 1.0 (лопнет всегда).  
Шанс интерполируется линейно между точками кривой.

**Важно:** `maxReward` достигается ровно на 60 сек (максимальное время надувания).

---

### 3. `ReplicatedStorage.Shared.Config.PetConfig`

Создать ModuleScript с конфигом питомцев. Взять структуру из ARCHITECTURE.md раздел "PetConfig — структура".

Коллекция `Base` (5 питомцев):
- Common (FluffyCat), Uncommon (WoofyDog), Rare (CoolBunny), Epic (MysticFox), Legendary (GoldenDrake)
- Поля каждого: `name`, `rarity`, `rarityWeight` (чем выше — тем ЧАЩЕ выпадает), `cost`, `standIncome`

Редкости и их string-значения:
```lua
-- Порядок редкостей от частого к редкому:
local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
```
Вынести этот список как `PetConfig.RARITIES` — он нужен RarityUtil.

**Проверка maxRarity:** Шар с maxRarity="Rare" даёт доступ к Common + Uncommon + Rare питомцам.  
RarityUtil должен уметь фильтровать по maxRarity.

---

### 4. `ReplicatedStorage.Shared.Util.RarityUtil`

Создать ModuleScript с алгоритмом взвешенного выбора.

```lua
-- Интерфейс:
RarityUtil.WeightedPick(candidates: { PetTier }, luck: number): PetTier
-- candidates — отфильтрованный список питомцев до maxRarity включительно
-- luck — итоговая удача игрока (влияет на сдвиг весов в сторону редких)

RarityUtil.FilterByMaxRarity(collection: Collection, maxRarity: string): { PetTier }
-- Возвращает только питомцев с rarity <= maxRarity (по порядку RARITIES)
```

**Алгоритм WeightedPick с luck:**
- Базовые веса из `rarityWeight` (большее число = чаще)
- `luck` сдвигает шанс в сторону редких:
  - Для каждого кандидата с индексом i (от редкого к частому):
    `adjustedWeight = rarityWeight * (1 + luck * rarityIndex * 0.1)`
  - Итоговый выбор — классический weighted random

**Важно:** Bomb и Key НЕ входят в candidates и выбираются ДО вызова WeightedPick в RouletteService.

---

### 5. `ReplicatedStorage.Shared.Util.TableUtil`

Создать ModuleScript с утилитами для таблиц.

Методы:
```lua
TableUtil.DeepCopy(t: table): table        -- глубокое копирование
TableUtil.Contains(t: table, value): bool   -- есть ли значение в массиве
TableUtil.Find(t: table, predicate: fn): any  -- первый элемент, где predicate(el)==true
TableUtil.Filter(t: table, predicate: fn): table  -- фильтрация массива
TableUtil.Sum(t: {number}): number           -- сумма числового массива
```

---

### 6. `ReplicatedStorage.Shared.Remotes`

Создать ModuleScript-реестр RemoteEvents и RemoteFunctions.

**Логика создания:**
- На **сервере** (`RunService:IsServer()`): создаёт Instance'ы RemoteEvent/RemoteFunction в `ReplicatedStorage.Remotes` (папка)
- На **клиенте**: ждёт папку и читает готовые Instance'ы

```lua
-- Список (из ARCHITECTURE.md раздел "Remotes — реестр"):
-- RemoteEvents:
--   Balloon_Start, Balloon_Stop, Balloon_Equip
--   Base_Collect, Pet_PlaceStand, Pet_RemoveStand
--   Balloon_Result, Roulette_Show, Tutorial_Step, Notification
-- RemoteFunctions:
--   Shop_BuyBalloon
```

**Важно:** Remotes.lua должен работать без ошибок и на сервере, и на клиенте.  
На сервере папка `ReplicatedStorage.Remotes` создаётся если её нет.  
На клиенте используй `WaitForChild` для надёжности.

---

## Что НЕ делать в этой сессии

- Не писать логику сервисов (PlayerService, BalloonService и т.д.)
- Не писать клиентские контроллеры
- Не трогать ProfileStore и Replica

---

## Проверка результата

После сессии должно быть 6 ModuleScript-файлов:
1. `ReplicatedStorage.Shared.Config.GameConfig`
2. `ReplicatedStorage.Shared.Config.BalloonConfig`
3. `ReplicatedStorage.Shared.Config.PetConfig`
4. `ReplicatedStorage.Shared.Util.RarityUtil`
5. `ReplicatedStorage.Shared.Util.TableUtil`
6. `ReplicatedStorage.Shared.Remotes`

Тест в Studio Output (вставить в Command Bar):
```lua
local RS = game:GetService("ReplicatedStorage")
local RC = require(RS.Shared.Config.BalloonConfig)
local PC = require(RS.Shared.Config.PetConfig)
local RU = require(RS.Shared.Util.RarityUtil)

local candidates = RU.FilterByMaxRarity(PC.Base, "Rare")
local pick = RU.WeightedPick(candidates, 1)
print("Picked pet:", pick.name, pick.rarity)
print("BalloonConfig Default maxRarity:", RC.Default.maxRarity)
-- Expected: picked pet, "Default Balloon maxRarity: Common"
```
