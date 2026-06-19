# SESSION 4 — PetService (серверная часть)

> **Цель сессии:** Серверная логика питомцев — добавление в инвентарь, стенды, доход.  
> После сессии: питомцы сохраняются в ProfileStore, реплицируются клиенту, стенды приносят доход.

---

## Контекст проекта

Игра: Roblox Tycoon "Blow Biggest Balloon"  
Стек: Luau, ProfileStore, Replica (MadStudio), только Roblox Studio  
Полная архитектура: см. `docs/ARCHITECTURE.md`  
Пройденные сессии: SESSION_1 ✓, SESSION_2 ✓, SESSION_3 ✓

---

## Предусловия

```
ReplicatedStorage/Shared/Config/PetConfig      ✓
ReplicatedStorage/Shared/Config/GameConfig     ✓
ServerScriptService/Modules/PlayerService      ✓
ServerScriptService/Modules/EconomyService     ✓
```

---

## Задачи сессии

### 1. `ServerScriptService/Modules/PetService` (ModuleScript)

**Интерфейс:**
```lua
PetService.Init()
PetService.Start()

-- Добавить питомца в инвентарь (вызывается из BalloonService)
PetService.AddPet(player: Player, petResult: table): PetEntry
-- petResult = { type="pet", name, rarity, collectionName } из RouletteService

-- Поставить питомца на стенд
PetService.PlaceOnStand(player: Player, petUid: string, slotIndex: number): boolean

-- Убрать питомца со стенда
PetService.RemoveFromStand(player: Player, slotIndex: number): boolean

-- Продать питомца из инвентаря
PetService.SellPet(player: Player, petUid: string): boolean

-- Собрать доход со всех стендов
PetService.CollectIncome(player: Player): number  -- возвращает начисленную сумму

-- Улучшить базу (за ключ)
PetService.UpgradeBase(player: Player): boolean
```

**PetEntry структура:**
```lua
{
    uid            = string,   -- уникальный ID экземпляра
    name           = string,   -- ключ в PetConfig (тип питомца)
    rarity         = string,   -- "Common", "Uncommon", и т.д.
    collectionName = string,   -- "Base", "Forest", и т.д.
}
```

**uid генерация:**
```lua
local uid = tostring(math.floor(tick() * 1000)) .. "_" .. tostring(math.random(1000, 9999))
```

**AddPet:**
```lua
local data = PlayerService.GetData(player)
local entry = {
    uid            = generateUid(),
    name           = petResult.name,
    rarity         = petResult.rarity,
    collectionName = petResult.collectionName,
}
table.insert(data.Pets, entry)
-- Реплицировать обновлённый список
PlayerService.GetReplica(player):Set({"Pets"}, data.Pets)
return entry
```

**PlaceOnStand:**
1. Проверить: `slotIndex <= data.BaseSlots` (не превышает лимит)
2. Проверить: `data.StandPets[tostring(slotIndex)]` = nil (слот свободен)
3. Найти питомца в `data.Pets` по uid
4. Удалить из `data.Pets`
5. Записать в `data.StandPets[tostring(slotIndex)]` = entry
6. Реплицировать оба поля через Replica

**RemoveFromStand:**
1. Найти питомца в `data.StandPets[tostring(slotIndex)]`
2. Добавить обратно в `data.Pets`
3. Удалить из `data.StandPets`
4. Реплицировать

**CollectIncome:**
```lua
local data = PlayerService.GetData(player)
local now = os.time()
local total = 0

for slotIndex, petEntry in pairs(data.StandPets) do
    local petConfig = findPetConfig(petEntry.name, petEntry.collectionName)
    if petConfig then
        total += petConfig.standIncome
    end
end

if total > 0 then
    EconomyService.AddCoins(player, total)
end
return total

-- Примечание: в MVP доход начисляется по запросу (игрок наступает на кнопку)
-- Не нужен автоматический таймер для MVP
```

**UpgradeBase:**
1. Проверить наличие ключа: TODO (инвентарь ключей — POST-MVP)
2. Увеличить `data.BaseSlots += 1`
3. Обновить `data.BaseLevel = math.ceil(data.BaseSlots / GameConfig.BASE_SLOTS_PER_FLOOR)`
4. Реплицировать оба поля
5. Вернуть `true`

**Вспомогательная findPetConfig(name, collectionName):**
```lua
local collection = PetConfig[collectionName]
if not collection then return nil end
for _, pet in ipairs(collection) do
    if pet.name == name then return pet end
end
return nil
```

---

### 2. Подключить Remotes в `Start()`

```lua
-- Pet_PlaceStand: (slotIndex: number, petUid: string)
Remotes.Pet_PlaceStand.OnServerEvent:Connect(function(player, slotIndex, petUid)
    PetService.PlaceOnStand(player, petUid, slotIndex)
end)

-- Pet_RemoveStand: (slotIndex: number)
Remotes.Pet_RemoveStand.OnServerEvent:Connect(function(player, slotIndex)
    PetService.RemoveFromStand(player, slotIndex)
end)

-- Base_Collect: ()
Remotes.Base_Collect.OnServerEvent:Connect(function(player)
    local earned = PetService.CollectIncome(player)
    if earned > 0 then
        Remotes.Notification:FireClient(player, {
            text = "+" .. earned .. " монет со стендов!",
            style = "income"
        })
    end
end)
```

---

### 3. Обновить `BalloonService` (SESSION_3)

Раскомментировать `TODO: PetService.AddPet`:
```lua
-- В обработчике Balloon_Stop, после RouletteService.Roll:
if result.type == "pet" then
    PetService.AddPet(player, result)
end
```

---

### 4. Обновить `ServerScriptService/Server.server`

```lua
local PetService = require(SSS.Modules.PetService)

-- Init (порядок)
PlayerService.Init()
EconomyService.Init()
LuckService.Init()
RouletteService.Init()
PetService.Init()      -- ← добавить
BalloonService.Init()

-- Start
PlayerService.Start()
EconomyService.Start()
LuckService.Start()
RouletteService.Start()
PetService.Start()     -- ← добавить
BalloonService.Start()
```

---

## Что НЕ делать в этой сессии

- Не писать клиентский PetController (SESSION_6)
- Не писать визуальное отображение питомцев
- Не реализовывать продажу за Robux (POST-MVP)

---

## Проверка результата

```lua
-- Command Bar в Studio (Play Solo):
local SSS = game:GetService("ServerScriptService")
local PS_svc = require(SSS.Modules.PetService)
local player = game.Players:GetPlayers()[1]

-- Добавить тестового питомца
local entry = PS_svc.AddPet(player, {
    type = "pet", name = "FluffyCat", rarity = "Common", collectionName = "Base"
})
print("Added pet uid:", entry.uid)

-- Поставить на стенд
local ok = PS_svc.PlaceOnStand(player, entry.uid, 1)
print("Placed on stand:", ok)

-- Собрать доход
local earned = PS_svc.CollectIncome(player)
print("Income collected:", earned)  -- Expected: 5 (standIncome FluffyCat)

-- Проверить Replica на клиенте:
-- В Output должно обновиться: Pets = {} (перемещён на стенд)
```
