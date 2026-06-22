# Bases System

## Responsibility
- Assign player base
- Track base ownership in session
- Update owner signs
- Provide base id to client
- Provide spawn CFrame for assigned base

## Server Side
### BaseService
- assigns free base on join
- clears base on leave
- exposes `GetBaseId(player)`
- exposes `GetSpawnCFrame(player)`

## Workspace Structure
- `Workspace.Location.Bases`
- `Base1 ... Base4`
- each base has:
  - `BaseArea`
  - `StandSlot_N`
  - `OwnerSign`
  - `SpawnPoint`

## Spawn Point Contract
Каждая база в `Workspace.Location.Bases.BaseN` должна содержать:
- `SpawnPoint` (`BasePart`)

### Rules
- `SpawnPoint` используется как точка появления игрока рядом с его базой
- `SpawnPoint` должен быть `Anchored = true`
- `SpawnPoint` должен быть `CanCollide = false`
- `SpawnPoint` должен быть расположен в безопасной точке рядом с базой
- `SpawnPoint` должен быть назван строго `SpawnPoint`

### API
#### `BaseService.GetSpawnCFrame(player) -> CFrame?`
- Возвращает `CFrame` `SpawnPoint` назначенной игроку базы
- Возвращает `nil`, если база не назначена или `SpawnPoint` не найден

## Notes
- Base ownership is in-memory
- No ProfileStore persistence for base assignment
- Количество баз в MVP соответствует максимальному числу игроков на сервере