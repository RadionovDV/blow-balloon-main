Ты работаешь как senior Roblox Studio / Luau developer.

Задача:
Игрок должен появляться рядом со своей базой, а не на стандартном SpawnLocation.

Важно:
- Нужна чистая архитектура
- PlayerService должен быть оркестратором жизненного цикла игрока
- BaseService должен заниматься только базами
- Не использовать BindableEvent
- Не использовать скрытые хак-поля вроде BaseService._applySpawn
- Не добавлять новые сервисы без необходимости
- Решение должно быть серверным

Контекст файлов:
- docs/ARCHITECTURE.md
- docs/systems/BASES.md
- docs/contracts/API_RULES.md
- docs/TASK.md

Требования к решению:
1. BaseService должен иметь только базовую логику:
   - AssignBase(player)
   - ReleaseBase(player)
   - GetBaseId(player)
   - GetSpawnCFrame(player)
2. PlayerService должен:
   - загрузить профиль
   - вызвать BaseService.AssignBase(player)
   - подключить CharacterAdded
   - телепортировать персонажа через ApplySpawnForPlayer(player)
3. Использовать character:PivotTo(spawnCFrame)
4. Если база ещё не назначена — ничего не ломать, fallback SpawnLocation должен работать
5. Поддерживать и первый спавн, и респавн

Правила ответа:
- Сначала кратко опиши понимание задачи
- Потом покажи план
- Потом дай код
- Не выходи за scope
- Не меняй лишнюю архитектуру
- Если нужен какой-то минимальный Workspace change, укажи его отдельно

Формат ответа:
## Understanding
## Plan
## Code
## Notes