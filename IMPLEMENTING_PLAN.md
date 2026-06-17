# IMPLEMENTING_PLAN.md

Архитектурный план реализации игры Blow Balloon (Roblox).

> Статус этапов обновляется вручную: `[ ]` не начат, `[x]` завершён, `[~]` в процессе

---

## Структура файлов (src -> Roblox сервисы)

| src/               | Roblox Studio (при переносе)       |
|--------------------|------------------------------------|
| server/            | ServerScriptService                |
| client/            | StarterPlayer.StarterPlayerScripts |
| shared/            | ReplicatedStorage (Shared)         |

```
src/
├── server/
│   ├── Main.server.lua
│   └── services/
│       ├── BalloonService.lua
│       ├── PetService.lua
│       ├── ShopService.lua
│       ├── BaseService.lua
│       ├── RebirthService.lua          # Этап 3
│       ├── RankingService.lua          # MORE_FEATURES
│       ├── QuestService.lua            # MORE_FEATURES
│       ├── ServerEventService.lua      # MORE_FEATURES
│       └── TutorialService.lua
│
├── client/
│   ├── Main.client.lua
│   ├── controllers/
│   │   ├── BalloonController.lua
│   │   ├── RouletteController.lua
│   │   ├── CameraController.lua
│   │   ├── ShopController.lua
│   │   ├── BaseController.lua
│   │   ├── HUDController.lua
│   │   ├── TutorialController.lua
│   │   └── RatingController.lua        # MORE_FEATURES
│   └── ui/
│       └── UIManager.lua
│
└── shared/
    ├── GameConfig.lua
    ├── NetworkBridge.lua
    ├── PlayerData/
    │   ├── PlayerDataServer.lua       # СУЩЕСТВУЕТ
    │   └── PlayerDataClient.lua       # СУЩЕСТВУЕТ
    ├── StatefulObjectController.lua   # СУЩЕСТВУЕТ
    ├── Signal.lua                     # СУЩЕСТВУЕТ
    ├── AudioController.lua
    └── utils/
        └── RaritySystem.lua
```

---

## Схема PlayerData

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

---

## NetworkBridge (shared/NetworkBridge.lua)

| Категория    | Событие           | Тип        | Описание                     |
|--------------|-------------------|------------|------------------------------|
| Balloon      | StartBlow         | RemoteEvent| Начать надувание             |
| Balloon      | StopBlow          | RemoteEvent| Отпустить кнопку             |
| Balloon      | BalloonPopped     | RemoteEvent| Шар лопнул                   |
| Balloon      | RouletteTriggered | RemoteEvent| Запуск рулетки               |
| Shop         | BuyBalloon        | RemoteFunc | Купить шар                   |
| Shop         | EquipBalloon      | RemoteEvent| Снарядить шар                |
| Base         | CollectIncome     | RemoteFunc | Собрать доход                |
| Base         | SellPet           | RemoteFunc | Продать питомца              |
| Base         | UpgradeBase       | RemoteFunc | Расширить базу               |
| Tutorial     | GetStep           | RemoteFunc | Получить шаг FTUE            |
| Tutorial     | CompleteStep      | RemoteEvent| Завершить шаг FTUE           |
| Rebirth      | PerformRebirth    | RemoteFunc | Совершить Rebirth            |
| ServerEvent  | EventLeaderboard  | RemoteFunc | Топ события (Этап 3)         |

---

## [ ] Этап 1 — Ядро и инфраструктура

**Цель:** игрок подходит к шару, надувает, получает деньги. Без питомцев и магазина.

**Файлы для создания:**
- `shared/GameConfig.lua` — RarityEnum, BalloonConfig, PetConfig, константы
- `shared/NetworkBridge.lua` — реестр Remote-событий
- `server/Main.server.lua` — входная точка сервера
- `server/services/BalloonService.lua` — серверная логика шаров
- `client/Main.client.lua` — входная точка клиента
- `client/controllers/BalloonController.lua` — управление шаром на клиенте
- `client/controllers/CameraController.lua` — камера, фокус, возврат
- `client/controllers/HUDController.lua` — монеты, luckLevel, BillboardGUI
- `client/ui/UIManager.lua` — обёртка StatefulObjectController для UI
- `shared/AudioController.lua` — единый плеер звуков

---

## [ ] Этап 2 — Питомцы, прогрессия, база

**Цель:** полный MVP — рулетка питомцев, магазин шаров, база с питомцами, FTUE.

**Файлы для создания:**
- `shared/utils/RaritySystem.lua` — алгоритм выпадения питомцев
- `server/services/PetService.lua` — выдача питомцев, бесхозные
- `server/services/ShopService.lua` — магазин шаров
- `server/services/BaseService.lua` — слоты, доход, расширение
- `server/services/TutorialService.lua` — FTUE шаги
- `client/controllers/RouletteController.lua` — анимация рулетки
- `client/controllers/ShopController.lua` — UI магазина
- `client/controllers/BaseController.lua` — UI базы
- `client/controllers/TutorialController.lua` — UI FTUE

---

## [ ] Этап 3 — Монетизация, More Features, полировка

**Цель:** все фичи из MORE_FEATURES, GamePass/DevProd интеграция, события.

**Файлы для создания / доработки:**
- `server/services/RebirthService.lua` — сброс прогресса, luck multiplier
- `server/services/RankingService.lua` — система рейтинга
- `server/services/QuestService.lua` — система заданий
- `server/services/ServerEventService.lua` — гонка рейтинга
- `client/controllers/RatingController.lua` — UI рейтинга
- Доработка BalloonService: Server Luck, Balloon Cosmetics
- Доработка PetService: Index (petsEverOwned), приют питомца, Save Pet
- Доработка RouletteController: Skip Animation GP, перетягивание питомца
- Доработка ShopController: поставки шаров (таймер 15 мин)
- Нить от шара: RopeConstraint в BalloonController
- Система лояльности: интеграция в RaritySystem
- Rebirth Save: сохранение balloonSaveSlots в RebirthService

---

## Правила разработки

1. **Сервер авторитарен.** Клиент только отправляет намерения. Все расчёты на сервере.
2. **NetworkBridge** — единственное место регистрации Remote-событий.
3. **GameConfig** — единственный источник констант и RarityEnum.
4. **PlayerDataServer/PlayerDataClient** — все изменения данных только через их API.
5. **UIManager** (через StatefulObjectController) — для всех Tween-анимаций UI.
6. **AudioController.Play(name)** — для всех звуков без исключений.
7. **Signal** вместо BindableEvent для внутрисерверной/внутриклиентской логики.
8. **Существующие модули** не изменять — только импортировать.

---

## Связанные документы

- `API_REFERENCE.md` — полный справочник API существующих модулей и форматов данных
- `TECHNICAL_SPECIFICATION.md` — полное описание MVP-фич
- `MORE_FEATURES.md` — фичи для реализации после MVP
- `AGENT.md` — контекст и соглашения проекта
