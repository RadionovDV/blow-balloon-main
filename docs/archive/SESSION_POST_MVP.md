# SESSION POST-MVP — После завершения MVP

> Эти задачи выполняются ПОСЛЕ того, как MVP полностью работает.  
> Порядок внутри документа — рекомендуемый, но не жёсткий.

---

## Блок A — Монетизация

### A1. GamePass полная реализация
- `BalloonCosmetics`: наклейки на шары (UI выбора наклейки в BalloonHudGui)
- `SkipAnimation`: пропуск рулетки, сразу показывается результат в RouletteController
- `StarterPack`: в PlayerService при Rebirth давать стартовые монеты если есть пасс
- `SavePet`: в PetService при `AddPet` если нет места и есть пасс — питомец становится прозрачным, не исчезает

### A2. DevProduct полная реализация
Заполнить `DevProductHandlers` в Server.server:
```lua
local DevProductHandlers = {
    [GameConfig.DEVPRODUCT_IDS.ServerLuck] = function(player)
        LuckService.AddServerBoost(GameConfig.SERVER_BOOST_AMOUNT, GameConfig.SERVER_BOOST_DURATION)
        -- Уведомить всех игроков
        for _, p in ipairs(Players:GetPlayers()) do
            Remotes.Notification:FireClient(p, { 
                text = player.Name .. " активировал Server Luck Boost на 30 мин!", 
                style = "boost" 
            })
        end
    end,
    [GameConfig.DEVPRODUCT_IDS.BalloonWithPet] = function(player)
        -- Следующий шар гарантирует питомца (флаг в session data)
    end,
    [GameConfig.DEVPRODUCT_IDS.AdoptPet] = function(player)
        -- Выкупить бесхозного питомца (если есть в очереди)
    end,
}
```

---

## Блок B — Rebirth

### B1. RebirthService
```lua
-- Условия:
-- 1. Coins >= GameConfig.REBIRTH_COIN_REQUIREMENT
-- 2. Наличие 2 конкретных питомцев (определить в GameConfig)
-- Сброс: Pets, Coins, Balloons (кроме Default)
-- Награда: BaseLuck += GameConfig.REBIRTH_LUCK_MULTIPLIER
--          если StarterPack GamePass → дать стартовые монеты
-- Обновить Replica после сброса
```

### B2. RebirthController (клиент)
- Кнопка Rebirth (появляется если выполнены условия)
- Анимация подтверждения (попап с предупреждением о сбросе)

---

## Блок C — Расширенные питомцы

### C1. Бесхозный питомец
В PetService при `AddPet` если `#data.Pets >= data.BaseSlots`:
- Создать `wanderingPets[player]` запись
- Через 30 сек удалить питомца
- Другие игроки видят питомца → могут купить через `AdoptPet` DevProduct

### C2. Анимированный бег к базе
В `PetController.SpawnAndRun`:
- Загрузить модель питомца из Assets
- Tween/lerp позиции от шара к свободному слоту базы
- По прибытии: анимация "settle"

### C3. Продажа питомца
ProximityPrompt на питомце на стенде → `PetService.SellPet`  
Цена продажи = `petConfig.cost * 0.5` (50% от стоимости)

---

## Блок D — Расширение базы

### D1. Ключи — инвентарь
Добавить в ProfileTemplate:
```lua
Keys = 0,  -- количество ключей
```
В RouletteService при `type=="key"` → `EconomyService`-аналог для ключей.

### D2. UpgradeBase полная реализация
В PetService.UpgradeBase снять TODO:
```lua
-- Списать ключ
if data.Keys < GameConfig.BASE_UPGRADE_KEY_COST then return false end
data.Keys -= GameConfig.BASE_UPGRADE_KEY_COST
PlayerService.GetReplica(player):Set({"Keys"}, data.Keys)
-- Добавить слот
...
```

---

## Блок E — Game Feel расширение

### E1. Смена музыкальных треков
В `AudioController` добавить:
```lua
AudioController.StartMusicRotation()
-- Запускает loop: через каждые 60-120 сек меняет трек на следующий Music_N
```

### E2. Bomb эффект в рулетке
В RouletteController для `result.type == "bomb"`:
- Специальная анимация взрыва (красный фон, VFX)
- Игрок теряет часть монет (логика в BombService или BalloonService)

### E3. 3D VFX лопания шара
Заменить простой эффект на ParticleEmitter в BalloonController.

---

## Блок F — Новые коллекции питомцев

В PetConfig добавить новые коллекции:
```lua
Forest = {
    { name = "ForestFox",   rarity = "Common",    ... },
    { name = "TreeOwl",     rarity = "Uncommon",  ... },
    ...
},
```
Новые шары в BalloonConfig с `collectionName = "Forest"`.  
RarityUtil.FilterByMaxRarity уже поддерживает несколько коллекций — дополнительных изменений не требуется.

---

## Блок G — Туториал полный

Завершить оставшиеся шаги туториала (SESSION_8 реализует только часть).  
Добавить стрелки-указатели (TutorialArrow) к нужным UI-элементам на каждом шаге.
