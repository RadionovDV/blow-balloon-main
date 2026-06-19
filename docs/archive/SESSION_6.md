# SESSION 6 — BalloonController (клиент): камера, анимация, HUD шара

> **Цель сессии:** Реализовать весь клиентский цикл надувания шара.  
> После сессии: игрок подходит к шару, нажимает Старт, видит анимацию надувания, камера фокусируется,  
> после отпускания — получает монеты и возвращается стандартная камера.  
> Рулетка НЕ реализуется в этой сессии (заглушка).

---

## Контекст проекта

Игра: Roblox Tycoon "Blow Biggest Balloon"  
Стек: Luau, ProfileStore, Replica (MadStudio), только Roblox Studio  
Полная архитектура: см. `docs/ARCHITECTURE.md`  
Пройденные сессии: SESSION_1–5 ✓

---

## Предусловия UI (созданы вручную в Studio)

```
StarterGui
├── BalloonHudGui (ScreenGui, Enabled=false по умолчанию)
│   ├── StartButton     (TextButton)  -- "Старт"
│   ├── ExitButton      (TextButton, Visible=false)  -- "Выйти"
│   ├── BalloonListFrame (Frame)     -- вертикальный список шаров
│   │   └── BalloonItemTemplate (Frame, Visible=false)  -- шаблон элемента
│   └── LuckBarFrame (Frame)         -- внизу экрана, удача
│       └── LuckLabel (TextLabel)
└── HudGui (из SESSION_5)
    └── ...

workspace
└── BalloonStation (Model)           -- место где стоит шар
    ├── BalloonModel (Model)         -- сам шар (заменяется при смене)
    │   └── BalloonPart (Part)       -- основная часть шара
    └── BillboardGui (BillboardGui, Adornee=BalloonPart)
        └── RewardLabel (TextLabel)  -- деньги над шаром
```

**Примечание:** Структура workspace-объектов условная — уточнить у разработчика перед реализацией.  
Если структура отличается — адаптировать пути в коде.

---

## Задачи сессии

### 1. `StarterPlayerScripts/Modules/BalloonController` (ModuleScript)

**Интерфейс:**
```lua
BalloonController.Init()
BalloonController.Start()
```

**Состояние модуля:**
```lua
local state = {
    isInflating    = false,
    isNearBalloon  = false,
    startTime      = 0,
    currentBalloon = nil,    -- ссылка на BalloonModel в workspace
    cameraReturning = false,
    applauseTimer  = 0,
    -- Replica data (кеш)
    activeBalloon  = "Default",
    ownedBalloons  = {},
}
```

---

**Proximity Detection (в Start()):**
```lua
-- Использовать RunService.Heartbeat или ProximityPrompt
-- Вариант для MVP: ProximityPrompt на BalloonStation
-- При Triggered: showBalloonHud()
-- При исчезновении: если не надуваем → hideBalloonHud()
```

---

**showBalloonHud() / hideBalloonHud():**
```lua
local function showBalloonHud()
    state.isNearBalloon = true
    BalloonHudGui.Enabled = true
    -- Обновить список шаров
    refreshBalloonList()
    -- Кнопка Старт активна (белая/зелёная)
    setStartButtonState("idle")
end

local function hideBalloonHud()
    if state.isInflating then return end  -- нельзя уйти во время надувания
    state.isNearBalloon = false
    BalloonHudGui.Enabled = false
end
```

---

**refreshBalloonList():**
```lua
-- Читает из Replica кешированные данные
-- Очищает BalloonListFrame от предыдущих элементов (кроме Template)
-- Для каждого шара в ownedBalloons создаёт клон BalloonItemTemplate
-- Активный шар подсвечивается (другой цвет фона)
-- При нажатии на элемент: FireServer(Balloon_Equip, balloonName)
```

---

**Нажатие StartButton (MouseButton1Down / TouchTapInArea):**
```lua
StartButton.MouseButton1Down:Connect(function()
    if state.isInflating or not state.isNearBalloon then return end
    startInflating()
end)

StartButton.MouseButton1Up:Connect(function()
    if not state.isInflating then return end
    stopInflating()
end)
```

---

**startInflating():**
```lua
local function startInflating()
    state.isInflating = true
    state.startTime = tick()
    state.applauseTimer = 0
    
    -- Скрыть персонажа
    setCharacterVisible(false)
    
    -- Камера на шар
    focusCameraOnBalloon()
    
    -- Показать ExitButton
    ExitButton.Visible = true
    setStartButtonState("active")
    
    -- Сообщить серверу
    Remotes.Balloon_Start:FireServer()
    
    -- Запустить loop анимации (Heartbeat)
    startInflateLoop()
    
    -- Звук надувания
    inflateLoopId = AudioController.PlayLoop(AudioController.Sounds.Inflate)
end
```

---

**startInflateLoop() — Heartbeat loop:**
```lua
local function startInflateLoop()
    inflateConnection = RunService.Heartbeat:Connect(function(dt)
        if not state.isInflating then
            inflateConnection:Disconnect()
            return
        end
        
        local elapsed = tick() - state.startTime
        local t = math.clamp(elapsed / 60, 0, 1)
        
        -- Обновить BillboardGui над шаром
        local config = BalloonConfig[state.activeBalloon]
        local previewReward = math.floor(config.baseReward + (config.maxReward - config.baseReward) * t)
        RewardLabel.Text = "+" .. previewReward
        
        -- Обновить LuckLabel
        local inflateLuck = t * 2  -- бонус удачи от степени надува (упрощённо)
        LuckLabel.Text = "Удача: " .. string.format("%.1f", inflateLuck)
        
        -- Анимация шара: увеличение размера
        local targetSize = Vector3.new(1 + t * 3, 1 + t * 3, 1 + t * 3)
        -- Импульсивное надувание: добавить синусоидальный пульс
        local pulse = 1 + math.sin(elapsed * 8) * 0.03 * (1 - t)
        BalloonPart.Size = targetSize * pulse
        
        -- Подъём по Y
        BalloonPart.Position = balloonBasePosition + Vector3.new(0, t * 5, 0)
        
        -- Камера следит за центром шара по Y
        updateCameraFollow()
        
        -- Аплодисменты каждые 10 сек
        state.applauseTimer += dt
        if state.applauseTimer >= GameConfig.APPLAUSE_INTERVAL then
            state.applauseTimer = 0
            AudioController.Play(AudioController.Sounds.Applause)
        end
    end)
end
```

---

**stopInflating():**
```lua
local function stopInflating()
    if not state.isInflating then return end
    state.isInflating = false
    
    -- Остановить звук
    AudioController.Stop(inflateLoopId)
    
    -- Кнопка неактивна
    setStartButtonState("inactive")
    ExitButton.Visible = false
    
    -- Сообщить серверу
    Remotes.Balloon_Stop:FireServer()
    
    -- Ждём результат от сервера (Balloon_Result)
end
```

---

**Обработка Balloon_Result (Server → Client):**
```lua
Remotes.Balloon_Result.OnClientEvent:Connect(function(result)
    if result.type == "pop" then
        -- VFX лопания (Particle Emitter или простой эффект)
        AudioController.Play(AudioController.Sounds.Pop)
        
        -- Скрыть шар на 1 сек
        BalloonModel.Parent = nil
        task.wait(1)
        BalloonModel.Parent = BalloonStation
        resetBalloonSize()
        
        -- Возврат камеры
        returnCamera()
        setCharacterVisible(true)
        setStartButtonState("idle")
        
        -- Сообщение туториала
        if needsPopTutorial then
            Remotes.Notification:FireServer(...)
            -- Или локально показать: "Упс, похоже что шар может лопнуть..."
            HudController.ShowNotification("Упс! Шар лопнул — не перенадувай!")
        end
        
    elseif result.type == "roulette" then
        -- Звук монет
        AudioController.Play(AudioController.Sounds.Coin)
        -- Запустить рулетку (SESSION_7)
        -- RouletteController.Show(result.result)  -- TODO SESSION_7
        returnCamera()
        setCharacterVisible(true)
        setStartButtonState("idle")
        
    elseif result.type == "coins_only" then
        AudioController.Play(AudioController.Sounds.Coin)
        returnCamera()
        setCharacterVisible(true)
        setStartButtonState("idle")
        
    elseif result.type == "no_balloon" then
        HudController.ShowNotification("Нет шара в инвентаре!")
        setStartButtonState("idle")
    end
    
    -- Сброс размера шара в любом случае
    resetBalloonSize()
end)
```

---

**Камера — вспомогательные функции:**
```lua
local function focusCameraOnBalloon()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    -- Начальный CFrame: смотрим на шар с небольшого расстояния
    local balloonPos = BalloonPart.Position
    camera.CFrame = CFrame.new(balloonPos + Vector3.new(0, 2, 8), balloonPos)
end

local function updateCameraFollow()
    -- Следим за центром шара по Y, X и Z фиксированы
    local camera = workspace.CurrentCamera
    if camera.CameraType ~= Enum.CameraType.Scriptable then return end
    local balloonPos = BalloonPart.Position
    local currentCF = camera.CFrame
    local targetCF  = CFrame.new(
        Vector3.new(currentCF.Position.X, balloonPos.Y + 2, currentCF.Position.Z),
        balloonPos
    )
    camera.CFrame = currentCF:Lerp(targetCF, 0.1)
end

local function returnCamera()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom  -- стандартная Roblox камера
end
```

---

**setCharacterVisible(visible):**
```lua
local function setCharacterVisible(visible)
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.LocalTransparencyModifier = visible and 0 or 1
        end
    end
end
```

---

**Кнопки состояния:**
```lua
-- "idle"     → StartButton активна, нормальный цвет
-- "active"   → StartButton нажата, другой цвет
-- "inactive" → StartButton красная/серая, недоступна (после лопания)
local function setStartButtonState(state)
    if state == "idle" then
        StartButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        StartButton.Active = true
    elseif state == "active" then
        StartButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        StartButton.Active = true
    elseif state == "inactive" then
        StartButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        StartButton.Active = false
    end
end
```

---

**ExitButton:**
```lua
ExitButton.MouseButton1Click:Connect(function()
    if state.isInflating then
        stopInflating()
    end
    hideBalloonHud()
    returnCamera()
    setCharacterVisible(true)
end)
```

---

**Replica слушатель (в Init()):**
```lua
ReplicaClient.OnNew("PlayerData", function(replica)
    state.activeBalloon  = replica.Data.ActiveBalloon
    state.ownedBalloons  = replica.Data.Balloons
    
    replica:OnSet({"ActiveBalloon"}, function(new)
        state.activeBalloon = new
        refreshBalloonList()
    end)
    
    replica:OnSet({"Balloons"}, function(new)
        state.ownedBalloons = new
        refreshBalloonList()
    end)
end)
```

---

### 2. Обновить `Client.client`

```lua
local BalloonController = require(PlayerScripts.Modules.BalloonController)

-- Init (после AudioController, HudController)
BalloonController.Init()

-- Start
BalloonController.Start()
```

---

## Что НЕ делать в этой сессии

- Не реализовывать RouletteController (SESSION_7)
- Не реализовывать PetController (SESSION_6b / SESSION_7)
- Не реализовывать магазин шаров

---

## Проверка результата

**Play Solo:**
1. Подойти к BalloonStation → появляется BalloonHudGui с кнопкой Старт
2. Нажать и держать Старт → шар начинает увеличиваться, камера фокусируется
3. RewardLabel над шаром показывает растущую сумму
4. Аплодисменты каждые 10 секунд
5. Отпустить → монеты начислились (CoinsLabel обновился), камера вернулась
6. Подождать случайный pop → VFX, шар исчезает на 1 сек, появляется снова
7. ExitButton работает, возвращает стандартную камеру
