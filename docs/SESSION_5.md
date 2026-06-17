# SESSION 5 — Client Infrastructure: StatefulObjectController, AudioController, HudController

> **Цель сессии:** Создать клиентский фундамент — утилиты анимаций и звука, базовый HUD.  
> После сессии: HUD отображает монеты и удачу, реагирует на изменения Replica автоматически.  
> UI-объекты уже созданы вручную в Studio (см. требования ниже).

---

## Контекст проекта

Игра: Roblox Tycoon "Blow Biggest Balloon"  
Стек: Luau, ProfileStore, Replica (MadStudio), только Roblox Studio  
Полная архитектура: см. `docs/ARCHITECTURE.md`  
Пройденные сессии: SESSION_1–4 ✓

---

## Предусловия UI (созданы вручную в Studio)

Перед началом сессии убедиться, что в `StarterGui` существуют:

```
StarterGui
├── HudGui (ScreenGui, ResetOnSpawn=false)
│   ├── CoinsLabel    (TextLabel)  -- отображает монеты
│   └── LuckLabel     (TextLabel)  -- отображает удачу
└── NotificationGui (ScreenGui, ResetOnSpawn=false)
    └── NotificationFrame (Frame, Visible=false)
        └── NotificationText (TextLabel)
```

Если UI не создан — написать код с `WaitForChild` и добавить комментарий `-- UI: ожидание элемента`.

---

## Задачи сессии

### 1. `StarterPlayerScripts/Modules/StatefulObjectController` (ModuleScript)

Обёртка над TweenService. Хранит активный Tween на каждый Instance, автоматически отменяет предыдущий.

**Интерфейс:**
```lua
StatefulObjectController.Tween(
    instance: Instance,
    properties: { [string]: any },
    duration: number,
    style: Enum.EasingStyle?,      -- default: Quad
    direction: Enum.EasingDirection?  -- default: Out
): Tween

StatefulObjectController.Cancel(instance: Instance)  -- отменить активный Tween
StatefulObjectController.CancelAll()                 -- отменить все (при cleanup)
```

**Реализация:**
```lua
local TweenService = game:GetService("TweenService")
local activeTweens = {}  -- { [instance]: Tween }

function StatefulObjectController.Tween(instance, properties, duration, style, direction)
    -- Отменить предыдущий Tween на этот instance
    if activeTweens[instance] then
        activeTweens[instance]:Cancel()
        activeTweens[instance] = nil
    end
    
    local tweenInfo = TweenInfo.new(
        duration,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    activeTweens[instance] = tween
    
    tween.Completed:Connect(function()
        if activeTweens[instance] == tween then
            activeTweens[instance] = nil
        end
    end)
    
    tween:Play()
    return tween
end
```

---

### 2. `StarterPlayerScripts/Modules/AudioController` (ModuleScript)

Управление звуками игры.

**Предусловие:** Sound-объекты должны быть созданы вручную в Studio:  
`ReplicatedStorage/Assets/Sounds/` — папка со Sound-объектами.  
Имена Sound-объектов совпадают с константами в ARCHITECTURE.md раздел "AudioController — интерфейс".

**Интерфейс:**
```lua
AudioController.Init()

AudioController.Play(soundName: string)             -- воспроизвести один раз
AudioController.PlayLoop(soundName: string): string  -- запустить looping, вернуть id
AudioController.Stop(id: string)                    -- остановить по id

-- Внутренние имена звуков (константы модуля):
AudioController.Sounds = {
    Pop           = "Pop",
    Inflate       = "Inflate",
    Applause      = "Applause",
    PetGet        = "PetGet",
    Coin          = "Coin",
    ButtonClick   = "ButtonClick",
    RouletteEnd   = "RouletteEnd",
    Music1        = "Music_1",
}
```

**Реализация:**
```lua
local soundsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds")
local loopingTracks = {}  -- { [id]: Sound }

function AudioController.Play(soundName)
    local sound = soundsFolder:FindFirstChild(soundName)
    if sound then
        sound:Play()
    else
        warn("[AudioController] Sound not found:", soundName)
    end
end

function AudioController.PlayLoop(soundName)
    local sound = soundsFolder:FindFirstChild(soundName)
    if not sound then
        warn("[AudioController] Sound not found:", soundName)
        return ""
    end
    local id = soundName .. "_" .. tostring(tick())
    local clone = sound:Clone()
    clone.Looped = true
    clone.Parent = workspace
    clone:Play()
    loopingTracks[id] = clone
    return id
end

function AudioController.Stop(id)
    if loopingTracks[id] then
        loopingTracks[id]:Stop()
        loopingTracks[id]:Destroy()
        loopingTracks[id] = nil
    end
end
```

---

### 3. `StarterPlayerScripts/Modules/HudController` (ModuleScript)

Подписывается на Replica и обновляет HUD-элементы.

**Интерфейс:**
```lua
HudController.Init()   -- подключить Replica слушатели
HudController.Start()  -- показать HUD (если скрыт)

HudController.UpdateCoins(amount: number)
HudController.UpdateLuck(amount: number)
HudController.ShowNotification(text: string, style: string?)
```

**Реализация Init():**
```lua
function HudController.Init()
    local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
    
    ReplicaClient.OnNew("PlayerData", function(replica)
        -- Начальный рендер
        HudController.UpdateCoins(replica.Data.Coins)
        HudController.UpdateLuck(replica.Data.BaseLuck)  -- упрощённо для MVP
        
        -- Автоматическое обновление при изменениях
        replica:OnSet({"Coins"}, function(new)
            HudController.UpdateCoins(new)
        end)
        
        replica:OnSet({"BaseLuck"}, function(new)
            HudController.UpdateLuck(new)
        end)
    end)
    
    -- Notification Remote
    local Remotes = require(ReplicatedStorage.Shared.Remotes)
    Remotes.Notification.OnClientEvent:Connect(function(data)
        HudController.ShowNotification(data.text, data.style)
    end)
end
```

**UpdateCoins:**
```lua
function HudController.UpdateCoins(amount)
    local label = PlayerGui:WaitForChild("HudGui"):WaitForChild("CoinsLabel")
    label.Text = "Монет: " .. tostring(math.floor(amount))
end
```

**ShowNotification:**
```lua
-- Показать NotificationFrame на 2 секунды
-- Использовать StatefulObjectController.Tween для fade in/out
function HudController.ShowNotification(text, style)
    local frame = PlayerGui:WaitForChild("NotificationGui"):WaitForChild("NotificationFrame")
    local label = frame:WaitForChild("NotificationText")
    label.Text = text
    frame.Visible = true
    StatefulObjectController.Tween(frame, { BackgroundTransparency = 0 }, 0.2)
    task.delay(2, function()
        StatefulObjectController.Tween(frame, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.3)
        frame.Visible = false
    end)
end
```

---

### 4. Обновить `StarterPlayerScripts/Client.client`

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)

local StarterPlayerScripts = game:GetService("StarterPlayerScripts")
-- Примечание: в Studio модули лежат в PlayerScripts во время игры
local PlayerScripts = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")

local StatefulObjectController = require(PlayerScripts.Modules.StatefulObjectController)
local AudioController          = require(PlayerScripts.Modules.AudioController)
local HudController            = require(PlayerScripts.Modules.HudController)

-- Init
AudioController.Init()
HudController.Init()

-- Start
HudController.Start()

ReplicaClient.RequestData()

-- В следующих сессиях сюда добавятся BalloonController, RouletteController, PetController
```

---

## Что НЕ делать в этой сессии

- Не писать BalloonController (SESSION_6)
- Не писать RouletteController (SESSION_7)
- Не писать PetController (SESSION_6)

---

## Проверка результата

**Play Solo:**
1. Должны отображаться CoinsLabel и LuckLabel в HUD
2. Command Bar:
   ```lua
   local SSS = game:GetService("ServerScriptService")
   local ES = require(SSS.Modules.EconomyService)
   ES.AddCoins(game.Players:GetPlayers()[1], 1000)
   -- HUD должен автоматически обновить CoinsLabel: "Монет: 1000"
   ```
3. Notification тест:
   ```lua
   local RS = game:GetService("ReplicatedStorage")
   local Remotes = require(RS.Shared.Remotes)
   Remotes.Notification:FireClient(game.Players:GetPlayers()[1], { text="Тест!", style="info" })
   -- Должен появиться и исчезнуть через 2 сек
   ```
