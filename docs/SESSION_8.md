# SESSION 8 — ShopController + TutorialController + полировка MVP

> **Цель сессии:** Магазин шаров, FTE-туториал, финальная полировка game feel.  
> После сессии: игрок проходит туториал, может купить шары в магазине, игра полностью воспроизводима.  
> Это финальная сессия MVP.

---

## Контекст проекта

Игра: Roblox Tycoon "Blow Biggest Balloon"  
Стек: Luau, ProfileStore, Replica (MadStudio), только Roblox Studio  
Полная архитектура: см. `docs/ARCHITECTURE.md`  
Пройденные сессии: SESSION_1–7 ✓

---

## Предусловия UI (созданы вручную в Studio)

```
StarterGui
└── ShopGui (ScreenGui, Enabled=false)
    └── ShopFrame (Frame)
        ├── CloseButton (TextButton)
        ├── TitleLabel (TextLabel) -- "Магазин шаров"
        └── BalloonListFrame (ScrollingFrame)
            └── BalloonItemTemplate (Frame, Visible=false)
                ├── BalloonNameLabel (TextLabel)
                ├── BalloonPriceLabel (TextLabel)
                ├── BalloonRarityLabel (TextLabel)
                └── BuyButton (TextButton)

workspace
└── ShopProximityPart (Part) -- наступить → открыть магазин

StarterGui
└── TutorialGui (ScreenGui, ResetOnSpawn=false)
    └── TutorialFrame (Frame, Visible=false)
        ├── TutorialText (TextLabel)
        └── TutorialArrow (ImageLabel, Visible=false) -- указатель
```

---

## Задачи сессии

### 1. Добавить цены в `BalloonConfig`

В каждый шар добавить поле `price`:
```lua
Default = { ..., price = 0 },       -- бесплатный (стартовый)
Blue    = { ..., price = 500 },
Pink    = { ..., price = 1000 },
```

---

### 2. `ServerScriptService/Modules/BalloonShopService` (ModuleScript)

Серверная логика покупки шаров.

**Интерфейс:**
```lua
BalloonShopService.Init()
BalloonShopService.Start()
```

**Shop_BuyBalloon (RemoteFunction, Client → Server):**
```lua
Remotes.Shop_BuyBalloon.OnServerInvoke = function(player, balloonName)
    -- Валидация
    local config = BalloonConfig[balloonName]
    if not config then return false, "Шар не найден" end
    
    local data = PlayerService.GetData(player)
    if not data then return false, "Данные не загружены" end
    
    -- Проверить: уже есть?
    if data.Balloons[balloonName] and data.Balloons[balloonName] > 0 then
        return false, "Уже есть в инвентаре"
    end
    
    -- Проверить деньги
    if not EconomyService.SpendCoins(player, config.price) then
        return false, "Недостаточно монет"
    end
    
    -- Добавить шар
    local newBalloons = table.clone(data.Balloons)  -- или TableUtil.DeepCopy
    newBalloons[balloonName] = 1
    PlayerService.SetData(player, {"Balloons"}, newBalloons)
    
    return true, "Куплено!"
end
```

---

### 3. `StarterPlayerScripts/Modules/ShopController` (ModuleScript)

**Интерфейс:**
```lua
ShopController.Init()
ShopController.Start()
ShopController.Open()
ShopController.Close()
```

**Init():**
```lua
-- Proximity к ShopProximityPart
local ProximityPrompt = ShopProximityPart:FindFirstChildOfClass("ProximityPrompt")
if ProximityPrompt then
    ProximityPrompt.Triggered:Connect(function()
        ShopController.Open()
    end)
end

-- Подписаться на Replica для актуальных данных
ReplicaClient.OnNew("PlayerData", function(replica)
    playerCoins    = replica.Data.Coins
    playerBalloons = replica.Data.Balloons
    
    replica:OnSet({"Coins"}, function(new) playerCoins = new end)
    replica:OnSet({"Balloons"}, function(new)
        playerBalloons = new
        if ShopGui.Enabled then refreshShopList() end
    end)
end)
```

**Open():**
```lua
function ShopController.Open()
    AudioController.Play(AudioController.Sounds.ButtonClick)
    ShopGui.Enabled = true
    StatefulObjectController.Tween(ShopFrame, 
        { Size = UDim2.new(0.6, 0, 0.7, 0) }, 0.3, Enum.EasingStyle.Back)
    refreshShopList()
end
```

**refreshShopList():**
```lua
local function refreshShopList()
    -- Очистить список (кроме Template)
    for _, child in ipairs(BalloonListFrame:GetChildren()) do
        if child.Name ~= "BalloonItemTemplate" and child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Создать элемент для каждого шара в BalloonConfig
    for balloonName, config in pairs(BalloonConfig) do
        local item = BalloonItemTemplate:Clone()
        item.Name    = balloonName
        item.Visible = true
        
        item.BalloonNameLabel.Text   = config.displayName
        item.BalloonRarityLabel.Text = "Макс: " .. config.maxRarity
        
        local owned = playerBalloons[balloonName] and playerBalloons[balloonName] > 0
        
        if owned then
            item.BalloonPriceLabel.Text = "Есть"
            item.BuyButton.Text         = "Куплено"
            item.BuyButton.Active       = false
            item.BuyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        else
            item.BalloonPriceLabel.Text = config.price .. " монет"
            item.BuyButton.Text         = "Купить"
            
            -- Недоступно если не хватает денег
            if playerCoins < config.price then
                item.BuyButton.Active = false
                item.BuyButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            else
                item.BuyButton.Active = true
                item.BuyButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            end
            
            item.BuyButton.MouseButton1Click:Connect(function()
                attemptBuy(balloonName)
            end)
        end
        
        item.Parent = BalloonListFrame
    end
end
```

**attemptBuy(balloonName):**
```lua
local function attemptBuy(balloonName)
    AudioController.Play(AudioController.Sounds.ButtonClick)
    -- RemoteFunction вызов
    local success, message = Remotes.Shop_BuyBalloon:InvokeServer(balloonName)
    if success then
        HudController.ShowNotification("Куплено: " .. BalloonConfig[balloonName].displayName)
        -- Список обновится автоматически через Replica OnSet Balloons
    else
        HudController.ShowNotification(message or "Ошибка покупки")
    end
end
```

---

### 4. `StarterPlayerScripts/Modules/TutorialController` (ModuleScript)

FTE-туториал. Отслеживает шаги через Replica `TutorialStep`.

**Шаги (из GameConfig.TUTORIAL_STEPS):**
```
1 = INFLATE_FIRST   — надуть шар первый раз
2 = INFLATE_SECOND  — надуть шар второй раз
3 = BUY_BALLOON     — купить новый шар
4 = EQUIP_BALLOON   — экипировать его
5 = INFLATE_NEW     — надуть новый шар
6 = GET_PET         — получить питомца
7 = PLACE_STAND     — поставить питомца на стенд
8 = COLLECT_INCOME  — собрать доход (накопить 1000 монет)
9 = BUY_PINK        — купить Розовый шар
-1 = COMPLETED
```

**Интерфейс:**
```lua
TutorialController.Init()
TutorialController.Start()
```

**Init():**
```lua
function TutorialController.Init()
    ReplicaClient.OnNew("PlayerData", function(replica)
        showTutorialStep(replica.Data.TutorialStep)
        
        replica:OnSet({"TutorialStep"}, function(new)
            showTutorialStep(new)
        end)
    end)
    
    -- Слушать Tutorial_Step Remote (для специальных подсказок от сервера)
    Remotes.Tutorial_Step.OnClientEvent:Connect(function(step, message)
        if message then
            HudController.ShowNotification(message)
        end
    end)
end
```

**showTutorialStep(step):**
```lua
local STEP_TEXTS = {
    [1] = "Подойди к шару и зажми кнопку Старт — надуй шар!",
    [2] = "Отлично! Надуй шар ещё раз.",
    [3] = "Теперь купи новый шар в магазине!",
    [4] = "Выбери новый шар из списка у шара.",
    [5] = "Надуй новый шар!",
    [6] = "Поздравляем с питомцем! Забери его.",
    [7] = "Поставь питомца на стенд базы.",
    [8] = "Накопи 1000 монет и собери доход.",
    [9] = "Купи Розовый шар в магазине!",
    [-1] = nil,  -- туториал завершён, не показывать
}

local function showTutorialStep(step)
    local text = STEP_TEXTS[step]
    if not text then
        TutorialFrame.Visible = false
        return
    end
    
    TutorialFrame.Visible = true
    TutorialText.Text = text
    
    -- Fade in
    TutorialFrame.BackgroundTransparency = 1
    StatefulObjectController.Tween(TutorialFrame, 
        { BackgroundTransparency = 0.2 }, 0.3)
end
```

**Прогресс туториала на сервере (добавить в Server.server или отдельный TutorialService):**
```lua
-- Простая проверка после каждого значимого события:
-- После успешного надувания → TutorialStep 0→1 или 1→2
-- После покупки шара → 2→3 и т.д.
-- Реализовать как вызовы PlayerService.SetData(player, {"TutorialStep"}, nextStep)
-- Добавить в BalloonService, PetService, BalloonShopService

-- Пример в BalloonService (после Balloon_Stop):
local data = PlayerService.GetData(player)
if data.TutorialStep == 0 then
    PlayerService.SetData(player, {"TutorialStep"}, 1)
elseif data.TutorialStep == 1 then
    PlayerService.SetData(player, {"TutorialStep"}, 2)
end

-- Сообщение о лопании (туториал):
if result.type == "pop" and data.TutorialStep <= 2 then
    Remotes.Tutorial_Step:FireClient(player, data.TutorialStep,
        "Упс, похоже что шар может лопнуть, если его сильно надуть!")
end
```

---

### 5. Game Feel — финальная полировка

Добавить в существующие контроллеры:

**Звуки кнопок (везде где MouseButton1Click):**
```lua
button.MouseButton1Click:Connect(function()
    AudioController.Play(AudioController.Sounds.ButtonClick)
    -- ... логика
end)
```

**Звук получения монет (HudController или BalloonController):**
```lua
-- При изменении Coins вверх:
replica:OnSet({"Coins"}, function(new, old)
    if new > old then
        AudioController.Play(AudioController.Sounds.Coin)
    end
    HudController.UpdateCoins(new)
end)
```

**Недоступные кнопки — красный цвет:**
Везде где `button.Active = false` добавлять `button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)`.

**Плавное открытие окон:**
Все GUI-окна открываются через `StatefulObjectController.Tween(frame, { Size = targetSize }, 0.3, Enum.EasingStyle.Back)`.

---

### 6. Обновить `Server.server` (финальная версия)

```lua
local PlayerService      = require(SSS.Modules.PlayerService)
local EconomyService     = require(SSS.Modules.EconomyService)
local LuckService        = require(SSS.Modules.LuckService)
local RouletteService    = require(SSS.Modules.RouletteService)
local PetService         = require(SSS.Modules.PetService)
local BalloonService     = require(SSS.Modules.BalloonService)
local BalloonShopService = require(SSS.Modules.BalloonShopService)

-- ProcessReceipt для DevProducts (заглушки до POST-MVP)
local MarketplaceService = game:GetService("MarketplaceService")
MarketplaceService.ProcessReceipt = function(receiptInfo)
    -- TODO POST-MVP: DevProductHandlers
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Init
PlayerService.Init()
EconomyService.Init()
LuckService.Init()
RouletteService.Init()
PetService.Init()
BalloonService.Init()
BalloonShopService.Init()

-- Start
PlayerService.Start()
EconomyService.Start()
LuckService.Start()
RouletteService.Start()
PetService.Start()
BalloonService.Start()
BalloonShopService.Start()
```

### 7. Обновить `Client.client` (финальная версия)

```lua
local StatefulObjectController = require(PlayerScripts.Modules.StatefulObjectController)
local AudioController          = require(PlayerScripts.Modules.AudioController)
local HudController            = require(PlayerScripts.Modules.HudController)
local BalloonController        = require(PlayerScripts.Modules.BalloonController)
local RouletteController       = require(PlayerScripts.Modules.RouletteController)
local PetController            = require(PlayerScripts.Modules.PetController)
local ShopController           = require(PlayerScripts.Modules.ShopController)
local TutorialController       = require(PlayerScripts.Modules.TutorialController)

-- Init (порядок важен)
AudioController.Init()
HudController.Init()
BalloonController.Init()
RouletteController.Init()
PetController.Init()
ShopController.Init()
TutorialController.Init()

-- Start
HudController.Start()
BalloonController.Start()
RouletteController.Start()
PetController.Start()
ShopController.Start()
TutorialController.Start()

ReplicaClient.RequestData()
```

---

## Чеклист MVP (финальная проверка)

После Session 8 всё нижеследующее должно работать:

- [ ] Подойти к шару → появляется HUD с кнопкой Старт
- [ ] Зажать Старт → шар надувается, камера фокусируется, монеты растут над шаром
- [ ] Отпустить → монеты начислены, HUD обновился автоматически
- [ ] С шансом 1/10 → запускается рулетка с анимацией ~6.5 сек
- [ ] Питомец добавляется в инвентарь (Replica)
- [ ] Шар лопается → VFX, сообщение туториала, новый шар через 1 сек
- [ ] Список шаров в HUD шара обновляется при смене ActiveBalloon
- [ ] ExitButton возвращает стандартную камеру и персонажа
- [ ] Магазин открывается рядом с Shop-объектом
- [ ] Купить Pink Balloon за 1000 монет → появляется в инвентаре
- [ ] Недоступные кнопки красные
- [ ] Питомца можно поставить на стенд → собрать доход
- [ ] Туториал показывает подсказки на каждом шаге
- [ ] При выходе и входе → данные сохранились (Coins, Balloons, Pets)
- [ ] Аудио: Inflate loop, Pop, Coin, Applause каждые 10 сек, ButtonClick
