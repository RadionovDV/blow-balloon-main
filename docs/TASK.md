# TASK.md

## Task Name
Spawn player near assigned base

## Goal
Игрок должен появляться рядом со своей базой, а не на стандартном `SpawnLocation`.

## Context
- В проекте уже есть `BaseService`, который назначает базу игроку
- В проекте уже есть `PlayerService`, который загружает профиль
- Нужна минимальная правка без изменения архитектуры
- Никаких новых сервисов и никаких рефакторингов “заодно”

## Scope

### In scope
- Добавить точку спавна внутри каждой базы
- Добавить возможность получить spawn CFrame для базы игрока
- Телепортировать персонажа к своей базе при первом спавне
- Телепортировать персонажа к своей базе при респавне
- Сохранить fallback: если база ещё не назначена, игрок остаётся на стандартном SpawnLocation

### Out of scope
- Переписывание архитектуры проекта
- Перенос назначения базы из `BaseService` в `PlayerService`
- Добавление новых сервисов
- Добавление RemoteEvent / RemoteFunction
- Изменение UI
- Изменение сохранения данных
- Изменение логики назначения баз

## Files Allowed to Change
- `src/server/Modules/BaseService.lua`
- `src/server/Modules/PlayerService.lua`
- `Workspace` — только если нужен `SpawnPoint` внутри каждой базы

## Related Contracts
- `docs/ARCHITECTURE.md`
- `docs/systems/BASES.md`
- `docs/contracts/API_RULES.md`

## Expected Behavior
- После входа игрок появляется рядом со своей базой
- После смерти и респавна игрок снова появляется рядом со своей базой
- Если база ещё не назначена, игрок не ломается и остаётся на стандартном spawn
- Решение работает на сервере и не использует client-side teleport

## Recommended Implementation Notes
- Добавить в каждую `BaseN` часть `SpawnPoint`
- В `BaseService` добавить метод `GetSpawnCFrame(player)`
- В `PlayerService` подписаться на `CharacterAdded`
- Телепорт делать через `character:PivotTo(spawnCFrame)`
- Не менять текущий flow назначения базы без необходимости

## Acceptance Criteria
- Игрок больше не появляется на общем `SpawnLocation`, если база уже назначена
- Первый спавн работает
- Респавн работает
- Если база ещё не назначена, fallback работает без ошибок
- В Output нет ошибок

## Verification Steps
1. Запустить игру
2. Проверить, что игрок появляется у своей базы
3. Умереть и проверить респавн
4. Проверить поведение при отсутствии базы
5. Проверить, что стандартный spawn остаётся fallback