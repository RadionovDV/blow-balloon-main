# Blow Biggest Balloon — Architecture Reference

> Единый источник правды об архитектуре проекта.  
> Читается перед каждой AI-сессией разработки.

---

## Стек

| Слой | Решение |
|---|---|
| IDE | Roblox Studio (без Rojo) |
| Язык | Luau |
| Persistence | ProfileStore.lua (SessionLocking, loaded/saved events) |
| State replication | Replica (MadStudio) — server→client state sync |
| Networking | Replica + голые RemoteEvents только для one-shot событий |
| Анимации | `StatefulObjectController` — обёртка над TweenService |
| Аудио | `AudioController.Play(soundName)` |

---

## Studio-иерархия (полная)

```
ReplicatedStorage
├── Lib/
│   ├── ReplicaClient          (ModuleScript)
│   └── ReplicaShared/         (Folder)
│       ├── Maid               (ModuleScript)
│       ├── RateLimit          (ModuleScript)
│       ├── Remote             (ModuleScript)
│       └── Signal             (ModuleScript)
├── Shared/
│   ├── Config/
│   │   ├── BalloonConfig      (ModuleScript)
│   │   ├── PetConfig          (ModuleScript)
│   │   └── GameConfig         (ModuleScript)
│   ├── Util/
│   │   ├── RarityUtil         (ModuleScript)
│   │   └── TableUtil          (ModuleScript)
│   └── Remotes                (ModuleScript)
└── Assets/                    (вручную в Studio: модели, звуки, VFX)

ServerScriptService
├── Lib/
│   ├── ReplicaServer          (ModuleScript)
│   └── ProfileStore           (ModuleScript)
├── Server.server              (Script)
└── Modules/
    ├── PlayerService          (ModuleScript)
    ├── BalloonService         (ModuleScript)
    ├── RouletteService        (ModuleScript)
    ├── PetService             (ModuleScript)
    ├── EconomyService         (ModuleScript)
    ├── LuckService            (ModuleScript)
    ├── BaseService            (ModuleScript)
    └── RebirthService         (ModuleScript)  ← POST-MVP

StarterPlayerScripts
├── Client.client              (LocalScript)
└── Modules/
    ├── BalloonController      (ModuleScript)
    ├── RouletteController     (ModuleScript)
    ├── PetController          (ModuleScript)
    ├── HudController          (ModuleScript)
    ├── ShopController         (ModuleScript)
    ├── AudioController        (ModuleScript)
    ├── StatefulObjectController (ModuleScript)
    └── TutorialController     (ModuleScript)

StarterGui
└── (UI Frames созданы вручную в Studio, скриптами только управляются)
```
---

## Репозиторий-иерархия

В текущем репозитории иерархия точно такая же как и в Studio с небольшими изменениями в названиях
- вся структура проекта находится в папке src

src
├── shared (всё что должно находиться в ReplicatedStorage)
├── server (всё что должно находиться в ServerScriptService)
└── client (всё что должно находиться в StarterPlayerScripts)
---

## Паттерн модуля (все сервисы и контроллеры)

```lua
-- Каждый серверный сервис / клиентский контроллер следует этому шаблону:
local MyService = {}

-- Вызывается первым. Здесь require зависимостей и начальная настройка.
-- НЕ запускает циклы, НЕ коннектит события.
function MyService.Init()
end

-- Вызывается после Init всех модулей. Здесь запускаются loops и коннекты.
function MyService.Start()
end

return MyService
```

**Порядок вызова в точках входа:**
1. Все `.Init()` по очереди
2. Все `.Start()` по очереди

---

## require() конвенция

```lua
-- Стандартный заголовок серверного модуля
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicaServer = require(ServerScriptService.Lib.ReplicaServer)
local ProfileStore  = require(ServerScriptService.Lib.ProfileStore)
local BalloonConfig = require(ReplicatedStorage.Shared.Config.BalloonConfig)
local PetConfig     = require(ReplicatedStorage.Shared.Config.PetConfig)
local GameConfig    = require(ReplicatedStorage.Shared.Config.GameConfig)
local RarityUtil    = require(ReplicatedStorage.Shared.Util.RarityUtil)
local Remotes       = require(ReplicatedStorage.Shared.Remotes)

-- Стандартный заголовок клиентского модуля
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local BalloonConfig = require(ReplicatedStorage.Shared.Config.BalloonConfig)
local GameConfig    = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes       = require(ReplicatedStorage.Shared.Remotes)
```

---

## WaitForChild конвенция

Все вызовы `WaitForChild` для элементов из `Workspace` или `PlayerGui` должны быть на верхнем уровне модуля, а не внутри функций или колбеков. Это гарантирует, что структура объектов валидна с момента загрузки, а ошибки отсутствия элемента проявляются сразу, а не в рантайме.

```lua
-- ✅ Правильно: на верхнем уровне
local location = Workspace:WaitForChild("Location")
local balloonStation = location:WaitForChild("BalloonStation")

-- ❌ Неправильно: внутри Init/Start или колбека
function SomeController.Init()
    local balloonStation = Workspace:WaitForChild("Location"):WaitForChild("BalloonStation")
end
```

---

## ProfileStore — схема данных (ProfileTemplate)

```lua
local ProfileTemplate = {
    Coins        = 0,
    Balloons     = { Default = 1 },   -- { [balloonName]: count }
    ActiveBalloon = "Default",

    -- Питомцы в инвентаре
    -- Каждый элемент: { uid, name, rarity, collectionName }
    Pets         = {},

    -- Питомцы на стендах: { [slotIndex]: { uid, name, rarity, collectionName } }
    StandPets    = {},

    -- База
    BaseLevel    = 1,    -- текущий этаж (10 слотов = 1 этаж)
    BaseSlots    = 10,   -- всего слотов (увеличивается за ключи)

    -- Прогрессия
    RebirthCount = 0,
    BaseLuck     = 1,    -- растёт при каждом Rebirth

    -- Бусты удачи (хранятся перманентно до истечения времени)
    LuckBonuses  = {
        -- temporary: список { amount: number, expiresAt: number (os.time()) }
        temporary = {},
        -- permanent: суммарный бонус от GamePass (число)
        permanent = 0,
    },

    -- Туториал
    TutorialStep = 0,    -- 0 = не начат, -1 = завершён

    -- GamePass (in-memory на сессию, не сохраняется)
    GamePasses  = {},
}
```

**Pet uid генерация (сервер):**
```lua
local uid = tostring(math.floor(tick() * 1000)) .. "_" .. tostring(math.random(1000, 9999))
```

---

## Replica — схема использования

### Сервер (PlayerService)
```lua
-- Создаётся при загрузке профиля
local playerReplica = ReplicaServer.New({
    Token = ReplicaServer.Token("PlayerData"),
    Tags  = { UserId = player.UserId },
    Data  = profile.Data,   -- прямая ссылка на таблицу ProfileStore
})
playerReplica:Subscribe(player)   -- только этот игрок

-- Изменение данных через Replica (автоматически реплицируется клиенту):
playerReplica:Set({"Coins"}, newValue)
playerReplica:Set({"Pets"}, newPetsTable)
```

### Клиент (HudController, PetController и др.)
```lua
ReplicaClient.OnNew("PlayerData", function(replica)
    -- Начальный рендер
    HudController.UpdateCoins(replica.Data.Coins)

    -- Реакция на изменения
    replica:OnSet({"Coins"}, function(new)
        HudController.UpdateCoins(new)
    end)
    replica:OnSet({"Pets"}, function(new)
        PetController.Refresh(new)
    end)
end)

ReplicaClient.RequestData()  -- вызвать один раз в Client.client
```

---

## Remotes — реестр

```lua
-- ReplicatedStorage.Shared.Remotes
-- Создаются только на сервере, читаются всеми

{
    -- Client → Server
    Balloon_Start   : RemoteEvent    -- игрок начал надувать
    Balloon_Stop    : RemoteEvent    -- игрок отпустил (успешно)
    Balloon_Equip   : RemoteEvent    -- выбрал шар из списка
    Base_Collect    : RemoteEvent    -- наступил на кнопку сбора дохода
    Pet_PlaceStand  : RemoteEvent    -- поставить питомца на стенд
    Pet_RemoveStand : RemoteEvent    -- убрать питомца со стенда
    Shop_BuyBalloon : RemoteFunction -- купить шар (нужен ответ success/fail)

    -- Server → Client (one-shot события, не состояние)
    Balloon_Result  : RemoteEvent    -- результат цикла { type, petData, reward }
    Base_Assigned   : RemoteEvent    -- назначен ID базы { baseId }
    Tutorial_Step   : RemoteEvent    -- переключить шаг туториала
    Notification    : RemoteEvent    -- показать нотификацию { text, style }

    -- Server → Client (deprecated — RouletteController слушает Balloon_Result)
    -- Roulette_Show  : RemoteEvent
}
```

---

## Data Flow — полный цикл надувания

```
[CLIENT] Зажата кнопка Старт
    → BalloonController: локальная анимация надувания
    → RemoteEvent Balloon_Start → сервер

[SERVER] BalloonService получает Balloon_Start
    → Проверяет: есть ли ActiveBalloon в инвентаре
    → Запускает серверный таймер
    → В каждый тик вычисляет шанс лопания (по BalloonConfig)
    → Если лопнул: FireClient(Balloon_Result, { type="pop" })
    → Если игрок отпустил: получает Balloon_Stop

[SERVER] Balloon_Stop получен
    → inflateTime = serverTimer - startTime
    → reward = EconomyService.CalcReward(balloonConfig, inflateTime)
    → EconomyService.AddCoins(player, reward)
       → playerReplica:Set({"Coins"}, newCoins)   ← автоматически на клиент
    → roll = math.random(GameConfig.ROULETTE_CHANCE)  -- 1/10
    → if roll == 1:
        → result = RouletteService.Roll(player, balloonConfig.maxRarity)
        → PetService.AddPet(player, result.petData)  -- если питомец
           → playerReplica:Set({"Pets"}, newPets)    ← автоматически на клиент
        → FireClient(Balloon_Result, { type="roulette", result=result })
    → else:
        → FireClient(Balloon_Result, { type="coins_only" })

[CLIENT] BalloonController получает Balloon_Result
    → type=="pop":       switchPhase(Viewing), VFX лопания,
                          balloonModel скрыт на 1s, 1.5s auto → Ready
    → type=="roulette":  switchPhase(Roulette) — шар скрыт, камера фикс, персонаж скрыт
                         RouletteController.Show() — анимация рулетки
                         Take/Exit → ReturnFromRoulette() → switchPhase(Viewing)
    → type=="coins_only":switchPhase(Viewing), 1.5s auto → Ready
    → Камера НЕ сбрасывается — переходы Viewing/Ready не трогают CameraType
    → Выход: ExitButton → switchPhase(Near) — CameraType = Custom, персонаж видим
```

**Клиентская фазовая машина BalloonController:**
```
Idle → Near → Inflating → Viewing → Ready → Inflating
  ↑        ↓                           ↑
  └────────┴─── ExitButton → Near ←────┘

                    Roulette → ReturnFromRoulette() → Viewing
                       ↑
                       └─── Balloon_Result{type="roulette"}
```

| Фаза | Камера | Персонаж | Старт | ExitButton |
|---|---|---|---|---|
| `Idle` | Custom | видим | HUD скрыт | скрыта |
| `Near` | Custom | видим | зелёная | скрыта |
| `Inflating` | Scriptable → шар | скрыт | тёмно-зелёная | видна |
| `Viewing` | Scriptable → шар | скрыт | красная/неактивна | видна |
| `Ready` | Scriptable → шар | скрыт | зелёная | видна |
| `Roulette` | Scriptable (фикс) | скрыт | красная/неактивна | скрыта |

**Вход/выход со станции:** `StandPlatform.Touched/TouchEnded` (проверка HumanoidRootPart), вместо ProximityPrompt.

---

## RouletteService — алгоритм Roll

```
1. Бросить Bomb:  math.random() < GameConfig.BOMB_CHANCE  → return { type="bomb" }
2. Бросить Key:   math.random() < GameConfig.KEY_CHANCE   → return { type="key" }
3. Иначе:
   → Собрать список питомцев из PetConfig до maxRarity включительно
   → Передать список + playerLuck в RarityUtil.WeightedPick
   → return { type="pet", name=petName, rarity=rarity, collectionName=col }

-- Шансы bomb/key — константы GameConfig, НЕ зависят от числа питомцев
-- playerLuck влияет ТОЛЬКО на взвешенный выбор питомца
```

---

## LuckService — формула

```lua
-- Все источники удачи:
-- baseLuck:     profile.Data.BaseLuck (по умолчанию 1, растёт при Rebirth)
-- temporary:    profile.Data.LuckBonuses.temporary (фильтруем истёкшие)
-- permanent:    profile.Data.LuckBonuses.permanent (GamePass)
-- serverBoost:  in-memory глобальная переменная (DevProduct, не в DS)
-- inflateLuck:  бонус от степени надува (передаётся параметром)

function LuckService.GetLuck(player, inflateLuck)
    inflateLuck = inflateLuck or 0
    local data = PlayerService.GetData(player)
    local now  = os.time()

    local tempBonus = 0
    for _, boost in ipairs(data.LuckBonuses.temporary) do
        if boost.expiresAt > now then
            tempBonus += boost.amount
        end
    end

    return data.BaseLuck
        + tempBonus
        + data.LuckBonuses.permanent
        + LuckService.GetServerBoost()
        + inflateLuck
end
```

---

## GamePass — правила работы

```lua
-- GamePass НЕ хранится в ProfileStore.
-- Проверяется через MarketplaceService при входе игрока.
-- Результат кешируется в in-memory таблице на сессию.

-- PlayerService при загрузке:
local MarketplaceService = game:GetService("MarketplaceService")

local GamePassIds = GameConfig.GAMEPASS_IDS  -- { SkipAnim=123, StarterPack=456, ... }

local passCache = {}  -- { [player]: { SkipAnim=bool, StarterPack=bool, ... } }

for passName, passId in pairs(GamePassIds) do
    local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync,
                           MarketplaceService, player.UserId, passId)
    passCache[player][passName] = ok and owns or false
end

-- Использование:
function PlayerService.HasPass(player, passName)
    return passCache[player] and passCache[player][passName] == true
end

-- Клиент получает информацию о GamePass через Replica:
-- playerReplica:Set({"GamePasses"}, passCache[player])
```

---

## DevProduct — правила работы

```lua
-- ProcessReceipt callback регистрируется один раз в Server.server
-- Логика выдачи — через соответствующий сервис

MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

    local productId = receiptInfo.ProductId
    local handler   = DevProductHandlers[productId]

    if handler then
        local success = pcall(handler, player)
        if success then
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end
```

---

## BalloonConfig — структура

```lua
-- ReplicatedStorage.Shared.Config.BalloonConfig
{
    Default = {
        displayName    = "Default Balloon",
        maxRarity      = "Common",       -- max редкость для рулетки
        baseReward     = 10,             -- монет за 1 сек надува
        maxReward      = 600,            -- монет за 60 сек надува (максимум)
        popCurve = {
            -- Вероятность лопания нарастает по кривой
            -- { time=0, chance=0.15 }, { time=5, chance=0.20 }, ...
            -- Интерполируется линейно между точками
            { time = 0,  chance = 0.15 },
            { time = 5,  chance = 0.20 },
            { time = 15, chance = 0.30 },
            { time = 30, chance = 0.50 },
            { time = 60, chance = 1.00 },
        },
    },
    Pink = {
        displayName = "Pink Balloon",
        maxRarity   = "Rare",
        baseReward  = 20,
        maxReward   = 1200,
        popCurve    = { ... },
    },
    -- и т.д.
}
```

---

## PetConfig — структура

```lua
-- ReplicatedStorage.Shared.Config.PetConfig
-- type PetTier = { name, rarityWeight, cost }
-- type Collection = { PetTier }
-- type PetConfig = { [CollectionName]: Collection }

{
    Base = {
        { name = "FluffyCat",  rarity = "Common",   rarityWeight = 100, cost = 0,    standIncome = 5  },
        { name = "WoofyDog",   rarity = "Uncommon", rarityWeight = 50,  cost = 0,    standIncome = 12 },
        { name = "CoolBunny",  rarity = "Rare",     rarityWeight = 20,  cost = 0,    standIncome = 30 },
        { name = "MysticFox",  rarity = "Epic",     rarityWeight = 5,   cost = 0,    standIncome = 80 },
        { name = "GoldenDrake",rarity = "Legendary",rarityWeight = 1,   cost = 0,    standIncome = 250 },
    },
    -- Forest = { ... },  -- будущая коллекция
}
```

---

## GameConfig — структура

```lua
-- ReplicatedStorage.Shared.Config.GameConfig
{
    -- Рулетка
    ROULETTE_CHANCE = 10,    -- 1/10 при успешном отпускании

    -- Key / Bomb шансы (независимы от питомцев)
    KEY_CHANCE  = 0.01,      -- 1%
    BOMB_CHANCE = 0.10,      -- 10%

    -- Key шанс растёт с приближением к максимуму надува
    KEY_CHANCE_MAX_INFLATE = 0.05,   -- 5% при 100% надуве

    -- Стенды
    STAND_INCOME_INTERVAL = 60,      -- сек между начислениями дохода
    BASE_SLOTS_PER_FLOOR  = 10,
    BASE_UPGRADE_KEY_COST = 1,       -- ключей за 1 слот

    -- Базы
    BASE_COUNT = 8,                  -- кол-во баз в Workspace (макс 8 игроков)

    -- Rebirth (POST-MVP)
    REBIRTH_COIN_REQUIREMENT = 100000,
    REBIRTH_LUCK_MULTIPLIER  = 0.5,  -- +0.5 к baseLuck за каждый rebirth

    -- Server Luck Boost (DevProduct)
    SERVER_BOOST_AMOUNT   = 5,
    SERVER_BOOST_DURATION = 1800,    -- 30 минут в секундах

    -- GamePass IDs (заполнить после публикации)
    GAMEPASS_IDS = {
        BalloonCosmetics = 0,
        SkipAnimation    = 0,
        StarterPack      = 0,
        SavePet          = 0,
    },

    -- DevProduct IDs
    DEVPRODUCT_IDS = {
        ServerLuck      = 0,
        BalloonWithPet  = 0,
        AdoptPet        = 0,
    },

    -- Туториал шаги
    TUTORIAL_STEPS = {
        INFLATE_FIRST   = 1,
        INFLATE_SECOND  = 2,
        BUY_BALLOON     = 3,
        EQUIP_BALLOON   = 4,
        INFLATE_NEW     = 5,
        GET_PET         = 6,
        PLACE_STAND     = 7,
        COLLECT_INCOME  = 8,
        BUY_PINK        = 9,
        COMPLETED       = -1,
    },

    -- Аудио
    APPLAUSE_INTERVAL = 10,   -- сек надувания до аплодисментов

    -- Цвета редкостей
    RARITY_COLORS = {
        Common    = Color3.fromRGB(180, 180, 180),
        Uncommon  = Color3.fromRGB(100, 200, 100),
        Rare      = Color3.fromRGB(100, 150, 255),
        Epic      = Color3.fromRGB(180, 100, 255),
        Legendary = Color3.fromRGB(255, 180, 50),
    },

    function GameConfig.GetRarityColor(rarity)
        return GameConfig.RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
    end
}
```

---

## StatefulObjectController — интерфейс

```lua
-- Модуль обёртки над TweenService
-- Хранит активный Tween на объект, отменяет предыдущий при новом вызове

StatefulObjectController.Tween(
    instance: Instance,
    properties: { [string]: any },
    duration: number,
    style: Enum.EasingStyle?,    -- default: Quad
    direction: Enum.EasingDirection?  -- default: Out
) → tween: Tween   -- можно вызвать :Cancel()

-- Пример:
StatefulObjectController.Tween(balloonModel, { Size = targetSize }, 0.3)
StatefulObjectController.Tween(frame, { BackgroundTransparency = 0 }, 0.2)
```

---

## AudioController — интерфейс

```lua
-- Все Sound-объекты лежат в ReplicatedStorage.Assets.Sounds
-- AudioController.Play ищет по имени

AudioController.Play(soundName: string)   -- воспроизвести один раз
AudioController.PlayLoop(soundName: string) → id  -- фоновый трек
AudioController.Stop(id)                  -- остановить трек

-- Имена звуков (константы):
-- "Pop"        — лопание шара
-- "Inflate"    — надувание (loop)
-- "Applause"   — аплодисменты (каждые 10 сек)
-- "PetGet"     — получение питомца
-- "Coin"       — получение монет
-- "ButtonClick"— нажатие кнопки
-- "RouletteEnd"— конец рулетки
-- "Music_1", "Music_2", ... — треки музыки
```

---

## RouletteController — интерфейс

Клиентский модуль анимации рулетки. Слушает `Balloon_Result{type="roulette"}`.

```lua
RouletteController.Init()
RouletteController.Start()

-- Запустить анимацию прокрутки
RouletteController.Show(result: RouletteResult)
-- result = { type="pet"|"key"|"bomb", name?, rarity?, collectionName?, uid? }
```

**Константы:**
```lua
local ROULETTE_DURATION = 6.5          -- секунд
local MIN_ITEM_SHOW_TIME = 0.08        -- мин. время показа элемента
local MAX_ITEM_SHOW_TIME = 0.8         -- макс. время (в конце замедления)
local FINAL_ITEMS_BEFORE = 3           -- элементов до результата
```

**Алгоритм:**
1. `buildSequence(result)`: 20 случайных питомцев + 3 filler + результат
2. `playSequence(sequence)`: Heartbeat-луп, замедление по `progress²`, ProgressBar
3. `displayItem(item)`: обновить ItemDisplay (имя, редкость, цвет, scale-пульс)
4. `showResult(result)`: ResultFrame, кнопки Take/Exit
5. Take → `PetController.SpawnAndRun(petResult)` + `BalloonController.ReturnFromRoulette()`
6. Exit → `BalloonController.ReturnFromRoulette()`

**Структура UI (RouletteGui, ScreenGui, Enabled=false):**
```
BackgroundFrame (Frame, BackgroundTransparency=1)
RouletteFrame (Frame)
├── ItemDisplay (Frame)
│   ├── PetNameLabel (TextLabel)
│   ├── RarityLabel (TextLabel)
│   └── ItemIcon (ImageLabel)
├── ProgressBar (Frame)
│   └── ProgressFill (Frame)
└── ResultFrame (Frame, Visible=false)
    ├── ResultNameLabel (TextLabel)
    ├── ResultRarityLabel (TextLabel)
    ├── TakeButton (TextButton)
    └── ExitButton (TextButton)
```

---

## PetController — интерфейс

Клиентский модуль визуального отображения питомцев. Слушает `Base_Assigned` и Replica `StandPets`.

```lua
PetController.Init()
PetController.Start()

-- Спавн питомца у шара + вызов Pet_PlaceStand
PetController.SpawnAndRun(petResult: RouletteResult)

-- Обновить модели на стендах
PetController.RefreshStands(standPets: table)
```

**SpawnAndRun:**
1. Создать модель питомца в случайной точке внутри `BalloonStation.SpawnPets`
2. Клонировать BillboardGui из `ReplicatedStorage.Assets.UI.PetBillboardGui`
3. Заполнить: `NameLabel`, `RarityLabel` (с цветом редкости), `CollectionLabel`, `IncomeLabel`, `CostLabel`
4. Найти первый пустой слот (`cachedStandPets`) и вызвать `Pet_PlaceStand:FireServer(slotIndex, uid)`
5. Через 2.5 сек — fade Out + Destroy

**Структура PetBillboardGui (ReplicatedStorage.Assets.UI):**
```
Frame
├── CollectionLabel (TextLabel)
├── NameLabel (TextLabel)
├── RarityLabel (TextLabel)
├── IncomeLabel (TextLabel)
└── CostLabel (TextLabel)
```

**RefreshStands:**
- Очистить старые модели (`spawnedStandModels`)
- Для каждого занятого слота в `StandPets`: клонировать модель из `ReplicatedStorage.Assets.Pets[petEntry.name]` на `Base{baseId}/BaseArea/StandSlot_N`

---

## BaseService — серверный модуль

Назначение физической базы из `Workspace.Location.Bases` каждому игроку при входе. In-memory, без сохранения в ProfileStore.

```lua
BaseService.Init()
BaseService.Start()

BaseService.GetBaseId(player) → baseId: number?
```

**PlayerAdded:**
1. Просканировать `baseAssignments` (player → baseId), найти свободный индекс 1..`BASE_COUNT`
2. Записать `player.Name` в `OwnerSign/Sign2/Background/SurfaceGui/Frame/OwnerLabel.Text`
3. `Remotes.Base_Assigned:FireClient(player, baseId)`

**PlayerRemoving:**
1. Очистить `OwnerLabel.Text`
2. Удалить из `baseAssignments`

### Workspace — структура баз

```
Workspace
└── Location
    └── Bases
        ├── Base1 (Model)
        │   ├── BaseArea (Model)
        │   │   ├── StandSlot_1 (Part) ... StandSlot_10 (Part)
        │   └── OwnerSign (Model)
        │       └── Sign2 (Part)
        │           └── Background (Part)
        │               └── SurfaceGui
        │                   └── Frame
        │                       └── OwnerLabel (TextLabel)
        ├── Base2 (Model)  -- такая же структура
        ...
        └── Base8 (Model)  -- такая же структура
```

---

## BalloonController — ReturnFromRoulette

Публичный метод для выхода из фазы Roulette.

```lua
-- Вызывается RouletteController после Take/Exit
-- Возвращает шар в станцию и переключает фазу в Viewing
BalloonController.ReturnFromRoulette()
```

При срабатывании `Balloon_Result{type="roulette"}`:
1. BalloonController: `switchPhase(Phase.Roulette)` — шар скрыт (`balloonModel.Parent = nil`), камера остаётся Scriptable (фикс), персонаж скрыт, ExitButton скрыта, StartButton неактивен
2. RouletteController: `Show(result)` — RouletteGui с прокруткой
3. После Take/Exit: `ReturnFromRoulette()` → `balloonModel.Parent = balloonStation`, `switchPhase(Viewing)`

---

## MVP scope (День 3 — что должно работать)

- [x] Balloon loop: надуть → деньги → (1/10) рулетка → питомец
- [x] Лопание шара: VFX, сброс, новый шар через 1 сек
- [x] Камера: фокус на шар, возврат только по ExitButton
- [x] BillboardGUI деньги над шаром, ScreenGUI удача внизу
- [x] Список шаров (HUD), кнопка Выйти
- [x] ProfileStore: сохранение Coins, Balloons, Pets
- [x] Replica: HUD обновляется автоматически
- [x] Базовые питомцы: добавление в инвентарь
- [x] Стенды: поставить питомца, доход раз в 60 сек
- [x] Магазин шаров: купить Default / Pink
- [x] FTE Tutorial: первые 3 шага

## POST-MVP (после 3 дней)

- [ ] Rebirth полный flow
- [ ] GamePass монетизация (SkipAnim, BalloonCosmetics, SavePet)
- [ ] DevProduct (ServerLuck, BalloonWithPet, AdoptPet)
- [ ] Бесхозный питомец (30 сек → Robux выкуп)
- [ ] Полный туториал (все 9 шагов)
- [ ] Key: улучшение базы (новые слоты)
- [ ] Bomb: эффект рулетки
- [ ] Смена музыкальных треков
- [ ] Наклейки на шары (Cosmetics)
