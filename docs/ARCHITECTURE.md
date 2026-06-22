# Blow Biggest Balloon — Architecture Reference

> Единый каркас архитектуры проекта.  
> Читается перед каждой AI-сессией разработки.

## 1. Stack
| Layer | Decision |
|---|---|
| IDE | Roblox Studio (без Rojo) |
| Language | Luau |
| Persistence | ProfileStore.lua |
| State replication | Replica (MadStudio) |
| Networking | Replica + RemoteEvents для one-shot событий |
| Animation | StatefulObjectController → TweenService |
| Audio | AudioController.Play(soundName) |


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
│   │   ├── TableUtil          (ModuleScript)
│   │   └── FormatNumber       (ModuleScript)
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
    ├── IndexService           (ModuleScript)
    ├── RouletteService        (ModuleScript)
    ├── PetService             (ModuleScript)
    ├── PetMovementService     (ModuleScript)
    ├── EconomyService         (ModuleScript)
    ├── LuckService            (ModuleScript)
    ├── BaseService            (ModuleScript)
    └── RebirthService         (ModuleScript)  ← POST-MVP

### New (Stage 3)
ServerScriptService
└── Modules/
    ├── StrayPetService         (ModuleScript)
    └── StickerService          (ModuleScript)

StarterPlayerScripts
├── Client.client              (LocalScript)
└── Modules/
    ├── BalloonController      (ModuleScript)
    ├── RouletteController     (ModuleScript)
    ├── PetController          (ModuleScript)
    ├── HudController          (ModuleScript)
    ├── ShopController         (ModuleScript)
    ├── RobuxShopController    (ModuleScript)
    ├── RebirthController       (ModuleScript)
    ├── AudioController        (ModuleScript)
    ├── StatefulObjectController (ModuleScript)
    ├── IndexController (ModuleScript)
    └── TutorialController     (ModuleScript)

StarterGui
└── (UI Frames созданы вручную в Studio, скриптами только управляются)
```

## 2. Core Constraints
- Максимум игроков на сервере: 4
- Количество баз в текущем MVP: 4
- Все критичные игровые данные хранятся и изменяются только на сервере
- Клиент отвечает только за UI, ввод и визуализацию
- Replica отражает серверное состояние, но не является источником истины
- Local UI state не считается игровой правдой

## 3. Project Structure
### Studio hierarchy
- ReplicatedStorage
- ServerScriptService
- StarterPlayerScripts
- StarterGui
- Workspace

### Repo hierarchy
- src/shared
- src/server
- src/client

## 4. Module Pattern
Каждый серверный сервис / клиентский контроллер:
- `Init()` — require зависимостей и настройка
- `Start()` — запуск loops и connect'ов

Порядок:
1. Все `Init()`
2. Все `Start()`

## 5. require() Convention
- Shared-код лежит в `ReplicatedStorage.Shared`
- Серверные либы лежат в `ServerScriptService.Lib`
- Клиентские либы лежат в `ReplicatedStorage.Lib`

## 6. WaitForChild Convention
- Обязательные узлы Workspace проверяются на верхнем уровне модуля или в `Init()`
- UI-узлы из `PlayerGui` ищутся после загрузки UI
- Если элемент может появиться позже — использовать безопасную повторную проверку

## 7. Ownership Rules
- `PlayerService` owns player lifecycle, profile loading, replica creation, ready-subscription, and character spawn positioning
- `BaseService` owns base assignment, base ownership labels, and spawn CFrame lookup for assigned bases
- `EconomyService` owns currency mutations
- `LuckService` owns luck calculation
- `IndexService` owns pet collection index mutation and persistence
- `RouletteService` owns roulette outcome generation
- `TutorialService` owns tutorial progression
- `MonetizationService` owns GamePass / DevProduct flow
- `StrayPetService` owns stray pet lifecycle (create, buy, claim, cleanup)
- `StickerService` owns sticker equip / unequip validation

## 8. Runtime Flow
1. `PlayerService` receives `Players.PlayerAdded`
2. `PlayerService` loads profile via `ProfileStore`
3. `PlayerService` creates `Replica` for player data
4. `PlayerService` subscribes replica only after the player is marked ready by `ReplicaServer`
5. `BaseService` assigns a base to the player
6. `PlayerService` listens to `CharacterAdded` and teleports the character to the assigned base spawn point if available
7. On respawn, `CharacterAdded` again applies the same spawn logic

## 9. Forbidden Changes
- Нельзя менять формат сохранения без миграции
- Нельзя переносить server logic на client
- Нельзя переименовывать публичные API без необходимости
- Нельзя создавать дублирующие системы
- Нельзя добавлять новые remotes без записи в `contracts/REMOTES.md`
- Нельзя менять data schema без обновления `contracts/DATA_SCHEMA.md`
- Нельзя вызывать `Replica:Subscribe(player)` до того, как игрок станет ready в `ReplicaServer`
- Если игрок ещё не ready, нужно ждать `ReplicaServer.NewReadyPlayer` или проверять `ReplicaServer.ReadyPlayers[player]`

## 10. Document Version
- Architecture version: v1.1
- Last updated: 2026-06-19
- Breaking changes must be reflected in contracts and state docs
