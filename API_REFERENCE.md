# API_REFERENCE.md

Справочник API существующих и ключевых модулей проекта Blow Balloon.

---

## PlayerDataServer (src/shared/PlayerData/PlayerDataServer.lua)

Полноценный серверный сервис данных. Автоматически загружает данные при PlayerAdded
через SessionLockedDataStoreWrapper, отправляет клиенту RemoteEvents, автосохраняет.

**Загрузка:**
```lua
PlayerDataServer.start(defaultPlayerData, "BlowBalloonData", { "gamepasses" })
-- privateValueNames (третий аргумент) — поля, НЕ отправляемые клиенту
```

**Чтение/запись:**
```lua
PlayerDataServer.getValue(player, "coins")
PlayerDataServer.getValue(player, "balloons", true)  -- syncedValueOnly
PlayerDataServer.setValue(player, "coins", 100)
PlayerDataServer.updateValue(player, "coins", function(old) return old + 50 end)
PlayerDataServer.removeValue(player, "temporaryField")
```

**Проверки:**
```lua
PlayerDataServer.hasLoaded(player)
PlayerDataServer.isLoading(player)
PlayerDataServer.hasErrored(player)
PlayerDataServer.canSave(player)
PlayerDataServer.waitForDataLoadAsync(player)
```

**События (Signal):**
```lua
PlayerDataServer.playerDataUpdated:Connect(function(player, valueName, value) end)
```

**Сохранение:**
```lua
PlayerDataServer.saveDataAsync(player)
PlayerDataServer.setMetaData(player, metadata)
PlayerDataServer.onPlayerRemovingAsync(player)
```

**Приватные поля:**
```lua
PlayerDataServer.setValueAsPrivate("gamepasses", true)
```

---

## PlayerDataClient (src/shared/PlayerData/PlayerDataClient.lua)

Клиентская часть. Принимает данные от сервера через RemoteEvents.

**Загрузка:**
```lua
PlayerDataClient.start()
```

**Чтение:**
```lua
PlayerDataClient.get("coins")
PlayerDataClient.hasLoaded()
PlayerDataClient.hasLoadingErrored()
PlayerDataClient.hasSavingErrored()
PlayerDataClient.getLoadError()
PlayerDataClient.getSaveError()
```

**События (Signal):**
```lua
PlayerDataClient.loaded:Connect(function(success, errorType) end)
PlayerDataClient.updated:Connect(function(valueName, value) end)
PlayerDataClient.saved:Connect(function(success, errorType) end)
```

---

## Signal (src/shared/Signal.lua)

Замена BindableEvent. Внутрисерверные/внутриклиентские события.

```lua
local Signal = require(...)
local sig = Signal.new()

local connection = sig:Connect(function(arg1, arg2) end)
sig:Fire(arg1, arg2)
local result = sig:Wait()

connection:Disconnect()
sig:DisconnectAll()
```

---

## StatefulObjectController (src/shared/StatefulObjectController.lua)

Управление Tween-анимациями через состояния. Предварительно создаёт Tween для каждого
состояния и переключает их без создания новых объектов.

**Создание:**
```lua
local ctrl = StatefulObjectController.hydrate({
    object = frame,
    states = {
        Visible = {
            transition = TweenInfo.new(0.3, Enum.EasingStyle.Quart),
            properties = { BackgroundTransparency = 0 }
        },
        Hidden = {
            transition = TweenInfo.new(0.3, Enum.EasingStyle.Quart),
            properties = { BackgroundTransparency = 1 }
        },
    },
    initialStateName = "Hidden"
})
```

**Переключение:**
```lua
ctrl:setState("Visible")
```

---

## UIManager (client/ui/UIManager.lua)

Обёртка над StatefulObjectController для всех UI-окон. Создаётся в Этапе 1.

**API:**
```lua
UIManager.register(frameName, frameInstance, states?, initialState?)
UIManager.show(frameName)
UIManager.hide(frameName)
UIManager.setState(frameName, stateName)
```

**Стандартные состояния:**
```lua
local defaultStates = {
    Visible = {
        transition = TweenInfo.new(0.3, Enum.EasingStyle.Quart),
        properties = { BackgroundTransparency = 0, Scale = Vector2.new(1, 1) }
    },
    Hidden = {
        transition = TweenInfo.new(0.3, Enum.EasingStyle.Quart),
        properties = { BackgroundTransparency = 1, Scale = Vector2.new(0.8, 0.8) }
    },
}
```

**Скелет реализации:**
```lua
local StatefulObjectController = require(...)
local UIManager = {}
UIManager._controllers = {}
UIManager._defaultStates = { ... }

function UIManager.register(name, object, customStates, initialState)
    local states = customStates or UIManager._defaultStates
    local ctrl = StatefulObjectController.hydrate({
        object = object,
        states = states,
        initialStateName = initialState or "Hidden",
    })
    UIManager._controllers[name] = ctrl
end

function UIManager.show(name)
    UIManager._controllers[name]:setState("Visible")
end

function UIManager.hide(name)
    UIManager._controllers[name]:setState("Hidden")
end

function UIManager.setState(name, stateName)
    UIManager._controllers[name]:setState(stateName)
end
```

---

## AudioController (shared/AudioController.lua)

Единая точка воспроизведения звуков. Создаётся в Этапе 1.

```lua
-- API:
AudioController.Play("BalloonPop")
AudioController.Play("RouletteTick")
AudioController.Play("CoinGain")
-- Маппинг soundName -> SoundId
```

---

## RaritySystem (shared/utils/RaritySystem.lua)

Ядро выпадения питомцев. Создаётся в Этапе 2.

```lua
-- roll(maxRarity, luckLevel, collectionName?) -> { type, data }

-- type:
--   "pet"        -> data = { id, name, rarity, ... }
--   "goldenKey"  -> data = {}
--   "bomb"       -> data = {}

-- maxRarity: Common | Uncommon | Rare | Epic | Legendary
-- luckLevel: baseLuck + bonusLuck
-- collectionName: nil (все) или "Gold" / "Diamond"

-- Логика:
--   rarityWeight + luckLevel влияет на вероятность лучшего
--   GoldenKey: шанс растёт ближе к макс. надуву
--   Bomb: фикс. 1/10, не зависит от надува
```

---

## NetworkBridge (shared/NetworkBridge.lua)

Централизованный реестр RemoteEvent и RemoteFunction. Создаётся в Этапе 1.

**Категории и события:**

| Категория    | Событие           | Тип        | Направление          | Описание                     |
|--------------|-------------------|------------|----------------------|------------------------------|
| Balloon      | StartBlow         | RemoteEvent| Client -> Server     | Начать надувание             |
| Balloon      | StopBlow          | RemoteEvent| Client -> Server     | Отпустить кнопку             |
| Balloon      | BalloonPopped     | RemoteEvent| Server -> Client     | Шар лопнул                   |
| Balloon      | RouletteTriggered | RemoteEvent| Server -> Client     | Запуск рулетки               |
| Shop         | BuyBalloon        | RemoteFunc | Client -> Server     | Купить шар                   |
| Shop         | EquipBalloon      | RemoteEvent| Client -> Server     | Снарядить шар                |
| Base         | CollectIncome     | RemoteFunc | Client -> Server     | Собрать доход со стенда      |
| Base         | SellPet           | RemoteFunc | Client -> Server     | Продать питомца              |
| Base         | UpgradeBase       | RemoteFunc | Client -> Server     | Расширить базу               |
| Tutorial     | GetStep           | RemoteFunc | Client -> Server     | Получить текущий шаг         |
| Tutorial     | CompleteStep      | RemoteEvent| Client -> Server     | Завершить шаг                |
| Rebirth      | PerformRebirth    | RemoteFunc | Client -> Server     | Совершить Rebirth            |
| ServerEvent  | EventLeaderboard  | RemoteFunc | Client -> Server     | Топ события (Этап 3)         |

---

## GameConfig (shared/GameConfig.lua)

Единственный источник констант и конфигов. Создаётся в Этапе 1.

**RarityEnum:**
```lua
local Rarity = {
    Common    = 1,
    Uncommon  = 2,
    Rare      = 3,
    Epic      = 4,
    Legendary = 5,
}
-- Расширяется: Gold, Diamond (MORE_FEATURES)
```

**BalloonConfig (формат структуры):**
```lua
-- type BalloonDef = {
--     id: string,             -- "default", "pink", "golden"
--     displayName: string,
--     rarity: number,         -- редкость в магазине
--     maxRarityUnlock: number,-- макс. редкость питомца
--     maxIncome: number,      -- макс. денег за надув
--     maxDuration: number,    -- макс. время надува (сек)
--     popChanceBase: number,  -- базовый шанс взрыва
--     modelId: string,        -- ID модели
--     cost: number,           -- цена (nil для default)
-- }
```

**Глобальные константы:**
```lua
GameConfig.BLOW_MAX_DURATION = 60
GameConfig.POP_WINDOW = 5
GameConfig.LOOT_CHANCE = 0.1
GameConfig.KEY_CHANCE = 0.01
GameConfig.BOMB_CHANCE = 0.1
GameConfig.BASE_INCOME_INTERVAL = 60
GameConfig.HOMELESS_PET_WAIT = 30
GameConfig.REBIRTH_PET_REQUIREMENT = 2
GameConfig.REBIRTH_LUCK_MULTIPLIER = 2
GameConfig.SLOTS_PER_FLOOR = 10
```

---

## Схема PlayerData

Передаётся в PlayerDataServer.start(defaultValue, ...):

```lua
local DEFAULT_PLAYER_DATA = {
    coins           = 0,
    goldenKeys      = 0,
    baseLuck        = 1,
    rebirthCount    = 0,
    balloons        = {},
    activeBalloonId = "default",
    baseLevel       = 1,
    petSlots        = {},
    petsEverOwned   = {},
    ranking         = { score = 0, rankName = "Common" },
    gamepasses      = {},
    tutorialStep    = 0,
    loyaltyStreak   = 0,
    balloonSaveSlots = {},
}
```
