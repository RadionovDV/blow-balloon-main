# UI System

## Responsibility
- Client-only visuals
- HUD
- inventory panels
- notifications
- tutorial prompts

## Rules
- UI does not own game truth
- UI reacts to Replica or one-shot remotes
- UI should not mutate server-critical state directly

## Controllers
- `HudController`
- `ShopController`
- `IndexController`
- `TutorialController`
- `RouletteController`
