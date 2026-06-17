# SESSION 7 — RouletteController + PetController (клиент)

> **Цель сессии:** Анимация рулетки и визуальное отображение питомцев на клиенте.  
> После сессии: при выпадении рулетки запускается анимация прокрутки, в конце показывается результат.  
> Питомец "бежит" к базе игрока после получения.

---

## Контекст проекта

Игра: Roblox Tycoon "Blow Biggest Balloon"  
Стек: Luau, ProfileStore, Replica (MadStudio), только Roblox Studio  
Полная архитектура: см. `docs/ARCHITECTURE.md`  
Пройденные сессии: SESSION_1–6 ✓

---

## Предусловия UI (созданы вручную в Studio)

```
StarterGui
└── RouletteGui (ScreenGui, Enabled=false)
    ├── BackgroundFrame (Frame, BackgroundTransparency=1)  -- тёмный фон
    └── RouletteFrame (Frame)
        ├── ItemDisplay (Frame)        -- центральный дисплей текущего элемента
        │   ├── PetNameLabel (TextLabel)
        │   ├── RarityLabel (TextLabel)
        │   └── ItemIcon (ImageLabel)  -- иконка питомца/ключа/бомбы
        ├── ProgressBar (Frame)        -- бар заполнения справа
        │   └── ProgressFill (Frame)   -- уменьшается до 0 = смена элемента
        └── ResultFrame (Frame, Visible=false)  -- финальный экран
            ├── ResultNameLabel (TextLabel)
            ├── ResultRarityLabel (TextLabel)
            ├── TakeButton (TextButton)   -- "Забрать"
            └── ExitButton (TextButton)   -- "Выйти"
```

---

## Задачи сессии

### 1. `StarterPlayerScripts/Modules/RouletteController` (ModuleScript)

**Интерфейс:**
```lua
RouletteController.Init()
RouletteController.Start()

-- Запустить рулетку с известным результатом
RouletteController.Show(result: RouletteResult)
-- result = { type="pet"|"key"|"bomb", name?, rarity?, collectionName? }
```

---

**Константы рулетки:**
```lua
local ROULETTE_DURATION = 6.5     -- секунд
local MIN_ITEM_SHOW_TIME = 0.08   -- мин. время показа одного элемента
local MAX_ITEM_SHOW_TIME = 0.8    -- макс. время (в конце замедления)
local FINAL_ITEMS_BEFORE = 3      -- сколько "лишних" элементов до результата
```

---

**Show(result) — основная логика:**
```lua
function RouletteController.Show(result)
    -- 1. Построить последовательность элементов
    local sequence = buildSequence(result)
    
    -- 2. Показать GUI (fade in)
    RouletteGui.Enabled = true
    StatefulObjectController.Tween(BackgroundFrame, { BackgroundTransparency = 0.5 }, 0.3)
    
    -- 3. Запустить прокрутку (сразу, не ждать fade)
    playSequence(sequence, result)
end
```

---

**buildSequence(result):**
```lua
-- Генерирует список элементов для прокрутки
-- Последовательность: случайные питомцы/элементы, в конце — результат
-- Длина: рассчитывается так, чтобы прокрутка заняла ROULETTE_DURATION сек
-- при замедлении от MIN до MAX времени показа
local function buildSequence(result)
    local sequence = {}
    
    -- Добавить ~20 случайных элементов в начало (быстрая часть)
    for i = 1, 20 do
        table.insert(sequence, getRandomRouletteItem())
    end
    
    -- FINAL_ITEMS_BEFORE случайных элементов перед результатом
    for i = 1, FINAL_ITEMS_BEFORE do
        table.insert(sequence, getRandomRouletteItem())
    end
    
    -- Финальный результат
    table.insert(sequence, result)
    
    return sequence
end

-- Случайный элемент для заполнения (не финальный результат)
local function getRandomRouletteItem()
    -- Простой вариант для MVP: случайный питомец Common редкости
    local base = PetConfig.Base
    local idx = math.random(#base)
    return { type = "pet", name = base[idx].name, rarity = base[idx].rarity }
end
```

---

**playSequence(sequence, finalResult):**
```lua
-- Рендерится через RunService.Heartbeat
-- Скорость замедляется от MAX_SPEED к MIN_SPEED по кривой
local function playSequence(sequence, finalResult)
    local currentIndex = 1
    local itemTimer = 0
    local totalTime = 0
    local connection
    
    connection = RunService.Heartbeat:Connect(function(dt)
        totalTime += dt
        itemTimer += dt
        
        -- Текущее время показа одного элемента (замедление)
        local progress = math.clamp(totalTime / ROULETTE_DURATION, 0, 1)
        local currentItemDuration = MIN_ITEM_SHOW_TIME 
            + (MAX_ITEM_SHOW_TIME - MIN_ITEM_SHOW_TIME) * (progress ^ 2)
        
        -- Обновить ProgressBar
        local fillProgress = 1 - (itemTimer / currentItemDuration)
        ProgressFill.Size = UDim2.new(math.clamp(fillProgress, 0, 1), 0, 1, 0)
        
        -- Смена элемента
        if itemTimer >= currentItemDuration then
            itemTimer = 0
            
            if currentIndex <= #sequence then
                displayItem(sequence[currentIndex])
                currentIndex += 1
            else
                -- Конец прокрутки
                connection:Disconnect()
                showResult(finalResult)
            end
        end
    end)
end
```

---

**displayItem(item):**
```lua
local function displayItem(item)
    -- Обновить ItemDisplay
    if item.type == "pet" then
        PetNameLabel.Text = item.name
        RarityLabel.Text  = item.rarity
        RarityLabel.TextColor3 = getRarityColor(item.rarity)
    elseif item.type == "key" then
        PetNameLabel.Text = "Золотой ключ"
        RarityLabel.Text  = "Особый"
    elseif item.type == "bomb" then
        PetNameLabel.Text = "Бомба!"
        RarityLabel.Text  = "Особый"
    end
    
    -- Scale анимация (пульс при смене)
    ItemDisplay.Size = UDim2.new(0.9, 0, 0.9, 0)
    StatefulObjectController.Tween(ItemDisplay, 
        { Size = UDim2.new(1, 0, 1, 0) }, 0.05, Enum.EasingStyle.Back)
end
```

---

**showResult(result):**
```lua
local function showResult(result)
    -- Скрыть прогресс бар
    ProgressBar.Visible = false
    
    -- Показать ResultFrame
    ResultFrame.Visible = true
    
    if result.type == "pet" then
        ResultNameLabel.Text   = result.name
        ResultRarityLabel.Text = result.rarity
        ResultRarityLabel.TextColor3 = getRarityColor(result.rarity)
        -- Увеличить иконку питомца
        StatefulObjectController.Tween(ItemIcon, 
            { Size = UDim2.new(1.2, 0, 1.2, 0) }, 0.3, Enum.EasingStyle.Back)
    elseif result.type == "key" then
        ResultNameLabel.Text = "Золотой ключ!"
    elseif result.type == "bomb" then
        ResultNameLabel.Text = "Бомба!"
    end
    
    -- Звук
    AudioController.Play(AudioController.Sounds.RouletteEnd)
    if result.type == "pet" then
        AudioController.Play(AudioController.Sounds.PetGet)
    end
end
```

---

**Кнопки результата:**
```lua
TakeButton.MouseButton1Click:Connect(function()
    AudioController.Play(AudioController.Sounds.ButtonClick)
    hideRoulette()
    -- Запустить анимацию питомца (бег к базе)
    if lastResult and lastResult.type == "pet" then
        PetController.SpawnAndRun(lastResult)
    end
end)

ExitButton.MouseButton1Click:Connect(function()
    AudioController.Play(AudioController.Sounds.ButtonClick)
    hideRoulette()
end)

local function hideRoulette()
    StatefulObjectController.Tween(BackgroundFrame, { BackgroundTransparency = 1 }, 0.2)
    task.wait(0.2)
    RouletteGui.Enabled = false
    ProgressBar.Visible = true
    ResultFrame.Visible = false
    ProgressFill.Size   = UDim2.new(1, 0, 1, 0)
    lastResult = nil
end
```

---

**Цвета редкостей:**
```lua
local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(100, 200, 100),
    Rare      = Color3.fromRGB(100, 150, 255),
    Epic      = Color3.fromRGB(180, 100, 255),
    Legendary = Color3.fromRGB(255, 180, 50),
}

local function getRarityColor(rarity)
    return RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
end
```

---

**Init(): подключить Roulette_Show Remote:**
```lua
function RouletteController.Init()
    Remotes.Roulette_Show.OnClientEvent:Connect(function(result)
        lastResult = result
        RouletteController.Show(result)
    end)
end
```

---

**Связь с BalloonController:**
В `BalloonController` раскомментировать:
```lua
elseif result.type == "roulette" then
    AudioController.Play(AudioController.Sounds.Coin)
    -- Рулетка запустится через Roulette_Show Remote (сервер сам пошлёт)
    -- BalloonController только возвращает камеру и персонажа
    returnCamera()
    setCharacterVisible(true)
    setStartButtonState("idle")
```

**В BalloonService (сервер) добавить:** после `RouletteService.Roll`:
```lua
Remotes.Roulette_Show:FireClient(player, result)
```

---

### 2. `StarterPlayerScripts/Modules/PetController` (ModuleScript)

Визуальное отображение питомцев. Для MVP — упрощённая версия.

**Интерфейс:**
```lua
PetController.Init()
PetController.Start()

-- Спавн питомца у шара и "бег" к базе
PetController.SpawnAndRun(petResult: RouletteResult)

-- Обновить визуальные модели на стендах
PetController.RefreshStands(standPets: table)
```

**SpawnAndRun (MVP — упрощённая версия):**
```lua
-- В MVP: показать простую Part над шаром, через 2 сек убрать
-- Полная версия (POST-MVP): анимированная модель питомца бежит к базе
function PetController.SpawnAndRun(petResult)
    -- Создать временную метку над шаром
    local part = Instance.new("Part")
    part.Size     = Vector3.new(1, 1, 1)
    part.Anchored = true
    part.Position = BalloonPart.Position + Vector3.new(0, 3, 0)
    part.BrickColor = BrickColor.new("Bright yellow")
    part.Parent = workspace
    
    local label = Instance.new("BillboardGui")
    label.Size  = UDim2.new(0, 100, 0, 50)
    label.Parent = part
    local text = Instance.new("TextLabel")
    text.Text = petResult.name .. "\n" .. petResult.rarity
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = getRarityColor(petResult.rarity)
    text.TextScaled = true
    text.Parent = label
    
    -- Через 2 сек убрать
    task.delay(2, function()
        StatefulObjectController.Tween(part, { Transparency = 1 }, 0.5)
        task.wait(0.5)
        part:Destroy()
    end)
end
```

**RefreshStands:**
```lua
-- Обновляет визуальные метки на стендах базы игрока
-- MVP: просто Part с BillboardGui на каждом занятом слоте
-- Подписывается на Replica изменения StandPets в Init()
function PetController.Init()
    ReplicaClient.OnNew("PlayerData", function(replica)
        PetController.RefreshStands(replica.Data.StandPets)
        
        replica:OnSet({"StandPets"}, function(new)
            PetController.RefreshStands(new)
        end)
    end)
end
```

---

### 3. Обновить `Client.client`

```lua
local RouletteController = require(PlayerScripts.Modules.RouletteController)
local PetController      = require(PlayerScripts.Modules.PetController)

RouletteController.Init()
PetController.Init()
RouletteController.Start()
PetController.Start()
```

---

## Проверка результата

**Play Solo:**
1. Надуть шар и отпустить несколько раз
2. При выпадении рулетки (1/10): RouletteGui появляется с анимацией
3. Прокрутка занимает ~6.5 сек, замедляется к концу
4. Финальный результат отображается с правильным цветом редкости
5. Кнопка "Забрать" закрывает рулетку, над шаром появляется метка питомца
6. Pets в Replica обновляется → HUD реагирует (если есть счётчик)
