# API Rules

## General Rules
- Public methods validate input
- Invalid requests return `false` / `nil`, not crash
- RemoteFunction handlers must not throw unhandled errors
- Server always validates client input

## Service API Style
- `Init()` — only setup
- `Start()` — only runtime start
- Public methods should be small and explicit
- One method = one responsibility

## Return Conventions
- `true/false` for success state
- `value, err` only when нужно объяснить причину ошибки
- No silent mutation without server validation

## Replica Subscription Rules
- `Replica:Subscribe(player)` must only be called when the player is ready in `ReplicaServer`
- If the player is not ready yet, use `ReplicaServer.ReadyPlayers[player]` or wait for `ReplicaServer.NewReadyPlayer`
- Do not use long fixed delays like `task.wait(10)` to work around readiness