# SESSION 3 — EconomyService + LuckService + BalloonService + RouletteService

> **Цель сессии:** Реализовать серверную логику основного game loop.  
> После сессии: сервер принимает Balloon_Start/Stop, вычисляет результат, начисляет монеты, решает рулетку.  
> Клиентской анимации здесь нет — только серверная логика и Remote-события.

---

## Контекст проекта

Игра: Roblox Tycoon "Blow Biggest Balloon"  
Стек: Luau, ProfileStore, Replica (MadStudio), только Roblox Studio  
Полная архитектура: см. `docs/ARCHITECTURE.md`  
Пройденные сессии: SESSION_1 ✓, SESSION_2 ✓

---

## Предусловия (уже должно существовать)

```
ReplicatedStorage/Shared/Config/GameConfig     ✓
ReplicatedStorage/Shared/Config/BalloonConfig  ✓
ReplicatedStorage/Shared/Config/PetConfig      ✓
ReplicatedStorage/Shared/Util/RarityUtil       ✓
ReplicatedStorage/Shared/Remotes               ✓
ServerScriptService/Modules/PlayerService      ✓
ServerScriptService/Server.server              ✓
```

---

## Задачи сессии

### 1. `ServerScriptService/Modules/LuckService` (ModuleScript)

Чистая функция, без состояния (кроме серверного буста).

**Интерфейс:**
```lua
LuckService.Init()
LuckService.Start()

LuckService.GetLuck(player: Player, inflateLuck: number?): number
LuckService.AddServerBoost(amount: number, duration: number)  -- DevProduct
LuckService.GetServerBoost(): number
```

**Формула** (из ARCHITECTURE.md):
```
totalLuck = baseLuck + tempBonuses + permanent + serverBoost + inflateLuck
```
- `baseLuck` = `profile.Data.BaseLuck`
- `tempBonuses` = сумма amount из `LuckBonuses.temporary` где `expiresAt > os.time()`
- `permanent` = `LuckBonuses.permanent`
- `serverBoost` = in-memory глобальная переменная (не в ProfileStore)
- `inflateLuck` = бонус от степени надува (параметр, передаётся из BalloonService)

**Серверный буст:**
- Хранится в модульной переменной `local serverBoostExpires = 0; local serverBoostAmount = 0`
- `AddServerBoost(amount, duration)` устанавливает значение и время истечения
- `GetServerBoost()` возвращает amount если `os.time() < serverBoostExpires`, иначе 0

---

### 2. `ServerScriptService/Modules/EconomyService` (ModuleScript)

**Интерфейс:**
```lua
EconomyService.Init()
EconomyService.Start()

EconomyService.AddCoins(player: Player, amount: number)
EconomyService.SpendCoins(player: Player, amount: number): boolean  -- false если не хватает
EconomyService.CalcBalloonReward(balloonConfig: table, inflateTime: number): number
```

**CalcBalloonReward:**
```
-- Линейная интерполяция от 0 до maxReward за 0..60 секунд
-- inflateTime ограничивается 60 сек
local t = math.clamp(inflateTime, 0, 60) / 60
local reward = math.floor(balloonConfig.baseReward + (balloonConfig.maxReward - balloonConfig.baseReward) * t)
return reward
```

**AddCoins:**
```lua
local data = PlayerService.GetData(player)
local newCoins = data.Coins + amount
PlayerService.SetData(player, {"Coins"}, newCoins)
```

**SpendCoins:**
```lua
local data = PlayerService.GetData(player)
if data.Coins < amount then return false end
PlayerService.SetData(player, {"Coins"}, data.Coins - amount)
return true
```

---

### 3. `ServerScriptService/Modules/RouletteService` (ModuleScript)

Вычисляет результат рулетки. Вызывается из BalloonService.

**Интерфейс:**
```lua
RouletteService.Init()
RouletteService.Start()

-- Возвращает таблицу результата
RouletteService.Roll(player: Player, maxRarity: string, inflatePercent: number): RouletteResult
-- inflatePercent: 0..1, влияет на шанс Key

-- Тип результата:
-- { type = "bomb" }
-- { type = "key" }
-- { type = "pet", name = string, rarity = string, collectionName = string }
```

**Алгоритм Roll** (из ARCHITECTURE.md):
```lua
-- 1. Bomb check (независимо от питомцев)
if math.random() < GameConfig.BOMB_CHANCE then
    return { type = "bomb" }
end

-- 2. Key check
-- Шанс ключа растёт с inflatePercent:
local keyChance = GameConfig.KEY_CHANCE 
    + (GameConfig.KEY_CHANCE_MAX_INFLATE - GameConfig.KEY_CHANCE) * inflatePercent
if math.random() < keyChance then
    return { type = "key" }
end

-- 3. Pet selection
local allCollections = {}  -- собрать всех питомцев из всех коллекций PetConfig до maxRarity
for collectionName, collection in pairs(PetConfig) do
    if type(collection) == "table" and collectionName ~= "RARITIES" then
        local filtered = RarityUtil.FilterByMaxRarity(collection, maxRarity)
        for _, pet in ipairs(filtered) do
            table.insert(allCollections, { pet = pet, collectionName = collectionName })
        end
    end
end

local luck = LuckService.GetLuck(player, 0)
-- WeightedPick по полному списку
local chosen = RarityUtil.WeightedPickFromAll(allCollections, luck)
return { type = "pet", name = chosen.pet.name, rarity = chosen.pet.rarity, collectionName = chosen.collectionName }
```

**Примечание:** Обновить `RarityUtil` (SESSION_1) добавив метод `WeightedPickFromAll(list, luck)`,  
где `list` — массив `{ pet: PetTier, collectionName: string }`.  
Если SESSION_1 уже завершена — дописать метод в существующий RarityUtil.

---

### 4. `ServerScriptService/Modules/BalloonService` (ModuleScript)

Серверная логика надувания. Главный модуль сессии.

**Интерфейс:**
```lua
BalloonService.Init()
BalloonService.Start()
```

**Внутренние структуры:**
```lua
-- Состояние надувания на игрока
local inflating = {}  -- { [player]: { startTime, balloonName, timer, popped } }
```

**Логика (Start подключает RemoteEvent-коннекты):**

**Balloon_Start (Client → Server):**
1. Проверить: игрок уже надувает? → игнорировать
2. Проверить: `data.Balloons[data.ActiveBalloon] > 0` → иначе `FireClient(Balloon_Result, { type="no_balloon" })`
3. Записать `inflating[player] = { startTime = tick(), balloonName = data.ActiveBalloon, popped = false }`
4. Запустить `task.spawn` — серверный pop-ticker:
   ```lua
   task.spawn(function()
       while inflating[player] and not inflating[player].popped do
           task.wait(0.5)  -- проверка каждые 0.5 сек
           if not inflating[player] then break end
           
           local elapsed = tick() - inflating[player].startTime
           local config = BalloonConfig[inflating[player].balloonName]
           local popChance = getPopChance(config.popCurve, elapsed)
           
           if math.random() < popChance * 0.5 then  -- * 0.5 т.к. проверяем 2 раза в сек
               inflating[player].popped = true
               inflating[player] = nil
               Remotes.Balloon_Result:FireClient(player, { type = "pop" })
               break
           end
       end
   end)
   ```

**Balloon_Stop (Client → Server):**
1. Проверить: `inflating[player]` существует и `not popped` → иначе игнорировать
2. Вычислить `inflateTime = tick() - inflating[player].startTime`
3. Очистить `inflating[player] = nil`
4. Вычислить `inflatePercent = math.clamp(inflateTime / 60, 0, 1)`
5. `reward = EconomyService.CalcBalloonReward(config, inflateTime)`
6. `EconomyService.AddCoins(player, reward)`
7. Бросить рулетку: `if math.random(GameConfig.ROULETTE_CHANCE) == 1 then`
   - `result = RouletteService.Roll(player, config.maxRarity, inflatePercent)`
   - Если `result.type == "pet"` → `PetService.AddPet(player, result)` (SESSION_4)
   - `FireClient(Balloon_Result, { type="roulette", result=result, reward=reward })`
8. Иначе: `FireClient(Balloon_Result, { type="coins_only", reward=reward })`

**Balloon_Equip (Client → Server):**
1. Проверить: `data.Balloons[balloonName] > 0`
2. Проверить: игрок сейчас НЕ надувает
3. `PlayerService.SetData(player, {"ActiveBalloon"}, balloonName)`

**Вспомогательная функция getPopChance(popCurve, elapsed):**
```lua
-- Линейная интерполяция между точками кривой
-- Найти две точки, между которыми находится elapsed
-- Вернуть интерполированный шанс
```

---

### 5. Обновить `ServerScriptService/Server.server`

Добавить инициализацию новых сервисов в правильном порядке:

```lua
-- Init (порядок важен — зависимости сначала)
PlayerService.Init()
EconomyService.Init()
LuckService.Init()
RouletteService.Init()
BalloonService.Init()

-- Start (после всех Init)
PlayerService.Start()
EconomyService.Start()
LuckService.Start()
RouletteService.Start()
BalloonService.Start()
```

---

## Что НЕ делать в этой сессии

- Не вызывать `PetService.AddPet` в BalloonService (PetService ещё не создан)
  → оставить `TODO: PetService.AddPet(player, result)` комментарий
- Не писать клиентские контроллеры
- Не создавать UI

---

## Проверка результата

**В Studio (Play Solo) через Command Bar:**
```lua
-- Проверка EconomyService
local SSS = game:GetService("ServerScriptService")
local ES = require(SSS.Modules.EconomyService)
local player = game.Players:GetPlayers()[1]
ES.AddCoins(player, 500)
-- Output клиента: [Client] Coins changed: 0 -> 500

-- Проверка RouletteService
local RS_svc = require(SSS.Modules.RouletteService)
local result = RS_svc.Roll(player, "Rare", 0.5)
print(result.type, result.name or "")
-- Expected: "pet", имя питомца Common/Uncommon/Rare
```

**Balloon_Start/Stop тест:**
```lua
-- Симулировать Balloon_Start с клиента:
local RS = game:GetService("ReplicatedStorage")
local Remotes = require(RS.Shared.Remotes)
Remotes.Balloon_Start:FireServer()
task.wait(3)
Remotes.Balloon_Stop:FireServer()
-- Output сервера: должен начислить монеты
-- Output клиента: [Client] Coins changed: 0 -> N
```
