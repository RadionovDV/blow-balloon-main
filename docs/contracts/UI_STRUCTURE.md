## UI Store (ReplicatedStorage)
ReplicatedStorage.Assets.UI - в этой папке хранятся все UI элементы для динамического названения

### HudGui (ScreenGui)
- `ResetOnSpawn = false`
- `IgnoreGuiInset = true` (опционально)
- Содержимое:
  - `CoinsLabel` (TextLabel) — позиция вверху слева
  - `LuckLabel` (TextLabel) — позиция внизу слева
  - `RightSide` (Frame)
    - `ShopButton` (TextButton)
  - `RebirthFrame` (Frame)
    - `BottomLine` (Frame)
      - `PetSlots` (Frame)
        - `PetSlot` (Frame) - UI Store
      - `RebirthButton` (ImageButton)
        - `Lock` (Frame)
        - `ImageLabel` (ImageLabel)
    - `CoinAmount` (Frame)
      - `Filler`  (Frame)
      - `AmountLabel` (TextLabel)


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
    - `BalloonItemTemplate` (Frame, `Visible = false`) - BalloonItemTemplate из UI Store
      - `BalloonNameLabel` (TextLabel)
      - `BalloonPriceLabel` (TextLabel)
      - `BalloonRarityLabel` (TextLabel)
      - `BuyButton` (TextButton)

### TutorialGui (ScreenGui)
- `ResetOnSpawn = false`
- `TutorialFrame` (Frame, `Visible = false`)
  - `TutorialText` (TextLabel)
  - `TutorialArrow` (ImageLabel, `Visible = false`)
