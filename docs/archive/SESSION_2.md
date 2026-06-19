# SESSION 2 — PlayerService + ProfileStore + Replica

> **Цель сессии:** Загружать/сохранять данные игрока через ProfileStore, реплицировать их клиенту через Replica.  
> После сессии: при входе игрока в Studio его данные загружаются, при выходе — сохраняются.  
> Клиент может читать данные через `ReplicaClient.OnNew("PlayerData", ...)`.

---

## Контекст проекта

Игра: Roblox Tycoon "Blow Biggest Balloon"  
Стек: Luau, ProfileStore, Replica (MadStudio), только Roblox Studio  
Полная архитектура: см. `docs/ARCHITECTURE.md`  
Пройденные сессии: SESSION_1 (Config, Utils, Remotes) ✓

---

## Предусловия (уже должно существовать)

```
ServerScriptService/Lib/ProfileStore    (ModuleScript)
ServerScriptService/Lib/ReplicaServer   (ModuleScript)
ReplicatedStorage/Lib/ReplicaClient     (ModuleScript)
ReplicatedStorage/Lib/ReplicaShared/    (папка с Maid, Signal, Remote, RateLimit)
ReplicatedStorage/Shared/Config/GameConfig  ✓
```

Если файлы Lib отсутствуют — остановиться и сообщить.

---

## Задачи сессии

### 1. `ServerScriptService/Modules/PlayerService` (ModuleScript)

Центральный сервис данных игрока. Все другие сервисы читают данные ТОЛЬКО через него.

**Интерфейс:**
```lua
PlayerService.Init()
PlayerService.Start()

-- Возвращает таблицу данных ProfileStore для игрока (прямая ссылка)
PlayerService.GetData(player: Player): ProfileData?

-- Возвращает объект Replica для игрока (для Set операций)
PlayerService.GetReplica(player: Player): Replica?

-- GamePass cache
PlayerService.HasPass(player: Player, passName: string): boolean

-- Утилита для других сервисов: безопасное изменение данных
-- Автоматически вызывает playerReplica:Set(path, value)
PlayerService.SetData(player: Player, path: {string}, value: any)
```

**ProfileTemplate** (схема из ARCHITECTURE.md):
```lua
local ProfileTemplate = {
    Coins         = 0,
    Balloons      = { Default = 1 },
    ActiveBalloon = "Default",
    Pets          = {},
    StandPets     = {},
    BaseLevel     = 1,
    BaseSlots     = 10,
    RebirthCount  = 0,
    BaseLuck      = 1,
    LuckBonuses   = {
        temporary = {},
        permanent = 0,
    },
    TutorialStep  = 0,
    GamePasses    = {},  -- { [passName]: bool } — заполняется при входе
}
```

**Логика Init():**
- Создать ProfileStore с шаблоном
- Зарегистрировать ReplicaServer.Token("PlayerData")
- Подключить Players.PlayerAdded → загрузка профиля
- Подключить Players.PlayerRemoving → сохранение и очистка

**Логика загрузки профиля (PlayerAdded):**
1. `ProfileStore:StartSessionAsync(tostring(player.UserId))`
2. Если профиль не загрузился → kick игрока с сообщением
3. Зарегистрировать `profile:OnSessionEnd(fn)` → kick игрока
4. Проверить GamePasses через `MarketplaceService:UserOwnsGamePassAsync`  
   (по `GameConfig.GAMEPASS_IDS`, pcall для безопасности)  
   Записать результаты в `profile.Data.GamePasses`
5. Создать Replica:
   ```lua
   local replica = ReplicaServer.New({
       Token = PlayerDataToken,
       Tags  = { UserId = player.UserId },
       Data  = profile.Data,
   })
   replica:Subscribe(player)
   ```
6. Сохранить в локальные таблицы `profiles[player]` и `replicas[player]`
7. Фильтровать истёкшие temporary LuckBonuses (по `os.time()`)

**Логика выгрузки (PlayerRemoving):**
1. Если replica существует → `replica:Destroy()`
2. `profile:EndSession()`
3. Очистить таблицы

**PlayerService.SetData(player, path, value):**
```lua
-- Изменяет данные в профиле И реплицирует клиенту:
local data = PlayerService.GetData(player)
-- Обход пути для записи в data (кроме последнего ключа)
-- ...
data[lastKey] = value
local replica = PlayerService.GetReplica(player)
replica:Set(path, value)
```

**Важно:** `profile.Data` — это прямая ссылка на таблицу, которую Replica использует как `Data`.  
Прямое изменение `profile.Data.Coins = 100` НЕ реплицирует клиенту.  
Всегда использовать `PlayerService.SetData` или `replica:Set` напрямую.

---

### 2. `ServerScriptService/Server.server` (Script)

Точка входа сервера. Инициализирует все сервисы в правильном порядке.

```lua
-- В Session 2 только PlayerService:
local PlayerService = require(...)

PlayerService.Init()
PlayerService.Start()

-- В будущих сессиях сюда добавятся другие сервисы.
-- Паттерн: сначала все .Init(), потом все .Start()
```

---

### 3. `StarterPlayerScripts/Client.client` (LocalScript)

Точка входа клиента. Запускает Replica и контроллеры.

```lua
-- В Session 2: только инициализация Replica
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)

-- Прослушивание данных игрока (для отладки в этой сессии)
ReplicaClient.OnNew("PlayerData", function(replica)
    print("[Client] PlayerData received, Coins:", replica.Data.Coins)
    
    replica:OnSet({"Coins"}, function(new, old)
        print("[Client] Coins changed:", old, "->", new)
    end)
end)

ReplicaClient.RequestData()

-- В будущих сессиях сюда добавятся require и Init контроллеров.
```

---

## Что НЕ делать в этой сессии

- Не писать BalloonService, EconomyService и другие сервисы
- Не писать клиентские контроллеры (BalloonController и т.д.)
- Не создавать UI

---

## Проверка результата

**В Studio (Play Solo):**
1. Открыть Output
2. Должно появиться: `[Client] PlayerData received, Coins: 0`
3. В Command Bar выполнить:
   ```lua
   local SSS = game:GetService("ServerScriptService")
   local PS = require(SSS.Modules.PlayerService)
   local player = game.Players:GetPlayers()[1]
   PS.SetData(player, {"Coins"}, 999)
   -- В Output клиента должно появиться: [Client] Coins changed: 0 -> 999
   ```
4. Выйти из Play и зайти снова — Coins должен вернуться в 0 (тест сохранения; в Studio DataStore может не сохранять без API Access)
