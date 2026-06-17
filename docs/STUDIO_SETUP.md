# STUDIO_SETUP — Ручная настройка Roblox Studio

> Этот документ описывает всё, что нужно создать вручную в Roblox Studio  
> ДО начала написания скриптов.  
> Скрипты копируются из файлов репозитория в нужные Instance после этого.

---

## Шаг 1 — Разместить библиотеки (Lib)

### В ReplicatedStorage создать папку `Lib`:
1. `ReplicatedStorage` → Insert Object → **Folder** → назвать `Lib`
2. В `Lib` создать **Folder** → `ReplicaShared`
3. В `ReplicaShared` создать 4 **ModuleScript**:
   - `Maid` — скопировать содержимое из `./Replica/ReplicaShared/Maid.lua`
   - `RateLimit` — из `./Replica/ReplicaShared/RateLimit.lua`
   - `Remote` — из `./Replica/ReplicaShared/Remote.lua`
   - `Signal` — из `./Replica/ReplicaShared/Signal.lua`
4. В `Lib` создать **ModuleScript** → `ReplicaClient` — из `./Replica/ReplicaClient.lua`

### В ServerScriptService создать папку `Lib`:
1. `ServerScriptService` → Insert Object → **Folder** → `Lib`
2. В `Lib` создать **ModuleScript** → `ReplicaServer` — из `./Replica/ReplicaServer.lua`
3. В `Lib` создать **ModuleScript** → `ProfileStore` — из `./ProfileStore.lua`

---

## Шаг 2 — Создать структуру папок

### ReplicatedStorage:
```
Shared/
  Config/      (Folder)
  Util/        (Folder)
Assets/
  Sounds/      (Folder) ← Sound-объекты вручную
```

### ServerScriptService:
```
Modules/       (Folder)
```

### StarterPlayerScripts:
```
Modules/       (Folder)
```

---

## Шаг 3 — Создать точки входа

1. `ServerScriptService` → Insert Object → **Script** → назвать `Server`
   - RunContext: **Server** (по умолчанию)

2. `StarterPlayerScripts` → Insert Object → **LocalScript** → назвать `Client`

---

## Шаг 4 — Создать все ModuleScript-и (пустые заглушки)

Создать пустые ModuleScript с правильными именами, затем копировать код из репозитория.

### ReplicatedStorage/Shared/Config/:
- `GameConfig`
- `BalloonConfig`
- `PetConfig`

### ReplicatedStorage/Shared/Util/:
- `RarityUtil`
- `TableUtil`

### ReplicatedStorage/Shared/:
- `Remotes`

### ServerScriptService/Modules/:
- `PlayerService`
- `EconomyService`
- `LuckService`
- `RouletteService`
- `BalloonService`
- `BalloonShopService`
- `PetService`
- `RebirthService` ← POST-MVP, можно пропустить

### StarterPlayerScripts/Modules/:
- `StatefulObjectController`
- `AudioController`
- `HudController`
- `BalloonController`
- `RouletteController`
- `PetController`
- `ShopController`
- `TutorialController`

---

## Шаг 5 — Создать UI (StarterGui)

### HudGui (ScreenGui)
- `ResetOnSpawn = false`
- `IgnoreGuiInset = true` (опционально)
- Содержимое:
  - `CoinsLabel` (TextLabel) — позиция вверху слева
  - `LuckLabel` (TextLabel) — позиция внизу слева

### NotificationGui (ScreenGui)
- `ResetOnSpawn = false`
- `NotificationFrame` (Frame, `Visible = false`)
  - Позиция: центр сверху
  - `NotificationText` (TextLabel)
  - `UICorner` для скруглённых углов

### BalloonHudGui (ScreenGui)
- `Enabled = false`
- `StartButton` (TextButton) — центр снизу
- `ExitButton` (TextButton, `Visible = false`) — сверху справа
- `BalloonListFrame` (Frame) — справа, вертикальный список
  - `BalloonItemTemplate` (Frame, `Visible = false`) — шаблон
    - `BalloonNameLabel` (TextLabel)
    - `SelectButton` (TextButton)
- `LuckBarFrame` (Frame) — снизу, во всю ширину
  - `LuckLabel` (TextLabel)

### RouletteGui (ScreenGui)
- `Enabled = false`
- `BackgroundFrame` (Frame) — полноэкранный, `BackgroundTransparency = 1`
- `RouletteFrame` (Frame) — центр экрана
  - `ItemDisplay` (Frame) — главный дисплей элемента
    - `PetNameLabel` (TextLabel)
    - `RarityLabel` (TextLabel)
    - `ItemIcon` (ImageLabel) — иконка
  - `ProgressBar` (Frame) — справа
    - `ProgressFill` (Frame) — уменьшается до 0
  - `ResultFrame` (Frame, `Visible = false`)
    - `ResultNameLabel` (TextLabel)
    - `ResultRarityLabel` (TextLabel)
    - `TakeButton` (TextButton)
    - `ExitButton` (TextButton)

### ShopGui (ScreenGui)
- `Enabled = false`
- `ShopFrame` (Frame) — центр экрана
  - `CloseButton` (TextButton) — крестик в углу
  - `TitleLabel` (TextLabel) — "Магазин шаров"
  - `BalloonListFrame` (ScrollingFrame) — список шаров
    - `BalloonItemTemplate` (Frame, `Visible = false`)
      - `BalloonNameLabel` (TextLabel)
      - `BalloonPriceLabel` (TextLabel)
      - `BalloonRarityLabel` (TextLabel)
      - `BuyButton` (TextButton)

### TutorialGui (ScreenGui)
- `ResetOnSpawn = false`
- `TutorialFrame` (Frame, `Visible = false`)
  - `TutorialText` (TextLabel)
  - `TutorialArrow` (ImageLabel, `Visible = false`)

---

## Шаг 6 — Создать объекты в Workspace

### BalloonStation (Model)
- `BalloonStation` (Model) — место стояния игрока у шара
  - `BalloonModel` (Model) — сам шар
    - `BalloonPart` (Part) — главная часть, сначала маленькая
      - `BillboardGui` (BillboardGui, `Adornee = BalloonPart`)
        - `RewardLabel` (TextLabel) — деньги над шаром
  - `StandPlatform` (Part) — где стоит игрок
  - `ProximityPrompt` (ProximityPrompt, родитель = `StandPlatform`)
    - `ActionText = "Надуть шар"`
    - `MaxActivationDistance = 8`

### ShopStand (Part или Model)
- Рядом с базой игрока
- `ProximityPrompt`:
  - `ActionText = "Магазин шаров"`

### BaseArea (Model)
- `BaseArea` — зона базы игрока
- `CollectButton` (Part) — наступить для сбора дохода
  - `ProximityPrompt`:
    - `ActionText = "Собрать доход"`
- `StandSlot_1` ... `StandSlot_10` (Parts) — места для стендов питомцев

---

## Шаг 7 — Создать Sound-объекты

В `ReplicatedStorage/Assets/Sounds/` создать Sound Instance для каждого:

| Имя объекта | SoundId | Описание |
|---|---|---|
| `Pop` | rbxassetid://... | Лопание шара |
| `Inflate` | rbxassetid://... | Надувание (зацикленный) |
| `Applause` | rbxassetid://... | Аплодисменты |
| `PetGet` | rbxassetid://... | Получение питомца |
| `Coin` | rbxassetid://... | Монеты |
| `ButtonClick` | rbxassetid://... | Нажатие кнопки |
| `RouletteEnd` | rbxassetid://... | Конец рулетки |
| `Music_1` | rbxassetid://... | Фоновая музыка |

**Где взять SoundId:** Roblox Toolbox → Audio → поиск по ключевым словам.  
Или использовать бесплатные аудио из Roblox Creator Store.

---

## Шаг 8 — Настроить DataStore

В Studio:
1. `File` → `Game Settings` → `Security`
2. Включить **Enable Studio Access to API Services**

Это нужно для тестирования ProfileStore в Studio.

---

## Контрольный список перед первой сессией кода

- [ ] Все папки созданы (Lib, Shared, Config, Util, Modules)
- [ ] Replica файлы скопированы в Lib
- [ ] ProfileStore скопирован в ServerScriptService/Lib
- [ ] Server.server и Client.client созданы (пустые)
- [ ] Все ModuleScript-заглушки созданы
- [ ] UI создан в StarterGui
- [ ] Workspace-объекты созданы
- [ ] Sound-объекты созданы
- [ ] DataStore API Access включён
