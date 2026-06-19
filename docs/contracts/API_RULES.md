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