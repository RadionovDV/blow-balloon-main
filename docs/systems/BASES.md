# Bases System

## Responsibility
- Assign player base
- Track base ownership in session
- Update owner signs
- Provide base id to client

## Server Side
### BaseService
- assigns free base on join
- clears base on leave
- exposes `GetBaseId(player)`

## Workspace Structure
- `Workspace.Location.Bases`
- `Base1 ... Base8`
- each base has:
  - `BaseArea`
  - `StandSlot_N`
  - `OwnerSign`

## Notes
- Base ownership is in-memory
- No ProfileStore persistence for base assignment