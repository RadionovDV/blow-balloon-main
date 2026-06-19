# Luck System

## Responsibility
- Calculate player luck
- Combine all sources of luck
- Provide one canonical luck value

## Luck Sources
- BaseLuck from profile
- temporary luck bonuses
- permanent luck bonuses
- server boost
- inflate bonus

## Server Side
### LuckService
- `GetLuck(player, inflateLuck) -> number`
- filters expired temporary bonuses
- returns total luck